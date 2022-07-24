`timescale 1ns/1ps
// `include "defines.vh"

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
    output logic [31:0]         sign_extend_imm_value,
    output logic                is_link_pc8,
    output logic [3:0]          branch_type,
    output logic [3:0]          trap_type,
    output logic [4:0]          reg_waddr,
    output logic [7:0]	 		aluop, // ALU operation
    output logic                flush_all,
    output logic                is_olny_in_master,
    output logic       			alu_sela,
    output logic       			alu_selb,
    output logic                mem_en,
    output logic                memWrite,
    output logic                memRead,
    output logic                memtoReg,
    output logic                cp0write,
    output logic                hilowrite,
    output logic                reg_wen,
    output logic				spec_inst,
    output logic				undefined_inst,  // 1 as received a unknown operation.
    output logic                syscall_inst,
    output logic                break_inst,
    output logic                eret_inst
);

    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shamt = instr[10:6];
    assign funct = instr[5:0];
    assign imm = instr[15:0];
    assign j_target = instr[25:0];
    assign sign_extend_imm_value = (instr[29:28]==2'b11) ? {{16{1'b0}},instr[15:0]}:{{16{instr[15]}},instr[15:0]}; //op[3:2] for logic_imm type

    // signsD = {[22:15]]ALUOP,14memRead,13mem_en,12cp0write,11hilowrite,10bal,9jr,8jal,7alu_sela,6reg_wen,5regdst,4alu_selb,3branch,2memWrite,1memtoReg,0jump}
    ctrl_sign signsD;
    assign aluop = signsD.aluop;
    assign flush_all = signsD.flush_all;
    assign reg_wen = signsD.reg_wen;
    assign alu_sela = signsD.alu_sela;
    assign alu_selb = signsD.alu_selb;
    assign mem_en = signsD.mem_en;
    assign memRead = signsD.memRead;
    assign memWrite = signsD.memWrite;
    assign memtoReg = signsD.memtoReg;
    assign cp0write = signsD.cp0write;
    assign hilowrite = signsD.hilowrite;
    assign is_olny_in_master = signsD.is_olny_in_master;
    assign eret_inst = (instr == 32'b01000010000000000000000000011000);

    always_comb begin : generate_control_signals
        undefined_inst = 1'b0;
        syscall_inst = 1'b0;
        break_inst = 1'b0;
        spec_inst = 1'b0;
        trap_type = `TT_NOP;
        signsD = `CTRL_SIGN_NOP;
        case(op)
            `OP_SPECIAL_INST:begin
                signsD.reg_wen = 1'b1;
                case (funct)
                    // logic
                    `FUN_AND   : begin
                        signsD.aluop = `ALUOP_AND;
                    end
                    `FUN_OR    : begin
                        signsD.aluop = `ALUOP_OR;
                    end
                    `FUN_XOR   : begin
                        signsD.aluop = `ALUOP_XOR;
                    end
                    `FUN_NOR   : begin
                        signsD.aluop = `ALUOP_NOR;
                    end
                    // arith
                    `FUN_SLT   : begin
                        signsD.aluop = `ALUOP_SLT;
                    end
                    `FUN_SLTU  : begin
                        signsD.aluop = `ALUOP_SLTU;
                    end
                    `FUN_ADD   : begin
                        signsD.aluop = `ALUOP_ADD;
                    end
                    `FUN_ADDU  : begin
                        signsD.aluop = `ALUOP_ADDU;
                    end
                    `FUN_SUB   : begin
                        signsD.aluop = `ALUOP_SUB;
                    end
                    `FUN_SUBU  : begin
                        signsD.aluop = `ALUOP_SUBU;
                    end
                    // shift
                    `FUN_SLL   : begin
                        signsD.aluop = `ALUOP_SLL;
                        signsD.alu_sela = 1'b1;
                    end
                    `FUN_SLLV  : begin
                        signsD.aluop = `ALUOP_SLLV;
                    end
                    `FUN_SRL   : begin
                        signsD.aluop = `ALUOP_SRL;
                        signsD.alu_sela = 1'b1;
                    end
                    `FUN_SRLV  : begin
                        signsD.aluop = `ALUOP_SRLV;
                    end
                    `FUN_SRA   : begin
                        signsD.aluop = `ALUOP_SRA;
                        signsD.alu_sela = 1'b1;
                    end
                    `FUN_SRAV  : begin
                        signsD.aluop = `ALUOP_SRAV;
                    end
                    // mul/div ==> hilo access
                    `FUN_MULT  : begin
                        signsD.aluop = `ALUOP_MULT;
                        signsD.hilowrite = 1'b1;
                        signsD.reg_wen = 1'b0;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_MULTU : begin
                        signsD.aluop = `ALUOP_MULTU;
                        signsD.hilowrite = 1'b1;
                        signsD.reg_wen = 1'b0;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_DIV   : begin
                        signsD.aluop = `ALUOP_DIV;
                        signsD.hilowrite = 1'b1;
                        signsD.reg_wen = 1'b0;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_DIVU  : begin
                        signsD.aluop = `ALUOP_DIVU;
                        signsD.hilowrite = 1'b1;
                        signsD.reg_wen = 1'b0;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    // move ==> hilo access
                    `FUN_MFHI  : begin
                        signsD.aluop = `ALUOP_MFHI;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_MFLO  : begin
                        signsD.aluop = `ALUOP_MFLO;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_MTHI  : begin
                        signsD.aluop = `ALUOP_MTHI;
                        signsD.reg_wen = 1'b0;
                        signsD.hilowrite = 1'b1;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    `FUN_MTLO  : begin
                        signsD.aluop = `ALUOP_MTLO;
                        signsD.reg_wen = 1'b0;
                        signsD.hilowrite = 1'b1;
                        signsD.is_olny_in_master = 1'b1;
                    end
                    // jump R
                    `FUN_JR    : begin
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_JALR  : begin // JALR:GPR[rd]=pc+8;
                        signsD.aluop = `ALUOP_NOP;
                    end
                    // 内陷指令
                    `FUN_SYSCALL:begin
                        spec_inst = 1'b1;
                        syscall_inst =1'b1;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_BREAK  :begin
                        break_inst = 1'b1;
                        spec_inst = 1'b1;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_ROTR   :begin
                        signsD.aluop = `ALUOP_ROTR;
                        signsD.alu_sela = 1'b1;
                    end
                    `FUN_ROTRV  :begin
                        signsD.aluop = `ALUOP_ROTR; // 和ROTR同理
                    end
                    `FUN_SYNC   :begin
                        signsD.reg_wen = 1'b0;// NOP ==> don't need to set value
                    end
                    `FUN_TEQ    :begin
                        trap_type = `TT_TEQ;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_TNE    :begin
                        trap_type = `TT_TNE;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_TGE    :begin
                        trap_type = `TT_TGE;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_TGEU   :begin
                        trap_type = `TT_TGEU;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_TLT    :begin
                        trap_type = `TT_TLT;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_TLTU   :begin
                        trap_type = `TT_TLTU;
                        signsD.reg_wen = 1'b0;
                    end
                    `FUN_MOVN: begin
                        signsD.aluop = `ALUOP_MOV;
                    end
                    `FUN_MOVZ: begin
                        signsD.aluop = `ALUOP_MOV;
                    end
                    default: begin 
                        signsD = `CTRL_SIGN_NOP;
                        undefined_inst = 1'b1;
                    end
                endcase
            end
            `OP_SPECIAL2_INST: begin
                signsD.is_olny_in_master = 1'b1; // mul/div ==> hilo access
                case (funct)
                    `FUN_MUL: begin
                        signsD.aluop = `ALUOP_MULT;
                        signsD.reg_wen = 1'b1;
                    end
                    `FUN_CLO: begin
                        signsD.aluop = `ALUOP_CLO;
                        signsD.reg_wen = 1'b1;
                    end
                    `FUN_CLZ: begin
                        signsD.aluop = `ALUOP_CLZ;
                        signsD.reg_wen = 1'b1;
                    end
                    `FUN_MADD:begin
                        signsD.aluop = `ALUOP_MADD;
                        signsD.hilowrite = 1'b1;
                    end
                    `FUN_MADDU:begin
                        signsD.aluop = `ALUOP_MADDU;
                        signsD.hilowrite = 1'b1;
                    end
                    `FUN_MSUB:begin
                        signsD.aluop = `ALUOP_MSUB;
                        signsD.hilowrite = 1'b1;
                    end
                    `FUN_MSUBU:begin
                        signsD.aluop = `ALUOP_MSUBU;
                        signsD.hilowrite = 1'b1;
                    end
                endcase
            end
            // lsmen
            `OP_LB    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memtoReg = 1'b1;
                signsD.memRead = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_LBU   : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memtoReg = 1'b1;
                signsD.memRead = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_LH    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memtoReg = 1'b1;
                signsD.memRead = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_LHU   : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memtoReg = 1'b1;
                signsD.memRead = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_LW    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memtoReg = 1'b1;
                signsD.memRead = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_SB    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memWrite = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_SH    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memWrite = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_SW    : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.memWrite = 1'b1;
                signsD.mem_en = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            // arith imme
            `OP_ADDI  : begin
                signsD.aluop = `ALUOP_ADD;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_ADDIU : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_SLTI  : begin
                signsD.aluop = `ALUOP_SLT;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_SLTIU : begin
                signsD.aluop = `ALUOP_SLTU;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            // logic imme
            `OP_ANDI  : begin
                signsD.aluop = `ALUOP_AND;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_ORI   : begin
                signsD.aluop = `ALUOP_OR;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_XORI  : begin
                signsD.aluop = `ALUOP_XOR;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            `OP_LUI   : begin
                signsD.aluop = `ALUOP_LUI;
                signsD.reg_wen = 1'b1;
                signsD.alu_selb = 1'b1;
            end
            // jump
            `OP_J     : begin
                signsD.aluop = `ALUOP_NOP;
            end
            `OP_JAL   : begin
                signsD.aluop = `ALUOP_NOP;
                signsD.reg_wen = 1'b1;
            end
            // branch
            `OP_BEQ, `OP_BNE, `OP_BGTZ, `OP_BLEZ: begin
                ;// NOP ==> don't need to set value
            end
            `OP_REGIMM: begin     // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    // `RT_BGEZ
                    // `RT_BLTZ
                    `RT_BGEZAL: begin
                        signsD.reg_wen = 1'b1;
                    end
                    `RT_BLTZAL: begin
                        signsD.reg_wen = 1'b1;
                    end
                    `RT_SYNCI: begin
                        signsD.flush_all = 1'b1;
                        signsD.is_olny_in_master = 1'b1;
                    end
                endcase
            end
            // special
            `OP_COP0_INST:begin
                spec_inst = 1'b1;
                case (rs)
                    `RS_MFC0: begin
                        signsD.aluop = `ALUOP_MFC0;
                        signsD.reg_wen = 1'b1;
                    end
                    `RS_MTC0: begin
                        signsD.aluop = `ALUOP_MTC0;
                        signsD.cp0write = 1'b1;
                    end
                endcase
            end
            default: begin
                undefined_inst = 1'b1;
            end
        endcase
    end

    always_comb begin: generate_branch_type
        case(op)
            `OP_SPECIAL_INST : 
                case(funct) 
                    `FUN_JR    : {branch_type,is_link_pc8} = {`BT_JREG, 1'b0};
                    `FUN_JALR  : {branch_type,is_link_pc8} = {`BT_JREG, 1'b1}; // JALR:GPR[rd]=pc+8;
                    default    : {branch_type,is_link_pc8} = {`BT_NOP, 1'b0};
                endcase
            // jump
            `OP_J     : {branch_type, is_link_pc8} = {`BT_J,1'b0}   ; // J     
            `OP_JAL   : {branch_type, is_link_pc8} = {`BT_J,1'b1} ; // JAL:GPR[31]=pc+8;
            // branch
            `OP_BEQ   : {branch_type, is_link_pc8} = {`BT_BEQ,1'b0} ; // BEQ
            `OP_BNE   : {branch_type, is_link_pc8} = {`BT_BNE,1'b0} ; // BNE
            `OP_BGTZ  : {branch_type, is_link_pc8} = {`BT_BGTZ,1'b0}; // BGTZ
            `OP_BLEZ  : {branch_type, is_link_pc8} = {`BT_BLEZ,1'b0}; // BLEZ  
            `OP_REGIMM: begin    // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    `RT_BGEZ  : {branch_type, is_link_pc8} = {`BT_BGEZ_, 1'b0};
                    `RT_BLTZ  : {branch_type, is_link_pc8} = {`BT_BLTZ_, 1'b0};
                    `RT_BGEZAL: {branch_type, is_link_pc8} = {`BT_BGEZ_, 1'b1}; // GPR[31] = PC + 8
                    `RT_BLTZAL: {branch_type, is_link_pc8} = {`BT_BLTZ_, 1'b1}; // GPR[31] = PC + 8
                    default   : {branch_type, is_link_pc8} = {`BT_NOP, 1'b0};
                endcase
            end
            default:{branch_type, is_link_pc8} = {`BT_NOP, 1'b0};
        endcase
    end


    always_comb begin : generate_reg_waddr
        reg_waddr = rd;
        case (op) 
            // load
            `OP_LB    : reg_waddr = rt;
            `OP_LBU   : reg_waddr = rt;
            `OP_LH    : reg_waddr = rt;
            `OP_LHU   : reg_waddr = rt;
            `OP_LW    : reg_waddr = rt;
            // arith imme
            `OP_ADDI  : reg_waddr = rt;
            `OP_ADDIU : reg_waddr = rt;
            `OP_SLTI  : reg_waddr = rt;
            `OP_SLTIU : reg_waddr = rt;
            // logic imme
            `OP_ANDI  : reg_waddr = rt;
            `OP_ORI   : reg_waddr = rt;
            `OP_XORI  : reg_waddr = rt;
            `OP_LUI   : reg_waddr = rt;
            // jump
            `OP_JAL   : reg_waddr = 5'd31;
            `OP_REGIMM: begin    // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    `RT_BGEZAL: reg_waddr = 5'd31;
                    `RT_BLTZAL: reg_waddr = 5'd31;
                    default:reg_waddr = rd;
                endcase
            end
            `OP_COP0_INST:
                if (rs==`RS_MFC0)  // GPR[rt] ← CP0[rd, sel]
                    reg_waddr = rt; 
                else
                    reg_waddr = rd; 
            default:reg_waddr = rd; 
        endcase
    end

endmodule