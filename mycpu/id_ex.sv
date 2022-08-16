`timescale 1ns / 1ps
`include "defines.vh"
module id_ex(
    input logic clk,
    input logic rst,
    input logic clear1,
    input logic clear2, 
    input logic ena1,
    input logic ena2,

    input  ctrl_sign        D_master_ctrl_sign,
    input  except_bus       D_master_except,
    input  cop0_info        D_master_cop0_info,
    input  logic            D_master_is_link_pc8,
    input  logic            D_master_is_in_delayslot,
    input  logic            D_master_is_branch,
    input  logic            D_master_pred_take,
    input  logic            D_master_jump_conflict,
    input  logic [3 :0]     D_master_branch_type,
    input  logic [3 :0]     D_master_trap_type,
    input  logic [4 :0]     D_master_rs,
    input  logic [4 :0]     D_master_rt,
    input  logic [4 :0]     D_master_reg_waddr,
    input  logic [5 :0]     D_master_op,
    input  logic [`CmovBus] D_master_cmov_type,
    input  logic [31:0]     D_master_pc,
    input  logic [31:0]     D_master_inst,
    input  logic [31:0]     D_master_rs_value,
    input  logic [31:0]     D_master_rt_value,
    input  logic [31:0]     D_master_imm_value,
    input  logic [31:0]     D_master_shamt_value,
    input  logic [31:0]     D_master_pc_plus4,
    input  logic [31:0]     D_master_branch_target,
    
    input  ctrl_sign        D_slave_ctrl_sign,
    input  except_bus       D_slave_except,
    input  cop0_info        D_slave_cop0_info,
    input  logic            D_slave_is_in_delayslot,
    input  logic [4 :0]     D_slave_rs,
    input  logic [4 :0]     D_slave_rt,
    input  logic [4 :0]     D_slave_reg_waddr,
    input  logic [5 :0]     D_slave_op,
    input  logic [`CmovBus] D_slave_cmov_type,
    input  logic [31:0]     D_slave_pc,
    input  logic [31:0]     D_slave_inst,
    input  logic [31:0]     D_slave_rs_value,
    input  logic [31:0]     D_slave_rt_value,
    input  logic [31:0]     D_slave_imm_value,
    input  logic [31:0]     D_slave_shamt_value,

    output ctrl_sign        E_master_ctrl_sign,
    output except_bus       E_master_except,
    output cop0_info        E_master_cop0_info,
    output logic            E_master_is_link_pc8,
    output logic            E_master_is_in_delayslot,
    output logic            E_master_is_branch,
    output logic            E_master_pred_take,
    output logic            E_master_jump_conflict,
    output logic [3 :0]     E_master_branch_type,
    output logic [3 :0]     E_master_trap_type,
    output logic [4 :0]     E_master_rs,
    output logic [4 :0]     E_master_rt,
    output logic [4 :0]     E_master_reg_waddr,
    output logic [5 :0]     E_master_op,
    output logic [`CmovBus] E_master_cmov_type,
    output logic [31:0]     E_master_pc,
    output logic [31:0]     E_master_inst,
    output logic [31:0]     E_master_rs_value,
    output logic [31:0]     E_master_rt_value,
    output logic [31:0]     E_master_imm_value,
    output logic [31:0]     E_master_shamt_value,
    output logic [31:0]     E_master_pc_plus4,
    output logic [31:0]     E_master_branch_target,
    
    output ctrl_sign        E_slave_ctrl_sign,
    output except_bus       E_slave_except,
    output cop0_info        E_slave_cop0_info,
    output logic            E_slave_is_in_delayslot,
    output logic [4 :0]     E_slave_rs,
    output logic [4 :0]     E_slave_rt,
    output logic [4 :0]     E_slave_reg_waddr,
    output logic [5 :0]     E_slave_op,
    output logic [`CmovBus] E_slave_cmov_type,
    output logic [31:0]     E_slave_pc,
    output logic [31:0]     E_slave_inst,
    output logic [31:0]     E_slave_rs_value,
    output logic [31:0]     E_slave_rt_value,
    output logic [31:0]     E_slave_imm_value,
    output logic [31:0]     E_slave_shamt_value
); 

    always @(posedge clk) begin
        if(rst | clear1) begin
            E_master_ctrl_sign <= 0;
            E_master_except <= 0;
            E_master_cop0_info <= 0;
            E_master_is_link_pc8 <= 0;
            E_master_is_in_delayslot <= 0;
            E_master_is_branch <= 0;
            E_master_pred_take <= 0;
            E_master_jump_conflict <= 0;
            E_master_branch_type <= 0;
            E_master_trap_type <= 0;
            E_master_rs <= 0;
            E_master_rt <= 0;
            E_master_reg_waddr <= 0;
            E_master_op <= 0;
            E_master_cmov_type <= 0;
            E_master_pc <= 0;
            E_master_inst <= 0;
            E_master_rs_value <= 0;
            E_master_rt_value <= 0;
            E_master_imm_value <= 0;
            E_master_shamt_value <= 0;
            E_master_pc_plus4 <= 0;
            E_master_branch_target <= 0;
        end
        else if (ena1) begin
            E_master_ctrl_sign <= D_master_ctrl_sign;
            E_master_except <= D_master_except;
            E_master_cop0_info <= D_master_cop0_info;
            E_master_is_link_pc8 <= D_master_is_link_pc8;
            E_master_is_in_delayslot <= D_master_is_in_delayslot;
            E_master_is_branch <= D_master_is_branch;
            E_master_pred_take <= D_master_pred_take;
            E_master_jump_conflict <= D_master_jump_conflict;
            E_master_branch_type <= D_master_branch_type;
            E_master_trap_type <= D_master_trap_type;
            E_master_rs <= D_master_rs;
            E_master_rt <= D_master_rt;
            E_master_reg_waddr <= D_master_reg_waddr;
            E_master_op <= D_master_op;
            E_master_cmov_type <= D_master_cmov_type;
            E_master_pc <= D_master_pc;
            E_master_inst <= D_master_inst;
            E_master_rs_value <= D_master_rs_value;
            E_master_rt_value <= D_master_rt_value;
            E_master_imm_value <= D_master_imm_value;
            E_master_shamt_value <= D_master_shamt_value;
            E_master_pc_plus4 <= D_master_pc_plus4;
            E_master_branch_target <= D_master_branch_target;
        end
    end

    always @(posedge clk) begin
        if(rst | clear2) begin
            E_slave_ctrl_sign <= 0;
            E_slave_except <= 0;
            E_slave_cop0_info <= 0;
            E_slave_is_in_delayslot <= 0;
            E_slave_rs <= 0;
            E_slave_rt <= 0;
            E_slave_reg_waddr <= 0;
            E_slave_op <= 0;
            E_slave_cmov_type <= 0;
            E_slave_pc <= 0;
            E_slave_inst <= 0;
            E_slave_rs_value <= 0;
            E_slave_rt_value <= 0;
            E_slave_imm_value <= 0;
            E_slave_shamt_value <= 0;
        end
        else if (ena2) begin
            E_slave_ctrl_sign <= D_slave_ctrl_sign;
            E_slave_except <= D_slave_except;
            E_slave_cop0_info <= D_slave_cop0_info;
            E_slave_is_in_delayslot <= D_slave_is_in_delayslot;
            E_slave_rs <= D_slave_rs;
            E_slave_rt <= D_slave_rt;
            E_slave_reg_waddr <= D_slave_reg_waddr;
            E_slave_op <= D_slave_op;
            E_slave_cmov_type <= D_slave_cmov_type;
            E_slave_pc <= D_slave_pc;
            E_slave_inst <= D_slave_inst;
            E_slave_rs_value <= D_slave_rs_value;
            E_slave_rt_value <= D_slave_rt_value;
            E_slave_imm_value <= D_slave_imm_value;
            E_slave_shamt_value <= D_slave_shamt_value;
        end
    end

endmodule