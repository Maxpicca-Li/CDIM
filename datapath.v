`timescale 1ns / 1ps
`include "defines.vh"

module datapath (
    input wire clk,
    input wire rst,
    // except 
    // input wire [5:0]ext_int,
    
    // 指令读取
    input wire inst_data_ok,
    input wire inst_data_ok1,
    input wire inst_data_ok2,
    input wire [31:0]inst_rdata1,
    input wire [31:0]inst_rdata2,
    output wire inst_sram_en, 
    output wire [31:0]F_pc, // 取回pc, pc+4的指令

    // 数据读取
    input wire [31:0]data_sram_rdata,
    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0]data_sram_addr,
    output wire [31:0]data_sram_wdata
);

// ====================================== 变量定义区 ======================================
wire clear;
wire en;
assign clear = 1'b0;
assign ena = 1'b1;

// 流水线控制信号
wire        	fifo_empty;
wire        	fifo_almost_empty;
wire        	fifo_full;
wire            E_div_stall;
wire [31:0]     cp0_data;
wire [63:0] 	hilo;
wire            M_except;
wire [31:0]     M_excepttype;
wire        	M_ades;
wire        	M_adel;
wire [31:0] 	M_bad_addr;
wire  	F_ena;
wire  	D_ena;
wire    slave_ena;
wire  	E_ena;
wire  	M_ena;
wire  	W_ena;
wire  	F_flush;
wire  	D_flush;
wire  	E_flush;
wire  	M_flush;
wire  	W_flush;
// 暂时未实现
assign cp0_data = 32'b0;
assign M_excepttype = 32'b0;
assign M_except = (|M_excepttype);

// D
wire [31:0] 	D_master_inst     ,D_slave_inst    ;
wire [31:0] 	D_master_pc       ,D_slave_pc      ;
wire            D_master_is_in_delayslot;
// inst
wire [5:0]  	D_master_op              ,D_slave_op              ;
wire [4:0]  	D_master_shamt           ,D_slave_shamt           ;
wire [5:0]  	D_master_funct           ,D_slave_funct           ;
wire [15:0] 	D_master_imm             ,D_slave_imm             ;
wire [31:0]     D_master_imm_value       ,D_slave_imm_value       ;
wire        	D_master_is_hilo_accessed,D_slave_is_hilo_accessed;
wire        	D_master_spec_inst       ,D_slave_spec_inst       ;
wire        	D_master_undefined_inst  ,D_slave_undefined_inst  ;
// branch
wire [3:0]  	D_master_branch_type     ,D_slave_branch_type     ;
wire        	D_master_is_link_pc8     ,D_slave_is_link_pc8     ;
wire [25:0] 	D_master_j_target        ,D_slave_j_target        ;
// alu
wire [7:0]  	D_master_aluop           ,D_slave_aluop           ;
wire        	D_master_alu_sela        ,D_slave_alu_sela        ;
wire        	D_master_alu_selb        ,D_slave_alu_selb        ;
// reg
wire [4:0]  	D_master_rs              ,D_slave_rs              ;
wire [4:0]  	D_master_rt              ,D_slave_rt              ;
wire [4:0]  	D_master_rd              ,D_slave_rd              ;
wire [31:0]     D_master_rs_data         ,D_slave_rs_data         ;
wire [31:0]     D_master_rt_data         ,D_slave_rt_data         ;
wire [31:0]     D_master_rs_value        ,D_slave_rs_value        ;
wire [31:0]     D_master_rt_value        ,D_slave_rt_value        ;
wire        	D_master_reg_wen         ,D_slave_reg_wen         ;
wire [4:0]  	D_master_reg_waddr       ,D_slave_reg_waddr       ;
// mem
wire        	D_master_mem_en          ,D_slave_mem_en          ;
wire        	D_master_memWrite        ,D_slave_memWrite        ;
wire        	D_master_memtoReg        ,D_slave_memtoReg        ;
// other
wire        	D_master_cp0write        ,D_slave_cp0write        ;
wire        	D_master_hilowrite       ,D_slave_hilowrite       ;

// E
wire [31:0] 	E_master_inst     ,E_slave_inst    ;
wire  	        E_branch_taken;
wire [31:0]     E_pc_branch_target;
wire [ 3:0]     E_master_branch_type;
wire [ 4:0]     E_master_shamt       ;
wire [31:0]     E_master_rs_value    ;
wire [31:0]     E_master_rt_value    ;
wire [31:0]     E_master_imm_value   ;
wire [ 7:0]     E_master_aluop       ;
wire [25:0]     E_master_j_target    ;
wire [31:0]     E_master_pc          ;
wire            E_master_is_link_pc8 ;
wire            E_master_mem_en      ;
wire            E_master_hilowrite   ;
wire [ 5:0]     E_master_op          ;
wire            E_master_memtoReg, E_slave_memtoReg;
wire            E_master_reg_wen     ;
wire [ 4:0]     E_master_reg_waddr   ;
wire [ 4:0]     E_slave_shamt        ;
wire [31:0]     E_slave_rs_value     ;
wire [31:0]     E_slave_rt_value     ;
wire [31:0]     E_slave_imm_value    ;
wire [ 7:0]     E_slave_aluop        ;
wire [31:0]     E_slave_pc           ;
wire            E_slave_reg_wen      ;
wire [ 4:0]     E_slave_reg_waddr    ;
wire            E_slave_is_link_pc8  ;
// alu
wire            E_master_alu_sela,E_slave_alu_sela;
wire            E_master_alu_selb,E_slave_alu_selb;
wire [31:0]     E_master_alu_srca,E_slave_alu_srca;
wire [31:0]     E_master_alu_srcb,E_slave_alu_srcb;
wire [31:0]     E_master_alu_res_a;
wire [31:0]     E_master_alu_res ,E_slave_alu_res;
wire [63:0]     E_master_alu_out64;
wire            E_master_overflow,E_slave_overflow;

// M
wire [31:0] 	M_master_inst     ,M_slave_inst    ;
wire            M_master_hilowrite;
wire            M_master_is_link_pc8;
wire            M_master_mem_en   ;
wire            M_master_memtoReg ,M_slave_memtoReg ;
wire            M_master_cp0write ,M_slave_cp0write ;
wire [ 5:0]     M_master_op       ;
wire [31:0]     M_master_pc       ;
wire [31:0]     M_master_rt_value ;
wire            M_master_reg_wen  ,M_slave_reg_wen  ;
wire [31:0]     M_master_alu_res  ,M_slave_alu_res  ;
wire [63:0]     M_master_alu_out64;
wire [31:0]     M_master_mem_rdata;
wire [ 4:0]     M_master_reg_waddr,M_slave_reg_waddr ;

// W
wire [31:0] 	W_master_inst     ,W_slave_inst    ;
wire            W_master_memtoReg;
wire [31:0]     W_master_pc       ;
wire [31:0]     W_master_mem_rdata;
wire [31:0]     W_master_alu_res  ,W_slave_alu_res  ;
wire            W_master_reg_wen  ,W_slave_reg_wen  ;
wire [ 4:0]     W_master_reg_waddr,W_slave_reg_waddr;
wire [31:0]     W_master_reg_wdata,W_slave_reg_wdata;


// TODO 异常数据从上至下传递
// assign syscallD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001100);
// assign breakD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001101);
// assign eretD = (instrD == 32'b01000010000000000000000000011000);
// assign pc_exceptF = (F_pc[1:0] == 2'b00) ? 1'b0 : 1'b1;

// TODO 冒险处理

hazard u_hazard(
    //ports
    .D_master_rs        		( D_master_rs        		),
    .D_master_rt        		( D_master_rt        		),
    .E_master_memtoReg  		( E_master_memtoReg  		),
    .E_master_reg_waddr 		( E_master_reg_waddr 		),
    .M_master_memtoReg  		( M_master_memtoReg  		),
    .M_master_reg_waddr 		( M_master_reg_waddr 		),
    .E_branch_taken     		( E_branch_taken     		),
    .E_div_stall                ( E_div_stall               ),
    .fifo_full         		    ( fifo_full            		),
    
    .F_ena              		( F_ena              		),
    .D_ena              		( D_ena              		),
    .E_ena              		( E_ena              		),
    .M_ena              		( M_ena              		),
    .W_ena              		( W_ena              		),
    .F_flush            		( F_flush            		),
    .D_flush            		( D_flush            		),
    .E_flush            		( E_flush            		),
    .M_flush            		( M_flush            		),
    .W_flush            		( W_flush            		)
);




// XXX ====================================== Fetch ======================================
// FIXME 注意，这里如果是i_stall导致的F_ena=0，inst_sram_en仍然使能(不太确定这个逻辑)
assign inst_sram_en =  ~rst & F_ena;

pc_reg u_pc_reg(
    //ports
    .clk           		( clk           		),
    .rst           		( rst || F_flush         ),
    .pc_en         		( F_ena         		),
    .inst_data_ok1 		( inst_data_ok1 		),
    .inst_data_ok2 		( inst_data_ok2 		),
    .fifo_full     		( fifo_full     		),
    .branch_taken       ( E_branch_taken        ),
    .branch_addr        ( E_pc_branch_target    ),
    .pc_curr       		( F_pc       		    )
);

inst_fifo u_inst_fifo(
    //ports
    .clk              		( clk              		),
    .rst              		( rst              		),
    .fifo_rst         		( rst || D_flush         ),
    .master_is_branch 		( (|D_master_branch_type)),
    
    .read_en1         		( D_ena         		),
    .read_en2         		( slave_ena         		),
    .read_addres1     		( D_master_pc     		),
    .read_addres2     		( D_slave_pc     		),
    .read_data1       		( D_master_inst       		),
    .read_data2       		( D_slave_inst      		),
    
    .write_en1        		( inst_data_ok && inst_data_ok1        		),
    .write_en2        		( inst_data_ok && inst_data_ok2        		),
    .write_address1   		( F_pc   		),
    .write_address2   		( F_pc + 32'd4   		),
    .write_data1      		( inst_rdata1 ),
    .write_data2      		( inst_rdata2 ),
    
    .master_is_in_delayslot_o(D_master_is_in_delayslot),
    .empty            		( fifo_empty            		),
    .almost_empty     		( fifo_almost_empty     		),
    .full             		( fifo_full             		)
);


// XXX ====================================== Decode ======================================
decoder u_decoder_master(
    //ports
    .instr          		( D_master_inst          		),
    .op             		( D_master_op             		),
    .rs             		( D_master_rs             		),
    .rt             		( D_master_rt             		),
    .rd             		( D_master_rd             		),
    .shamt          		( D_master_shamt          		),
    .funct          		( D_master_funct          		),
    .imm            		( D_master_imm            		),
    .sign_extend_imm_value  ( D_master_imm_value            ),
    .j_target       		( D_master_j_target       		),
    .is_link_pc8    		( D_master_is_link_pc8    		),
    .branch_type    		( D_master_branch_type    		),
    .reg_waddr      		( D_master_reg_waddr      		),
    .aluop          		( D_master_aluop          		),
    .alu_sela       		( D_master_alu_sela       		),
    .alu_selb       		( D_master_alu_selb       		),
    .mem_en         		( D_master_mem_en         		),
    .memWrite       		( D_master_memWrite       		),
    .memtoReg       		( D_master_memtoReg       		),
    .cp0write       		( D_master_cp0write       		),
    .is_hilo_accessed       ( D_master_is_hilo_accessed     ),
    .hilowrite      		( D_master_hilowrite      		),
    .reg_wen        		( D_master_reg_wen        		),
    .spec_inst      		( D_master_spec_inst      		),
    .undefined_inst 		( D_master_undefined_inst 		)
);

decoder u_decoder_slave(
    //ports
    .instr          		( D_slave_inst          		),
    .op             		( D_slave_op             		),
    .rs             		( D_slave_rs             		),
    .rt             		( D_slave_rt             		),
    .rd             		( D_slave_rd             		),
    .shamt          		( D_slave_shamt          		),
    .funct          		( D_slave_funct          		),
    .imm            		( D_slave_imm                   ),
    .sign_extend_imm_value  ( D_slave_imm_value            ),
    .j_target       		( D_slave_j_target       		),
    .is_link_pc8    		( D_slave_is_link_pc8    		),
    .branch_type    		( D_slave_branch_type    		),
    .reg_waddr      		( D_slave_reg_waddr      		),
    .aluop          		( D_slave_aluop          		),
    .alu_sela       		( D_slave_alu_sela       		),
    .alu_selb       		( D_slave_alu_selb       		),
    .mem_en         		( D_slave_mem_en         		),
    .memWrite       		( D_slave_memWrite       		),
    .memtoReg       		( D_slave_memtoReg       		),
    .cp0write       		( D_slave_cp0write       		),
    .is_hilo_accessed       ( D_slave_is_hilo_accessed      ),
    .hilowrite      		( D_slave_hilowrite      		),
    .reg_wen        		( D_slave_reg_wen        		),
    .spec_inst      		( D_slave_spec_inst      		),
    .undefined_inst 		( D_slave_undefined_inst 		)
);


regfile u_regfile(
    //ports
    .clk   		( clk   		),
    .rst   		( rst   		),
    
    .ra1_a 		( D_master_rs 		),
    .rd1_a 		( D_master_rs_data ),
    .ra1_b 		( D_master_rt 		),
    .rd1_b 		( D_master_rt_data 		),
    .wen1  		( W_master_reg_wen  		),
    .wa1   		( W_master_reg_waddr ),
    .wd1   		( W_master_reg_wdata ),
    
    .ra2_a 		( D_slave_rs 		),
    .rd2_a 		( D_slave_rs_data 		),
    .ra2_b 		( D_slave_rt 		),
    .rd2_b 		( D_slave_rt_data 		),
    .wen2  		( W_slave_reg_wen  		),
    .wa2   		( W_slave_reg_waddr   		),
    .wd2   		( W_slave_reg_wdata   		)
);

// 只前推计算结果，lw stall解决
forward_top u_forward_top(
    //ports
    .E_slave_reg_wen    		( E_slave_reg_wen & (!E_slave_memtoReg)    		),
    .E_slave_reg_waddr  		( E_slave_reg_waddr  		),
    .E_slave_reg_wdata  		( E_slave_alu_res  		),
    .E_master_reg_wen   		( E_master_reg_wen & (!E_master_memtoReg)   		),
    .E_master_reg_waddr 		( E_master_reg_waddr 		),
    .E_master_reg_wdata 		( E_master_alu_res 		),
    
    .M_slave_reg_wen    		( M_slave_reg_wen & (!M_slave_memtoReg)), // TODO wb优化
    .M_slave_reg_waddr  		( M_slave_reg_waddr  		),
    .M_slave_reg_wdata  		( M_slave_alu_res  		),
    .M_master_reg_wen   		( M_master_reg_wen & (!M_master_memtoReg)), // TODO wb优化
    .M_master_reg_waddr 		( M_master_reg_waddr 		),
    .M_master_reg_wdata 		( M_master_alu_res 		),
    
    .D_master_rs        		( D_master_rs        		),
    .D_master_rs_data   		( D_master_rs_data   		),
    .D_master_rs_value  		( D_master_rs_value  		),
    .D_master_rt        		( D_master_rt        		),
    .D_master_rt_data   		( D_master_rt_data   		),
    .D_master_rt_value  		( D_master_rt_value  		),
    .D_slave_rs         		( D_slave_rs         		),
    .D_slave_rs_data    		( D_slave_rs_data    		),
    .D_slave_rs_value   		( D_slave_rs_value   		),
    .D_slave_rt         		( D_slave_rt         		),
    .D_slave_rt_data    		( D_slave_rt_data    		),
    .D_slave_rt_value   		( D_slave_rt_value   		)
);

issue_ctrl u_issue_ctrl(
    //ports
    .D_master_en        		( D_ena        		),
    .D_master_reg_wen   		( D_master_reg_wen   		),
    .D_master_reg_waddr 		( D_master_reg_waddr 		),
    .E_master_memtoReg  		( E_master_memtoReg  		),
    .E_master_reg_waddr 		( E_master_reg_waddr 		),
    .D_slave_op         		( D_slave_op         		),
    .D_slave_rs         		( D_slave_rs         		),
    .D_slave_rt         		( D_slave_rt         		),
    .D_slave_mem_en     		( D_slave_mem_en     		),
    .D_slave_is_branch  		( (|D_slave_branch_type)  	),
    .D_slave_is_hilo_accessed   ( D_slave_is_hilo_accessed  ),
    .fifo_empty         		( fifo_empty         		),
    .fifo_almost_empty  		( fifo_almost_empty  		),
    .D_slave_en         		( slave_ena         		)
);


// XXX ====================================== Execute ======================================
flopenrc #(32) DFF_E_master_inst        (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_inst        ,E_master_inst        );
flopenrc #(5 ) DFF_E_master_shamt       (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_shamt       ,E_master_shamt       );
flopenrc #(32) DFF_E_master_rs_value    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_rs_value    ,E_master_rs_value    );
flopenrc #(32) DFF_E_master_rt_value    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_rt_value    ,E_master_rt_value    );
flopenrc #(32) DFF_E_master_imm_value   (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_imm_value   ,E_master_imm_value   );
flopenrc #(8 ) DFF_E_master_aluop       (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_aluop       ,E_master_aluop       );
flopenrc #(1 ) DFF_E_master_alu_sela    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_alu_sela    ,E_master_alu_sela    );
flopenrc #(1 ) DFF_E_master_alu_selb    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_alu_selb    ,E_master_alu_selb    );
flopenrc #(26) DFF_E_master_j_target    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_j_target    ,E_master_j_target    );
flopenrc #(32) DFF_E_master_pc          (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_pc          ,E_master_pc          );
flopenrc #(1 ) DFF_E_master_is_link_pc8 (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_is_link_pc8 ,E_master_is_link_pc8 );
flopenrc #(1 ) DFF_E_master_mem_en      (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_mem_en      ,E_master_mem_en      );
flopenrc #(1 ) DFF_E_master_hilowrite   (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_hilowrite   ,E_master_hilowrite   );
flopenrc #(6 ) DFF_E_master_op          (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_op          ,E_master_op          );
flopenrc #(1 ) DFF_E_master_memtoReg    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_memtoReg    ,E_master_memtoReg    );
flopenrc #(1 ) DFF_E_master_reg_wen     (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_reg_wen     ,E_master_reg_wen     );
flopenrc #(5 ) DFF_E_master_reg_waddr   (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_reg_waddr   ,E_master_reg_waddr   );
flopenrc #(4 ) DFF_E_master_branch_type (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_branch_type ,E_master_branch_type );

flopenrc #(32) DFF_E_slave_inst        (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_inst        ,E_slave_inst        );
flopenrc #(5 ) DFF_E_slave_shamt       (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_shamt       ,E_slave_shamt       );
flopenrc #(32) DFF_E_slave_rs_value    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_rs_value    ,E_slave_rs_value    );
flopenrc #(32) DFF_E_slave_rt_value    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_rt_value    ,E_slave_rt_value    );
flopenrc #(32) DFF_E_slave_imm_value   (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_imm_value   ,E_slave_imm_value   );
flopenrc #(8 ) DFF_E_slave_aluop       (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_aluop       ,E_slave_aluop       );
flopenrc #(32) DFF_E_slave_pc          (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_pc          ,E_slave_pc          );
flopenrc #(1 ) DFF_E_slave_reg_wen     (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_reg_wen     ,E_slave_reg_wen     );
flopenrc #(5 ) DFF_E_slave_reg_waddr   (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_reg_waddr   ,E_slave_reg_waddr   );
flopenrc #(1 ) DFF_E_slave_alu_sela    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_alu_sela    ,E_slave_alu_sela    );
flopenrc #(1 ) DFF_E_slave_alu_selb    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_alu_selb    ,E_slave_alu_selb    );
flopenrc #(1 ) DFF_E_slave_is_link_pc8 (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_is_link_pc8 ,E_slave_is_link_pc8 );
flopenrc #(1 ) DFF_E_slave_memtoReg    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_memtoReg    ,E_slave_memtoReg    );



branch_judge u_branch_judge(
    //ports
    .branch_type       		( E_master_branch_type       		),
    .offset         		( {E_master_imm_value[29:0],2'b00}  ),
    .j_target          		( E_master_j_target          		),
    .rs_data           		( E_master_rs_value           		),
    .rt_data           		( E_master_rt_value           		),
    .pc_plus4          		( E_master_pc + 32'd4          		),
    .branch_taken      		( E_branch_taken      		),
    .pc_branch_address 		( E_pc_branch_target 		)
);


// select_alusrc: 所有的pc要加8的，都在alu执行，进行电路复用
// FIXME 还是需要单独列一个加法器来做pc+8
assign E_master_alu_srca =  E_master_alu_sela ? {{27{1'b0}},E_master_shamt} : 
                            E_master_rs_value;
assign E_slave_alu_srca  =  E_slave_alu_sela  ? {{27{1'b0}},E_slave_shamt} : 
                            E_slave_rs_value ;                            
// TODO 提频:为访存指令加base+offset单独设置一个加法器
assign E_master_alu_srcb =  E_master_alu_selb ? E_master_imm_value :
                            E_master_rt_value;
assign E_slave_alu_srcb  =  E_slave_alu_selb  ? E_slave_imm_value :
                            E_slave_rt_value ;

alu_master u_alu_master(
    //ports
    .clk       		( clk       		),
    .rst       		( rst       		),
    .aluop     		( E_master_aluop    ),
    .a         		( E_master_alu_srca ),
    .b         		( E_master_alu_srcb ),
    .cp0_data  		( cp0_data  		),
    .hilo      		( hilo      		),
    .stall_div 		( E_div_stall 		),
    .y         		( E_master_alu_res_a  ),
    .aluout_64 		( E_master_alu_out64),
    .overflow  		( E_master_overflow )
);

alu_slave u_alu_slave(
    //ports
    .aluop     		( E_slave_aluop    ),
    .a         		( E_slave_alu_srca ),
    .b         		( E_slave_alu_srcb ),
    .y         		( E_slave_alu_res  ),
    .overflow  		( E_slave_overflow )
);

assign E_master_alu_res = E_master_is_link_pc8 ? (E_master_pc + 32'd8) : E_master_alu_res_a;

// XXX ====================================== Memory ======================================
flopenrc #(32) DFF_M_master_inst       (clk,rst,M_flush,M_ena,E_master_inst       ,M_master_inst       );
flopenrc #(1 ) DFF_M_master_mem_en     (clk,rst,M_flush,M_ena,E_master_mem_en     ,M_master_mem_en     );
flopenrc #(1 ) DFF_M_master_hilowrite  (clk,rst,M_flush,M_ena,E_master_hilowrite  ,M_master_hilowrite  );
flopenrc #(6 ) DFF_M_master_op         (clk,rst,M_flush,M_ena,E_master_op         ,M_master_op         );
flopenrc #(32) DFF_M_master_rt_value   (clk,rst,M_flush,M_ena,E_master_rt_value   ,M_master_rt_value   );
flopenrc #(32) DFF_M_master_alu_res    (clk,rst,M_flush,M_ena,E_master_alu_res    ,M_master_alu_res    );
flopenrc #(32) DFF_M_master_pc         (clk,rst,M_flush,M_ena,E_master_pc         ,M_master_pc         );
flopenrc #(64) DFF_M_master_alu_out64  (clk,rst,M_flush,M_ena,E_master_alu_out64  ,M_master_alu_out64  );
flopenrc #(1 ) DFF_M_master_memtoReg   (clk,rst,M_flush,M_ena,E_master_memtoReg   ,M_master_memtoReg   );
flopenrc #(1 ) DFF_M_master_reg_wen    (clk,rst,M_flush,M_ena,E_master_reg_wen    ,M_master_reg_wen    );
flopenrc #(5 ) DFF_M_master_reg_waddr  (clk,rst,M_flush,M_ena,E_master_reg_waddr  ,M_master_reg_waddr  );

flopenrc #(32) DFF_M_slave_inst         (clk,rst,M_flush,M_ena,E_slave_inst        ,M_slave_inst        );
flopenrc #(1 ) DFF_M_slave_reg_wen      (clk,rst,M_flush,M_ena,E_slave_reg_wen     ,M_slave_reg_wen     );
flopenrc #(5 ) DFF_M_slave_reg_waddr    (clk,rst,M_flush,M_ena,E_slave_reg_waddr   ,M_slave_reg_waddr   );
flopenrc #(32) DFF_M_slave_alu_res      (clk,rst,M_flush,M_ena,E_slave_alu_res     ,M_slave_alu_res     );
flopenrc #(1 ) DFF_M_slave_memtoReg     (clk,rst,M_flush,M_ena,E_slave_memtoReg    ,M_slave_memtoReg    );

mem_access u_mem_access(
    //ports
    .opM             		( M_master_op           ),
    .mem_en                 ( M_master_mem_en       ),
    .mem_wdata       		( M_master_rt_value     ),
    .mem_addr        		( M_master_alu_res      ),
    .mem_rdata       		( M_master_mem_rdata    ),
    .data_sram_en           ( data_sram_en          ),
    .data_sram_rdata 		( data_sram_rdata 		),
    .data_sram_wen   		( data_sram_wen   		),
    .data_sram_addr 		( data_sram_addr 		),
    .data_sram_wdata 		( data_sram_wdata 		),
    .ades           		( M_ades           		),
    .adel           		( M_adel           		),
    .bad_addr        		( M_bad_addr        	)
);

// hilo到M阶段处理，W阶段写完
hilo_reg u_hilo_reg(
	//ports
	.clk    		( clk    		   ),
	.rst    		( rst    		   ),
    .we     		( M_master_hilowrite & ~M_except & M_ena),
	.hilo_i 		( M_master_alu_out64),
	.hilo   		( hilo   	       )
);


// TODO exception
// exception exp(
//     rst,
//     exceptM,
//     M_adel,
//     M_ades,
//     status_o,
//     cause_o,
//     excepttypeM
// );


// TODO cp0_reg
// cp0_reg CP0(
//     .clk(clk),
// 	.rst(rst),
//     .we_i(cp0writeM & ~M_stall),
// 	.waddr_i(rdM),  // M阶段写入CP0
// 	.raddr_i(rdE),  // E阶段读取CP0，这两步可以避免数据冒险处理
// 	.data_i(sel_rd2M),

// 	.int_i(ext_int),

// 	.excepttype_i(excepttypeM),
// 	.current_inst_addr_i(pc_nowM),
// 	.is_in_delayslot_i(is_in_delayslotM),
// 	.bad_addr_i(bad_addr),

// 	.data_o(cp0_data_oE),
// 	.count_o(count_o),
// 	.compare_o(compare_o),
// 	.status_o(status_o),
// 	.cause_o(cause_o),
// 	.epc_o(epc_o),
// 	.config_o(config_o),
// 	.prid_o(prid_o),
// 	.badvaddr_o(badvaddr),
// 	.timer_int_o(timer_int_o)
// );

// XXX ====================================== WriteBack ======================================
flopenrc #(32) DFF_W_master_inst       (clk,rst,W_flush,W_ena,M_master_inst        ,W_master_inst        );
flopenrc #(32) DFF_W_master_pc         (clk,rst,W_flush,W_ena,M_master_pc          ,W_master_pc          );
flopenrc #(32) DFF_W_master_alu_res    (clk,rst,W_flush,W_ena,M_master_alu_res     ,W_master_alu_res     );
flopenrc #(32) DFF_W_master_mem_rdata  (clk,rst,W_flush,W_ena,M_master_mem_rdata   ,W_master_mem_rdata   );
flopenrc #(1 ) DFF_W_master_reg_wen    (clk,rst,W_flush,W_ena,M_master_reg_wen     ,W_master_reg_wen     );
flopenrc #(1 ) DFF_W_master_memtoReg   (clk,rst,W_flush,W_ena,M_master_memtoReg    ,W_master_memtoReg    );
flopenrc #(5 ) DFF_W_master_reg_waddr  (clk,rst,W_flush,W_ena,M_master_reg_waddr   ,W_master_reg_waddr   );

flopenrc #(32) DFF_W_slave_inst      (clk,rst,W_flush,W_ena,M_slave_inst      ,W_slave_inst      );
flopenrc #(32) DFF_W_slave_alu_res   (clk,rst,W_flush,W_ena,M_slave_alu_res   ,W_slave_alu_res   );
flopenrc #(1 ) DFF_W_slave_reg_wen   (clk,rst,W_flush,W_ena,M_slave_reg_wen   ,W_slave_reg_wen   );
flopenrc #(5 ) DFF_W_slave_reg_waddr (clk,rst,W_flush,W_ena,M_slave_reg_waddr ,W_slave_reg_waddr );

assign W_master_reg_wdata = W_master_memtoReg ? W_master_mem_rdata : W_master_alu_res;
assign W_slave_reg_wdata = W_slave_alu_res;

// ascii
wire [39:0] master_asciiD;
wire [39:0] master_asciiE;
wire [39:0] master_asciiM;
wire [39:0] master_asciiW;
wire [39:0] slave_asciiD ;
wire [39:0] slave_asciiE ;
wire [39:0] slave_asciiM ;
wire [39:0] slave_asciiW ;
instdec u_master_asciiD(D_master_inst,master_asciiD);
instdec u_master_asciiE(E_master_inst,master_asciiE);
instdec u_master_asciiM(M_master_inst,master_asciiM);
instdec u_master_asciiW(W_master_inst,master_asciiW);
instdec u_slave_asciiD (D_slave_inst ,slave_asciiD );
instdec u_slave_asciiE (E_slave_inst ,slave_asciiE );
instdec u_slave_asciiM (M_slave_inst ,slave_asciiM );
instdec u_slave_asciiW (W_slave_inst ,slave_asciiW );


endmodule