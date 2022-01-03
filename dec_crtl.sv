`timescale 1ns/1ps
// `include "common.vh"
`include "defines.vh"

module dec_crtl(
        // input [31:0]				instr,    这个好像不用都行
        input [5:0]				op,
        input [4:0]				rs,    // XXX 这里比原来的多加了一个rs
        input [4:0]				rt,
        input [4:0]				rd,
        input [5:0]				funct,
        input					is_branch,
        input					is_branch_link,

        output logic				undefined_inst, // 1 as received a unknown operation.
        output logic [7:0]	 		aluop, // ALU operation
        output logic [1:0] 			alusrc_op, // ALU oprand 2 source(0 as rt, 1 as immed) 1、移位指令2、跳转指令3、rs
        output logic       			alu_imm_sign, // ALU immediate src - 1 as unsigned, 0 as signed.
        output logic [1:0] 			mem_type, // Memory operation type -- load or store
        output logic [2:0] 			mem_size, // Memory operation size -- B,H,W,WL,WR
        output logic [4:0] 			wb_reg_dest, // Writeback register address
        output logic       			wb_reg_en, // Writeback is enabled
        output logic       			unsigned_flag,   // mem 要用上
        output logic                priv_inst   // Is this instruction a priv inst?

    );
    //generate control logic signals
    always_comb begin : generate_control_signals
        //initial
        undefined_inst  = 1'b0;
        aluop           = `ALUOP_ADDU;
        alusrc_op       = 2'd0;
        alu_imm_sign    = 1'd1;
        mem_type        = `MEM_NOOP;
        mem_size        = `SZ_FULL;
        wb_reg_dest     = 5'd0;
        wb_reg_en       = 1'd0;
        unsigned_flag   = 1'd0;
        priv_inst       = 1'b0;

        case(op)
            `OP_R_TYPE:
            case (funct)
                // logic
                `FUN_AND   : //and
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_AND, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_OR    : //or
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_OR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_XOR   : //xor
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_XOR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_NOR   : //nor
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_NOR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                // arith
                `FUN_SLT   : //slt
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SLT, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SLTU  : //sltu
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SLTU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_ADD   : //add
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_ADD, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_ADDU  : //addu
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SUB   : //sub
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SUB, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SUBU  : //subu
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SUBU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_MULT  : //mult
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MULT, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                `FUN_MULTU : //multu
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MULTU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                `FUN_DIV   : //div
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_DIV, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                `FUN_DIVU  : //divu
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_DIVU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                // shift
                `FUN_SLL   :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SLL, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SLLV  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SLL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SRL   :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SRL, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SRLV  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SRL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SRA   :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SRA, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_SRAV  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SRA, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                //     // jump R
                //     `FUN_JR    : signsD <= 14'b00001000000001;
                //     `FUN_JALR  : signsD <= 14'b00001001100000;
                // move
                `FUN_MFHI  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MFHI, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_MFLO  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MFLO, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
                `FUN_MTHI  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MTHI, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                `FUN_MTLO  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_MTLO, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
                // 内陷指令
                `FUN_SYSCALL:
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SYSCALL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    priv_inst = 1'b1;
                `FUN_BREAK  :
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_BREAK, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    priv_inst = 1'b1;
                default: begin
                    undefined_inst = 1'd1;
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                end
            endcase
            // lsmen
            `OP_LB    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_BYTE, rt, 1'b1, `SIGN_EXTENDED};
            `OP_LBU   :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_BYTE, rt, 1'b1, `ZERO_EXTENDED};
            `OP_LH    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_BYTE, rt, 1'b1, `ZERO_EXTENDED};
            `OP_LHU   :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_HALF, rt, 1'b1, `ZERO_EXTENDED};
            `OP_LW    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_SB    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_BYTE, rt, 1'b0, `SIGN_EXTENDED};
            `OP_SH    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_HALF, rt, 1'b0, `SIGN_EXTENDED};
            `OP_SW    :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
            // arith imme
            `OP_ADDI  : // addi
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADD, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_ADDIU : // addiu
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_SLTI  :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_SLT, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_SLTIU :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_SLTU, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            // logic imme
            `OP_ANDI  :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_AND, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_ORI   :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_OR, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
            `OP_XORI  :
                {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                {`ALUOP_XOR, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTEND};
                 `OP_LUI   :
                 {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                 {`ALUOP_LUI, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
                 //     // branch
                 //     `OP_BEQ   : signsD <= 14'b00000000001000; // BEQ
                 //     `OP_BNE   : signsD <= 14'b00000000001000; // BNE
                 //     `OP_BGTZ  : signsD <= 14'b00000000001000; // BGTZ
                 //     `OP_BLEZ  : signsD <= 14'b00000000001000; // BLEZ
                 //     `OP_SPEC_B:     // BGEZ,BLTZ,BGEZAL,BLTZAL
                 //         case(rt)
                 //             `RT_BGEZ : signsD  <= 14'b00000000001000;
                 //             `RT_BLTZ : signsD  <= 14'b00000000001000;
                 //             `RT_BGEZAL: signsD <= 14'b00010001001000;
                 //             `RT_BLTZAL: signsD <= 14'b00010001001000;
                 //             default: invalid <= 1'b1;
                 //         endcase
                 //     // jump
                 //     `OP_J     : signsD <= 14'b00000000000001; // J
                 //     `OP_JAL   : signsD <= 14'b00000101000000;
                 // special
                 `OP_SPECIAL_INST:
                 priv_inst = 1'b1;
             case (rs)
                 `RS_MFC0:
                     {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                     {`ALUOP_MFC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
                 `RS_MTC0:
                     {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                     {`ALUOP_MTC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                 default:
                     undefined_inst = 1'd1;
                 {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                 {`ALUOP_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
             endcase
             default: begin
                 if(is_branch && is_branch_link)
                     {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                     {`ALUOP_OUTA, `SRC_PCA, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, 5'd31, 1'b1, `ZERO_EXTENDED};
                 else begin
                     undefined_inst = ~is_branch;
                     {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                     {`ALUOP_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                 end
             end
         endcase
     end




 endmodule
