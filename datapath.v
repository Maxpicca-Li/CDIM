`timescale 1ns / 1ps
`include "defines.vh"

module datapath (
    input wire clk,
    input wire rst,
    // except 
    input wire [5:0]ext_int,
    
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
wire [63:0] 	hilo;
wire [31:0]     cp0_data;
wire        	M_ades;
wire        	M_adel;
wire [31:0] 	M_bad_addr;
wire            M_except;
wire [31:0]     M_excepttype;
wire [31:0]     M_except_inst_addr;
wire [31:0]     M_except_in_delayslot;
wire [31:0]     M_pc_except_target;
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
wire[31:0] cp0_count,cp0_compare,cp0_status,cp0_cause,cp0_epc,cp0_config,cp0_prid;
wire[31:0] badvaddr;

assign M_except = (|M_excepttype);

//F
wire            F_master_except_pc                 ;

// D
wire [31:0] 	D_master_inst     ,D_slave_inst    ;
wire [31:0] 	D_master_pc       ,D_slave_pc      ;
wire            D_master_is_in_delayslot ,D_slave_is_in_delayslot ;
// inst
wire [5:0]  	D_master_op              ,D_slave_op              ;
wire [4:0]  	D_master_shamt           ,D_slave_shamt           ;
wire [5:0]  	D_master_funct           ,D_slave_funct           ;
wire [15:0] 	D_master_imm             ,D_slave_imm             ;
wire [31:0]     D_master_imm_value       ,D_slave_imm_value       ;
wire        	D_master_is_hilo_accessed,D_slave_is_hilo_accessed;
wire        	D_master_spec_inst       ,D_slave_spec_inst       ;
wire        	D_master_break_inst      ,D_slave_break_inst      ;
wire        	D_master_syscall_inst    ,D_slave_syscall_inst    ;
wire        	D_master_eret_inst       ,D_slave_undefined_inst  ;
wire            D_master_except_inst                              ;

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
wire            D_master_is_pc_except    ,D_slave_is_pc_except    ;
// E
wire [31:0] 	E_master_inst     ,E_slave_inst    ;
wire  	        E_branch_taken;
wire [31:0]     E_pc_branch_target;
wire [ 3:0]     E_master_branch_type;
wire [ 4:0]     E_master_shamt          ;
wire [31:0]     E_master_rs_value       ;
wire [31:0]     E_master_rt_value       ;
wire [31:0]     E_master_imm_value      ;
wire [ 7:0]     E_master_aluop          ;
wire [25:0]     E_master_j_target       ;
wire [31:0]     E_master_pc             ;  
wire            E_master_is_link_pc8    ;
wire            E_master_mem_en         ;
wire            E_master_hilowrite      ;
wire [ 5:0]     E_master_op             ;  
wire            E_master_memtoReg, E_slave_memtoReg;
wire            E_master_reg_wen        ;
wire [ 4:0]     E_master_reg_waddr      ;
wire [ 4:0]     E_slave_shamt           ;
wire [31:0]     E_slave_rs_value        ;
wire [31:0]     E_slave_rt_value        ;
wire [31:0]     E_slave_imm_value       ;
wire [ 7:0]     E_slave_aluop           ;
wire [31:0]     E_slave_pc              ;
wire            E_slave_reg_wen         ;
wire [ 4:0]     E_slave_reg_waddr       ;
wire            E_slave_is_link_pc8     ;
wire            E_master_is_in_delayslot,E_slave_is_in_delayslot;
wire [ 7:0]     E_master_except, E_slave_except;  // TODO: check the width
wire            E_master_cp0write, E_slave_cp0write ;
wire [ 4:0]     E_master_rd             ;
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
wire [31:0]     M_master_pc       ,M_slave_pc       ;
wire [31:0]     M_master_rt_value ;
wire            M_master_reg_wen  ,M_slave_reg_wen  ;
wire [31:0]     M_master_alu_res  ,M_slave_alu_res  ;
wire [63:0]     M_master_alu_out64;
wire [31:0]     M_master_mem_rdata;
wire [ 4:0]     M_master_reg_waddr,M_slave_reg_waddr ;
wire [ 7:0]     M_master_except, M_slave_except;
wire            M_master_is_in_delayslot, M_slave_is_in_delayslot;
wire [ 4:0]     M_master_rd       ;

// W
wire [31:0] 	W_master_inst     ,W_slave_inst    ;
wire            W_master_memtoReg;
wire [31:0]     W_master_pc       ,W_slave_pc      ;
wire [31:0]     W_master_mem_rdata;
wire [31:0]     W_master_alu_res  ,W_slave_alu_res  ;
wire            W_master_reg_wen  ,W_slave_reg_wen  ;
wire [ 4:0]     W_master_reg_waddr,W_slave_reg_waddr;
wire [31:0]     W_master_reg_wdata,W_slave_reg_wdata;
wire [63:0]     W_master_alu_out64;
wire            W_master_hilowrite;


// TODO 异常数据从上至下传递
// _except = [7pc_exp, 6syscall, 5break, 4eret, 3undefined, 2overflow, 2'b00]
assign D_master_is_pc_except  = (D_master_pc[1:0] == 2'b00) ? 1'b0 : 1'b1;
assign D_slave_is_pc_except  = (D_slave_pc[1:0] == 2'b00) ? 1'b0 : 1'b1;

// 冒险处理
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
    .M_except                   ( M_except                  ),
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
assign inst_sram_en =  F_ena & (~fifo_full);  // fifo_full 不取指

pc_reg u_pc_reg(
    //ports
    .clk           		( clk           		),
    .rst           		( rst                   ),
    .pc_en         		( F_ena | M_except         		), // 异常的优先级最高，必须使能
    .inst_data_ok1 		( inst_data_ok1 		),
    .inst_data_ok2 		( inst_data_ok2 		),
    .fifo_full     		( fifo_full     		), // fifo_full pc不变
    .is_except          ( M_except              ),
    .except_addr        ( M_pc_except_target    ),
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
    .undefined_inst 		( D_master_undefined_inst 		),
    .break_inst             ( D_master_break_inst           ),
    .syscall_inst           ( D_master_syscall_inst         ),
    .eret_inst              ( D_master_eret_inst            )
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
    .undefined_inst 		( D_slave_undefined_inst 		),
    .break_inst             ( D_slave_break_inst            ),
    .syscall_inst           ( D_slave_syscall_inst          ),
    .eret_inst              ( D_slave_eret_inst             )
);



regfile u_regfile(
    //ports
    .clk   		( clk   		),
    .rst   		( rst   		),
    
    .ra1_a 		( D_master_rs 		),
    .rd1_a 		( D_master_rs_data ),
    .ra1_b 		( D_master_rt 		),
    .rd1_b 		( D_master_rt_data 		),
    .wen1  		( W_master_reg_wen & W_ena),
    .wa1   		( W_master_reg_waddr ),
    .wd1   		( W_master_reg_wdata ),
    
    .ra2_a 		( D_slave_rs 		),
    .rd2_a 		( D_slave_rs_data 		),
    .ra2_b 		( D_slave_rt 		),
    .rd2_b 		( D_slave_rt_data 		),
    .wen2  		( W_slave_reg_wen & W_ena ),
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
    .D_master_mem_en            ( D_master_mem_en           ), // FIXME: 主线访存，一定要控制单发吗？如果满足不冲突条件，可以双发否？
    .D_master_reg_waddr 		( D_master_reg_waddr 		),
    .D_master_is_branch		    ( (|D_master_branch_type)   ),
    .D_master_is_spec_inst      ( D_master_spec_inst        ),
    .E_master_memtoReg  		( E_master_memtoReg  		),
    .E_master_reg_waddr 		( E_master_reg_waddr 		),
    .D_slave_op         		( D_slave_op         		),
    .D_slave_rs         		( D_slave_rs         		),
    .D_slave_rt         		( D_slave_rt         		),
    .D_slave_mem_en     		( D_slave_mem_en     		),
    .D_slave_is_branch  		( (|D_slave_branch_type)  	),
    .D_slave_is_hilo_accessed   ( D_slave_is_hilo_accessed  ),
    .D_slave_is_spec_inst       ( D_slave_spec_inst         ),
    .fifo_empty         		( fifo_empty         		),
    .fifo_almost_empty  		( fifo_almost_empty  		),
    
    .D_slave_is_in_delayslot    ( D_slave_is_in_delayslot   ),
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
flopenrc #(5 ) DFF_E_master_rd          (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_rd          ,E_master_rd          );
flopenrc #(4 ) DFF_E_master_branch_type (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_branch_type ,E_master_branch_type );
flopenrc #(8 ) DFF_E_master_except      (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,{D_master_is_pc_except,D_master_syscall_inst,D_master_break_inst,D_master_eret_inst,D_master_undefined_inst,3'b0},E_master_except);
flopenrc #(1 ) DFF_E_master_cp0write    (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_cp0write     ,E_master_cp0write   );
flopenrc #(1 ) DFF_E_master_is_in_delayslot (clk,rst,M_except|(!D_master_is_in_delayslot & E_flush) | (!D_ena & E_ena),E_ena,D_master_is_in_delayslot,E_master_is_in_delayslot);

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
flopenrc #(8 ) DFF_E_slave_except      (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,{D_slave_is_pc_except,D_slave_syscall_inst,D_slave_break_inst,D_slave_eret_inst,D_slave_undefined_inst,3'b0},E_slave_except);
flopenrc #(4 ) DFF_E_slave_cp0write    (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_cp0write    ,E_slave_cp0write    );
flopenrc #(1 ) DFF_E_slave_is_in_delayslot (clk,rst,E_flush || (E_ena & !slave_ena),slave_ena,D_slave_is_in_delayslot,E_slave_is_in_delayslot);

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
// FIXME: 还是需要单独列一个加法器来做pc+8
assign E_master_alu_srca =  E_master_alu_sela ? {{27{1'b0}},E_master_shamt} : 
                            E_master_rs_value;
assign E_slave_alu_srca  =  E_slave_alu_sela  ? {{27{1'b0}},E_slave_shamt} : 
                            E_slave_rs_value ;                            
// TODO: 提频:为访存指令加base+offset单独设置一个加法器
assign E_master_alu_srcb =  E_master_alu_selb ? E_master_imm_value :
                            E_master_rt_value;
assign E_slave_alu_srcb  =  E_slave_alu_selb  ? E_slave_imm_value :
                            E_slave_rt_value ;

alu_master u_alu_master(
    //ports
    .clk       		( clk       		),
    .rst       		( rst | M_except      		),
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
flopenrc #(5 ) DFF_M_master_rd         (clk,rst,M_flush,M_ena,E_master_rd         ,M_master_rd         );
flopenrc #(8 ) DFF_M_master_except     (clk,rst,M_flush,M_ena,{E_master_except[7:3],E_master_overflow,E_master_except[1:0]},M_master_except);
flopenrc #(4 ) DFF_M_master_cp0write    (clk,rst,M_flush,M_ena,E_master_cp0write   ,M_master_cp0write   );
flopenrc #(4 ) DFF_M_master_is_in_delayslot  (clk,rst,M_flush,M_ena,E_master_is_in_delayslot ,M_master_is_in_delayslot);

flopenrc #(32) DFF_M_slave_pc          (clk,rst,M_flush,M_ena,E_slave_pc          ,M_slave_pc          );
flopenrc #(32) DFF_M_slave_inst        (clk,rst,M_flush,M_ena,E_slave_inst        ,M_slave_inst        );
flopenrc #(1 ) DFF_M_slave_reg_wen     (clk,rst,M_flush,M_ena,E_slave_reg_wen     ,M_slave_reg_wen     );
flopenrc #(5 ) DFF_M_slave_reg_waddr   (clk,rst,M_flush,M_ena,E_slave_reg_waddr   ,M_slave_reg_waddr   );
flopenrc #(32) DFF_M_slave_alu_res     (clk,rst,M_flush,M_ena,E_slave_alu_res     ,M_slave_alu_res     );
flopenrc #(1 ) DFF_M_slave_memtoReg    (clk,rst,M_flush,M_ena,E_slave_memtoReg    ,M_slave_memtoReg    );
flopenrc #(8 ) DFF_M_slave_except      (clk,rst,M_flush,M_ena,{E_slave_except[7:3],E_slave_overflow,E_slave_except[1:0]},M_slave_except);
flopenrc #(4 ) DFF_M_slave_cp0write    (clk,rst,M_flush,M_ena,E_slave_cp0write    ,M_slave_cp0write    );
flopenrc #(4 ) DFF_M_slave_is_in_delayslot  (clk,rst,M_flush,M_ena,E_slave_is_in_delayslot ,M_slave_is_in_delayslot);

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
	.clk    		( clk    		),
	.rst    		( rst    		),
	.M_we   		( M_master_hilowrite & M_ena & ~M_except),
    .W_we   		( W_master_hilowrite & W_ena ), // W_flush没有单独因为M_except而置1
	.M_hilo 		( M_master_alu_out64 		),
    .W_hilo 		( W_master_alu_out64 		),
	
	.hilo_o 		( hilo 		)
);

// hilo_reg u_hilo_reg(
// 	//ports
// 	.clk    		( clk    		),
// 	.rst    		( rst    		),
// 	.we     		( M_master_hilowrite & M_ena & ~M_except     		),
// 	.hilo_i 		( M_master_alu_out64 		),
// 	.hilo   		( hilo   		)
// );



// TODO exception
// 辅流水线在M阶段只在无异常的情况下将信号传到下一个阶段
exception u_exp(
    //ports
    .rst            ( rst            ),
    .master_except  ( M_master_except),
    .master_pc      ( M_master_pc    ),
    .slave_except   ( M_slave_except ),
    .slave_pc       ( M_slave_pc     ),
    .adel           ( M_adel         ),
    .ades           ( M_ades         ),
    .cp0_status     ( cp0_status      ),
    .cp0_cause      ( cp0_cause       ),
    .cp0_epc        ( cp0_epc         ),
    .master_is_in_delayslot( M_master_is_in_delayslot),
    .slave_is_in_delayslot ( M_slave_is_in_delayslot ),
    
    .except_inst_addr   ( M_except_inst_addr),
    .except_in_delayslot( M_except_in_delayslot),
    .except_target      ( M_pc_except_target),
    .excepttype         ( M_excepttype   )
 
// M_slave_except 
);


// TODO cp0_reg
// 
cp0_reg u_cp0_reg(
    //ports
    .clk                    ( clk                        ),
    .rst                    ( rst                        ),
    .we_i                   ( M_master_cp0write  & M_ena ),  // 只有master访问cp0_reg,
	// MTCP0 CP0[rd, sel] ← GPR[rt] 
    .waddr_i                ( M_master_rd         ),  // M阶段写入CP0 // TODO: 需要改为wb阶段写寄存器吗？如果不前推访存的rt_value的话 
	// MFCP0 GPR[rt] ← CP0[rd, sel] 写寄存器
    .raddr_i                ( E_master_rd         ),  // E阶段读取CP0，这两步可以避免数据冒险处理 ==> 这个的E_master_reg_waddr默认是rd
	.data_i                 ( M_master_rt_value          ),
	.int_i                  ( ext_int                    ),
	.excepttype_i           ( M_excepttype               ),
	.current_inst_addr_i    ( M_except_inst_addr     ),
	.is_in_delayslot_i      ( M_except_in_delayslot      ),
	.bad_addr_i             ( M_bad_addr                 ),
	.data_o                 ( cp0_data                   ),
	.count_o                ( cp0_count                  ),
	.compare_o              ( cp0_compare                ),
	.status_o               ( cp0_status                 ),
	.cause_o                ( cp0_cause                  ),
	.epc_o                  ( cp0_epc                    ),
	.config_o               ( cp0_config                 ),
	.prid_o                 ( cp0_prid                   ),
	.badvaddr_o             ( badvaddr                   ),
	.timer_int_o            ( cp0_timer_int              )
);

// XXX ====================================== WriteBack ======================================
flopenrc #(32) DFF_W_master_inst       (clk,rst,W_flush,W_ena,M_master_inst        ,W_master_inst        );
flopenrc #(32) DFF_W_master_pc         (clk,rst,W_flush,W_ena,M_master_pc          ,W_master_pc          );
flopenrc #(32) DFF_W_master_alu_res    (clk,rst,W_flush,W_ena,M_master_alu_res     ,W_master_alu_res     );
flopenrc #(32) DFF_W_master_mem_rdata  (clk,rst,W_flush,W_ena,M_master_mem_rdata   ,W_master_mem_rdata   );
flopenrc #(64) DFF_W_master_alu_out64  (clk,rst,W_flush,W_ena,M_master_alu_out64   ,W_master_alu_out64   );
flopenrc #(1 ) DFF_W_master_hilowrite  (clk,rst,W_flush,W_ena,M_master_hilowrite   ,W_master_hilowrite   );
flopenrc #(1 ) DFF_W_master_reg_wen    (clk,rst,W_flush,W_ena,M_master_reg_wen     ,W_master_reg_wen     );
flopenrc #(1 ) DFF_W_master_memtoReg   (clk,rst,W_flush,W_ena,M_master_memtoReg    ,W_master_memtoReg    );
flopenrc #(5 ) DFF_W_master_reg_waddr  (clk,rst,W_flush,W_ena,M_master_reg_waddr   ,W_master_reg_waddr   );

flopenrc #(32) DFF_W_slave_inst      (clk,rst,W_flush,W_ena,M_slave_inst      ,W_slave_inst      );
flopenrc #(32) DFF_W_slave_pc        (clk,rst,W_flush,W_ena,M_slave_pc        ,W_slave_pc        );
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