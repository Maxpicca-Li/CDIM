`timescale 1ns / 1ps
module id_ex(
    input wire clk,
    input wire rst,
    input wire clear1,
    input wire clear2, 
    input wire ena1,
    input wire ena2,

    input wire D_master_memtoReg,
    input wire D_master_reg_wen,
    input wire D_master_alu_sela,
    input wire D_master_alu_selb,
    input wire D_master_is_link_pc8,
    input wire D_master_mem_en,
    input wire D_master_memWrite,
    input wire D_master_memRead,
    input wire D_master_hilowrite,   
    input wire D_master_cp0write,
    input wire D_master_is_in_delayslot,
    input wire [3 :0]D_master_branch_type,
    input wire [4 :0]D_master_shamt,
    input wire [4 :0]D_master_reg_waddr,
    input wire [4 :0]D_master_rd,
    input wire [7 :0]D_master_aluop,
    input wire [5 :0]D_master_op,
    input wire [7 :0]D_master_except,
    input wire [25:0]D_master_j_target,
    input wire [31:0]D_master_pc,
    input wire [31:0]D_master_inst,
    input wire [31:0]D_master_rs_value,
    input wire [31:0]D_master_rt_value,
    input wire [31:0]D_master_imm_value,

    input wire D_slave_reg_wen,
    input wire D_slave_alu_sela,
    input wire D_slave_alu_selb,
    input wire D_slave_is_link_pc8,
    input wire D_slave_memtoReg,
    input wire D_slave_cp0write,
    input wire D_slave_is_in_delayslot,
    input wire [4 :0]D_slave_shamt,
    input wire [4 :0]D_slave_reg_waddr,
    input wire [7 :0]D_slave_aluop,
    input wire [7 :0]D_slave_except,
    input wire [31:0]D_slave_inst,
    input wire [31:0]D_slave_rs_value,
    input wire [31:0]D_slave_rt_value,
    input wire [31:0]D_slave_imm_value,
    input wire [31:0]D_slave_pc,

    output reg E_master_memtoReg,
    output reg E_master_reg_wen,
    output reg E_master_alu_sela,
    output reg E_master_alu_selb,
    output reg E_master_is_link_pc8,
    output reg E_master_mem_en,
    output reg E_master_memWrite,
    output reg E_master_memRead,
    output reg E_master_hilowrite,   
    output reg E_master_cp0write,
    output reg E_master_is_in_delayslot,
    output reg [3 :0]E_master_branch_type,
    output reg [4 :0]E_master_shamt,
    output reg [4 :0]E_master_reg_waddr,
    output reg [4 :0]E_master_rd,
    output reg [7 :0]E_master_aluop,
    output reg [5 :0]E_master_op,
    output reg [7 :0]E_master_except,
    output reg [25:0]E_master_j_target,
    output reg [31:0]E_master_pc,
    output reg [31:0]E_master_inst,
    output reg [31:0]E_master_rs_value,
    output reg [31:0]E_master_rt_value,
    output reg [31:0]E_master_imm_value,

    output reg E_slave_ena,
    output reg E_slave_reg_wen,
    output reg E_slave_alu_sela,
    output reg E_slave_alu_selb,
    output reg E_slave_is_link_pc8,
    output reg E_slave_memtoReg,
    output reg E_slave_cp0write,
    output reg E_slave_is_in_delayslot,
    output reg [4 :0]E_slave_shamt,
    output reg [4 :0]E_slave_reg_waddr,
    output reg [7 :0]E_slave_aluop,
    output reg [7 :0]E_slave_except,
    output reg [31:0]E_slave_inst,
    output reg [31:0]E_slave_rs_value,
    output reg [31:0]E_slave_rt_value,
    output reg [31:0]E_slave_imm_value,
    output reg [31:0]E_slave_pc
); 

    always @(posedge clk) begin
        if(rst | clear1) begin
            E_master_memtoReg <= 0;
            E_master_reg_wen <= 0;
            E_master_alu_sela <= 0;
            E_master_alu_selb <= 0;
            E_master_is_link_pc8 <= 0;
            E_master_mem_en <= 0;
            E_master_memWrite <= 0;
            E_master_memRead <= 0;
            E_master_hilowrite <= 0;
            E_master_cp0write <= 0;
            E_master_is_in_delayslot <= 0;
            E_master_branch_type <= 0;
            E_master_shamt <= 0;
            E_master_reg_waddr <= 0;
            E_master_rd <= 0;
            E_master_aluop <= 0;
            E_master_op <= 0;
            E_master_except <= 0;
            E_master_j_target <= 0;
            E_master_pc <= 0;
            E_master_inst <= 0;
            E_master_rs_value <= 0;
            E_master_rt_value <= 0;
            E_master_imm_value <= 0;
        end
        else if (ena1) begin
            E_master_memtoReg <= D_master_memtoReg;
            E_master_reg_wen <= D_master_reg_wen;
            E_master_alu_sela <= D_master_alu_sela;
            E_master_alu_selb <= D_master_alu_selb;
            E_master_is_link_pc8 <= D_master_is_link_pc8;
            E_master_mem_en <= D_master_mem_en;
            E_master_memWrite <= D_master_memWrite;
            E_master_memRead <= D_master_memRead;
            E_master_hilowrite <= D_master_hilowrite;
            E_master_cp0write <= D_master_cp0write;
            E_master_is_in_delayslot <= D_master_is_in_delayslot;
            E_master_branch_type <= D_master_branch_type;
            E_master_shamt <= D_master_shamt;
            E_master_reg_waddr <= D_master_reg_waddr;
            E_master_rd <= D_master_rd;
            E_master_aluop <= D_master_aluop;
            E_master_op <= D_master_op;
            E_master_except <= D_master_except;
            E_master_j_target <= D_master_j_target;
            E_master_pc <= D_master_pc;
            E_master_inst <= D_master_inst;
            E_master_rs_value <= D_master_rs_value;
            E_master_rt_value <= D_master_rt_value;
            E_master_imm_value <= D_master_imm_value;
        end
    end

    always @(posedge clk) begin
        if(rst | clear2) begin
            E_slave_reg_wen <= 0;
            E_slave_alu_sela <= 0;
            E_slave_alu_selb <= 0;
            E_slave_is_link_pc8 <= 0;
            E_slave_memtoReg <= 0;
            E_slave_cp0write <= 0;
            E_slave_is_in_delayslot <= 0;
            E_slave_shamt <= 0;
            E_slave_reg_waddr <= 0;
            E_slave_aluop <= 0;
            E_slave_except <= 0;
            E_slave_inst <= 0;
            E_slave_rs_value <= 0;
            E_slave_rt_value <= 0;
            E_slave_imm_value <= 0;
            E_slave_pc <= 0;
            E_slave_ena <= 0;
        end
        else if (ena2) begin
            E_slave_reg_wen <= D_slave_reg_wen;
            E_slave_alu_sela <= D_slave_alu_sela;
            E_slave_alu_selb <= D_slave_alu_selb;
            E_slave_is_link_pc8 <= D_slave_is_link_pc8;
            E_slave_memtoReg <= D_slave_memtoReg;
            E_slave_cp0write <= D_slave_cp0write;
            E_slave_is_in_delayslot <= D_slave_is_in_delayslot;
            E_slave_shamt <= D_slave_shamt;
            E_slave_reg_waddr <= D_slave_reg_waddr;
            E_slave_aluop <= D_slave_aluop;
            E_slave_except <= D_slave_except;
            E_slave_inst <= D_slave_inst;
            E_slave_rs_value <= D_slave_rs_value;
            E_slave_rt_value <= D_slave_rt_value;
            E_slave_imm_value <= D_slave_imm_value;
            E_slave_pc <= D_slave_pc;
            E_slave_ena <= ena2;
        end
    end

endmodule