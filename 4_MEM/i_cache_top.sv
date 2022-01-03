module i_cache_top (
    input  clk,
    input  rst,
    input  longest_stall, // one pipline stall -->  one mem visit
    output logic        i_stall,  // to let cpu wait return_data

    // cpu master
    input               inst_en   ,
    input       [3 :0]  inst_wen  ,
    input       [31:0]  inst_addr ,
    output logic        inst_data_ok ,
    output logic        inst_data_ok1,
    output logic        inst_data_ok2,
    output logic [31:0] inst_rdata1,
    output logic [31:0] inst_rdata2,
    
    // axi slave
    // read channel
    input               arready,
    output logic [31:0] araddr ,
    output logic [3 :0] arlen  ,
    output logic [2 :0] arsize ,
    output logic        arvalid,
    // read response channel
    input  [31:0] rdata        ,
    input         rlast        ,
    input         rvalid       ,
    output logic  rready   

);
    wire        inst_addr_ok;
    wire        inst_req   ;
    wire        inst_wr    ;
    wire [1 :0] inst_size  ;
    wire [31:0] inst_wdata ;
    reg addr_succ; // 地址握手成功
    reg do_finish; // 完成读写操作
    
    // cpu control signals
    assign i_stall = inst_en & ~do_finish;

    // sram like signals
    assign inst_req  = inst_en & ~addr_succ & ~do_finish;
    assign inst_wr   = 1'b0;
    assign inst_size = 2'b10;
    assign inst_wdata = 32'b0;

    // cache access control
    // addr_succ
    always @(posedge clk) begin
        addr_succ <= rst ? 1'b0:
                     inst_req & inst_addr_ok & ~inst_data_ok ? 1'b1 : // 判断顺序：先req，再addr_ok，再data_ok
                     inst_data_ok ? 1'b0 :
                     addr_succ;
    end
    // do_finish
    always @(posedge clk) begin
        do_finish <= rst ? 1'b0:
                     inst_data_ok ? 1'b1:
                     ~longest_stall ? 1'b0 : // cpu未阻塞时
                     do_finish;
    end

    i_cache_burst #(
        .INDEX_WIDTH  		( 7 		),
        .OFFSET_WIDTH 		( 5 		),
        .WAY_NUM      		( 2 		))
    u_i_cache_burst(
        //ports
        .clk               		( clk               		),
        .rst               		( rst               		),
        .cpu_inst_req      		( inst_req      		),
        .cpu_inst_wr       		( inst_wr       		),
        .cpu_inst_wdata    		( inst_wdata    		),
        .cpu_inst_size     		( inst_size     		),
        .cpu_inst_addr     		( inst_addr     		),
        .cpu_inst_rdata1   		( inst_rdata1   		),
        .cpu_inst_rdata2   		( inst_rdata2   		),
        .cpu_inst_addr_ok  		( inst_addr_ok  		),
        .cpu_inst_data_ok  		( inst_data_ok  		),
        .cpu_inst_data_ok1 		( inst_data_ok1 		),
        .cpu_inst_data_ok2 		( inst_data_ok2 		),
        .araddr            		( araddr            		),
        .arlen             		( arlen             		),
        .arsize            		( arsize            		),
        .arvalid           		( arvalid           		),
        .arready           		( arready           		),
        .rdata             		( rdata             		),
        .rlast             		( rlast             		),
        .rvalid            		( rvalid            		),
        .rready            		( rready            		)
    );


endmodule