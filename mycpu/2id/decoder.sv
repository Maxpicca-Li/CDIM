`timescale 1ns/1ps
`include "defines.vh"

// 代码优化的事情，以后再说
module  decoder(
    input [31:0] instr,
    input        c0_useable,
    //per part
    output logic [5 :0]         op,
    output logic [4 :0]         rs,
    output logic [4 :0]         rt,
    output logic [4 :0]         rd,
    output logic [5 :0]         funct,
    output logic [4 :0]         reg_waddr,
    output logic [31:0]         shamt_value,
    output logic [31:0]         sign_extend_imm_value,
    output logic                is_link_pc8,
    output logic [3 :0]         branch_type,
    output logic [3 :0]         trap_type,
    output logic [`CmovBus]     cmov_type,
    // control
    output ctrl_sign            signsD,
    // separate signal
    output logic				undefined_inst,  // 1 as received a unknown operation.
    output logic                syscall_inst,
    output logic                break_inst,
    output logic                eret_inst,
    output logic                id_cpu,
    output cop0_info            cop0_info_out
);

    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign funct = instr[5:0];
    assign shamt_value = {{27{1'b0}},instr[10:6]};
    assign sign_extend_imm_value = (instr[29:28]==2'b11) ? {{16{1'b0}},instr[15:0]}:{{16{instr[15]}},instr[15:0]}; //op[3:2] for logic_imm type ==> andi, xori, lui, ori为无符号拓展，其它为有符号拓展
    
    always_comb begin : generate_control_signals
        undefined_inst = 1'b0;
        syscall_inst = 1'b0;
        break_inst = 1'b0;
        eret_inst = 1'b0;
        id_cpu = 1'b0;
        trap_type = `TT_NOP;
        cmov_type = `C_MOVNOP;
        signsD = '{default: '0};
        cop0_info_out = '{default: '0, reg_addr: rd, sel_addr: instr[2:0]};
        case(op)
            `OP_SPECIAL_INST:begin
                case (funct)
                    // logic
                    `FUN_AND   : begin
                        signsD.aluop = `ALUOP_AND;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_OR    : begin
                        signsD.aluop = `ALUOP_OR;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_XOR   : begin
                        signsD.aluop = `ALUOP_XOR;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_NOR   : begin
                        signsD.aluop = `ALUOP_NOR;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    // arith
                    `FUN_SLT   : begin
                        signsD.aluop = `ALUOP_SLT;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SLTU  : begin
                        signsD.aluop = `ALUOP_SLTU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_ADD   : begin
                        signsD.aluop = `ALUOP_ADD;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_ADDU  : begin
                        signsD.aluop = `ALUOP_ADDU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SUB   : begin
                        signsD.aluop = `ALUOP_SUB;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SUBU  : begin
                        signsD.aluop = `ALUOP_SUBU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    // shift
                    `FUN_SLL   : begin
                        signsD.aluop = `ALUOP_SLL;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SLLV  : begin
                        signsD.aluop = `ALUOP_SLLV;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SRL   : begin
                        // signsD.aluop = instr[21]?`ALUOP_ROTR:`ALUOP_SRL; // ROTR RS1 is different from SRL
                        signsD.aluop = `ALUOP_SRL;                          // no MIPS release 2
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SRLV  : begin
                        // signsD.aluop = instr[6]?`ALUOP_ROTR:`ALUOP_SRLV; // ROTRV sa1 is different from SRLV
                        signsD.aluop = `ALUOP_SRLV;                         // no MIPS release 2
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SRA   : begin
                        signsD.aluop = `ALUOP_SRA;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_SRAV  : begin
                        signsD.aluop = `ALUOP_SRAV;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    // mul/div ==> hilo access
                    `FUN_MULT  : begin
                        signsD.aluop = `ALUOP_MULT;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_MULTU : begin
                        signsD.aluop = `ALUOP_MULTU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_DIV   : begin
                        signsD.aluop = `ALUOP_DIV;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.div_en = 1'b1;
                    end
                    `FUN_DIVU  : begin
                        signsD.aluop = `ALUOP_DIVU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.div_en = 1'b1;
                    end
                    // move ==> hilo access
                    `FUN_MFHI  : begin
                        signsD.aluop = `ALUOP_MFHI;
                        signsD.hilo_read = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_MFLO  : begin
                        signsD.aluop = `ALUOP_MFLO;
                        signsD.hilo_read = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_MTHI  : begin
                        signsD.aluop = `ALUOP_MTHI;
                        signsD.read_rs = 1'b1;
                        signsD.hilo_write = 1'b1;
                    end
                    `FUN_MTLO  : begin
                        signsD.aluop = `ALUOP_MTLO;
                        signsD.read_rs = 1'b1;
                        signsD.hilo_write = 1'b1;
                    end
                    // jump R
                    `FUN_JR    : begin
                        signsD.read_rs = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_JALR  : begin // JALR:GPR[rd]=pc+8;
                        signsD.read_rs = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    // 内陷指令
                    `FUN_SYSCALL:begin
                        syscall_inst =1'b1;
                        signsD.may_bring_flush = 1'b1;
                        signsD.only_one_issue = 1'b1;
                    end
                    `FUN_BREAK  :begin
                        break_inst = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                        signsD.only_one_issue = 1'b1;
                    end
                    `FUN_SYNC   :begin
                        signsD.may_bring_flush = 1'b1; // NOP ==> don't need to set value
                    end
                    `FUN_TEQ    :begin
                        trap_type = `TT_TEQ;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_TNE    :begin
                        trap_type = `TT_TNE;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_TGE    :begin
                        trap_type = `TT_TGE;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_TGEU   :begin
                        trap_type = `TT_TGEU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_TLT    :begin
                        trap_type = `TT_TLT;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_TLTU   :begin
                        trap_type = `TT_TLTU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.may_bring_flush = 1'b1;
                    end
                    `FUN_MOVN: begin
                        cmov_type = `C_MOVN;
                        signsD.aluop = `ALUOP_MOV;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_MOVZ: begin
                        cmov_type = `C_MOVZ;
                        signsD.aluop = `ALUOP_MOV;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    default: begin 
                        undefined_inst = 1'b1;
                    end
                endcase
            end
            `OP_SPECIAL2_INST: begin
                case (funct)
                    `FUN_MUL: begin
                        signsD.aluop = `ALUOP_MULT;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.reg_write = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_CLO: begin
                        signsD.read_rs = 1'b1;
                        signsD.aluop = `ALUOP_CLO;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_CLZ: begin
                        signsD.aluop = `ALUOP_CLZ;
                        signsD.read_rs = 1'b1;
                        signsD.reg_write = 1'b1;
                    end
                    `FUN_MADD:begin
                        signsD.aluop = `ALUOP_MADD;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.hilo_read = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_MADDU:begin
                        signsD.aluop = `ALUOP_MADDU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.hilo_read = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_MSUB:begin
                        signsD.aluop = `ALUOP_MSUB;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.hilo_read = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    `FUN_MSUBU:begin
                        signsD.aluop = `ALUOP_MSUBU;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                        signsD.hilo_write = 1'b1;
                        signsD.hilo_read = 1'b1;
                        signsD.mul_en = 1'b1;
                    end
                    default: begin
                        undefined_inst = 1'b1;
                    end
                endcase
            end
            // lsmen
            `OP_LB    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LBU   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LH    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LHU   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LW    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LL    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LWL   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1; // need initial contents of dest register
            end
            `OP_LWR   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_read = 1'b1; signsD.mem_write_reg = 1'b1;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1; // need initial contents of dest register
            end
            `OP_SB    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
            end
            `OP_SH    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
            end
            `OP_SW    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
            end
            `OP_SWL   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
            end
            `OP_SWR   : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1;
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
            end
            `OP_SC    : begin
                signsD.mem_en = 1'b1;
                signsD.mem_write = 1'b1; 
                signsD.read_rs = 1'b1;       // read rs
                signsD.read_rt = 1'b1;       // read rt
                signsD.reg_write = 1'b1;     // write rt
                signsD.aluop = `ALUOP_SC;    // in E phase, the register wvalue is in ALU path, which will not cause lwstall in D
            end
            // arith imme
            `OP_ADDI  : begin
                signsD.aluop = `ALUOP_ADD;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_ADDIU : begin
                signsD.aluop = `ALUOP_ADDU;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_SLTI  : begin
                signsD.aluop = `ALUOP_SLT;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_SLTIU : begin
                signsD.aluop = `ALUOP_SLTU;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            // logic imme
            `OP_ANDI  : begin
                signsD.aluop = `ALUOP_AND;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_ORI   : begin
                signsD.aluop = `ALUOP_OR;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_XORI  : begin
                signsD.aluop = `ALUOP_XOR;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            `OP_LUI   : begin
                signsD.aluop = `ALUOP_LUI;
                signsD.reg_write = 1'b1;
                signsD.read_rs = 1'b1;
            end
            // jump
            `OP_J     : begin
                signsD.may_bring_flush = 1'b1;
            end
            `OP_JAL   : begin
                signsD.reg_write = 1'b1;
                signsD.may_bring_flush = 1'b1;
            end
            // branch
            `OP_BEQ, `OP_BNE, `OP_BGTZ, `OP_BLEZ: begin
                signsD.read_rs = 1'b1;
                signsD.read_rt = 1'b1;
                signsD.may_bring_flush = 1'b1;// NOP ==> don't need to set value
            end
            `OP_REGIMM: begin     // BGEZ,BLTZ,BGEZAL,BLTZAL
                signsD.may_bring_flush = 1'b1;
                case(rt)
                    `RT_BGEZ: begin
                        signsD.read_rs = 1'b1;
                    end
                    `RT_BLTZ: begin
                        signsD.read_rs = 1'b1;
                    end
                    `RT_BGEZAL: begin
                        signsD.reg_write = 1'b1;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                    end
                    `RT_BLTZAL: begin
                        signsD.reg_write = 1'b1;
                        signsD.read_rs = 1'b1;
                        signsD.read_rt = 1'b1;
                    end
                    `RT_TEQI: begin
                        trap_type = `TT_TEQ;
                        signsD.read_rs = 1'b1;
                    end
                    `RT_TNEI: begin
                        trap_type = `TT_TNE;
                        signsD.read_rs = 1'b1;
                    end
                    `RT_TGEI: begin
                        trap_type = `TT_TGE;
                        signsD.read_rs = 1'b1;
                    end
                    `RT_TGEIU: begin
                        trap_type = `TT_TGEU;
                        signsD.read_rs = 1'b1;
                    end
                    `RT_TLTI: begin
                        trap_type = `TT_TLT;
                        signsD.read_rs = 1'b1;
                    end
                    `RT_TLTIU: begin
                        trap_type = `TT_TLTU;
                        signsD.read_rs = 1'b1;
                    end
                    default: begin
                        undefined_inst = 1'b1;
                    end
                endcase
            end
            // special
            `OP_COP0_INST:begin
                signsD.only_one_issue = 1'b1;
                id_cpu = !c0_useable;
                case (rs)
                    `RS_MFC0: begin
                        signsD.aluop = `ALUOP_MFC0;
                        signsD.reg_write = 1'b1;
                        signsD.cp0_read = 1'b1;
                    end
                    `RS_MTC0: begin
                        signsD.read_rt = 1'b1;
                        signsD.cp0_write = 1'b1; // TODO: delete this signal
                        signsD.tlb_fence = 1'b1;
                        signsD.flush_all = 1'b1;
                        cop0_info_out.mtc0_en = 1'b1;
                    end
                    `RS_CO: begin
                        case(funct)
                            `FUN_TLBR: begin
                                cop0_info_out.TLBR = 1'b1;
                                signsD.only_one_issue = 1'b1;
                            end
                            `FUN_TLBWI: begin
                                cop0_info_out.TLBWI = 1'b1;
                                signsD.only_one_issue = 1'b1;
                                // signsD.flush_all = 1'b1;
                                signsD.tlb_fence = 1'b1;
                            end
                            `FUN_TLBWR: begin
                                cop0_info_out.TLBWR = 1'b1;
                                signsD.only_one_issue = 1'b1;
                                // signsD.flush_all = 1'b1;
                                signsD.tlb_fence = 1'b1;
                            end
                            `FUN_TLBP: begin
                                cop0_info_out.TLBP = 1'b1;
                                signsD.only_one_issue = 1'b1;
                            end
                            `FUN_ERET: begin
                                signsD.only_one_issue = 1'b1;
                                eret_inst = 1'b1;
                            end
                            `FUN_WAIT: begin
                                // wait as nop
                            end
                            default: begin
                                undefined_inst = 1'b1;
                            end
                        endcase
                    end
                    default: begin
                        undefined_inst = 1'b1;
                    end
                endcase
            end
            `OP_CACHE: begin
                signsD.only_one_issue = 1'b1;
                signsD.icache_fence = instr[16] == 1'b0;
                signsD.dcache_fence = instr[16] == 1'b1;
                signsD.read_rs = 1'b1;
                signsD.aluop = `ALUOP_ADD; // base + offset (no mem_en, so put it in alu path)
            end
            `OP_PREF: begin
                // as NOP
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
            `OP_LL    : reg_waddr = rt;
            `OP_LWL   : reg_waddr = rt;
            `OP_LWR   : reg_waddr = rt;
            `OP_SC    : reg_waddr = rt;
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