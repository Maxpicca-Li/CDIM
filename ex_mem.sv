`timescale 1ns / 1ps
module ex_mem(
    input logic clk,
    input logic rst,
    input logic clear1,
    input logic clear2, 
    input logic ena1,
    input logic ena2,

    input  logic        E_mem_en,
    input  logic        E_mem_ren,
    input  logic        E_mem_wen,
    input  logic [5 :0] E_mem_op,
    input  logic [31:0] E_mem_addr,
    input  logic [31:0] E_mem_wdata,
    input  logic [31:0] E_mem_va,
    output logic        M_mem_en,
    output logic        M_mem_ren,
    output logic        M_mem_wen,
    output logic [5 :0] M_mem_op,
    output logic [31:0] M_mem_addr,
    output logic [31:0] M_mem_wdata,
    output logic [31:0] M_mem_va,

    input  ctrl_sign    E_master_ctrl_sign,
    input  except_bus   E_master_except,
    input  logic        E_master_reg_wen,
    input  logic        E_master_mem_sel,
    input  logic        E_master_is_in_delayslot,
    input  logic [4 :0] E_master_reg_waddr,
    input  logic [31:0] E_master_inst,
    input  logic [31:0] E_master_alu_res,
    input  logic [31:0] E_master_pc,

    input  ctrl_sign    E_slave_ctrl_sign,
    input  except_bus   E_slave_except,
    input  logic        E_slave_reg_wen,
    input  logic        E_slave_mem_sel,
    input  logic        E_slave_is_in_delayslot,
    input  logic [4 :0] E_slave_reg_waddr,
    input  logic [31:0] E_slave_pc,
    input  logic [31:0] E_slave_inst,
    input  logic [31:0] E_slave_alu_res,

    output ctrl_sign    M_master_ctrl_sign,
    output except_bus   M_master_except,
    output logic        M_master_reg_wen,
    output logic        M_master_mem_sel,
    output logic        M_master_is_in_delayslot,
    output logic [4 :0] M_master_reg_waddr,
    output logic [31:0] M_master_inst,
    output logic [31:0] M_master_alu_res,
    output logic [31:0] M_master_pc,
    
    output ctrl_sign    M_slave_ctrl_sign,
    output except_bus   M_slave_except,
    output logic        M_slave_reg_wen,
    output logic        M_slave_mem_sel,
    output logic        M_slave_is_in_delayslot,
    output logic [4 :0] M_slave_reg_waddr,
    output logic [31:0] M_slave_pc,
    output logic [31:0] M_slave_inst,
    output logic [31:0] M_slave_alu_res,

    input  [31:0]       E_master_debug_cp0_count,  
    input  [31:0]       E_master_debug_cp0_random,
    input  [31:0]       E_master_debug_cp0_cause,

    output logic [31:0] M_master_debug_cp0_count,  
    output logic [31:0] M_master_debug_cp0_random,
    output logic [31:0] M_master_debug_cp0_cause
); 

    always_ff @(posedge clk) begin
        if(rst | clear1) begin
            M_mem_en <= 0;
            M_mem_ren <= 0;
            M_mem_wen <= 0;
            M_mem_op <= 0;
            M_mem_addr <= 0;
            M_mem_wdata <= 0;
            M_mem_va <= 0;
            M_master_ctrl_sign <= 0;
            M_master_except <= 0;
            M_master_reg_wen <= 0;
            M_master_mem_sel <= 0;
            M_master_is_in_delayslot <= 0;
            M_master_reg_waddr <= 0;
            M_master_inst <= 0;
            M_master_alu_res <= 0;
            M_master_pc <= 0;
            M_master_debug_cp0_count <= 0;
            M_master_debug_cp0_random <= 0;
            M_master_debug_cp0_cause <= 0;
        end
        else if (ena1) begin
            M_mem_en <= E_mem_en;
            M_mem_ren <= E_mem_ren;
            M_mem_wen <= E_mem_wen;
            M_mem_op <= E_mem_op;
            M_mem_addr <= E_mem_addr;
            M_mem_wdata <= E_mem_wdata;
            M_mem_va <= E_mem_va;
            M_master_ctrl_sign <= E_master_ctrl_sign;
            M_master_except <= E_master_except;
            M_master_reg_wen <= E_master_reg_wen;
            M_master_mem_sel <= E_master_mem_sel;
            M_master_is_in_delayslot <= E_master_is_in_delayslot;
            M_master_reg_waddr <= E_master_reg_waddr;
            M_master_inst <= E_master_inst;
            M_master_alu_res <= E_master_alu_res;
            M_master_pc <= E_master_pc;
            M_master_debug_cp0_count <= E_master_debug_cp0_count;
            M_master_debug_cp0_random <= E_master_debug_cp0_random;
            M_master_debug_cp0_cause <= E_master_debug_cp0_cause;
        end
    end

    always_ff @(posedge clk) begin
        if(rst | clear2) begin
            M_slave_ctrl_sign <= 0;
            M_slave_except <= 0;
            M_slave_reg_wen <= 0;
            M_slave_mem_sel <= 0;
            M_slave_is_in_delayslot <= 0;
            M_slave_reg_waddr <= 0;
            M_slave_pc <= 0;
            M_slave_inst <= 0;
            M_slave_alu_res <= 0;
        end
        else if (ena2) begin
            M_slave_ctrl_sign <= E_slave_ctrl_sign;
            M_slave_except <= E_slave_except;
            M_slave_reg_wen <= E_slave_reg_wen;
            M_slave_mem_sel <= E_slave_mem_sel;
            M_slave_is_in_delayslot <= E_slave_is_in_delayslot;
            M_slave_reg_waddr <= E_slave_reg_waddr;
            M_slave_pc <= E_slave_pc;
            M_slave_inst <= E_slave_inst;
            M_slave_alu_res <= E_slave_alu_res;
        end
    end

endmodule