`timescale 1ns/1ps
`include "defines.vh"

module  decoder(
    input [31:0] instr,

    //per part
    output logic [5:0]          op,
    output logic [4:0]          rs,
    output logic [4:0]          rt,
    output logic [4:0]          rd,
    output logic [4:0]          shamt,
    output logic [5:0]          funct,
    output logic [15:0]         imm,
    output logic [25:0]         j_target,
    // output logic [2:0]          branch_type,    //only used in branch unit,maybe is not that necessary
    output logic                is_branch_link,    // link ==> $31
    output logic                is_branch,
    output logic                is_hilo_accessed,  //FIXME why care about hilo?

    output logic				undefined_inst, // 1 as received a unknown operation.
    output logic [7:0]	 		aluop, // ALU operation
    output logic [1:0] 			alusrc_op, // ALU oprand 2 source(0 as rt, 1 as immed) 1、移位指令2
    output logic       			alu_imm_sign, // ALU immediate src - 1 as unsigned, 0 as signed.
    output logic [1:0] 			mem_type, // Memory operation type -- load or store
    output logic [2:0] 			mem_size, // Memory operation size -- B,H,W,WL,WR
    output logic [4:0] 			wb_reg_dest, // Writeback register address
    output logic       			wb_reg_en, // Writeback is enabled
    output logic       			unsigned_flag,   // mem 要用上
    output logic                priv_inst   // Is this instruction a priv inst?   
);
    
    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shamt = instr[10:6];
    assign funct = instr[5:0];
    assign imm = instr[15:0];
    assign j_target = instr[25:0];

    //judge if the instr is branch/jump
    always_comb begin
        //BEQ,BGTZ,BLEZ,BNE
        if (op[5:2] == 4'b0001) begin
            is_branch = 1'b1;
            // branch_type = `B_EQNE;

        end
        // BLTZ, BGEZ, BLTZL, BGEZL
        else if(op == 6'b000001 && rt[3:1] == 3'b000) begin
            is_branch = 1'b1;
            // branch_type = `B_LTGE;
        // J, JAL
        end
        else if(op[5:1] == 5'b00001) begin
            is_branch = 1'b1;
            // branch_type = `B_JUMP;
        //  JR, JALR
        end
        else if(op == 6'b000000 && funct[5:1] == 5'b00100) begin
            is_branch = 1'b1;
            // branch_type = `B_JREG;
        end
        else begin
            is_branch = 1'b0;
            // branch_type = `B_INVA;
        end
    end

    always_comb begin
        if(op == `OP_R_TYPE && (instr[5:2] == 4'b0100 || instr[5:2] == 4'b0110)) // 0110 div/mul  0100 MF/MT HI/LO
            is_hilo_accessed = 1'b1;
        else
            is_hilo_accessed = 1'b0;
    end

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
                `FUN_SYSCALL: begin
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_SYSCALL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    priv_inst = 1'b1;
                end
                `FUN_BREAK  : begin
                    {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                    {`ALUOP_BREAK, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    priv_inst = 1'b1;
                end
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
                {`ALUOP_XOR, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
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
            `OP_SPECIAL_INST: begin
                priv_inst = 1'b1;
                case (rs)
                    `RS_MFC0:
                        {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                        {`ALUOP_MFC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
                    `RS_MTC0:
                        {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                        {`ALUOP_MTC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    default : begin
                        undefined_inst = 1'd1;
                        {aluop, alusrc_op, alu_imm_sign, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} =
                        {`ALUOP_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
                    end
                endcase
            end
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