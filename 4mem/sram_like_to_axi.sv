`timescale 1ns / 1ps

// 针对访问外设时wlen=1：类sram接口 转 类axi接口，修改自cpu_axi_interface
module sram_like_to_axi (
    input wire clk, rst,
    // sram_like
    input  wire        sraml_req     ,
    input  wire        sraml_wr      ,
    input  wire [1 :0] sraml_size    ,
    input  wire [31:0] sraml_addr    ,
    input  wire [31:0] sraml_wdata   ,
    output wire [31:0] sraml_rdata   ,
    output wire        sraml_addr_ok ,
    output wire        sraml_data_ok ,

    // axi
    // ar
    output wire [31:0] araddr       ,
    output wire [3 :0] arlen        ,
    output wire [2 :0] arsize       ,
    output wire        arvalid      ,
    input  wire        arready      ,
    // r
    input  wire [31:0] rdata        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output wire        rready       ,
    // aw
    output wire [31:0] awaddr       ,
    output wire [3 :0] awlen        ,
    output wire [2 :0] awsize       ,
    output wire        awvalid      ,
    input  wire        awready      ,
    // w
    output wire [31:0] wdata        ,
    output wire [3 :0] wstrb        ,
    output wire        wlast        ,
    output wire        wvalid       ,
    input  wire        wready       ,
    // b
    input  wire        bvalid       ,
    output wire        bready       
);

// 一次完整的事务信号
    reg  do_req; // 一次请求事务
    reg  addr_rcv;
    reg  wdata_rcv;
    wire data_back;
    assign data_back = addr_rcv && (rvalid&&rready||bvalid&&bready);

    always @(posedge clk) begin
        do_req     <= rst                       ? 1'b0 : 
                    (sraml_req)&&!do_req ? 1'b1 :
                    data_back                     ? 1'b0 : do_req;
        addr_rcv  <= rst          ? 1'b0 :
                    arvalid&&arready ? 1'b1 : // 读请求
                    awvalid&&awready ? 1'b1 : // 写请求
                    data_back        ? 1'b0 : addr_rcv;
        wdata_rcv <= rst        ? 1'b0 :
                    wvalid&&wready ? 1'b1 :
                    data_back      ? 1'b0 : wdata_rcv;
    end


// sraml接口信号
    assign sraml_addr_ok = (arvalid && arready) ||(awvalid && awready);
    assign sraml_data_ok = addr_rcv && data_back;
    assign sraml_rdata   = rdata;

// axi接口信号
    //ar
    assign araddr  = sraml_addr;
    assign arlen   = 4'd0;
    assign arsize  = sraml_size;
    assign arvalid = !sraml_wr && do_req && !addr_rcv;
    //r
    assign rready  = addr_rcv;
    //aw
    assign awaddr  = sraml_addr;
    assign awlen   = 4'd0;
    assign awsize  = sraml_size;
    assign awvalid = sraml_wr && do_req && !addr_rcv;
    //w
    assign wdata  = sraml_wdata;
    assign wstrb  = sraml_size==2'd0 ? 4'b0001<<sraml_addr[1:0] :
                    sraml_size==2'd1 ? 4'b0011<<sraml_addr[1:0] : 4'b1111;
    assign wlast  = 1'd1;
    assign wvalid = sraml_wr && addr_rcv && !wdata_rcv;
    //b
    assign bready  = 1'b1;

endmodule