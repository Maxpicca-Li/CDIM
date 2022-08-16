`include "defines.vh"
// VIPT D$
module d_cache #(
    parameter LEN_LINE = 6,  // 64 Bytes
    parameter LEN_INDEX = 6, // 64 lines
    parameter NR_WAYS = 2,
    parameter SIZE_STORE_BUFFER = 4
) (
    input               clk,
    input               rst,
    // to cpu
    input               stallM,
    output              dstall,
    input        [31:0] E_mem_va, // only used for match bram
    input        [31:0] M_mem_va,
    input        [31:0] M_fence_addr, // used for fence
    input               M_fence_d, // fence address reuse the M_memva. Note: we shouldn't raise M_fence_en with M_mem_en.
    input               M_mem_en,
    input               M_mem_write,
    input        [ 3:0] M_wmask,
    input         [1:0] M_mem_size,
    input        [31:0] M_wdata,
    output       [31:0] M_rdata,
    // to l2 tlb
    output logic [31:13]dtlb_vpn2,
    input               dtlb_found,
    input  tlb_entry    dtlb_entry,
    input               fence_tlb,
    // M_tlb_except
    output logic        data_tlb_refill,
    output logic        data_tlb_invalid,
    output logic        data_tlb_mod,
    // to axi
    output logic [31:0] araddr,
    output logic [ 7:0] arlen,
    output logic [ 2:0] arsize,
    output logic        arvalid,
    input               arready,
    input  [31:0]       rdata,
    input               rlast,
    input               rvalid,
    output logic        rready,
    output logic [31:0] awaddr,
    output logic  [7:0] awlen,
    output logic  [2:0] awsize,
    output logic        awvalid,
    input               awready,
    output logic [31:0] wdata,
    output logic [3: 0] wstrb,
    output logic        wlast,
    output logic        wvalid,
    input               wready,
    input               bvalid,
    output              bready
);

// tlb
typedef struct packed {
    logic [31:12] vpn;
    logic [31:12] ppn;
    logic uncached;
    logic dirty;
    logic valid;
} l1_dtlb;

l1_dtlb dtlb;

// dTLB Translation
wire direct_mapped = M_mem_va[31:30] == 2'b10; // kseg0 and kseg1
wire M_mem_uncached = direct_mapped ? M_mem_va[29] : dtlb.uncached;
wire [31:12] data_tag = direct_mapped ? {3'b000, M_mem_va[28:12]} : dtlb.ppn;
wire [31:12] data_vpn = M_mem_va[31:12];
wire [31:0 ] M_mem_pa = {data_tag, M_mem_va[11:0]};

wire l1tlb_ok = (dtlb.vpn == data_vpn && dtlb.valid);
wire translation_ok = direct_mapped | (dtlb.vpn == data_vpn && dtlb.valid && (!M_mem_write || dtlb.dirty));

// defines

localparam LEN_PER_WAY = LEN_LINE + LEN_INDEX;
localparam LEN_TAG = 32 - LEN_LINE - LEN_INDEX;
localparam LEN_BRAM_ADDR = LEN_LINE - 3 + LEN_INDEX;
localparam NR_LINES = 1 << LEN_INDEX;
localparam NR_WORDS = 1 << (LEN_LINE - 2);

typedef struct packed {
    logic [LEN_TAG-1:0] tag;
} dcache_tag;

typedef struct packed {
    logic [NR_WAYS-1:0] valid;
    logic [NR_WAYS-1:0] dirty;
    logic LRU;
    // Note: If NR_WAYS > 2, we should implement pseudo-LRU or LFSR.
} dcache_meta;

enum { IDLE, TLB_FILL, UNCACHED_READ, CACHE_WRITEBACK, CACHE_REPLACE, SAVE_RESULT} dcache_status;

// metadata
dcache_meta meta [NR_LINES-1:0];

// mmio store buffer
typedef struct packed {
    logic [31:0]    waddr;
    logic [1:0]     wsize;
    logic [3:0]     wstrb;
    logic [31:0]    wdata; // note: data should place at correct place. (like axi)
} store_buffer_entry;

typedef struct packed {
    logic [$clog2(SIZE_STORE_BUFFER)-1:0] ptr_begin;
    logic [$clog2(SIZE_STORE_BUFFER)-1:0] ptr_end;
    logic axi_busy;
} store_buffer_control;

store_buffer_entry store_buffer[SIZE_STORE_BUFFER-1:0];
store_buffer_control store_buffer_ctrl;
logic current_mmio_write_saved;
wire store_buffer_has_next = store_buffer_ctrl.ptr_begin != store_buffer_ctrl.ptr_end;
wire store_buffer_busy = store_buffer_has_next | store_buffer_ctrl.axi_busy;
wire store_buffer_full = (store_buffer_ctrl.ptr_end + 1'd1) == store_buffer_ctrl.ptr_begin;

// replace & fence control
wire [LEN_PER_WAY-1:LEN_LINE]   fence_line_addr = M_fence_addr[LEN_PER_WAY-1:LEN_LINE];
logic [LEN_LINE-1:2] axi_wcnt; // axi_r -> cache cnt
logic [LEN_PER_WAY-1:2] bram_replace_addr;
logic [LEN_PER_WAY-1:2] bram_read_ready_addr;
logic [LEN_PER_WAY-1:2] bram_replace_write_addr;
logic [$clog2(NR_WORDS):0] bram_replace_cnt; // cnt itself can be send to axi (by mux cache_data[i] and bram_r_buffer), cnt - 1 can be read from bram_r_buffer
logic [31:0] bram_r_buffer [NR_WORDS-1:0];
logic bram_use_replace_addr;
logic bram_data_valid;
logic fence_working;
logic replace_working;
logic ar_handshake;
logic aw_handshake;
logic replace_writeback;
wire fence_way = meta[fence_line_addr].dirty[1] ? 1'b1 : 1'b0;
// TODO: If we changed NR_WAYS, we should add judge to each way

logic tag_wea[NR_WAYS-1:0];
logic [3:0] bram_replace_wea [NR_WAYS-1:0];

wire [3:0] data_wea [NR_WAYS-1:0]; // assign at generate

dcache_tag tag_ram_wdata;

// dcache bram
wire [31:LEN_PER_WAY] addr_tag = M_mem_pa[31:LEN_PER_WAY];
wire bram_addr_choose = (dcache_status != IDLE) & (dcache_status != SAVE_RESULT); // 1: M_mem_va or M_fence_addr, 0: M_mem_va

// FIXME: fix M_fence_addr
wire [LEN_PER_WAY-1:2]          bram_word_addr = bram_use_replace_addr ? bram_replace_addr : (bram_addr_choose ? M_mem_va[LEN_PER_WAY-1:2] : E_mem_va[LEN_PER_WAY-1:2]);
wire [LEN_PER_WAY-1:LEN_LINE]   bram_line_addr = bram_use_replace_addr ? bram_replace_addr[LEN_PER_WAY-1:LEN_LINE] : (bram_addr_choose ? M_mem_va[LEN_PER_WAY-1:LEN_LINE] : E_mem_va[LEN_PER_WAY-1:LEN_LINE]);

wire [LEN_PER_WAY-1:2] data_write_addr = bram_use_replace_addr ? bram_replace_write_addr : M_mem_va[LEN_PER_WAY-1:2];

wire data_bram_wdata_sel = dcache_status == CACHE_REPLACE; // 1: axi rdata, 0: M_wdata
wire [31:0] data_bram_wdata = data_bram_wdata_sel ? rdata : M_wdata;

wire [31:0] cache_data [NR_WAYS-1:0];
dcache_tag cache_tag[NR_WAYS-1:0];

wire [NR_WAYS-1:0] tag_compare_valid;
wire cache_hit = |tag_compare_valid;

// stall control
wire mmio_read_stall = M_mem_uncached && !M_mem_write;
wire mmio_write_stall = M_mem_uncached && M_mem_write && store_buffer_full;
wire cached_stall = (!M_mem_uncached) && !cache_hit;
wire tlb_stall = !translation_ok;

// Note: If NR_WAYS > 2, we should mux one hot from tag_compare_valid;
wire d_cache_sel = tag_compare_valid[1];

wire [LEN_PER_WAY-1:LEN_LINE] pa_line_addr = M_mem_va[LEN_PER_WAY-1:LEN_LINE];

assign dstall = dcache_status == IDLE ? (M_mem_en ? (cached_stall | mmio_read_stall | mmio_write_stall | tlb_stall) : M_fence_d) : (dcache_status != SAVE_RESULT);

logic [31:0] saved_rdata;

// forward last stored data in data bram
logic [LEN_PER_WAY-1:2] last_line_addr; // two way shared
logic [31:0] last_wea [NR_WAYS-1:0]; // assume only write one way at a time
logic [31:0] last_wdata; // two way shared
wire [31:0] cache_data_forward [NR_WAYS-1:0];

assign M_rdata = dcache_status == SAVE_RESULT ? saved_rdata : cache_data_forward[d_cache_sel];

// generate bram
genvar i;
generate
    for (i=0;i<NR_WAYS;i++) begin
        dual_port_bram_bw8 #(.LEN_DATA(32),.LEN_ADDR(LEN_PER_WAY-2)) d_data
        (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (1'b1),
            .addra  (data_write_addr),
            .dina   (data_bram_wdata),
            .wea    (data_wea[i]),
            .addrb  (bram_word_addr),
            .doutb  (cache_data[i])
        );
        dual_port_bram_nobw #(.LEN_DATA(LEN_TAG),.LEN_ADDR(LEN_PER_WAY-LEN_LINE)) d_tag
        (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (1'b1),
            .addra  (bram_replace_addr[LEN_PER_WAY-1:LEN_LINE]),
            .dina   (tag_ram_wdata),
            .wea    (tag_wea[i]),
            .addrb  (bram_line_addr),
            .doutb  (cache_tag[i])
        );
        assign tag_compare_valid[i] = cache_tag[i].tag == addr_tag && meta[pa_line_addr].valid[i] && translation_ok;
        assign cache_data_forward[i] = last_line_addr == M_mem_va[LEN_PER_WAY-1:2] ? ((last_wea[i] & last_wdata) | (cache_data[i] & (~last_wea[i]))) : cache_data[i];
        assign data_wea[i] = (tag_compare_valid[i] && M_mem_en && M_mem_write && !M_mem_uncached && dcache_status == IDLE) ? M_wmask :  bram_replace_wea[i];
        always_ff @(posedge clk) begin
            if (rst) begin
                last_wea[i] <= 0;
            end
            else begin
                last_wea[i] <= {{8{data_wea[i][3]}},{8{data_wea[i][2]}},{8{data_wea[i][1]}},{8{data_wea[i][0]}}};
            end
        end
    end
endgenerate
// save last_line_addr
always_ff @(posedge clk) begin
    if (rst) begin
        last_line_addr <= 0;
        last_wdata <= 0;
    end
    else begin
        last_line_addr <= data_write_addr;
        last_wdata <= data_bram_wdata;
    end
end

// axi bready
assign bready = 1'b1;


always_ff @(posedge clk) begin
    /*
    if (M_mem_pa == 32'haef134 && M_mem_write && !dstall) begin
        $display("RTL wdata = %x, bram_write_addr = %x\n", M_wdata, data_write_addr);
    end
    */
    /*
    if (M_mem_va == 32'h5b7134 && M_mem_write && !dstall) begin
        $display("RTL wdata = %x, bram_write_addr = %x\n", M_wdata, data_write_addr);
    end
    */
    /*
    if ({M_mem_pa[31:2],2'b0} == 32'haed134) begin
        $display("RTL wdata = %x, bram_write_addr = %x\n", M_wdata, data_write_addr);
    end
     */
    /*
    if (data_write_addr == 10'h04d && M_wdata == 32'h1000) begin
        $display("M_va = %x, M_pa = %x\n",M_mem_va,M_mem_pa);
    end
    */
    if (rst) begin
        // clear meta
        meta <= '{default: '0};
        store_buffer <= '{default: '0};
        // clear store buffer
        store_buffer_ctrl <= 0;
        current_mmio_write_saved <= 0;
        // clear replace ctrl
        axi_wcnt <= 0;
        bram_replace_addr <= 0;
        bram_read_ready_addr <= 0;
        bram_replace_cnt <= 0;
        bram_r_buffer <= '{default: '0};
        bram_use_replace_addr <= 0;
        bram_replace_write_addr <= 0;
        bram_data_valid <= 0;
        fence_working <= 0;
        replace_working <= 0;
        ar_handshake <= 0;
        aw_handshake <= 0;
        replace_writeback <= 0;
        tag_wea <= '{default: '0};
        bram_replace_wea <= '{default: '0};
        tag_ram_wdata <= 0;
        // clear tlb except output
        data_tlb_refill <= 0;
        data_tlb_invalid <= 0;
        data_tlb_mod <= 0;
        // clear dtlb
        dtlb <= '{default: '0};
        // clear dtlb req
        dtlb_vpn2 <= 0;
        // clear saved rdata
        saved_rdata <= 0;
        // clear axi
        araddr <= 0;
        arlen <= 0;
        arsize <= 0;
        arvalid <= 0;
        rready <= 0;
        awaddr <= 0;
        awlen <= 0;
        awsize <= 0;
        awvalid <= 0;
        wdata <= 0;
        wstrb <= 0;
        wlast <= 0;
        wvalid <= 0;
        dcache_status <= IDLE;
    end
    else begin
        // store buffer
        if (store_buffer_busy) begin
            if (store_buffer_ctrl.axi_busy) begin // To implement SC memory ordering, if store buffer busy, axi is unseable.
                if (awvalid & awready) begin
                    awvalid <= 0;
                end
                if (wvalid & wready) begin
                    wvalid <= 0;
                    wlast <= 0;
                end
                if (bvalid & bready) begin
                    store_buffer_ctrl.axi_busy <= 1'b0;
                end
            end
            else begin
                awaddr <= store_buffer[store_buffer_ctrl.ptr_begin].waddr;
                awlen <= 0;
                awsize <= {1'd0,store_buffer[store_buffer_ctrl.ptr_begin].wsize};
                awvalid <= 1'b1;
                wdata <= store_buffer[store_buffer_ctrl.ptr_begin].wdata;
                wstrb <= store_buffer[store_buffer_ctrl.ptr_begin].wstrb;
                wlast <= 1'b1;
                wvalid <= 1'b1;
                store_buffer_ctrl.ptr_begin <= store_buffer_ctrl.ptr_begin + 1;
                store_buffer_ctrl.axi_busy <= 1'b1;
            end
        end
        case (dcache_status)
            IDLE: begin
                if (M_mem_en) begin
                    if (!translation_ok) begin
                        if (l1tlb_ok) begin // tlbmod
                            dcache_status <= SAVE_RESULT;
                            data_tlb_mod <= 1'b1;
                        end
                        else begin
                            dcache_status <= TLB_FILL;
                            dtlb_vpn2 <= data_vpn[31:13];
                        end
                    end
                    else if (M_mem_uncached) begin
                        if (M_mem_write) begin
                            if (!store_buffer_full && !current_mmio_write_saved) begin
                                store_buffer[store_buffer_ctrl.ptr_end] <= '{
                                    waddr: M_mem_size == 2'd2 ? {M_mem_pa[31:2],2'd0} : M_mem_pa,
                                    wsize: M_mem_size,
                                    wstrb: M_wmask,
                                    wdata: M_wdata
                                };
                                store_buffer_ctrl.ptr_end <= store_buffer_ctrl.ptr_end + 1;
                                current_mmio_write_saved <= 1'b1;
                            end
                            if (!dstall && !stallM) begin
                                current_mmio_write_saved <= 1'b0;
                            end
                        end
                        else begin // mmio read
                            if (!store_buffer_busy) begin
                                araddr <= M_mem_size == 2'd2 ? {M_mem_pa[31:2],2'd0} : M_mem_pa;
                                arlen <= 0;
                                arsize <= {1'b0, M_mem_size};
                                arvalid <= 1'b1;
                                dcache_status <= UNCACHED_READ;
                                rready <= 1'b1;
                            end // if store buffer busy, read will stop at IDLE but stall pipeline.
                        end
                    end
                    else begin
                        if (!cache_hit) begin
                            dcache_status <= CACHE_REPLACE;
                            axi_wcnt <= 0;
                            bram_replace_addr <= {pa_line_addr,{LEN_LINE-2{1'b0}}};
                            bram_read_ready_addr <= {pa_line_addr,{LEN_LINE-2{1'b0}}};
                            bram_replace_write_addr <= {pa_line_addr,{LEN_LINE-2{1'b0}}};
                            bram_replace_cnt <= 0;
                            bram_use_replace_addr <= 1'b1;
                            bram_data_valid <= 0;
                            replace_writeback <= meta[pa_line_addr].dirty[meta[pa_line_addr].LRU];
                        end
                        else begin
                            if (!dstall) begin
                                // update lru and mark dirty
                                meta[pa_line_addr].LRU <= ~d_cache_sel;
                                if (M_mem_write) meta[pa_line_addr].dirty[d_cache_sel] <= 1'b1;
                                if (stallM) begin
                                    saved_rdata <= cache_data_forward[d_cache_sel];
                                    dcache_status <= SAVE_RESULT;
                                end
                            end
                        end
                    end
                end
                else if (M_fence_d) begin
                    if (|meta[fence_line_addr].dirty) begin
                        if (!store_buffer_busy) begin
                            dcache_status <= CACHE_WRITEBACK;
                            axi_wcnt <= 0;
                            bram_replace_addr <= {M_fence_addr[LEN_PER_WAY-1:LEN_LINE],{LEN_LINE-2{1'b0}}};
                            bram_read_ready_addr <= {M_fence_addr[LEN_PER_WAY-1:LEN_LINE],{LEN_LINE-2{1'b0}}};
                            bram_replace_cnt <= 0;
                            bram_use_replace_addr <= 1'b1;
                            bram_data_valid <= 0;
                        end
                    end
                    else begin
                        if (|meta[fence_line_addr].valid) meta[fence_line_addr].valid <= 0;
                        dcache_status <= SAVE_RESULT;
                    end
                end
            end
            TLB_FILL: begin
                if (dtlb_found) begin
                    if ( (data_vpn[12] & dtlb_entry.V1) | (!data_vpn[12] & dtlb_entry.V0)) begin
                        dtlb.vpn <= data_vpn[31:12];
                        dtlb.ppn <= data_vpn[12] ? dtlb_entry.PFN1 : dtlb_entry.PFN0;
                        dtlb.uncached <= data_vpn[12] ? !dtlb_entry.C1 : !dtlb_entry.C0;
                        dtlb.dirty <= data_vpn[12] ? dtlb_entry.D1 : dtlb_entry.D0;
                        dtlb.valid <= 1'b1;
                        dcache_status <= IDLE;
                    end
                    else begin
                        dcache_status <= SAVE_RESULT;
                        data_tlb_invalid <= 1'b1;
                    end
                end
                else begin
                    dcache_status <= SAVE_RESULT;
                    data_tlb_refill <= 1'b1;
                end
            end
            UNCACHED_READ: begin
                if (arvalid && arready) begin
                    arvalid <= 1'b0;
                end
                if (rvalid) begin
                    saved_rdata <= rdata;
                    dcache_status <= SAVE_RESULT;
                end
            end
            CACHE_WRITEBACK: begin // CACHE Instruction
                if (fence_working) begin
                    if (bram_replace_addr[LEN_LINE-1:2] != NR_WORDS - 1) begin
                        bram_replace_addr <= bram_replace_addr + 1;
                    end
                    bram_read_ready_addr <= bram_replace_addr;
                    bram_r_buffer[bram_read_ready_addr[LEN_LINE-1:2]] <= cache_data[fence_way];
                    if (!aw_handshake) begin
                        awaddr <= {cache_tag[fence_way].tag,fence_line_addr,{LEN_LINE{1'b0}}};
                        awlen <= NR_WORDS - 1;
                        awsize <= 3'd2;
                        awvalid <= 1'b1;
                        wdata <= cache_data[fence_way];
                        wstrb <= 4'b1111;
                        wlast <= NR_WORDS == 1 ? 1'b1 : 1'b0;
                        wvalid <= 1'b1;
                        aw_handshake <= 1'b1;
                    end
                    if (awvalid & awready) begin
                        awvalid <= 1'b0;
                    end
                    if (wvalid & wready) begin
                        if (wlast) begin
                            wvalid <= 1'b0;
                        end
                        else begin
                            wdata <= ((axi_wcnt + 1'b1) == bram_read_ready_addr[LEN_LINE-1:2]) ? cache_data[fence_way] : bram_r_buffer[axi_wcnt + 1'b1];
                            axi_wcnt <= axi_wcnt + 1;
                            if ({1'b0,axi_wcnt} + 1'b1 == NR_WORDS - 1) begin
                                wlast <= 1'b1;
                            end
                        end
                    end
                    if (bvalid & bready) begin
                        meta[fence_line_addr].dirty[fence_way] <= 1'b0;
                        fence_working <= 1'b0;
                        bram_use_replace_addr <= 1'b0;
                        dcache_status <= IDLE;
                    end
                end
                else begin
                    aw_handshake <= 1'b0;
                    fence_working <= 1'b1;
                    bram_replace_addr[LEN_LINE-1:2] <= bram_replace_addr[LEN_LINE-1:2] + 1;
                    // transfer [addr + 1], and receive [addr].
                end
            end
            CACHE_REPLACE: begin
                if (!store_buffer_busy) begin
                    if (replace_working) begin
                        if (replace_writeback) begin
                            if (bram_replace_addr[LEN_LINE-1:2] != NR_WORDS - 1) begin
                                bram_replace_addr <= bram_replace_addr + 1;
                            end
                            bram_read_ready_addr <= bram_replace_addr;
                            bram_r_buffer[bram_read_ready_addr[LEN_LINE-1:2]] <= cache_data[meta[pa_line_addr].LRU];
                            if (!aw_handshake) begin
                                awaddr <= {cache_tag[meta[pa_line_addr].LRU].tag,pa_line_addr,{LEN_LINE{1'b0}}};
                                awlen <= NR_WORDS - 1;
                                awsize <= 3'd2;
                                awvalid <= 1'b1;
                                wdata <= cache_data[meta[pa_line_addr].LRU];
                                wstrb <= 4'b1111;
                                wlast <= NR_WORDS == 1 ? 1'b1 : 1'b0;
                                wvalid <= 1'b1;
                                aw_handshake <= 1'b1;
                            end
                            if (awvalid & awready) begin
                                awvalid <= 1'b0;
                            end
                            if (wvalid & wready) begin
                                if (wlast) begin
                                    wvalid <= 1'b0;
                                end
                                else begin
                                    wdata <= ((axi_wcnt + 1'b1) == bram_read_ready_addr[LEN_LINE-1:2]) ? cache_data[meta[pa_line_addr].LRU] : bram_r_buffer[axi_wcnt + 1'b1];
                                    axi_wcnt <= axi_wcnt + 1;
                                    if ({1'b0,axi_wcnt} + 1'b1 == NR_WORDS - 1) begin
                                        wlast <= 1'b1;
                                    end
                                end
                            end
                            if (bvalid & bready) begin
                                meta[pa_line_addr].dirty[meta[pa_line_addr].LRU] <= 1'b0;
                                replace_writeback <= 1'b0;
                            end
                        end
                        // at here, cache line is writeable from axi read.
                        if (!ar_handshake) begin
                            araddr <= {M_mem_pa[31:LEN_LINE],{LEN_INDEX{1'b0}}};
                            arlen <= NR_WORDS - 1;
                            arsize <= 3'd2;
                            arvalid <= 1'b1;
                            rready <= 1'b1;
                            ar_handshake <= 1'b1;
                            bram_replace_wea[meta[pa_line_addr].LRU] <= 4'b1111;
                            tag_wea[meta[pa_line_addr].LRU] <= 1'b1;
                            tag_ram_wdata.tag <= M_mem_pa[31:12];
                        end
                        if (arvalid & arready) begin
                            tag_wea[meta[pa_line_addr].LRU] <= 1'b0;
                            arvalid <= 1'b0;
                        end
                        if (rvalid & rready) begin
                            if (rlast) begin
                                rready <= 1'b0;
                                bram_replace_wea[meta[pa_line_addr].LRU] <= 0;
                            end
                            else begin
                                bram_replace_write_addr <= bram_replace_write_addr + 1;
                            end
                        end
                        if ((!replace_writeback || (bvalid & bready)) && ( (ar_handshake && rvalid && rlast) || (ar_handshake && !rready) ) ) begin
                            bram_use_replace_addr <= 0;
                            meta[pa_line_addr].valid[meta[pa_line_addr].LRU] <= 1'b1;
                        end
                        if (!bram_use_replace_addr) begin
                            replace_working <= 1'b0;
                            dcache_status <= IDLE;
                        end
                    end
                    else begin
                        ar_handshake <= 1'b0;
                        aw_handshake <= 1'b0;
                        replace_working <= 1'b1;
                        bram_replace_addr[LEN_LINE-1:2] <= bram_replace_addr[LEN_LINE-1:2] + 1;
                        // transfer [addr + 1], and receive [addr].
                    end
                end
            end
            SAVE_RESULT: begin
                if (!dstall && !stallM) begin
                    dcache_status <= IDLE;
                    data_tlb_invalid <= 0;
                    data_tlb_refill <= 0;
                    data_tlb_mod <= 0;
                end
            end
        endcase
    end
    // fence tlb
    if (fence_tlb) dtlb.valid <= 0;
end

endmodule
