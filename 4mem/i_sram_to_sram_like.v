module i_sram_to_sram_like (
    input wire clk, rst,
    //sram
    input wire inst_sram_en,
    input wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_rdata1,
    output wire [31:0] inst_sram_rdata2,
    output wire inst_sram_data_ok1,
    output wire inst_sram_data_ok2,
    output wire i_stall,
    //sram like
    output wire inst_req, //
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok1,
    input wire inst_data_ok2,
    input wire [31:0] inst_rdata1,
    input wire [31:0] inst_rdata2,

    input wire longest_stall
);
    reg addr_rcv;      //地址握手成功
    reg do_finish;     //读事务结束
    reg data_ok_save1;
    reg data_ok_save2;

    always @(posedge clk) begin
        addr_rcv <= rst          ? 1'b0 :
                    inst_req & inst_addr_ok & ~inst_data_ok1 ? 1'b1 :    //保证先inst_req再addr_rcv；如果addr_ok同时data_ok，则优先data_ok
                    inst_data_ok1 ? 1'b0 : addr_rcv;
    end

    always @(posedge clk) begin
        do_finish <= rst          ? 1'b0 :
                     inst_data_ok1 ? 1'b1 :
                     ~longest_stall ? 1'b0 : do_finish;
        data_ok_save1  <= rst ? 1'b0 : inst_data_ok1;
        data_ok_save2  <= rst ? 1'b0 : inst_data_ok2;
    end

    //save rdata
    reg [31:0] inst_rdata_save1;
    reg [31:0] inst_rdata_save2;
    always @(posedge clk) begin
        inst_rdata_save1 <= rst ? 32'b0:
                           inst_data_ok1 ? inst_rdata1 : inst_rdata_save1;
        inst_rdata_save2 <= rst ? 32'b0:
                           inst_data_ok2 ? inst_rdata2 : inst_rdata_save2;
    end

    //sram like
    assign inst_req = inst_sram_en & ~addr_rcv & ~do_finish;
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    //sram
    assign inst_sram_rdata1 = inst_rdata_save1;
    assign inst_sram_rdata2 = inst_rdata_save2;
    assign inst_sram_data_ok1 = data_ok_save1;
    assign inst_sram_data_ok2 = data_ok_save2;
    assign i_stall = inst_sram_en & ~do_finish;

endmodule