`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/26 17:20:25
// Design Name: 
// Module Name: d_arbitrater
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module d_arbitrater (
    input wire clk, rst,
    //tlb
    input wire no_cache_E,
    input wire no_cache,
    //datapath
    input wire data_en,
    input wire [31:0] data_addr,
    output wire [31:0] data_rdata,
    input wire [1:0] data_rlen,
    input wire [3:0] data_wen,
    input wire [31:0] data_wdata,
    output wire stall,
    input wire [31:0] mem_addrE,
    input wire mem_read_enE,
    input wire mem_write_enE,
    input wire stallM,
    //arbitrater
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire [2:0] arsize,
    output wire arvalid,
    input wire arready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready,

    //write
    output reg [31:0] awaddr,
    output reg [7:0] awlen,
    output reg [2:0] awsize,
    output wire awvalid,
    input wire awready,
    
    output reg [31:0] wdata,
    output reg [3:0] wstrb,
    //output reg wlast,
    output wire wlast,
    output wire wvalid,
    input wire wready,

    input wire bvalid,
    output wire bready    
); 

    wire [31:0]  cache_araddr   , cache_awaddr, cfg_araddr, cfg_awaddr;
    wire [31:0]  cache_rdata    , cfg_rdata   ;
    wire [7 :0]  cache_arlen    , cache_awlen , cfg_arlen  , cfg_awlen    ;
    wire [2 :0]  cache_arsize   , cache_awsize, cfg_arsize , cfg_awsize   ;
    wire         cache_awvalid  , cfg_awvalid , cfg_arvalid, cache_arvalid;
    wire [3 :0]  cache_wstrb    , cfg_wstrb   ;
    wire         cache_bready   , cfg_bready  , cfg_rready , cache_rready ;
    wire         cache_stall    , cfg_stall   , cache_wlast, cfg_wlast    ;
    wire         cfg_wvalid     , cache_wvalid;
    wire         cfg_writting;

    d_cache_daxi u_d_cache_daxi(
        .clk(clk), .rst(rst),
        .data_en_E(~no_cache_E),
        //TLB
        .cfg_writting(cfg_writting),

        //datapath
        .data_en(data_en & ~no_cache),
        .data_addr(data_addr),
        .data_rdata(cache_rdata),
        .data_rlen(data_rlen),
        .data_wen(data_wen),
        .data_wdata(data_wdata),
        .stall(cache_stall),
        .mem_addrE(mem_addrE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        .stallM(stallM),
        
        //arbitrater
        .araddr          (cache_araddr ),
        .arlen           (cache_arlen  ),
        .arsize          (cache_arsize ),
        .arvalid         (cache_arvalid),
        .arready         (arready),

        .rdata           (rdata ),
        .rlast           (rlast ),
        .rvalid          (rvalid),
        .rready          (cache_rready),

        .awaddr          (cache_awaddr ),
        .awlen           (cache_awlen  ),
        .awsize          (cache_awsize ),
        .awvalid         (cache_awvalid),
        .awready         (awready),

        .wdata           (cache_wdata ),
        .wstrb           (cache_wstrb ),
        .wlast           (cache_wlast ),
        .wvalid          (cache_wvalid),
        .wready          (wready),

        .bvalid          (bvalid),
        .bready          (cache_bready)
    );


    d_confreg d_cfg(
        .clk(clk), .rst(rst),

        //TLB
        .no_cache(no_cache),

        //datapath
        .data_enE((mem_read_enE | mem_write_enE) & no_cache_E),
        .data_en(data_en & no_cache),
        .data_addr(data_addr),
        .data_rdata(cfg_rdata),
        .data_rlen(data_rlen),
        .data_wen(data_wen),
        .data_wdata(data_wdata),
        .stall(cfg_stall),
        .mem_addrE(mem_addrE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        .stallM(stallM),
        
        //arbitrater
        .araddr          (cfg_araddr ),
        .arlen           (cfg_arlen  ),
        .arsize          (cfg_arsize ),
        .arvalid         (cfg_arvalid),
        .arready         (arready),

        .rdata           (rdata ),
        .rlast           (rlast ),
        .rvalid          (rvalid),
        .rready          (cfg_rready),

        .awaddr          (cfg_awaddr ),
        .awlen           (awlen      ),
        .awsize          (cfg_awsize ),
        .awvalid         (cfg_awvalid),
        .awready         (awready),

        .wdata           (cfg_wdata ),
        .wstrb           (cfg_wstrb ),
        .wlast           (cfg_wlast ),
        .wvalid          (cfg_wvalid),
        .wready          (wready),

        .bvalid          (bvalid),
        .bready          (cfg_bready),
        .cfg_writting    (cfg_writting)
    );
    assign data_rdata = no_cache ? cfg_rdata : cache_rdata;
    assign stall      = cache_stall | cfg_stall;
    assign araddr     = no_cache ? cfg_araddr: cache_araddr;
    assign arlen      = no_cache ? cfg_arlen : cache_arlen ;
    assign arsize     = no_cache ? cfg_arsize: cache_arsize;
    assign arvalid    = no_cache ? cfg_arvalid:cache_arvalid;
    assign rready     = no_cache ? cfg_rready: cache_rready;
    assign awvalid    = cfg_awvalid | cache_awvalid;
   // assign wdata      = no_cache ? cfg_wdata : cache_wdata ;
    //assign wstrb      = no_cache ? cfg_wstrb : cache_wstrb ;
    //assign wlast      = no_cache ? cfg_wlast : cache_wlast ;
    assign wlast      = cfg_wlast | cache_wlast;
    //assign   wlast      = data_en & ~no_cache ? cache_wlast : 1'b1;
    assign wvalid     = cfg_wvalid | cache_wvalid;
    assign bready     = cfg_bready | cache_bready;
    
    always @(posedge clk) begin
        if(data_en) begin
        if(no_cache) begin
            awaddr <= data_addr;
            awsize <= data_wen==4'b1111 ? 3'b10:
                       data_wen==4'b1100 || data_wen==4'b0011 ? 3'b01: 3'b00;
            awlen  <= 8'd0;
            wdata  <= data_wdata;
            wstrb  <= data_wen;
        end
        else begin
            awaddr <= cache_awaddr;
            awsize <= cache_awsize;
            awlen  <= cache_awlen;
            wdata  <= cache_wdata;
            wstrb  <= cache_wstrb;
        end
        end
    end
endmodule
