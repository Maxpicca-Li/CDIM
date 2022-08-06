`timescale 1ns / 1ps
module mem_wb(
    input wire clk,
    input wire rst,
    input wire clear1,
    input wire clear2, 
    input wire ena1,
    input wire ena2,

    input wire M_master_reg_wen, 
    input wire [4 :0]M_master_reg_waddr, 
    input except_bus M_master_except, 
    input wire [31:0]M_master_inst, 
    input wire [31:0]M_master_pc, 
    input wire [31:0]M_master_reg_wdata, 

    input wire M_slave_reg_wen,
    input wire [4 :0]M_slave_reg_waddr,
    input except_bus M_slave_except,
    input wire [31:0]M_slave_inst,
    input wire [31:0]M_slave_pc,
    input wire [31:0]M_slave_reg_wdata,

    output reg W_master_reg_wen, 
    output reg [4 :0]W_master_reg_waddr, 
    output except_bus W_master_except, 
    output reg [31:0]W_master_inst, 
    output reg [31:0]W_master_pc, 
    output reg [31:0]W_master_reg_wdata, 

    output reg W_slave_reg_wen,
    output reg [4 :0]W_slave_reg_waddr,
    output except_bus W_slave_except,
    output reg [31:0]W_slave_inst,
    output reg [31:0]W_slave_pc,
    output reg [31:0]W_slave_reg_wdata

); 
    always @(posedge clk) begin
        if(rst | clear1) begin
            W_master_reg_wen <= 0;
            W_master_reg_waddr <= 0;
            W_master_except <= 0;
            W_master_inst <= 0;
            W_master_pc <= 0;
            W_master_reg_wdata <= 0;
        end
        else if (ena1) begin
            W_master_reg_wen <= M_master_reg_wen;
            W_master_reg_waddr <= M_master_reg_waddr;
            W_master_except <= M_master_except;
            W_master_inst <= M_master_inst;
            W_master_pc <= M_master_pc;
            W_master_reg_wdata <= M_master_reg_wdata;
        end
    end

    always @(posedge clk) begin
        if(rst | clear2) begin
            W_slave_reg_wen <= 0;
            W_slave_reg_waddr <= 0;
            W_slave_except <= 0;
            W_slave_inst <= 0;
            W_slave_pc <= 0;
            W_slave_reg_wdata <= 0;
        end
        else if (ena2) begin
            W_slave_reg_wen <= M_slave_reg_wen;
            W_slave_reg_waddr <= M_slave_reg_waddr;
            W_slave_except <= M_slave_except;
            W_slave_inst <= M_slave_inst;
            W_slave_pc <= M_slave_pc;
            W_slave_reg_wdata <= M_slave_reg_wdata;
        end
    end

endmodule