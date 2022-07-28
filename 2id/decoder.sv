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
    output logic [31:0]         sign_extend_imm_value,
    output logic                is_link_pc8,
    output logic [3:0]          branch_type,
    output logic [4:0]          reg_waddr,
    output logic [7:0]	 		aluop, // ALU operation
    output logic       			alu_sela,
    output logic       			alu_selb,
    output logic                mem_en,
    output logic                memWrite,
    output logic                memRead,
    output logic                memtoReg,
    output logic                cp0write,
    output logic                is_hilo_accessed,
    output logic                hilowrite,
    output logic                is_only_master,
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
    reg [22:0]signsD;
    assign aluop     = signsD[22:15];
    assign memRead   = signsD[14];
    assign mem_en    = signsD[13];
    assign cp0write  = signsD[12];
    assign hilowrite = signsD[11];
    // assign bal       = signsD[10];
    // assign jr        = signsD[ 9];
    // assign jal       = signsD[ 8];
    assign alu_sela  = signsD[ 7];
    assign reg_wen  = signsD[ 6];
    // assign regdst    = signsD[ 5];
    assign alu_selb  = signsD[ 4];
    // assign branch    = signsD[ 3];
    assign memWrite  = signsD[ 2];
    assign memtoReg  = signsD[ 1];
    assign jump      = signsD[ 0];        
    assign eret_inst = (instr == 32'b01000010000000000000000000011000);

    always_comb begin : generate_control_signals
        undefined_inst = 1'b0;
        syscall_inst = 1'b0;
        break_inst = 1'b0;
        spec_inst = 1'b0;
        signsD = {`ALUOP_NOP,15'b000000000000000};
        if (instr==32'b0) begin
            signsD = {`ALUOP_NOP,15'b000000000000000};
        end
        else begin
            case(op)
                `OP_SPECIAL_INST:
                    case (funct)
                        // logic
                        `FUN_AND   : signsD = {`ALUOP_AND  ,15'b000000001100000};    //and
                        `FUN_OR    : signsD = {`ALUOP_OR   ,15'b000000001100000};    //or
                        `FUN_XOR   : signsD = {`ALUOP_XOR  ,15'b000000001100000};   //xor
                        `FUN_NOR   : signsD = {`ALUOP_NOR  ,15'b000000001100000};   //nor
                        // arith
                        `FUN_SLT   : signsD = {`ALUOP_SLT  ,15'b000000001100000};   //slt
                        `FUN_SLTU  : signsD = {`ALUOP_SLTU ,15'b000000001100000};   //sltu
                        `FUN_ADD   : signsD = {`ALUOP_ADD  ,15'b000000001100000};   //add
                        `FUN_ADDU  : signsD = {`ALUOP_ADDU ,15'b000000001100000};   //addu
                        `FUN_SUB   : signsD = {`ALUOP_SUB  ,15'b000000001100000};   //sub
                        `FUN_SUBU  : signsD = {`ALUOP_SUBU ,15'b000000001100000};   //subu
                        `FUN_MULT  : signsD = {`ALUOP_MULT ,15'b000100001100000};   //mult
                        `FUN_MULTU : signsD = {`ALUOP_MULTU,15'b000100001100000};  //multu
                        `FUN_DIV   : signsD = {`ALUOP_DIV  ,15'b000100001100000};   //div
                        `FUN_DIVU  : signsD = {`ALUOP_DIVU ,15'b000100001100000};   //divu
                        // shift
                        `FUN_SLL   : signsD = {`ALUOP_SLL  ,15'b000000011100000} ;
                        `FUN_SLLV  : signsD = {`ALUOP_SLLV ,15'b000000001100000} ;
                        `FUN_SRL   : signsD = {`ALUOP_SRL  ,15'b000000011100000} ;
                        `FUN_SRLV  : signsD = {`ALUOP_SRLV ,15'b000000001100000} ;
                        `FUN_SRA   : signsD = {`ALUOP_SRA  ,15'b000000011100000} ;
                        `FUN_SRAV  : signsD = {`ALUOP_SRAV ,15'b000000001100000} ;
                        // move
                        `FUN_MFHI  : signsD = {`ALUOP_MFHI ,15'b000000001100000};
                        `FUN_MFLO  : signsD = {`ALUOP_MFLO ,15'b000000001100000};
                        `FUN_MTHI  : signsD = {`ALUOP_MTHI ,15'b000100000000000};
                        `FUN_MTLO  : signsD = {`ALUOP_MTLO ,15'b000100000000000};
                        // jump R
                        `FUN_JR    : signsD = {`ALUOP_NOP  ,15'b000001000000001};
                        `FUN_JALR  : signsD = {`ALUOP_NOP  ,15'b000001001100000}; // JALR:GPR[rd]=pc+8;
                        // 内陷指令
                        `FUN_SYSCALL:begin
                            spec_inst = 1'b1;
                            signsD = {`ALUOP_NOP  ,15'b000000000000000};
                            syscall_inst =1'b1;
                        end
                        `FUN_BREAK  :begin
                            break_inst = 1'b1;
                            spec_inst = 1'b1;
                            signsD = {`ALUOP_NOP  ,15'b000000000000000};
                        end
                        default: begin 
                            signsD = {`ALUOP_NOP  ,15'b000000001100000};
                            undefined_inst = 1'b1;
                        end
                    endcase
                `OP_SPECIAL2_INST:
                    case (funct)
                        `FUN_MUL: signsD = {`ALUOP_MULT,15'b000000001100000};
                    endcase
                // lsmen
                `OP_LB    : signsD = {`ALUOP_ADDU ,15'b110000001010010};
                `OP_LBU   : signsD = {`ALUOP_ADDU ,15'b110000001010010};
                `OP_LH    : signsD = {`ALUOP_ADDU ,15'b110000001010010};
                `OP_LHU   : signsD = {`ALUOP_ADDU ,15'b110000001010010};
                `OP_LW    : signsD = {`ALUOP_ADDU ,15'b110000001010010}; // lw
                `OP_SB    : signsD = {`ALUOP_ADDU ,15'b010000000010100};
                `OP_SH    : signsD = {`ALUOP_ADDU ,15'b010000000010100};
                `OP_SW    : signsD = {`ALUOP_ADDU ,15'b010000000010100}; // sw
                // arith imme
                `OP_ADDI  : signsD = {`ALUOP_ADD  ,15'b000000001010000}; // addi
                `OP_ADDIU : signsD = {`ALUOP_ADDU ,15'b000000001010000}; // addiu
                `OP_SLTI  : signsD = {`ALUOP_SLT  ,15'b000000001010000};// slti
                `OP_SLTIU : signsD = {`ALUOP_SLTU ,15'b000000001010000}; // sltiu
                // logic imme
                `OP_ANDI  : signsD = {`ALUOP_AND  ,15'b000000001010000}; // andi
                `OP_ORI   : signsD = {`ALUOP_OR   ,15'b000000001010000}; // ori
                `OP_XORI  : signsD = {`ALUOP_XOR  ,15'b000000001010000}; // xori
                `OP_LUI   : signsD = {`ALUOP_LUI  ,15'b000000001010000}; // lui            
                // jump
                `OP_J     : signsD = {`ALUOP_NOP  ,15'b000000000000001}; // J     
                `OP_JAL   : signsD = {`ALUOP_NOP  ,15'b000000101000000}; // JAL:GPR[31]=pc+8;
                // branch
                `OP_BEQ   : signsD = {`ALUOP_NOP  ,15'b000000000001000}; // BEQ
                `OP_BNE   : signsD = {`ALUOP_NOP  ,15'b000000000001000}; // BNE
                `OP_BGTZ  : signsD = {`ALUOP_NOP  ,15'b000000000001000}; // BGTZ
                `OP_BLEZ  : signsD = {`ALUOP_NOP  ,15'b000000000001000}; // BLEZ  
                `OP_SPEC_B:     // BGEZ,BLTZ,BGEZAL,BLTZAL
                    case(rt)
                        `RT_BGEZ : signsD  = {`ALUOP_NOP  ,15'b000000000001000};
                        `RT_BLTZ : signsD  = {`ALUOP_NOP  ,15'b000000000001000};
                        `RT_BGEZAL: signsD = {`ALUOP_NOP  ,15'b000010001001000}; // GPR[31] = PC + 8
                        `RT_BLTZAL: signsD = {`ALUOP_NOP  ,15'b000010001001000}; // GPR[31] = PC + 8
                        default: begin
                            undefined_inst = 1'b1;
                            signsD = {`ALUOP_NOP  ,15'b000000000000000};
                        end
                    endcase
                // special
                `OP_COP0_INST:begin
                    spec_inst = 1'b1;
                    case (rs)
                        `RS_MFC0: signsD = {`ALUOP_MFC0 ,15'b000000001000000};
                        `RS_MTC0: signsD = {`ALUOP_MTC0 ,15'b001000000000000};
                        default : signsD = {`ALUOP_NOP  ,15'b000000000000000};
                    endcase
                end
                default: begin
                    undefined_inst = 1'b1;
                    signsD = {`ALUOP_NOP  ,15'b000000000000000};
                end
            endcase
        end
    end

    always_comb begin
        if(op == `OP_SPECIAL_INST && (instr[5:2] == 4'b0100 || instr[5:2] == 4'b0110)) // 0110 div/mul  0100 MF/MT HI/LO
            is_hilo_accessed = 1'b1;
        else
            is_hilo_accessed = 1'b0;
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
            `OP_SPEC_B:     // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    `RT_BGEZ  : {branch_type, is_link_pc8} = {`BT_BGEZ_, 1'b0};
                    `RT_BLTZ  : {branch_type, is_link_pc8} = {`BT_BLTZ_, 1'b0};
                    `RT_BGEZAL: {branch_type, is_link_pc8} = {`BT_BGEZ_, 1'b1}; // GPR[31] = PC + 8
                    `RT_BLTZAL: {branch_type, is_link_pc8} = {`BT_BLTZ_, 1'b1}; // GPR[31] = PC + 8
                    default   : {branch_type, is_link_pc8} = {`BT_NOP, 1'b0};
                endcase
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
            `OP_SPEC_B:     // BGEZ,BLTZ,BGEZAL,BLTZAL
                case(rt)
                    `RT_BGEZAL: reg_waddr = 5'd31;
                    `RT_BLTZAL: reg_waddr = 5'd31;
                    default:reg_waddr = rd;
                endcase
            `OP_COP0_INST:
                if (rs==`RS_MFC0)  // GPR[rt] ← CP0[rd, sel]
                    reg_waddr = rt; 
                else
                    reg_waddr = rd; 
            default:reg_waddr = rd; 
        endcase
    end

    always_comb begin : generate_is_only_master
        case(op)
            `OP_SPECIAL2_INST: is_only_master = 1; // TODO: 所有的SPECIAL2_INST都放在master，有例外吗？
            default: is_only_master = 0;
        endcase
    end

endmodule