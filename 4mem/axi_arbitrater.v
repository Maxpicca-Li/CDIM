// 仲裁参考：https://github.com/14010007517/2020NSCSCC
module axi_arbitrater (
    input wire clk, rst,
    //I CACHE 从方
    input wire [31:0] i_araddr,
    input wire [3:0] i_arlen,
    input wire i_arvalid,
    output wire i_arready,

    output wire [31:0] i_rdata,
    output wire i_rlast,
    output wire i_rvalid,
    input wire i_rready,

    //D CACHE 从方
    input wire [31:0] d_araddr,
    input wire [3:0] d_arlen,
    input wire [2:0] d_arsize,
    input wire d_arvalid,
    output wire d_arready,

    output wire [31:0] d_rdata,
    output wire d_rlast,
    output wire d_rvalid,
    input wire d_rready,
    //write
    input wire [31:0] d_awaddr,
    input wire [3:0] d_awlen,
    input wire [2:0] d_awsize,
    input wire d_awvalid,
    output wire d_awready,
    
    input wire [31:0] d_wdata,
    input wire [3:0] d_wstrb,
    input wire d_wlast,
    input wire d_wvalid,
    output wire d_wready,

    output wire d_bvalid,
    input wire d_bready,
    
    //Outer 主方
    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[3:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
                
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready,
               
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[3:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready
);
	// picca: 含i和d的仲裁模块，支持多字传输
    wire ar_sel;     //0-> i_cache, 1-> d_cache

    //ar 
    // picca: 请求分类，inst_rreq,data_rreq,data_wreq三种请求
    // picca: 按理说应该优先d_cache，ar的片选
    // picca: 这里的arvalid，其实可以理解为是否有req
    // assign ar_sel = ~i_arvalid & d_arvalid ? 1'b1 : 1'b0;   //优先i_cache
    assign ar_sel = ~d_arvalid & i_arvalid ? 1'b0 : 1'b1;   //优先d_cache

    //r
    // picca: ar冲突后，r的片选
    // picca: 《CPU设计实战》中提到的是0取指，1取数，一般地，(out的arid)=(in的rid)
    // picca: 完美利用多通道及其仲裁
    wire r_sel;     //0-> i_cache, 1-> d_cache
    assign r_sel = rid[0];

    //I CACHE
    assign i_arready = arready & ~ar_sel;
    assign i_rdata = ~r_sel ? rdata : 32'b0;
    assign i_rlast = ~r_sel ? rlast : 1'b0;  // picca: 块多字传输用的到
    assign i_rvalid = ~r_sel ? rvalid : 1'b0;
    
    //D CACHE
    assign d_arready = arready & ar_sel;
    assign d_rdata = r_sel ? rdata : 32'b0;
    assign d_rlast = r_sel ? rlast : 1'b0;
    assign d_rvalid = r_sel ? rvalid : 1'b0;

    //AXI
    //ar
    assign arid = {3'b0, ar_sel}; // picca: 自定义arid，方便识别rid
    assign araddr = ar_sel ? d_araddr : i_araddr;
    assign arlen = ar_sel ? d_arlen : i_arlen; // picca: 块多字传输协议
    assign arsize  = ar_sel ? d_arsize : 2'b10;         //读一个字
    assign arburst = 2'b10;         //Incrementing burst // picca: 增量突发传输
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = ar_sel ? d_arvalid : i_arvalid;
                        //         
    //r
    assign rready = ~r_sel ? i_rready : d_rready;
                        //            

    //aw
    assign awid    = 4'd0;
    assign awaddr  = d_awaddr;
    assign awlen   = d_awlen;      //8*4B
    assign awsize  = d_awsize;
    assign awburst = 2'b10;     //Incrementing burst
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = d_awvalid;
    //w
    assign wid    = 4'd0;
    assign wdata  = d_wdata;
    // assign wstrb  = do_size_r==2'd0 ? 4'b0001<<do_addr_r[1:0] :
    //                 do_size_r==2'd1 ? 4'b0011<<do_addr_r[1:0] : 4'b1111;
    assign wstrb = d_wstrb;
    assign wlast  = d_wlast;
    assign wvalid = d_wvalid;
    //b
    assign bready  = d_bready;
    
    //to d-cache
    assign d_awready = awready;
    assign d_wready  = wready;
    assign d_bvalid  = bvalid;
endmodule