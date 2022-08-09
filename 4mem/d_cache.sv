module d_cache #(
    parameter LEN_LINE = 6,  // 64 Bytes
    parameter LEN_INDEX = 6, // 64 lines
    parameter NR_WAYS = 2,
    parameter SIZE_STORE_BUFFER = 8
) (
    input               clk,
    input               rst,
    // to cpu
    input               stallM,
    output              dstall,
    input        [31:0] E_mem_pa, // only used for match bram
    input        [31:0] M_mem_pa,
    input        [31:0] M_fence_addr, // used for fence
    input               M_fence_d, // fence address reuse the M_memva. Note: we shouldn't raise M_fence_en with M_mem_en.
    input               M_mem_en,
    input               M_mem_write,
    input               M_mem_uncached,
    input        [ 3:0] M_wmask,
    input         [1:0] M_mem_size,
    input        [31:0] M_wdata,
    output       [31:0] M_rdata,
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

enum { IDLE, UNCACHED_READ, CACHE_WRITEBACK, CACHE_REPLACE, SAVE_RESULT } dcache_status;

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
wire store_buffer_full = (store_buffer_ctrl.ptr_end + 3'd1) == store_buffer_ctrl.ptr_begin;

// dcache bram
wire [31:LEN_PER_WAY] addr_tag = M_mem_pa[31:LEN_PER_WAY];
wire bram_addr_choose = (dcache_status != IDLE && dcache_status != SAVE_RESULT); // 1: M_mem_pa, 0: E_mem_pa
wire [LEN_PER_WAY-1:2]          bram_word_addr = bram_addr_choose ? E_mem_pa[LEN_PER_WAY-1:2]        : M_mem_pa[LEN_PER_WAY-1:2];
wire [LEN_PER_WAY-1:LEN_LINE]   bram_line_addr = bram_addr_choose ? E_mem_pa[LEN_PER_WAY-1:LEN_LINE] : M_mem_pa[LEN_PER_WAY-1:LEN_LINE];

wire [31:0] bram_rdata;

wire [LEN_PER_WAY-1:2] tag_read_addr;
wire [LEN_PER_WAY-1:2] data_read_addr;
wire [LEN_PER_WAY-1:2] data_write_addr;
logic [LEN_PER_WAY-1:LEN_LINE] replace_line_addr;


wire [31:0] cache_data [NR_WAYS-1:0];
dcache_tag cache_tag[NR_WAYS-1:0];

logic [3:0] data_wea [NR_WAYS-1:0];
logic tag_wea[NR_WAYS-1:0];

dcache_tag tag_ram_wdata;

wire [NR_WAYS-1:0] tag_compare_valid;
wire cache_hit = |tag_compare_valid;

wire cache_hit_available = cache_hit && !M_mem_uncached;

wire mmio_read_stall = M_mem_en && M_mem_uncached && !M_mem_write && dcache_status != SAVE_RESULT;
wire mmio_write_stall = (M_mem_en && M_mem_uncached && M_mem_write && (dcache_status != IDLE || store_buffer_full) );
wire cached_stall = M_mem_en & (!M_mem_uncached) & !cache_hit;

// Note: If NR_WAYS > 2, we should mux one hot from tag_compare_valid;
wire d_cache_sel = tag_compare_valid[1];

wire [LEN_PER_WAY-1:LEN_LINE] pa_line_addr = M_mem_pa[LEN_PER_WAY-1:LEN_LINE];
wire [LEN_PER_WAY-1:LEN_LINE] fence_index = M_fence_addr[LEN_PER_WAY-1:LEN_LINE];

assign dstall = dcache_status == IDLE ? ((cached_stall | mmio_read_stall | mmio_write_stall) | M_fence_d) : (dcache_status != SAVE_RESULT);

logic [31:0] saved_rdata;

assign M_rdata = dcache_status == SAVE_RESULT ? saved_rdata : 32'd0;

// axi ctrl
logic [LEN_LINE:2] axi_rcnt;
logic [LEN_LINE:2] axi_wcnt;

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
            .dina   (rdata),
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
            .addra  (replace_line_addr),
            .dina   (tag_ram_wdata),
            .wea    (tag_wea[i]),
            .addrb  (bram_line_addr),
            .doutb  (cache_tag[i])
        );
        assign tag_compare_valid[i] = cache_tag[i].tag == addr_tag && meta[pa_line_addr].valid[i];
    end
endgenerate

// axi bready
assign bready = 1'b1;


always_ff @(posedge clk) begin
    if (rst) begin
        // clear store buffer
        store_buffer_ctrl <= 0;
        current_mmio_write_saved <= 0;
        // clear axi ctrl
        axi_rcnt <= 0;
        axi_wcnt <= 0;
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
    end
    else begin
        // store buffer
        if (store_buffer_busy) begin
            if (store_buffer_ctrl.axi_busy) begin // To implement SC memory ordering, if store buffer busy, axi is unseable.
                if (awvalid & awready) begin
                    awvalid <= 0;
                end
                if (wvalid & wready) begin
                    if (store_buffer_has_next) begin
                        awaddr <= store_buffer[store_buffer_ctrl.ptr_begin].waddr;
                        awlen <= 0;
                        awsize <= {1'd0,store_buffer[store_buffer_ctrl.ptr_begin].wsize};
                        awvalid <= 1'b1;
                        wdata <= store_buffer[store_buffer_ctrl.ptr_begin].wdata;
                        wstrb <= store_buffer[store_buffer_ctrl.ptr_begin].wstrb;
                        wlast <= 1'b1;
                        wvalid <= 1'b1;
                        store_buffer_ctrl.ptr_begin <= store_buffer_ctrl.ptr_begin + 3'd1;
                    end
                    else begin
                        wvalid <= 0;
                        wlast <= 0;
                        store_buffer_ctrl.axi_busy <= 1'b0;
                    end
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
                store_buffer_ctrl.ptr_begin <= store_buffer_ctrl.ptr_begin + 3'd1;
                store_buffer_ctrl.axi_busy <= 1'b1;
            end
        end
        case (dcache_status)
            IDLE: begin
                if (M_mem_en) begin
                    if (M_mem_uncached) begin
                        if (M_mem_write) begin
                            if (!store_buffer_full && !current_mmio_write_saved) begin
                                store_buffer[store_buffer_ctrl.ptr_end] <= '{
                                    waddr: M_mem_pa,
                                    wsize: M_mem_size,
                                    wstrb: M_wmask,
                                    wdata: M_wdata
                                };
                                store_buffer_ctrl.ptr_end <= store_buffer_ctrl.ptr_end + 3'd1;
                                current_mmio_write_saved <= 1'b1;
                            end
                            if (!dstall && !stallM) begin
                                current_mmio_write_saved <= 1'b0;
                            end
                        end
                        else begin // mmio read
                            if (!store_buffer_busy) begin
                                araddr <= M_mem_pa;
                                arlen <= 0;
                                arsize <= {1'b0, M_mem_size};
                                arvalid <= 1'b1;
                                dcache_status <= UNCACHED_READ;
                                rready <= 1'b1;
                            end // if store buffer busy, read will stop at IDLE but stall pipeline.
                        end
                    end
                    else begin
                        // TODO: cached
                    end
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
            CACHE_WRITEBACK: begin // cache op
            end
            CACHE_REPLACE: begin
            end
            SAVE_RESULT: begin
                if (!dstall && !stallM) begin
                    dcache_status <= IDLE;
                end
            end
        endcase
    end
end

endmodule
