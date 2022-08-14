`ifndef DEF_COMMON
`define DEF_COMMON

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
//data RAM
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 64
`define DataMemNumLog2 17
`define ByteWidth 7:0
`define RegBus 			31:0
`define EXCEPT_BUS      8:0
// `define RegWidth		32
// `define DoubleRegWidth	64
// `define DoubleRegBus	63:0
// `define RegNum			32
// `define RegNumLog2		5
// `define NOPRegAddr		5'b00000

// # op
// ## special op
`define EXE_NOP			6'b000000
`define OP_SPECIAL_INST 6'b000000
    //logic inst
`define FUN_AND 		6'b100100
`define FUN_OR 			6'b100101
`define FUN_XOR 		6'b100110
`define FUN_NOR			6'b100111
    //shift inst
`define FUN_SLL			6'b000000
`define FUN_SLLV		6'b000100
`define FUN_SRL 		6'b000010
`define FUN_SRLV 		6'b000110
`define FUN_SRA 		6'b000011
`define FUN_SRAV 		6'b000111
    //rotate inst
`define FUN_ROTR        6'b000010
`define FUN_ROTRV       6'b000110
    //move inst
`define FUN_MFHI  		6'b010000
`define FUN_MTHI  		6'b010001
`define FUN_MFLO  		6'b010010
`define FUN_MTLO  		6'b010011
    //arithmetic inst
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
    //jump
`define FUN_JR          6'b001000
`define FUN_JALR        6'b001001
    //内陷指令
`define FUN_SYSCALL     6'b001100
`define FUN_BREAK       6'b001101
    // trap compare
`define FUN_TEQ         6'b110100
`define FUN_TNE         6'b110110
`define FUN_TGE         6'b110000
`define FUN_TGEU        6'b110001
`define FUN_TLT         6'b110010
`define FUN_TLTU        6'b110011
    //同步指令
`define FUN_SYNC        6'b001111
    // move
`define FUN_MOVN        6'b001011
`define FUN_MOVZ        6'b001010

// ## special2 op
`define OP_SPECIAL2_INST 6'b011100
    //special2 inst
`define FUN_MUL         6'b000010
`define FUN_CLO         6'b100001
`define FUN_CLZ         6'b100000
`define FUN_MADD        6'b000000
`define FUN_MADDU       6'b000001
`define FUN_MSUB        6'b000100
`define FUN_MSUBU       6'b000101

// COP0 CO FUNCT
`define FUN_TLBR        6'b000001
`define FUN_TLBWI       6'b000010
`define FUN_TLBWR       6'b000110
`define FUN_TLBP        6'b001000
`define FUN_ERET        6'b011000
`define FUN_WAIT        6'b100000

// ## branch op
`define OP_BEQ          6'b000100
`define OP_BNE          6'b000101
`define OP_BGTZ         6'b000111   //大于
`define OP_BLEZ         6'b000110
`define OP_J            6'b000010
`define OP_JAL          6'b000011
`define OP_JR           6'b000000
`define OP_JALR         6'b000000

// ## load/store op
`define OP_LB           6'b100000
`define OP_LBU          6'b100100
`define OP_LH           6'b100001
`define OP_LHU          6'b100101
`define OP_LW           6'b100011
`define OP_SB           6'b101000
`define OP_SH           6'b101001
`define OP_SW           6'b101011

// ## REGIMM
`define OP_REGIMM       6'b000001
    //rt
`define RT_BLTZ         5'b00000
`define RT_BGEZ         5'b00001
`define RT_BLTZAL       5'b10000
`define RT_BGEZAL       5'b10001
`define RT_TEQI         5'b01100
`define RT_TNEI         5'b01110
`define RT_TGEI         5'b01000
`define RT_TGEIU        5'b01001
`define RT_TLTI         5'b01010
`define RT_TLTIU        5'b01011

// ## other op
`define OP_ANDI		    6'b001100
`define OP_ORI			6'b001101
`define OP_XORI		    6'b001110
`define OP_LUI			6'b001111
`define OP_ADDI         6'b001000
`define OP_ADDIU        6'b001001
`define OP_SLTI         6'b001010
`define OP_SLTIU        6'b001011   
`define OP_COP0_INST    6'b010000
`define OP_LWR          6'b100110
`define OP_SC           6'b111000
`define OP_SWL          6'b101010
`define OP_SWR          6'b101110
`define OP_LL           6'b110000
`define OP_LWL          6'b100010
`define OP_CACHE        6'b101111
`define OP_PREF         6'b110011

// # ALU OP
// ## special1
`define ALUOP_AND       8'b00100100
`define ALUOP_OR        8'b00100101
`define ALUOP_XOR  	    8'b00100110
`define ALUOP_NOR  	    8'b00100111
`define ALUOP_ANDI      8'b01011001
`define ALUOP_ORI  	    8'b01011010
`define ALUOP_XORI      8'b01011011
`define ALUOP_LUI  	    8'b01011100   
`define ALUOP_SLL  	    8'b01111100
`define ALUOP_SLLV      8'b00000100
`define ALUOP_SRL  	    8'b00000010
`define ALUOP_SRLV      8'b00000110
`define ALUOP_SRA  	    8'b00000011
`define ALUOP_SRAV      8'b00000111
`define ALUOP_MFHI      8'b00010000
`define ALUOP_MTHI      8'b00010001
`define ALUOP_MFLO      8'b00010010
`define ALUOP_MTLO      8'b00010011
`define ALUOP_SLT       8'b00101010
`define ALUOP_SLTU      8'b00101011
`define ALUOP_SLTI      8'b01010111
`define ALUOP_SLTIU     8'b01011000   
`define ALUOP_ADD       8'b00100000
`define ALUOP_ADDU      8'b00100001
`define ALUOP_SUB       8'b00100010
`define ALUOP_SUBU      8'b00100011
`define ALUOP_ADDI      8'b01010101
`define ALUOP_ADDIU     8'b01010110
`define ALUOP_MULT      8'b00011000
`define ALUOP_MULTU     8'b00011001
`define ALUOP_DIV       8'b00011010
`define ALUOP_DIVU      8'b00011011
`define ALUOP_PREF      8'b11110011
`define ALUOP_SC        8'b11111000
`define ALUOP_SYNC      8'b00001111
`define ALUOP_MFC0      8'b01011101
`define ALUOP_ROTR      8'b00000101
`define ALUOP_MOV       8'b00001010 // GPR[rd] <= GPR[rs]
// ## special2
`define ALUOP_TNEI      8'b01001001
`define ALUOP_ERET      8'b01101011
`define ALUOP_CLO       8'b01100001
`define ALUOP_CLZ       8'b01100011
`define ALUOP_MADD      8'b01000000
`define ALUOP_MADDU     8'b01000001
`define ALUOP_MSUB      8'b01100100
`define ALUOP_MSUBU     8'b01100101
// ## default
`define ALUOP_NOP       8'b00000000


// # 特殊指令类型
`define EXE_ERET 32'b01000010000000000000000000011000 // 特权指令
`define RS_MTC0 5'b00100
`define RS_MFC0 5'b00000
`define RS_CO   5'b10000
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
//ALU Sel
`define EXE_RES_LOGIC 3'b001
`define EXE_RES_SHIFT 3'b010
`define EXE_RES_MOVE 3'b011	
`define EXE_RES_ARITHMETIC 3'b100	
`define EXE_RES_MUL 3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE 3'b111	
`define EXE_RES_NOP 3'b000

//CP0
`define CP0_REG_INDEX       5'd0
`define CP0_REG_RANDOM      5'd1
`define CP0_REG_ENTRYLO0    5'd2
`define CP0_REG_ENTRYLO1    5'd3
`define CP0_REG_CONTEXT     5'd4
`define CP0_REG_PAGEMASK    5'd5
`define CP0_REG_WIRED       5'd6
`define CP0_REG_BADVADDR    5'd8
`define CP0_REG_COUNT       5'd9
`define CP0_REG_ENTRYHI     5'd10
`define CP0_REG_COMPARE     5'd11
`define CP0_REG_STATUS      5'd12
`define CP0_REG_CAUSE       5'd13
`define CP0_REG_EPC         5'd14
`define CP0_REG_PRID_EBASE  5'd15   // Note: ebase is optional, so we didn't implement it.
`define CP0_REG_CONFIG      5'd16
`define CP0_REG_TAGLO       5'd28
`define CP0_REG_TAGHI       5'd29
`define CP0_REG_ERREPC      5'd30

// EXCCODE
`define EXC_INT     5'd0    // Interrupt
`define EXC_MOD     5'd1    // TLB modification
`define EXC_TLBL    5'd2    // TLB exception (load or instruction fetch)
`define EXC_TLBS    5'd3    // TLB exception (store)
`define EXC_ADEL    5'd4    // Address error exception (load or instruction fetch)
`define EXC_ADES    5'd5    // Address error exception (store)
`define EXC_SYS     5'd8    // Syscall exception
`define EXC_BP      5'd9    // Breakpoint exception
`define EXC_RI      5'd10   // Reserved instruction exception
`define EXC_CPU     5'd11   // Coprocessor Unusable exception
`define EXC_OV      5'd12   // Arithmetic Overflow exception
`define EXC_TR      5'd13   // Trap exception

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
`define SLT         6'b101010
`define SLTU        6'b101011
`define SLTI        6'b001010
`define SLTIU       6'b001011    
`define ADD         6'b100000
`define ADDU        6'b100001
`define SUB         6'b100010
`define SUBU        6'b100011
`define ADDI        6'b001000
`define ADDIU       6'b001001
`define MULT        6'b011000
`define MULTU       6'b011001
`define DIV         6'b011010
`define DIVU        6'b011011
`define J           6'b000010
`define JAL         6'b000011
`define JALR        6'b001001
`define JR          6'b001000
`define BEQ         6'b000100
`define BGEZ        5'b00001
`define BGEZAL      5'b10001
`define BGTZ        6'b000111
`define BLEZ        6'b000110
`define BLTZ        5'b00000
`define BLTZAL      5'b10000
`define BNE         6'b000101
`define LB          6'b100000
`define LBU         6'b100100
`define LH          6'b100001
`define LHU         6'b100101
`define LW          6'b100011
`define SB          6'b101000
`define SH          6'b101001
`define SW          6'b101011
`define SYSCALL     6'b001100
`define BREAK       6'b001101
`define ERET        5'b10000
`define R_TYPE      6'b000000
`define REGIMM_INST 6'b000001
`define SPECIAL3_INST 6'b010000

//change the SPECIAL2_INST from 6'b011100 to 6'b010000
`define MTC0        5'b00100
`define MFC0        5'b00000

//branch instruction type
`define BT_NOP      4'b0000
`define BT_BEQ      4'b0001
`define BT_BNE      4'b0010
`define BT_BGTZ     4'b0011
`define BT_BLEZ     4'b0100
`define BT_BGEZ_    4'b0101
`define BT_BLTZ_    4'b0110
`define BT_J        4'b1000 
`define BT_JREG     4'b1001

// trap instrunction type
`define TT_NOP      4'b0000
`define TT_TEQ      4'b0001
`define TT_TNE      4'b0010
`define TT_TGE      4'b0011
`define TT_TGEU     4'b0100
`define TT_TLT      4'b0101
`define TT_TLTU     4'b0110

// condition move type
`define CmovBus     1:0
`define C_MOVNOP    2'b00
`define C_MOVN      2'b01
`define C_MOVZ      2'b10

`define MEM_LOAD    2'b10
`define MEM_STOR    2'b01
`define MEM_NOOP    2'b00
`define SZ_FULL     3'b111
`define SZ_HALF     3'b010
`define SZ_BYTE     3'b000
`define SRC_REG     2'd0
`define SRC_IMM     2'd1
`define SRC_SFT     2'd2
`define SRC_PCA     2'd3
`define SIGN_EXTENDED   1'b0
`define ZERO_EXTENDED   1'b1

typedef struct packed{
    logic [7:0] aluop;
    logic flush_all; // 1: flush all but commit current inst
    logic read_rs; // 1: reg value; 0: shamt / not need read reg
    logic read_rt; // 1: reg value; 0: imm / not need read reg
    logic reg_write;
    logic mem_en;
    logic mem_write_reg;
    logic mem_read;
    logic mem_write;
    logic cp0_read;
    logic cp0_write;
    logic hilo_read;
    logic hilo_write;
    logic may_bring_flush; // instruction which will bring flush
    logic only_one_issue;  // such as
    logic icache_fence;
    logic dcache_fence;
    logic tlb_fence;
    logic mul_en;
    logic div_en;
} ctrl_sign;

typedef struct packed {
    logic           mtc0_en;
    logic           TLBP;
    logic           TLBR;
    logic           TLBWI;
    logic           TLBWR;
    logic [4:0]     reg_addr;
    logic [2:0]     sel_addr;
} cop0_info;

typedef struct packed {
    logic [2:0] blank3;
    logic       CU0;    // cp0 useable
    logic [4:0] blank2;
    logic       BEV;    // bootstrap exception vector
    logic [5:0] blank1;
    logic [7:0] IM;     // Interrupt Mask
    logic [2:0] blank0;
    logic       UM;     // 0: Kernel, 1: User
    logic       R0;
    logic       ERL;    // Error Level
    logic       EXL;    // Exception Level
    logic       IE;     // Interrupt Enable
} cp0_status;

typedef struct packed {
    logic       BD;     // in a branch delay slot
    logic [6:0] blank3;
    logic       IV;     // special interrupt vector
    logic [6:0] blank2;
    logic [7:0] IP;     // interrupt pending
    logic       blank1;
    logic [4:0] exccode;// exception code
    logic [1:0] blank0;
} cp0_cause;

typedef struct packed {
    logic [5:0] F; // for 32 bit PALEN, F is 6 bit.
    logic [19:0]PFN;
    logic [2:0] C;
    logic       D;
    logic       V;
    logic       G;
} cp0_entrylo;

typedef struct packed {
    logic [8:0] ptebase;
    logic [18:0] badvpn2;
    logic [3:0] blank;
} cp0_context;

typedef struct packed {
    logic [18:0]VPN2;
    logic [4:0] blank0;
    logic [7:0] ASID;
} cp0_entryhi;

typedef struct packed {
    logic [7:0] ASID;
    logic       usermode;
} mmu_info;

typedef struct packed {
    logic       int_allowed;
    logic [7:0] IM;
    logic [7:0] IP;
} int_info;

typedef struct packed {
    logic       if_adel;
    logic       if_tlbl;    // 
    logic       if_tlbrf;   // 1: goto tlb refill, 0: goto tlb invalid
    logic       id_ri;
    logic       id_syscall;
    logic       id_break;
    logic       id_eret;
    logic       id_int;     // interrupt
    logic       id_cpu;     // co-processor unuseable
    logic       ex_ov;      // alu overflow
    logic       ex_adel;    // ade load
    logic       ex_ades;    // ade store
    logic       ex_tlbl;    // tlb load
    logic       ex_tlbs;    // tlb store
    logic       ex_tlbm;    // tlb modified
    logic       ex_tlbrf;   // 1: goto tlb refill, 0: goto tlb invalid
    logic       ex_trap;    // trap
} except_bus;

typedef struct packed {
    logic       M;  // 1: Conﬁg1 register is implemented
    logic [2:0] K23;// 0
    logic [2:0] KU; // 0
    logic [8:0] Impl;   // 0
    logic       BE; // 0: Little endian
    logic [1:0] AT; // Architecture Type 1: MIPS32
    logic [2:0] AR; // MIPS32 Architecture revision level. 0: Release 1
    logic [2:0] MT; // MMU Type: 1: Standard TLB
    logic [2:0] blank0;
    logic       VI; // Virtual instruction cache
    logic [2:0] k0; // Kseg0 cacheability and coherency
} cp0_config0;

typedef struct packed {
    logic       M;  // Config2 is present: 0
    logic [5:0] MS; // MMU Size - 1
    logic [2:0] IS; // Icache sets per way
    logic [2:0] IL; // Icache line size
    logic [2:0] IA; // Icache associativity
    logic [2:0] DS; // Dcache sets per way: 0:64, 1:128, 2:256, 3: 512
    logic [2:0] DL; // Dcache line size: 3: 16bytes, 4: 32bytes, 5: 64bytes
    logic [2:0] DA; // Dcache associativity: 1: 2-way 3: 4-way
    logic       C2; // no CP2: 0
    logic       MD; // no MDMX: 0
    logic       PC; // no performance counter: 0
    logic       WR; // no Watch registers: 0
    logic       CA; // no Code compression: 0
    logic       EP; // no EJTAG : 0
    logic       FP; // no FPU: 0
} cp0_config1;

typedef struct packed {
    logic [31:0] count;
    logic shadow;
} cp0_count;

typedef struct packed {
    logic        G;
    logic        V0;
    logic        V1;
    logic        D0;
    logic        D1;
    logic        C0;    // 1 as cacheable
    logic        C1;    // 1 as cacheable
    logic [19:0] PFN0;
    logic [19:0] PFN1;
    logic [18:0] VPN2;
    logic  [7:0] ASID;
} tlb_entry;

typedef struct packed {
    logic       refill;
    logic       invalid;
    logic [31:0]addr;
    logic [31:0]data;
} fifo_entry;

parameter NR_TLB_ENTRY = 8;

typedef struct packed {
    logic p;
    logic [30-$clog2(NR_TLB_ENTRY):0] blank;
    logic [$clog2(NR_TLB_ENTRY)-1:0] index;
} cp0_index;

`endif