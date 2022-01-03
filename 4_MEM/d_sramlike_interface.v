module d_sramlike_interface (
    input  wire clk,rst,
    input  wire longest_stall, // one pipline stall -->  one mem visit
    // sram
    input  wire        data_sram_en   ,
    input  wire [3 :0] data_sram_wen  ,
    input  wire [31:0] data_sram_addr ,
    input  wire [31:0] data_sram_wdata,
    output wire [31:0] data_sram_rdata,
    output wire        d_stall,  // to let cpu wait return_data

    // sram_like
    output wire        data_req     ,
    output wire        data_wr      ,
    output wire [1 :0] data_size    ,
    output wire [31:0] data_addr    ,
    output wire [31:0] data_wdata   ,
    input  wire [31:0] data_rdata   ,
    input  wire        data_addr_ok ,
    input  wire        data_data_ok 
);
    
    reg addr_succ; // 地址握手成功
    reg do_finish; // 完成读写操作
    reg [31:0] data_rdata_temp;

    // sramlike
    assign data_req  = data_sram_en & ~addr_succ & ~do_finish;
    assign data_wr   = data_sram_en & |data_sram_wen;
    assign data_size = (data_sram_wen == 4'b0001 ||
                        data_sram_wen == 4'b0010 ||
                        data_sram_wen == 4'b0100 || 
                        data_sram_wen == 4'b1000  ) ? 2'b00 :
                       (data_sram_wen == 4'b0011 ||
                        data_sram_wen == 4'b1100  ) ? 2'b01 :
                        2'b10;
    assign data_addr  = data_sram_addr;
    assign data_wdata = data_sram_wdata;

    // sram
    assign data_sram_rdata = data_rdata_temp;
    assign d_stall = data_sram_en & ~do_finish;

    // signal of addr_succ
    always @(posedge clk) begin
        addr_succ <= rst ? 1'b0:
                     data_req & data_addr_ok & ~data_data_ok ? 1'b1 : // 判断顺序：先req，再addr_ok，再data_ok
                     data_data_ok ? 1'b0 :
                     addr_succ;
    end

    // signal of do_finish
    always @(posedge clk) begin
        do_finish <= rst ? 1'b0:
                     data_data_ok ? 1'b1:
                     ~longest_stall ? 1'b0 : // cpu未阻塞时
                     do_finish;
    end

    // data of rdata
    always @(posedge clk) begin
        data_rdata_temp <=  rst ? 32'b0:
                            data_data_ok ? data_rdata:
                            data_rdata_temp;
    end

endmodule