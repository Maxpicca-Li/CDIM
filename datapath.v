`timescale 1ns / 1ps
`include "defines.vh"

module datapath (
    input wire clk,
    input wire rst,
    
    // except 
    input wire [5:0]ext_int,
    output wire except_logicM,

    // stall 访存控制
    input wire i_stall,
    input wire d_stall,
    output wire longest_stall,
    
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
    output wire [31:0]data_sram_waddr,
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
wire            M_except;
wire            M_stall;
wire [31:0]     M_excepttype;
wire        	M_ades;
wire        	M_adel;
wire [31:0] 	M_bad_addr;


wire [31:0] 	D_master_inst     ,D_slave_inst    ;
wire [11:0] 	D_master_inst_exp ,D_slave_inst_exp;
wire [31:0] 	D_master_pc       ,D_slave_pc      ;

wire            D_master_en              ,D_slave_en              ;
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

wire  	        E_branch_taken;
wire [31:0]     E_pc_branch_target;
wire [ 3:0]     E_master_branch_type;
wire [5 :0]     E_master_shamt       ;
wire [32:0]     E_master_rs_value    ;
wire [32:0]     E_master_rt_value    ;
wire [32:0]     E_master_imm_value   ;
wire [8 :0]     E_master_aluop       ;
wire [26:0]     E_master_j_target    ;
wire [32:0]     E_master_pc          ;
wire            E_master_is_link_pc8 ;
wire            E_master_mem_en      ;
wire            E_master_hilowrite   ;
wire [6 :0]     E_master_op          ;
wire            E_master_memtoReg    ;
wire [5 :0]     E_master_reg_wen     ;
wire [5 :0]     E_master_reg_waddr   ;
wire [5 :0]     E_slave_shamt        ;
wire [32:0]     E_slave_rs_value     ;
wire [32:0]     E_slave_rt_value     ;
wire [32:0]     E_slave_imm_value    ;
wire [8 :0]     E_slave_aluop        ;
wire [32:0]     E_slave_pc           ;
wire            E_slave_reg_wen      ;
wire [5 :0]     E_slave_reg_waddr    ;
wire            E_slave_is_link_pc8  ;

// alu
wire            E_master_alu_sela,E_slave_alu_sela;
wire            E_master_alu_selb,E_slave_alu_selb;
wire [31:0]     E_master_alu_srca,E_slave_alu_srca;
wire [31:0]     E_master_alu_srcb,E_slave_alu_srcb;
wire [31:0]     E_master_alu_res ,E_slave_alu_res;
wire [63:0]     E_master_alu_out64;
wire            E_master_overflow,E_slave_overflow;


wire            M_master_hilowrite;
wire            M_master_mem_en   ;
wire            M_master_cp0write ,M_slave_cp0write ;
wire [ 6:0]     M_master_op       ;
wire [31:0]     M_master_pc       ;
wire [31:0]     M_master_rt_value ;
wire            M_master_reg_wen  ,M_slave_reg_wen  ;
wire [31:0]     M_master_alu_res  ,M_slave_alu_res  ;
wire [31:0]     M_master_alu_out64;
wire [31:0]     M_master_mem_rdata;

wire            W_master_memtoReg;
wire [31:0]     W_master_mem_rdata;
wire [31:0]     W_master_alu_res  ,W_slave_alu_res  ;
wire            W_master_reg_wen  ,W_slave_reg_wen  ;
wire [31:0]     W_master_reg_wdata,W_slave_reg_wdata;

// assign M_except = (|M_excepttype);
// TODO 整个pipeline由冒险模块控制 / pipeline_ctrl 
// D_en_master由pipeline_ctrl生成


// TODO 异常数据从上至下传递
// assign syscallD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001100);
// assign breakD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001101);
// assign eretD = (instrD == 32'b01000010000000000000000000011000);
// assign pc_exceptF = (F_pc[1:0] == 2'b00) ? 1'b0 : 1'b1;
// assign inst_sram_en =  1'b1; // !except_logicM & !pc_exceptF;

// XXX ====================================== Fetch ======================================

pc_reg u_pc_reg(
	//ports
	.clk           		( clk           		),
	.rst           		( rst           		),
	.pc_en         		( pc_en         		),
	.inst_data_ok1 		( inst_data_ok1 		),
	.inst_data_ok2 		( inst_data_ok2 		),
	.fifo_full     		( fifo_full     		),
	.branch_taken       ( E_branch_taken ),
	.pc_branch_addr     ( E_pc_branch_target          ),
	.pc_curr       		( F_pc       		)
);

inst_fifo u_inst_fifo(
	//ports
	.clk              		( clk              		),
	.rst              		( rst              		),
	.fifo_rst         		( 1'b0         		),
	.master_is_branch 		( 1'b0 		),
	
    .read_en1         		( D_master_en         		),
	.read_addres1     		( D_master_pc     		),
    .read_data1       		( D_master_inst       		),
    .inst_exp1        		( D_master_inst_exp        		),
    .read_en2         		( D_slave_en         		),
	.read_addres2     		( D_slave_pc     		),
    .read_data2       		( D_slave_inst      		),
	.inst_exp2        		( D_slave_inst_exp        		),
	
    .write_en1        		( inst_ok && inst_data_ok1        		),
	.write_en2        		( inst_ok && inst_data_ok2        		),
	.write_inst_exp1  		( 12'b0  		),
	.write_address1   		( F_pc   		),
	.write_address2   		( F_pc + 32'd4   		),
	.write_data1      		( inst_rdata1 ),
	.write_data2      		( inst_rdata2 ),
	
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
	.ra2_b 		( D_slave_rs 		),
	.rd2_b 		( D_slave_rs_data 		),
	.wen2  		( W_slave_reg_wen  		),
	.wa2   		( W_slave_reg_waddr   		),
	.wd2   		( W_slave_reg_wdata   		)
);

// FIXME D阶段做前推，会不会让D过于臃肿
forward_top u_forward_top(
	//ports
	.E_slave_reg_wen    		( E_slave_reg_wen    		),
	.E_slave_reg_waddr  		( E_slave_reg_waddr  		),
	.E_slave_reg_wdata  		( E_slave_reg_wdata  		),
	.E_master_reg_wen   		( E_master_reg_wen   		),
	.E_master_reg_waddr 		( E_master_reg_waddr 		),
	.E_master_reg_wdata 		( E_master_reg_wdata 		),
	.M_slave_reg_wen    		( M_slave_reg_wen    		),
	.M_slave_reg_waddr  		( M_slave_reg_waddr  		),
	.M_slave_reg_wdata  		( M_slave_reg_wdata  		),
	.M_master_reg_wen   		( M_master_reg_wen   		),
	.M_master_reg_waddr 		( M_master_reg_waddr 		),
	.M_master_reg_wdata 		( M_master_reg_wdata 		),
	
	.D_master_rs        		( D_master_rs        		),
	.D_master_rs_dara   		( D_master_rs_dara   		),
	.D_master_rs_value  		( D_master_rs_value  		),
	.D_master_rd        		( D_master_rd        		),
	.D_master_rd_dara   		( D_master_rd_dara   		),
	.D_master_rd_value  		( D_master_rd_value  		),
	.D_slave_rs         		( D_slave_rs         		),
	.D_slave_rs_dara    		( D_slave_rs_dara    		),
	.D_slave_rs_value   		( D_slave_rs_value   		),
	.D_slave_rd         		( D_slave_rd         		),
	.D_slave_rd_dara    		( D_slave_rd_dara    		),
	.D_slave_rd_value   		( D_slave_rd_value   		)
);

issue_ctrl u_issue_ctrl(
    //master's status
    .D_inst_priv_master         (D_master_spec_inst), // 主分支是否是特权指令
    .D_reg_en_master            (D_master_wb_reg_en), // regWrite
    .D_reg_dst_master           (D_master_rd), // rd
    .D_hilo_accessed_master     (D_master_is_hilo_accessed), // 是否用到hilo寄存器 hiloWrite/Read  // FIXME 为啥读也要管
    .D_en_master                (D_master_en), // master是否发射
    //slave's status
    .D_op_slave                 (D_slave_op ),
    .D_rs_slave                 (D_slave_rs),
    .D_rt_slave                 (D_slave_rt),
    .D_mem_type_slave           (D_slave_mem_type),
    .D_branch_slave             (D_slave_is_branch),
    .D_inst_priv_slave          (D_slave_inst_priv), // 是否是特权指令
    .D_hilo_accessed_slave      (D_slave_is_hilo_accessed),

    .fifo_empty                 (fifo_empty ),
    .fifo_almost_empty          (fifo_almost_empty),

    //raw detection
    // FIXME 应该是E阶段流水中的信号
    .E_mem_type                 (E_master_mem_size ), // BUG 这信号是指啥？
    .E_mem_wb_reg_dst           (E_master_reg_waddr),

    .D_en_slave                 (D_slave_en)
);

// XXX ====================================== Execute ======================================
flopenrc #(5 ) DFF_E_master_shamt       (clk,rst,E_master_flush,~E_master_stall,D_master_shamt       ,E_master_shamt       );
flopenrc #(32) DFF_E_master_rs_value    (clk,rst,E_master_flush,~E_master_stall,D_master_rs_value    ,E_master_rs_value    );
flopenrc #(32) DFF_E_master_rt_value    (clk,rst,E_master_flush,~E_master_stall,D_master_rt_value    ,E_master_rt_value    );
flopenrc #(32) DFF_E_master_imm_value   (clk,rst,E_master_flush,~E_master_stall,D_master_imm_value   ,E_master_imm_value   );
flopenrc #(8 ) DFF_E_master_aluop       (clk,rst,E_master_flush,~E_master_stall,D_master_aluop       ,E_master_aluop       );
flopenrc #(1 ) DFF_E_master_alu_sela    (clk,rst,E_master_flush,~E_master_stall,D_master_alu_sela    ,E_master_alu_sela    );
flopenrc #(1 ) DFF_E_master_alu_selb    (clk,rst,E_master_flush,~E_master_stall,D_master_alu_selb    ,E_master_alu_selb    );
flopenrc #(26) DFF_E_master_j_target    (clk,rst,E_master_flush,~E_master_stall,D_master_j_target    ,E_master_j_target    );
flopenrc #(32) DFF_E_master_pc          (clk,rst,E_master_flush,~E_master_stall,D_master_pc          ,E_master_pc          );
flopenrc #(1 ) DFF_E_master_is_link_pc8 (clk,rst,E_master_flush,~E_master_stall,D_master_is_link_pc8 ,E_master_is_link_pc8 );
flopenrc #(1 ) DFF_E_master_mem_en      (clk,rst,E_master_flush,~E_master_stall,D_master_mem_en      ,E_master_mem_en      );
flopenrc #(1 ) DFF_E_master_hilowrite   (clk,rst,E_master_flush,~E_master_stall,D_master_hilowrite   ,E_master_hilowrite   );
flopenrc #(6 ) DFF_E_master_op          (clk,rst,E_master_flush,~E_master_stall,D_master_op          ,E_master_op          );
flopenrc #(1 ) DFF_E_master_memtoReg    (clk,rst,E_master_flush,~E_master_stall,D_master_memtoReg    ,E_master_memtoReg    );
flopenrc #(5 ) DFF_E_master_reg_wen     (clk,rst,E_master_flush,~E_master_stall,D_master_reg_wen     ,E_master_reg_wen     );
flopenrc #(5 ) DFF_E_master_reg_waddr   (clk,rst,E_master_flush,~E_master_stall,D_master_reg_waddr   ,E_master_reg_waddr   );
flopenrc #(5 ) DFF_E_master_branch_type (clk,rst,E_master_flush,~E_master_stall,D_master_branch_type ,E_master_branch_type );

flopenrc #(5 ) DFF_E_slave_shamt       (clk,rst,E_slave_flush,~E_slave_stall,D_slave_shamt       ,E_slave_shamt       );
flopenrc #(32) DFF_E_slave_rs_value    (clk,rst,E_slave_flush,~E_slave_stall,D_slave_rs_value    ,E_slave_rs_value    );
flopenrc #(32) DFF_E_slave_rt_value    (clk,rst,E_slave_flush,~E_slave_stall,D_slave_rt_value    ,E_slave_rt_value    );
flopenrc #(32) DFF_E_slave_imm_value   (clk,rst,E_slave_flush,~E_slave_stall,D_slave_imm_value   ,E_slave_imm_value   );
flopenrc #(8 ) DFF_E_slave_aluop       (clk,rst,E_slave_flush,~E_slave_stall,D_slave_aluop       ,E_slave_aluop       );
flopenrc #(32) DFF_E_slave_pc          (clk,rst,E_slave_flush,~E_slave_stall,D_slave_pc          ,E_slave_pc          );
flopenrc #(1 ) DFF_E_slave_reg_wen     (clk,rst,E_slave_flush,~E_slave_stall,D_slave_reg_wen     ,E_slave_reg_wen     );
flopenrc #(5 ) DFF_E_slave_reg_waddr   (clk,rst,E_slave_flush,~E_slave_stall,D_slave_reg_waddr   ,E_slave_reg_waddr   );
flopenrc #(1 ) DFF_E_slave_alu_sela    (clk,rst,E_slave_flush,~E_slave_stall,D_slave_alu_sela    ,E_slave_alu_sela    );
flopenrc #(1 ) DFF_E_slave_alu_selb    (clk,rst,E_slave_flush,~E_slave_stall,D_slave_alu_selb    ,E_slave_alu_selb    );
flopenrc #(1 ) DFF_E_slave_is_link_pc8 (clk,rst,E_slave_flush,~E_slave_stall,D_slave_is_link_pc8 ,E_slave_is_link_pc8 );



branch_judge u_branch_judge(
	//ports
	.branch_type       		( E_master_branch_type       		),
	.imm_value         		( E_master_imm_value         		),
	.j_target          		( E_master_j_target          		),
	.rs_data           		( E_master_rs_value           		),
	.rt_data           		( E_master_rt_value           		),
	.pc_plus4          		( E_master_pc + 32'd4          		),
	.branch_taken      		( E_branch_taken      		),
	.pc_branch_address 		( E_pc_branch_target 		)
);


// select_alusrc: 所有的pc要加8的，都在alu执行，进行电路复用
// FIXME 要不要封装呢
assign E_master_alu_srca = (E_master_is_link_pc8) ? E_master_pc : 
                           (E_master_alu_sela) ? {{27{1'b0}},E_master_shamt} : 
                            E_master_rs_value;
assign E_slave_alu_srca  = (E_slave_is_link_pc8 ) ? E_slave_pc :
                           (E_slave_alu_sela ) ? {{27{1'b0}},E_slave_shamt} : 
                            E_slave_rs_value ;                            
assign E_master_alu_srcb = (E_master_is_link_pc8) ? 32'd8 :
                           (E_master_alu_selb) ? E_master_imm_value :
                            E_master_rt_value;
assign E_salve_alu_srcb  = (E_slave_is_link_pc8 ) ? 32'd8 :
                           (E_slave_alu_selb) ? E_slave_imm_value :
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
	.y         		( E_master_alu_res  ),
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

// XXX ====================================== Memory ======================================
flopenrc #(1 ) DFF_M_master1 (clk,rst,M_master_flush,~M_master_stall,E_master_mem_en,M_master_mem_en);
flopenrc #(1 ) DFF_M_master2 (clk,rst,M_master_flush,~M_master_stall,E_master_hilowrite,M_master_hilowrite);
flopenrc #(6 ) DFF_M_master3 (clk,rst,M_master_flush,~M_master_stall,E_master_op,M_master_op);
flopenrc #(32) DFF_M_master7 (clk,rst,M_master_flush,~M_master_stall,E_master_pc,M_master_pc);
flopenrc #(32) DFF_M_master4 (clk,rst,M_master_flush,~M_master_stall,E_master_rt_value,M_master_rt_value);
flopenrc #(8 ) DFF_M_master5 (clk,rst,M_master_flush,~M_master_stall,E_master_alu_res,M_master_alu_res);
flopenrc #(1 ) DFF_M_master8 (clk,rst,M_master_flush,~M_master_stall,E_master_alu_out64,M_master_alu_out64);
flopenrc #(1 ) DFF_M_master9 (clk,rst,E_master_flush,~E_master_stall,E_master_memtoReg,M_master_memtoReg);
flopenrc #(5 ) DFF_M_master10(clk,rst,E_master_flush,~E_master_stall,E_master_reg_wen,M_master_reg_wen);
flopenrc #(5 ) DFF_M_master11(clk,rst,E_master_flush,~E_master_stall,E_master_reg_waddr,M_master_reg_waddr);

flopenrc #(1 ) DFF_M_slave1  (clk,rst,M_slave_flush ,~M_slave_stall ,E_slave_reg_wen,M_slave_reg_wen);
flopenrc #(5 ) DFF_M_slave2  (clk,rst,M_slave_flush ,~M_slave_stall ,E_slave_reg_waddr,M_slave_reg_waddr);
flopenrc #(32) DFF_M_slave5  (clk,rst,M_slave_flush ,~M_slave_stall ,E_slave_alu_res,M_slave_alu_res);

mem_access u_mem_access(
	//ports
	.opM             		( M_master_op             		),
	.pcM             		( M_master_pc             		),
	.mem_en                 ( M_master_mem_en       ),
    .mem_wdata       		( M_master_rt_value       		),
	.mem_addr        		( M_master_alu_res        		),
	.mem_rdata       		( M_master_mem_rdata       		),
	.data_sram_en           ( data_sram_en           ),
    .data_sram_rdata 		( data_sram_rdata 		),
	.data_sram_wen   		( data_sram_wen   		),
	.data_sram_waddr 		( data_sram_waddr 		),
	.data_sram_wdata 		( data_sram_wdata 		),
	.ades           		( M_ades           		),
	.adel           		( M_adel           		),
	.bad_addr        		( M_bad_addr        		)
);

// hilo到M阶段处理，W阶段写完
// TODO hiloreg
// hilo_reg u_hilo_reg(
// 	//ports
// 	.clk    		( clk    		   ),
// 	.rst    		( rst    		   ),
// 	.we     		( M_master_hilowrite & ~M_except & ~M_stall),
// 	.hilo_i 		( M_master_alu_out64),
// 	.hilo   		( hilo   	       )
// );


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
flopenrc #(1 ) DFF_W_master1(clk,rst,W_master_flush,~W_master_stall,M_master_memtoReg,W_master_memtoReg);
flopenrc #(32) DFF_W_master3(clk,rst,W_master_flush,~W_master_stall,M_master_mem_rdata,W_master_mem_rdata);
flopenrc #(5 ) DFF_W_master4(clk,rst,W_master_flush,~W_master_stall,M_master_reg_wen,W_master_reg_wen);
flopenrc #(5 ) DFF_W_master5(clk,rst,W_master_flush,~W_master_stall,M_master_reg_waddr,W_master_reg_waddr);
flopenrc #(32) DFF_W_master6(clk,rst,W_master_flush,~W_master_stall,M_master_alu_res,M_master_alu_res);


flopenrc #(1 ) DFF_W_slave1 (clk,rst,W_slave_flush ,~W_slave_stall ,M_slave_reg_wen,W_slave_reg_wen);
flopenrc #(5 ) DFF_W_slave2 (clk,rst,W_slave_flush ,~W_slave_stall ,M_slave_reg_waddr,W_slave_reg_waddr);
flopenrc #(32) DFF_W_slave5 (clk,rst,W_slave_flush ,~W_slave_stall ,M_slave_alu_res ,W_slave_alu_res);

assign W_master_reg_wdata = W_master_memtoReg ? W_master_mem_rdata : W_master_alu_res;
assign W_slave_reg_wdata = W_slave_alu_res;

// ******************* 冒险处理 *****************
// TODO 冒险处理
hazard hazard(
    .regwriteE(regwriteE),
    .regwriteM(regwriteM),
    .regwriteW(regwriteW),
    .memtoRegE(memtoRegE),
    .memtoRegM(memtoRegM),
    .jumpD(jumpD),
    .jalD(jalD),
    .branchD(branchD),
    .jrD(jrD),
    .stall_divE(stall_divE),
    .i_stall(i_stall),
    .d_stall(d_stall),
    .rsD(rsD),
    .rtD(rtD),
    .rsE(rsE),
    .rtE(rtE),
    .reg_waddrM(reg_waddrM),
    .reg_waddrW(reg_waddrW),
    .reg_waddrE(reg_waddrE),
    
    .forwardAD(forwardAD),
    .forwardBD(forwardBD),
    .forwardAE(forwardAE), 
    .forwardBE(forwardBE),
    .stallF(stallF),
    .stallD(stallD),
    .stallE(stallE),
    .stallM(stallM),
    .stallW(stallW),
    .longest_stall(longest_stall),
    .flushD(flushD),
    .flushE(flushE),
    .flushM(flushM),
    .flushW(flushW),
    
    // 异常
    .opM(instrM[31:26]),
    .except_logicM(except_logicM),
    .excepttypeM(excepttypeM),
    .cp0_epcM(epc_o),
    .pc_except(pc_except_addr)
);

// ascii
instdec instdecF(instrF);
instdec instdecD(instrD);
instdec instdecE(instrE);
instdec instdecM(instrM);

endmodule