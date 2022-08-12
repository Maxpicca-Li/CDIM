`timescale 1ns / 1ps
module mem_wb(
    input logic clk,
    input logic rst,
    input logic clear1,
    input logic clear2, 
    input logic ena1,
    input logic ena2,

    // input  ctrl_sign    M_master_ctrl_sign,
    input  except_bus   M_master_except,
    input  logic        M_master_reg_wen, 
    input  logic [4 :0] M_master_reg_waddr, 
    input  logic [31:0] M_master_inst, 
    input  logic [31:0] M_master_pc, 
    input  logic [31:0] M_master_reg_wdata, 
 
    // input  ctrl_sign    M_slave_ctrl_sign,
    input  except_bus   M_slave_except,
    input  logic        M_slave_reg_wen,
    input  logic [4 :0] M_slave_reg_waddr,
    input  logic [31:0] M_slave_inst,
    input  logic [31:0] M_slave_pc,
    input  logic [31:0] M_slave_reg_wdata,

    // output ctrl_sign    W_master_ctrl_sign,
    output except_bus   W_master_except,
    output logic        W_master_reg_wen,
    output logic [4 :0] W_master_reg_waddr, 
    output logic [31:0] W_master_inst, 
    output logic [31:0] W_master_pc, 
    output logic [31:0] W_master_reg_wdata, 

    // output ctrl_sign    W_slave_ctrl_sign,
    output except_bus   W_slave_except,
    output logic        W_slave_reg_wen,
    output logic [4 :0] W_slave_reg_waddr,
    output logic [31:0] W_slave_inst,
    output logic [31:0] W_slave_pc,
    output logic [31:0] W_slave_reg_wdata,

    input  [31:0]       M_master_debug_cp0_count,
    input  [31:0]       M_master_debug_cp0_random,
    input  [31:0]       M_master_debug_cp0_cause,
    input               M_master_debug_int,
    output logic [31:0] W_master_debug_cp0_count,
    output logic [31:0] W_master_debug_cp0_random,
    output logic [31:0] W_master_debug_cp0_cause,
    output logic        W_master_debug_int
); 
    always @(posedge clk) begin
        if(rst | clear1) begin
            // W_master_ctrl_sign <= 0;
            W_master_except <= 0;
            W_master_reg_wen <= 0;
            W_master_reg_waddr <= 0;
            W_master_inst <= 0;
            W_master_pc <= 0;
            W_master_reg_wdata <= 0;
            W_master_debug_cp0_count <= 0;
            W_master_debug_cp0_random <= 0;
            W_master_debug_cp0_cause <= 0;
            W_master_debug_int <= 0;
        end
        else if (ena1) begin
            // W_master_ctrl_sign <= M_master_ctrl_sign;
            W_master_except <= M_master_except;
            W_master_reg_wen <= M_master_reg_wen;
            W_master_reg_waddr <= M_master_reg_waddr;
            W_master_inst <= M_master_inst;
            W_master_pc <= M_master_pc;
            W_master_reg_wdata <= M_master_reg_wdata;
            W_master_debug_cp0_count <= M_master_debug_cp0_count;
            W_master_debug_cp0_random <= M_master_debug_cp0_random;
            W_master_debug_cp0_cause <= M_master_debug_cp0_cause;
            W_master_debug_int <= M_master_debug_int;
        end
    end

    always @(posedge clk) begin
        if(rst | clear2) begin
            // W_slave_ctrl_sign <= 0;
            W_slave_except <= 0;
            W_slave_reg_wen <= 0;
            W_slave_reg_waddr <= 0;
            W_slave_inst <= 0;
            W_slave_pc <= 0;
            W_slave_reg_wdata <= 0;
        end
        else if (ena2) begin
            // W_slave_ctrl_sign <= M_slave_ctrl_sign;
            W_slave_except <= M_slave_except;
            W_slave_reg_wen <= M_slave_reg_wen;
            W_slave_reg_waddr <= M_slave_reg_waddr;
            W_slave_inst <= M_slave_inst;
            W_slave_pc <= M_slave_pc;
            W_slave_reg_wdata <= M_slave_reg_wdata;
        end
    end

endmodule