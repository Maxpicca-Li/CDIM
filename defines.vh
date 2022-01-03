// 单独封装instr定义
// global macro definition
`define RstEnable 		1'b1
`define RstDisable		1'b0
`define ZeroWord		32'h00000000
`define WriteEnable		1'b1
`define WriteDisable	1'b0
`define ReadEnable		1'b1
`define ReadDisable		1'b0
`define AluOpBus		7:0
`define AluSelBus		2:0
`define InstValid		1'b0
`define InstInvalid		1'b1
`define Stop 			1'b1
`define NoStop 			1'b0
`define InDelaySlot 	1'b1
`define NotInDelaySlot 	1'b0
`define Branch 			1'b1
`define NotBranch 		1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 		1'b1
`define TrapNotAssert 	1'b0
`define True_v			1'b1
`define False_v			1'b0
`define ChipEnable		1'b1
`define ChipDisable		1'b0
`define AHB_IDLE 2'b00
`define AHB_BUSY 2'b01
`define AHB_WAIT_FOR_STALL 2'b11

//specific inst macro definition

`define EXE_NOP			6'b000000
`define OP_R_TYPE       6'b000000
//logic inst
`define FUN_AND 		6'b100100
`define FUN_OR 			6'b100101
`define FUN_XOR 		6'b100110
`define FUN_NOR			6'b100111
`define OP_ANDI		    6'b001100
`define OP_ORI			6'b001101
`define OP_XORI		    6'b001110
`define OP_LUI			6'b001111
//shift inst
`define FUN_SLL			6'b000000
`define FUN_SLLV		6'b000100
`define FUN_SRL 		6'b000010
`define FUN_SRLV 		6'b000110
`define FUN_SRA 		6'b000011
`define FUN_SRAV 		6'b000111

//move inst 数据移动指令
`define FUN_MFHI  		6'b010000
`define FUN_MTHI  		6'b010001
`define FUN_MFLO  		6'b010010
`define FUN_MTLO  		6'b010011

// arithmetic inst
`define FUN_SLT         6'b101010
`define FUN_SLTU        6'b101011
`define FUN_ADD         6'b100000
`define FUN_ADDU        6'b100001
`define FUN_SUB         6'b100010
`define FUN_SUBU        6'b100011
`define FUN_MULT        6'b011000
`define FUN_MULTU       6'b011001
`define FUN_DIV         6'b011010
`define FUN_DIVU        6'b011011

`define OP_ADDI         6'b001000
`define OP_ADDIU        6'b001001
`define OP_SLTI         6'b001010
`define OP_SLTIU        6'b001011   

// 分支跳转指令
`define OP_BEQ          6'b000100
`define OP_BNE          6'b000101

`define OP_BGTZ         6'b000111   //大于
`define OP_BLEZ         6'b000110
`define OP_SPEC_B    6'b000001
`define OP_J            6'b000010
`define OP_JAL          6'b000011
`define OP_JR           6'b000000
`define OP_JALR         6'b000000

`define RT_BLTZ         5'b00000
`define RT_BGEZ         5'b00001
`define RT_BLTZAL       5'b10000
`define RT_BGEZAL       5'b10001

`define FUN_JR          6'b001000
`define FUN_JALR        6'b001001

// load/store inst
`define OP_LB  6'b100000
`define OP_LBU  6'b100100
`define OP_LH  6'b100001
`define OP_LHU  6'b100101
`define OP_LW  6'b100011
`define OP_SB  6'b101000
`define OP_SH  6'b101001
`define OP_SW  6'b101011

// `define EXE_LWR  6'b100110
// `define EXE_SC  6'b111000
// `define EXE_SWL  6'b101010
// `define EXE_SWR  6'b101110
// `define EXE_LL  6'b110000
// `define EXE_LWL  6'b100010

// 内陷指令
`define FUN_SYSCALL 6'b001100
`define FUN_BREAK   6'b001101

// 特权指令
`define EXE_ERET 32'b01000010000000000000000000011000
`define OP_SPECIAL_INST 6'b010000
`define RS_MTC0 5'b00100
`define RS_MFC0 5'b00000
`define EXE_TYPE_INT =  32'h00000001
`define EXC_TYPE_ADEL = 32'h00000004
`define EXC_TYPE_ADES = 32'h00000005
`define EXC_TYPE_SYS =  32'h00000008
`define EXC_TYPE_BP =   32'h00000009
`define EXC_TYPE_RI =   32'h0000000a
`define EXC_TYPE_OV =   32'h0000000c
// `define EXE_TEQ    6'b110100
// `define EXE_TEQI   5'b01100
// `define EXE_TGE    6'b110000
// `define EXE_TGEI   5'b01000
// `define EXE_TGEIU   5'b01001
// `define EXE_TGEU 6'b110001
// `define EXE_TLT 6'b110010
// `define EXE_TLTI 5'b01010
// `define EXE_TLTIU 5'b01011
// `define EXE_TLTU 6'b110011
// `define EXE_TNE 6'b110110
// `define EXE_TNEI 5'b01110


// `define EXE_SYNC		6'b001111
// `define EXE_PREF		6'b110011
// `define EXE_SPECIAL_INST 6'b000000
// `define EXE_REGIMM_INST 6'b000001
// `define EXE_SPECIAL2_INST 6'b011100

//ALU OP
`define ALUOP_AND   	8'b00100100
`define ALUOP_OR    	8'b00100101
`define ALUOP_XOR  	8'b00100110
`define ALUOP_NOR  	8'b00100111
`define ALUOP_ANDI  	8'b01011001
`define ALUOP_ORI  	8'b01011010
`define ALUOP_XORI  	8'b01011011
`define ALUOP_LUI  	8'b01011100   

`define ALUOP_SLL  	8'b01111100
`define ALUOP_SLLV  	8'b00000100
`define ALUOP_SRL  	8'b00000010
`define ALUOP_SRLV  	8'b00000110
`define ALUOP_SRA  	8'b00000011
`define ALUOP_SRAV  	8'b00000111

`define ALUOP_MFHI  8'b00010000
`define ALUOP_MTHI  8'b00010001
`define ALUOP_MFLO  8'b00010010
`define ALUOP_MTLO  8'b00010011

`define ALUOP_SLT  8'b00101010
`define ALUOP_SLTU  8'b00101011
`define ALUOP_SLTI  8'b01010111
`define ALUOP_SLTIU  8'b01011000   
`define ALUOP_ADD  8'b00100000
`define ALUOP_ADDU  8'b00100001
`define ALUOP_SUB  8'b00100010
`define ALUOP_SUBU  8'b00100011
`define ALUOP_ADDI  8'b01010101
`define ALUOP_ADDIU  8'b01010110


`define ALUOP_MULT  8'b00011000
`define ALUOP_MULTU  8'b00011001

`define ALUOP_DIV  8'b00011010
`define ALUOP_DIVU  8'b00011011

`define ALUOP_J  8'b01001111
`define ALUOP_JAL  8'b01010000
`define ALUOP_JALR  8'b00001001
`define ALUOP_JR  8'b00001000
`define ALUOP_BEQ  8'b01010001
`define ALUOP_BGEZ  8'b01000001
`define ALUOP_BGEZAL  8'b01001011
`define ALUOP_BGTZ  8'b01010100
`define ALUOP_BLEZ  8'b01010011
`define ALUOP_BLTZ  8'b01000000
`define ALUOP_BLTZAL  8'b01001010
`define ALUOP_BNE  8'b01010010

`define ALUOP_LB  8'b11100000
`define ALUOP_LBU  8'b11100100
`define ALUOP_LH  8'b11100001
`define ALUOP_LHU  8'b11100101
`define ALUOP_LL  8'b11110000
`define ALUOP_LW  8'b11100011
`define ALUOP_LWL  8'b11100010
`define ALUOP_LWR  8'b11100110
`define ALUOP_PREF  8'b11110011
`define ALUOP_SB  8'b11101000
`define ALUOP_SC  8'b11111000
`define ALUOP_SH  8'b11101001
`define ALUOP_SW  8'b11101011
`define ALUOP_SWL  8'b11101010
`define ALUOP_SWR  8'b11101110
`define ALUOP_SYNC  8'b00001111

`define ALUOP_MFC0 8'b01011101
`define ALUOP_MTC0 8'b01100000

`define ALUOP_SYSCALL 8'b00001100
`define ALUOP_BREAK 8'b00001011
// FAKE ALU OP
`define ALUOP_OUTA    8'd22   // from sirius
`define ALUOP_OUTB    8'd23

`define ALUOP_TEQ 8'b00110100
`define ALUOP_TEQI 8'b01001000
`define ALUOP_TGE 8'b00110000
`define ALUOP_TGEI 8'b01000100
`define ALUOP_TGEIU 8'b01000101
`define ALUOP_TGEU 8'b00110001
`define ALUOP_TLT 8'b00110010
`define ALUOP_TLTI 8'b01000110
`define ALUOP_TLTIU 8'b01000111
`define ALUOP_TLTU 8'b00110011
`define ALUOP_TNE 8'b00110110
`define ALUOP_TNEI 8'b01001001
   
`define ALUOP_ERET 8'b01101011

`define ALUOP_NOP    8'b00000000

//ALU Sel
`define EXE_RES_LOGIC 3'b001
`define EXE_RES_SHIFT 3'b010
`define EXE_RES_MOVE 3'b011	
`define EXE_RES_ARITHMETIC 3'b100	
`define EXE_RES_MUL 3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE 3'b111	

`define EXE_RES_NOP 3'b000

//inst ROM macro definition
// `define InstAddrBus		31:0
// `define InstBus 		31:0
// `define InstMemNum		131071
// `define InstMemNumLog2	17

// //data RAM
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 64
`define DataMemNumLog2 17
`define ByteWidth 7:0

// //regfiles macro definition

// `define RegAddrBus		4:0
`define RegBus 			31:0
// `define RegWidth		32
// `define DoubleRegWidth	64
// `define DoubleRegBus	63:0
// `define RegNum			32
// `define RegNumLog2		5
// `define NOPRegAddr		5'b00000


//CP0
`define CP0_REG_BADVADDR    5'b01000       //只读
`define CP0_REG_COUNT    5'b01001        //可读写
`define CP0_REG_COMPARE    5'b01011      //可读写
`define CP0_REG_STATUS    5'b01100       //可读写
`define CP0_REG_CAUSE    5'b01101        //只读
`define CP0_REG_EPC    5'b01110          //可读写
`define CP0_REG_PRID    5'b01111         //只读
`define CP0_REG_CONFIG    5'b10000       //只读

//div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0


//specific inst macro definition

`define NOP			6'b000000
`define AND 		6'b100100
`define OR 			6'b100101
`define XOR 		6'b100110
`define NOR			6'b100111
`define ANDI		6'b001100
`define ORI			6'b001101
`define XORI		6'b001110
`define LUI			6'b001111

`define SLL			6'b000000
`define SLLV		6'b000100
`define SRL 		6'b000010
`define SRLV 		6'b000110
`define SRA 		6'b000011
`define SRAV 		6'b000111

`define MFHI  		6'b010000
`define MTHI  		6'b010001  
`define MFLO  		6'b010010
`define MTLO  		6'b010011

`define SLT  6'b101010
`define SLTU  6'b101011
`define SLTI  6'b001010
`define SLTIU  6'b001011   
`define ADD  6'b100000
`define ADDU  6'b100001
`define SUB  6'b100010
`define SUBU  6'b100011
`define ADDI  6'b001000
`define ADDIU  6'b001001

`define MULT  6'b011000
`define MULTU  6'b011001
`define DIV  6'b011010
`define DIVU  6'b011011

`define J  6'b000010
`define JAL  6'b000011
`define JALR  6'b001001
`define JR  6'b001000
`define BEQ  6'b000100
`define BGEZ  5'b00001
`define BGEZAL  5'b10001
`define BGTZ  6'b000111
`define BLEZ  6'b000110
`define BLTZ  5'b00000
`define BLTZAL  5'b10000
`define BNE  6'b000101

`define LB  6'b100000
`define LBU  6'b100100
`define LH  6'b100001
`define LHU  6'b100101
`define LW  6'b100011
`define SB  6'b101000
`define SH  6'b101001
`define SW  6'b101011

`define SYSCALL 6'b001100
`define BREAK 6'b001101
   
`define ERET 5'b10000

`define R_TYPE 6'b000000
`define REGIMM_INST 6'b000001
`define SPECIAL3_INST 6'b010000
//change the SPECIAL2_INST from 6'b011100 to 6'b010000
`define MTC0 5'b00100
`define MFC0 5'b00000


//branch 
// JUMP instruction type
`define B_EQNE          3'b000
`define B_LTGE          3'b001
`define B_JUMP          3'b010
`define B_JREG          3'b011
`define B_INVA          3'b111

`define MEM_LOAD        2'b10
`define MEM_STOR        2'b01
`define MEM_NOOP        2'b00

`define SZ_FULL         3'b111
`define SZ_HALF         3'b010
`define SZ_BYTE         3'b000

`define SRC_REG         2'd0
`define SRC_IMM         2'd1
`define SRC_SFT         2'd2
`define SRC_PCA         2'd3

`define SIGN_EXTENDED   1'b0
`define ZERO_EXTENDED   1'b1