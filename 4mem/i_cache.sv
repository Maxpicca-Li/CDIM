`include "defines.vh"
// I Cache and L1 I TLB
module i_cache #(
    parameter LEN_LINE = 6,  // 64 Bytes
    parameter LEN_INDEX = 6, // 64 lines
    parameter NR_WAYS = 2
) (
    input               clk,
    input               rst,
    // to cpu
    input               inst_en,
    input  [31:0]       inst_va,
    input  [31:0]       inst_va_next,
    output [31:0]       inst_rdata0,
    output [31:0]       inst_rdata1,
    output              inst_ok0,
    output              inst_ok1,
    output logic        inst_tlb_refill,
    output logic        inst_tlb_invalid,
    input               stallF,
    output              istall,
    input               fence_i,    // only index is useable
    input  [31:0]       fence_addr, // fence_addr used for fence_i
    input               fence_tlb,  // every cop0 executed (mtc0 changed asid/eret/tlbwi/tlbwr should raise fence_tlb)
    // to l2 tlb
    output logic [31:13]itlb_vpn2,
    input               itlb_found,
    input  tlb_entry    itlb_entry,
    // to axi
    output logic [31:0] araddr,
    output logic [ 7:0] arlen,
    output logic [ 2:0] arsize,
    output logic        arvalid,
    input               arready,
    input  [31:0]       rdata,
    input               rlast,
    input               rvalid,
    output logic        rready
);

// defines

localparam LEN_PER_WAY = LEN_LINE + LEN_INDEX;
localparam LEN_TAG = 32 - LEN_LINE - LEN_INDEX;
localparam LEN_BRAM_ADDR = LEN_LINE - 3 + LEN_INDEX;
localparam NR_LINES = 1 << LEN_INDEX;
localparam NR_WORDS = 1 << (LEN_LINE - 2);

typedef struct packed {
    logic [LEN_TAG-1:0] tag;
} icache_tag;

typedef struct packed {
    logic [NR_WAYS-1:0] valid;
    logic LRU;
    // Note: If NR_WAYS > 2, we should implement pseudo-LRU or LFSR.
} icache_meta;

typedef struct packed {
    logic [31:12] vpn;
    logic [31:12] ppn;
    logic uncached;
    logic valid;
} l1_tlb;

enum { IDLE, TLB_FILL, UNCACHED, CACHE_REPLACE, SAVE_RESULT } icache_status;


// metadata
icache_meta meta [NR_LINES-1:0];

// iTLB Translation
l1_tlb itlb;
wire direct_mapped = inst_va[31:30] == 2'b10; // kseg0 and kseg1
wire uncached = direct_mapped ? inst_va[29] : itlb.uncached;
wire [31:12] inst_tag = direct_mapped ? {3'b000, inst_va[28:12]} : itlb.ppn;
wire [31:12] inst_vpn = inst_va[31:12];
wire [31: 0] inst_pa = {inst_tag,inst_va[11:0]};

wire translation_ok = direct_mapped | (itlb.vpn == inst_vpn && itlb.valid);

// icache bram
logic [LEN_PER_WAY-1:LEN_LINE] replace_line_addr; // used for controller replace.

wire bram_addr_choose = (icache_status != IDLE && icache_status != SAVE_RESULT); // 1: inst_va, 0: inst_va_next
wire [LEN_PER_WAY-1:3]          bram_word_addr = bram_addr_choose ? inst_va[LEN_PER_WAY-1:3]         : inst_va_next[LEN_PER_WAY-1:3];
wire [LEN_PER_WAY-1:LEN_LINE]   bram_line_addr = bram_addr_choose ? inst_va[LEN_PER_WAY-1:LEN_LINE]  : inst_va_next[LEN_PER_WAY-1:LEN_LINE];
wire [63:0] cache_data [NR_WAYS-1:0];
icache_tag cache_tag [NR_WAYS-1:0];

logic [7:0] data_wea [NR_WAYS-1:0];
logic tag_wea [NR_WAYS-1:0];
icache_tag tag_ram_wdata;

wire [NR_WAYS-1:0] tag_compare_valid;
wire cache_hit = |tag_compare_valid;

wire cache_hit_available = cache_hit && translation_ok && !uncached;

wire cache_inst_ok0 = cache_hit_available;
wire cache_inst_ok1 = cache_hit_available && inst_va[2] == 1'b0;

// Note: If NR_WAYS > 2, we should mux one hot from tag_compare_valid;
wire i_cache_sel = tag_compare_valid[1];

wire [LEN_PER_WAY-1:LEN_LINE] va_line_addr = inst_va[LEN_PER_WAY-1:LEN_LINE];
wire [LEN_PER_WAY-1:LEN_LINE] fence_index = fence_addr[LEN_PER_WAY-1:LEN_LINE];

wire [31:0] cache_inst0 = inst_va[2]  ? cache_data[i_cache_sel][63:32] : cache_data[i_cache_sel][31:0];
wire [31:0] cache_inst1 =               cache_data[i_cache_sel][63:32];

assign istall = icache_status == IDLE ? (!cache_hit_available & inst_en) : (icache_status != SAVE_RESULT);

logic [31:0] saved_inst0;
logic [31:0] saved_inst1;
logic saved_inst_ok0;
logic saved_inst_ok1;

// to cpu inst ok
assign inst_ok0     = (icache_status == IDLE ? cache_inst_ok0    : saved_inst_ok0) & inst_en;
assign inst_ok1     = (icache_status == IDLE ? cache_inst_ok1    : saved_inst_ok1) & inst_en;
assign inst_rdata0  = icache_status == IDLE ? cache_inst0       : saved_inst0;
assign inst_rdata1  = icache_status == IDLE ? cache_inst1       : saved_inst1;

// axi cnt
logic [LEN_LINE:2] axi_cnt;

// generate bram
genvar i;
generate
    for (i=0;i<NR_WAYS;i++) begin
        dual_port_bram_bw8 #(.LEN_DATA(64),.LEN_ADDR(LEN_PER_WAY-3)) i_data
        (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (1'b1),
            .addra  ({replace_line_addr,axi_cnt[LEN_LINE-1:3]}),
            .dina   (axi_cnt[2]?{rdata,32'h0}:{32'h0,rdata}),
            .wea    (data_wea[i]),
            .addrb  (bram_word_addr),
            .doutb  (cache_data[i])
        );
        dual_port_bram_nobw #(.LEN_DATA(LEN_TAG),.LEN_ADDR(LEN_PER_WAY-LEN_LINE)) i_tag
        (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (1'b1),
            .addra  (replace_line_addr),
            .dina   (tag_ram_wdata),
            .wea    (tag_wea[i]),
            .addrb  (bram_line_addr),
            .doutb  (cache_tag[i])
        );
        assign tag_compare_valid[i] = cache_tag[i].tag == inst_tag && meta[va_line_addr].valid[i];
    end
endgenerate

always_ff @(posedge clk) begin // Cache FSM
    if (rst) begin
        icache_status <= IDLE;
        itlb <= '{default: '0};
        meta <= '{default: '0};
        // clear to cpu output
        inst_tlb_refill <= 0;
        inst_tlb_invalid <= 0;
        itlb_vpn2 <= 0;
        // clear status
        replace_line_addr <= 0;
        data_wea <= '{default: '0};
        tag_wea <= '{default: '0};
        tag_ram_wdata <= 0;
        // clear axi output
        araddr <= 0;
        arlen <= 0;
        arsize <= 0;
        arvalid <= 0;
        rready <= 0;
        // clear axi status
        axi_cnt <= 0;
        // clear saved
        saved_inst0 <= 0;
        saved_inst1 <= 0;
        saved_inst_ok0 <= 0;
        saved_inst_ok1 <= 0;
    end
    else begin
        // assume istall will stop the whole pipeline
        // wait !istall && !stallF to avoid fence dead-lock
        if (fence_tlb && !istall && !stallF) itlb.valid <= 1'b0; 
        if (fence_i && !istall && !stallF) meta[fence_index].valid <= 0;
        case (icache_status)
            IDLE: begin
                if (inst_en) begin
                    if (!translation_ok) begin
                        icache_status <= TLB_FILL;
                        itlb_vpn2 <= inst_vpn[31:13];
                    end
                    else if (uncached) begin
                        araddr <= inst_pa;
                        arlen  <= 0;
                        arsize <= 3'd2;
                        arvalid <= 1'b1;
                        icache_status <= UNCACHED;
                    end
                    else if (!cache_hit) begin
                        araddr <= {inst_pa[31:LEN_LINE],{LEN_LINE{1'b0}}};
                        arlen <= NR_WORDS - 1;
                        arsize <= 3'd2;
                        arvalid <= 1'b1;
                        replace_line_addr <= va_line_addr;
                        data_wea[meta[va_line_addr].LRU] <= 8'h0f;
                        tag_wea[meta[va_line_addr].LRU] <= 1'b1;
                        tag_ram_wdata <= '{tag: inst_tag};
                        meta[va_line_addr].valid[meta[va_line_addr].LRU] <= 1'b1;
                        icache_status <= CACHE_REPLACE;
                        axi_cnt <= 0;
                    end
                    else if (!istall) begin
                        // Update LRU when icache hit
                        // Note: If NR_WAYS > 2, we should implement pseudo-LRU or LFSR.
                        meta[va_line_addr].LRU <= ~i_cache_sel;
                        if (stallF) begin
                            icache_status <= SAVE_RESULT;
                            saved_inst1 <= cache_inst1;
                            saved_inst_ok0 <= cache_inst_ok0;
                            saved_inst_ok1 <= cache_inst_ok1;
                        end
                    end
                end
            end
            TLB_FILL: begin
                if (itlb_found) begin
                    if ( (inst_vpn[12] & itlb_entry.V1) | (!inst_vpn[12] & itlb_entry.V0)) begin
                        itlb.vpn <= inst_vpn[31:12];
                        itlb.ppn <= inst_vpn[12] ? itlb_entry.PFN1 : itlb_entry.PFN0;
                        itlb.uncached <= inst_vpn[12] ? !itlb_entry.C1 : !itlb_entry.C0;
                        itlb.valid <= 1'b1;
                        icache_status <= IDLE;
                    end
                    else begin
                        icache_status <= SAVE_RESULT;
                        inst_tlb_invalid <= 1'b1;
                        saved_inst0 <= 0;
                        saved_inst_ok0 <= 1;
                    end
                end
                else begin
                    icache_status <= SAVE_RESULT;
                    inst_tlb_refill <= 1'b1;
                    saved_inst0 <= 0;
                    saved_inst_ok0 <= 1;
                end
            end
            UNCACHED: begin
                if (arvalid) begin
                    if (arready) begin
                        arvalid <= 0;
                        rready <= 1'b1;
                    end
                end
                else begin
                    if (rvalid & rready) begin
                        saved_inst0 <= rdata;
                        saved_inst_ok0 <= 1'b1;
                        rready <= 1'b0;
                        icache_status <= SAVE_RESULT;
                    end
                end
            end
            CACHE_REPLACE: begin
                if (arvalid) begin
                    if (arready) begin
                        arvalid <= 0;
                        rready <= 1'b1;
                    end
                end
                else begin
                    if (rvalid & rready) begin
                        if (!rlast) begin
                            axi_cnt <= axi_cnt + 1;
                            // data_wea initial set to 8'h0f
                            data_wea[meta[va_line_addr].LRU] <= ~data_wea[meta[va_line_addr].LRU];
                        end
                        else begin
                            rready <= 0;
                            data_wea[meta[va_line_addr].LRU] <= 0;
                            tag_wea[meta[va_line_addr].LRU] <= 0;
                        end
                    end
                    else if (!rready) begin // wait the final data write to bram.
                        icache_status <= IDLE;
                    end
                end
            end
            SAVE_RESULT: begin
                if (!istall && !stallF) begin
                    inst_tlb_invalid <= 1'b0;
                    inst_tlb_refill <= 1'b0;
                    icache_status <= IDLE;
                    saved_inst_ok0 <= 1'b0;
                    saved_inst_ok1 <= 1'b0;
                end
            end
        endcase
    end
end

endmodule