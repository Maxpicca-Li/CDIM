`timescale 1ns / 1ps
`include "defines.vh"
module alu_res_selectM(
    input  logic [7:0]aluop,
    input  logic [31:0]cp0_data,
    input  logic [31:0]alu_res_tmp,
    input  logic [63:0]hilo,
    output logic [31:0]alu_res
);
    // alu_res的选择
    // 1. MFC0 cp0_data
    // 2. MFHI hi 
    // 3. MFLO lo
    // 4. pc_link_8 (暂时在E解决)
    // 5. alu_res_tmp
    assign alu_res = aluop==`ALUOP_MFC0 ? cp0_data    :
                     aluop==`ALUOP_MFHI ? hilo[63:32] :
                     aluop==`ALUOP_MFLO ? hilo[31: 0] :
                     alu_res_tmp;

endmodule
    
