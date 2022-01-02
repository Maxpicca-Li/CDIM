`timescale 1ns/1ps
`include "common.vh"

module dec_crtl(
        input [31:0]				instr,
        input [5:0]					op,
        input [4:0]					rt,
        input [4:0]					rd,
        input [5:0]					funct,
        input						is_branch,
        input						is_branch_link,

        output logic				undefined_inst, // 1 as received a unknown operation.
        output logic [5:0]	 		alu_op, // ALU operation
        output logic [1:0] 			alu_src, // ALU oprand 2 source(0 as rt, 1 as immed)
        output logic       			alu_imm_src, // ALU immediate src - 1 as unsigned, 0 as signed.
        output logic [1:0] 			mem_type, // Memory operation type -- load or store
        output logic [2:0] 			mem_size, // Memory operation size -- B,H,W,WL,WR
        output logic [4:0] 			wb_reg_dest, // Writeback register address
        output logic       			wb_reg_en, // Writeback is enabled
        // output logic       			unsigned_flag,   seems like is not used at all
        output logic                priv_inst   // Is this instruction a priv inst?

);
    
  



    
endmodule
