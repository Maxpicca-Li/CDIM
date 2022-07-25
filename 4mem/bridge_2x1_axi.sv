`timescale 1ns/1ps
module bridge_2x1_axi (
    input no_dcache,

    // 主方
    input  wire [31:0] cache_araddr       ,
    input  wire [3 :0] cache_arlen        ,
    input  wire [2 :0] cache_arsize       ,
    input  wire        cache_arvalid      ,
    output wire        cache_arready      ,
    output wire [31:0] cache_rdata        ,
    output wire        cache_rlast        ,
    output wire        cache_rvalid       ,
    input  wire        cache_rready       ,
    input  wire [31:0] cache_awaddr       ,
    input  wire [3 :0] cache_awlen        ,
    input  wire [2 :0] cache_awsize       ,
    input  wire        cache_awvalid      ,
    output wire        cache_awready      ,
    input  wire [31:0] cache_wdata        ,
    input  wire [3 :0] cache_wstrb        ,
    input  wire        cache_wlast        ,
    input  wire        cache_wvalid       ,
    output wire        cache_wready       ,
    output wire        cache_bvalid       ,
    input  wire        cache_bready       ,

    input  wire [31:0] conf_araddr       ,
    input  wire [3 :0] conf_arlen        ,
    input  wire [2 :0] conf_arsize       ,
    input  wire        conf_arvalid      ,
    output wire        conf_arready      ,
    output wire [31:0] conf_rdata        ,
    output wire        conf_rlast        ,
    output wire        conf_rvalid       ,
    input  wire        conf_rready       ,
    input  wire [31:0] conf_awaddr       ,
    input  wire [3 :0] conf_awlen        ,
    input  wire [2 :0] conf_awsize       ,
    input  wire        conf_awvalid      ,
    output wire        conf_awready      ,
    input  wire [31:0] conf_wdata        ,
    input  wire [3 :0] conf_wstrb        ,
    input  wire        conf_wlast        ,
    input  wire        conf_wvalid       ,
    output wire        conf_wready       ,
    output wire        conf_bvalid       ,
    input  wire        conf_bready       ,
    
    // 从方
    output wire [31:0] wrap_araddr       ,
    output wire [3 :0] wrap_arlen        ,
    output wire [2 :0] wrap_arsize       ,
    output wire        wrap_arvalid      ,
    input  wire        wrap_arready      ,
    input  wire [31:0] wrap_rdata        ,
    input  wire        wrap_rlast        ,
    input  wire        wrap_rvalid       ,
    output wire        wrap_rready       ,
    output wire [31:0] wrap_awaddr       ,
    output wire [3 :0] wrap_awlen        ,
    output wire [2 :0] wrap_awsize       ,
    output wire        wrap_awvalid      ,
    input  wire        wrap_awready      ,
    output wire [31:0] wrap_wdata        ,
    output wire [3 :0] wrap_wstrb        ,
    output wire        wrap_wlast        ,
    output wire        wrap_wvalid       ,
    input  wire        wrap_wready       ,
    input  wire        wrap_bvalid       ,
    output wire        wrap_bready       

);

    assign cache_arready = no_dcache ? 0 : wrap_arready;
    assign cache_rdata   = no_dcache ? 0 : wrap_rdata  ;
    assign cache_rlast   = no_dcache ? 0 : wrap_rlast  ;
    assign cache_rvalid  = no_dcache ? 0 : wrap_rvalid ;
    assign cache_awready = no_dcache ? 0 : wrap_awready;
    assign cache_wready  = no_dcache ? 0 : wrap_wready ;
    assign cache_bvalid  = no_dcache ? 0 : wrap_bvalid ;

    assign conf_arready = no_dcache ? wrap_arready : 0;
    assign conf_rdata   = no_dcache ? wrap_rdata   : 0;
    assign conf_rlast   = no_dcache ? wrap_rlast   : 0;
    assign conf_rvalid  = no_dcache ? wrap_rvalid  : 0;
    assign conf_awready = no_dcache ? wrap_awready : 0;
    assign conf_wready  = no_dcache ? wrap_wready  : 0;
    assign conf_bvalid  = no_dcache ? wrap_bvalid  : 0;


    assign wrap_araddr  = no_dcache ? conf_araddr  : cache_araddr ;
    assign wrap_arlen   = no_dcache ? conf_arlen   : cache_arlen  ;
    assign wrap_arsize  = no_dcache ? conf_arsize  : cache_arsize ;
    assign wrap_arvalid = no_dcache ? conf_arvalid : cache_arvalid;
    assign wrap_rready  = no_dcache ? conf_rready  : cache_rready ;
    assign wrap_awaddr  = no_dcache ? conf_awaddr  : cache_awaddr ;
    assign wrap_awlen   = no_dcache ? conf_awlen   : cache_awlen  ;
    assign wrap_awsize  = no_dcache ? conf_awsize  : cache_awsize ;
    assign wrap_awvalid = no_dcache ? conf_awvalid : cache_awvalid;
    assign wrap_wdata   = no_dcache ? conf_wdata   : cache_wdata  ;
    assign wrap_wstrb   = no_dcache ? conf_wstrb   : cache_wstrb  ;
    assign wrap_wlast   = no_dcache ? conf_wlast   : cache_wlast  ;
    assign wrap_wvalid  = no_dcache ? conf_wvalid  : cache_wvalid ;
    assign wrap_bready  = no_dcache ? conf_bready  : cache_bready ;

endmodule