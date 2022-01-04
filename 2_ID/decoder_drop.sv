`timescale 1ns/1ps
`include "defines.vh"

// 代码优化的事情，以后再说
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
    // output logic                is_branch,
    output logic                regdst,
    output logic [7:0]	 		aluop, // ALU operation
    output logic       			alusrcA,
    output logic       			alusrcB,
    output logic                branch,
    output logic                bal,
    output logic                jr,
    output logic                jal,
    output logic                jump,
    output logic                mem_en,
    output logic                memWrite,
    output logic                memtoReg,
    output logic                cp0write,
    output logic                hilowrite,
    output logic                regwrite,
    output logic				undefined_inst  // 1 as received a unknown operation.
);

    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shamt = instr[10:6];
    assign funct = instr[5:0];
    assign imm = instr[15:0];
    assign j_target = instr[25:0];
    
    // signsD = {[21:14]]ALUOP,13mem_en,12cp0write,11hilowrite,10bal,9jr,8jal,7alusrcA,6regwrite,5regdst,4alusrcB,3branch,2memWrite,1memtoReg,0jump}
    reg [21:0]signsD;
    assign aluop     = signsD[21:14];
    assign mem_en    = signsD[13];
    assign cp0write  = signsD[12];
    assign hilowrite = signsD[11];
    assign bal       = signsD[10];
    assign jr        = signsD[ 9];
    assign jal       = signsD[ 8];
    assign alusrcA   = signsD[ 7];
    assign regwrite  = signsD[ 6];
    assign regdst    = signsD[ 5];
    assign alusrcB   = signsD[ 4];
    assign branch    = signsD[ 3];
    assign memWrite  = signsD[ 2];
    assign memtoReg  = signsD[ 1];
    assign jump      = signsD[ 0];    

    /* TODO: branch type optimize 
    //judge if the instr is branch/jump
    always_comb begin
        //BEQ,BGTZ,BLEZ,BNE
        if (op[5:2] == 4'b0001) begin
            is_branch = 1'b1;
            branch_type = `B_EQNE;
        end
        // BLTZ, BGEZ, BLTZL, BGEZL
        else if(op == 6'b000001 && rt[3:1] == 3'b000) begin
            is_branch = 1'b1;
            branch_type = `B_LTGE;
        // J, JAL
        end
        else if(op[5:1] == 5'b00001) begin
            is_branch = 1'b1;
            branch_type = `B_JUMP;
        //  JR, JALR
        end
        else if(op == 6'b000000 && funct[5:1] == 5'b00100) begin
            is_branch = 1'b1;
            branch_type = `B_JREG;
        end
        else begin
            is_branch = 1'b0;
            branch_type = `B_INVA;
        end
    end
    */

    //generate control logic signals
    always @(*) begin
        undefined_inst = 1'b0;
        signsD = {`ALUOP_NOP,14'b00000000000000};
        case(op)
            `OP_R_TYPE:
                case (funct)
                    // logic
                    `FUN_AND   : signsD = {`ALUOP_AND  ,14'b00000001100000};    //and
                    `FUN_OR    : signsD = {`ALUOP_OR   ,14'b00000001100000};    //or
                    `FUN_XOR   : signsD = {`ALUOP_XOR  ,14'b00000001100000};   //xor
                    `FUN_NOR   : signsD = {`ALUOP_NOR  ,14'b00000001100000};   //nor
                    // arith
                    `FUN_SLT   : signsD = {`ALUOP_SLT  ,14'b00000001100000};   //slt
                    `FUN_SLTU  : signsD = {`ALUOP_SLTU ,14'b00000001100000};   //sltu
                    `FUN_ADD   : signsD = {`ALUOP_ADD  ,14'b00000001100000};   //add
                    `FUN_ADDU  : signsD = {`ALUOP_ADDU ,14'b00000001100000};   //addu
                    `FUN_SUB   : signsD = {`ALUOP_SUB  ,14'b00000001100000};   //sub
                    `FUN_SUBU  : signsD = {`ALUOP_SUBU ,14'b00000001100000};   //subu
                    `FUN_MULT  : signsD = {`ALUOP_MULT ,14'b00100001100000};   //mult
                    `FUN_MULTU : signsD = {`ALUOP_MULTU,14'b00100001100000};  //multu
                    `FUN_DIV   : signsD = {`ALUOP_DIV  ,14'b00100001100000};   //div
                    `FUN_DIVU  : signsD = {`ALUOP_DIVU ,14'b00100001100000};   //divu
                    // shift
                    `FUN_SLL   : signsD = {`ALUOP_SLL  ,14'b00000011100000} ;
                    `FUN_SLLV  : signsD = {`ALUOP_SLLV ,14'b00000001100000} ;
                    `FUN_SRL   : signsD = {`ALUOP_SRL  ,14'b00000011100000} ;
                    `FUN_SRLV  : signsD = {`ALUOP_SRLV ,14'b00000001100000} ;
                    `FUN_SRA   : signsD = {`ALUOP_SRA  ,14'b00000011100000} ;
                    `FUN_SRAV  : signsD = {`ALUOP_SRAV ,14'b00000001100000} ;
                    // move
                    `FUN_MFHI  : signsD = {`ALUOP_MFHI ,14'b00000001100000};
                    `FUN_MFLO  : signsD = {`ALUOP_MFLO ,14'b00000001100000};
                    `FUN_MTHI  : signsD = {`ALUOP_MTHI ,14'b00100000000000};
                    `FUN_MTLO  : signsD = {`ALUOP_MTLO ,14'b00100000000000};
                    // jump R
                    `FUN_JR    : signsD = {`ALUOP_NOP  ,14'b00001000000001};
                    `FUN_JALR  : signsD = {`ALUOP_NOP  ,14'b00001001100000};
                    // 内陷指令
                    `FUN_SYSCALL:signsD = {`ALUOP_NOP  ,14'b00000000000000};
                    `FUN_BREAK  :signsD = {`ALUOP_NOP  ,14'b00000000000000};
                    default: begin 
                        signsD = 14'b00000001100000;
                        undefined_inst = 1'b1;
                    end
                endcase
            // lsmen
            `OP_LB    : signsD = {`ALUOP_ADDU ,14'b10000001010010};
            `OP_LBU   : signsD = {`ALUOP_ADDU ,14'b10000001010010};
            `OP_LH    : signsD = {`ALUOP_ADDU ,14'b10000001010010};
            `OP_LHU   : signsD = {`ALUOP_ADDU ,14'b10000001010010};
            `OP_LW    : signsD = {`ALUOP_ADDU ,14'b10000001010010}; // lw
            `OP_SB    : signsD = {`ALUOP_ADDU ,14'b10000000010110};
            `OP_SH    : signsD = {`ALUOP_ADDU ,14'b10000000010110};
            `OP_SW    : signsD = {`ALUOP_ADDU ,14'b10000000010110}; // sw
            // arith imme
            `OP_ADDI  : signsD = {`ALUOP_ADD  ,14'b00000001010000}; // addi
            `OP_ADDIU : signsD = {`ALUOP_ADDU ,14'b00000001010000}; // addiu
            `OP_SLTI  : signsD = {`ALUOP_SLT  ,14'b00000001010000};// slti
            `OP_SLTIU : signsD = {`ALUOP_SLTU ,14'b00000001010000}; // sltiu
            // logic imme
            `OP_ANDI  : signsD = {`ALUOP_AND  ,14'b00000001010000}; // andi
            `OP_ORI   : signsD = {`ALUOP_OR   ,14'b00000001010000}; // ori
            `OP_XORI  : signsD = {`ALUOP_XOR  ,14'b00000001010000}; // xori
            `OP_LUI   : signsD = {`ALUOP_LUI  ,14'b00000001010000}; // lui            
            // branch
            `OP_BEQ   : signsD = {`ALUOP_NOP  ,14'b00000000001000}; // BEQ
            `OP_BNE   : signsD = {`ALUOP_NOP  ,14'b00000000001000}; // BNE
            `OP_BGTZ  : signsD = {`ALUOP_NOP  ,14'b00000000001000}; // BGTZ
            `OP_BLEZ  : signsD = {`ALUOP_NOP  ,14'b00000000001000}; // BLEZ  
            `OP_SPEC_B:     // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    `RT_BGEZ : signsD  = {`ALUOP_NOP  ,14'b00000000001000};
                    `RT_BLTZ : signsD  = {`ALUOP_NOP  ,14'b00000000001000};
                    `RT_BGEZAL: signsD = {`ALUOP_NOP  ,14'b00010001001000};
                    `RT_BLTZAL: signsD = {`ALUOP_NOP  ,14'b00010001001000};
                    default: begin
                        undefined_inst = 1'b1;
                        signsD = {`ALUOP_NOP  ,14'b00000000000000};
                    end
                endcase
            // jump
            `OP_J     : signsD = {`ALUOP_NOP  ,14'b00000000000001}; // J     
            `OP_JAL   : signsD = {`ALUOP_NOP  ,14'b00000101000000}; 
            // special
            `OP_SPECIAL_INST:
                case (rs)
                    `RS_MFC0: signsD = {`ALUOP_MFC0 ,14'b00000001000000};
                    `RS_MTC0: signsD = {`ALUOP_MTC0 ,14'b01000000000000};
                    default : signsD = {`ALUOP_NOP  ,14'b00000000000000};
                endcase
            default: begin
                undefined_inst = 1'b1;
                signsD = {`ALUOP_NOP  ,14'b00000000000000};
            end
        endcase
    end

endmodule