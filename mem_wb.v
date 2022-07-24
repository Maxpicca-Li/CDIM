`timescale 1ns / 1ps
module mem_wb(
    input wire clk,
    input wire rst,
    input wire clear1,
    input wire clear2, 
    input wire ena1,
    input wire ena2,

    input wire M_master_hilowrite, 
    input wire M_master_reg_wen, 
    input wire M_master_memtoReg, 
    input wire [4 :0]M_master_reg_waddr, 
    input wire [`EXCEPT_BUS]M_master_except, 
    input wire [31:0]M_master_inst, 
    input wire [31:0]M_master_pc, 
    input wire [31:0]M_master_alu_res, 
    input wire [31:0]M_master_mem_rdata, 
    input wire [63:0]M_master_alu_out64, 

    input wire M_slave_reg_wen,
    input wire [4 :0]M_slave_reg_waddr,
    input wire [`EXCEPT_BUS]M_slave_except,
    input wire [31:0]M_slave_inst,
    input wire [31:0]M_slave_pc,
    input wire [31:0]M_slave_alu_res,

    output reg W_master_hilowrite, 
    output reg W_master_reg_wen, 
    output reg W_master_memtoReg, 
    output reg [4 :0]W_master_reg_waddr, 
    output reg [`EXCEPT_BUS]W_master_except, 
    output reg [31:0]W_master_inst, 
    output reg [31:0]W_master_pc, 
    output reg [31:0]W_master_alu_res, 
    output reg [31:0]W_master_mem_rdata, 
    output reg [63:0]W_master_alu_out64, 

    output reg W_slave_reg_wen,
    output reg [4 :0]W_slave_reg_waddr,
    output reg [`EXCEPT_BUS]W_slave_except,
    output reg [31:0]W_slave_inst,
    output reg [31:0]W_slave_pc,
    output reg [31:0]W_slave_alu_res

); 
    always @(posedge clk) begin
        if(rst | clear1) begin
            W_master_hilowrite <= 0;
            W_master_reg_wen <= 0;
            W_master_memtoReg <= 0;
            W_master_reg_waddr <= 0;
            W_master_except <= 0;
            W_master_inst <= 0;
            W_master_pc <= 0;
            W_master_alu_res <= 0;
            W_master_mem_rdata <= 0;
            W_master_alu_out64 <= 0;
        end
        else if (ena1) begin
            W_master_hilowrite <= M_master_hilowrite;
            W_master_reg_wen <= M_master_reg_wen;
            W_master_memtoReg <= M_master_memtoReg;
            W_master_reg_waddr <= M_master_reg_waddr;
            W_master_except <= M_master_except;
            W_master_inst <= M_master_inst;
            W_master_pc <= M_master_pc;
            W_master_alu_res <= M_master_alu_res;
            W_master_mem_rdata <= M_master_mem_rdata;
            W_master_alu_out64 <= M_master_alu_out64;
        end
    end

    always @(posedge clk) begin
        if(rst | clear2) begin
            W_slave_reg_wen <= 0;
            W_slave_reg_waddr <= 0;
            W_slave_except <= 0;
            W_slave_inst <= 0;
            W_slave_pc <= 0;
            W_slave_alu_res <= 0;
        end
        else if (ena2) begin
            W_slave_reg_wen <= M_slave_reg_wen;
            W_slave_reg_waddr <= M_slave_reg_waddr;
            W_slave_except <= M_slave_except;
            W_slave_inst <= M_slave_inst;
            W_slave_pc <= M_slave_pc;
            W_slave_alu_res <= M_slave_alu_res;
        end
    end

endmodule