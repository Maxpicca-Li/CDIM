`timescale 1ns / 1ps
`include "defines.vh"
// TODO 结合之前的decoder和当前的decoder，结合二者的信号吧
/*
当前的decoder

之前的decoder:
hilowrite
wire        E_master_alu_sela,E_slave_alu_sela;
wire        E_master_alu_selb,E_slave_alu_selb;
cp0writeM
*/
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
    input wire [31:0]data_sram_rdataM,
    output wire data_sram_enM,
    output wire [3:0] data_sram_wenM,
    output wire [31:0]data_sram_waddrM,
    output wire [31:0]data_sram_wdataM
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


wire [31:0] 	D_master_inst     ,D_slave_inst    ;
wire [11:0] 	D_master_inst_exp ,D_slave_inst_exp;
wire [31:0] 	D_master_pc       ,D_slave_pc      ;

wire            D_master_en              ,D_slave_en              ;
wire [5:0]  	D_master_op              ,D_slave_op              ;
wire [4:0]  	D_master_rs              ,D_slave_rs              ;
wire [4:0]  	D_master_rt              ,D_slave_rt              ;
wire [4:0]  	D_master_rd              ,D_slave_rd              ;
wire [4:0]  	D_master_shamt           ,D_slave_shamt           ;
wire [5:0]  	D_master_funct           ,D_slave_funct           ;
wire [15:0] 	D_master_imm             ,D_slave_imm             ;
wire [25:0] 	D_master_j_target        ,D_slave_j_target        ;
wire        	D_master_is_branch_link  ,D_slave_is_branch_link  ;
wire        	D_master_is_branch       ,D_slave_is_branch       ;
wire        	D_master_is_hilo_accessed,D_slave_is_hilo_accessed;
wire        	D_master_undefined_inst  ,D_slave_undefined_inst  ;
wire [7:0]  	D_master_aluop           ,D_slave_aluop           ;
wire [1:0]  	D_master_alusrc_op       ,D_slave_alusrc_op       ;
wire        	D_master_alu_imm_sign    ,D_slave_alu_imm_sign    ;
wire [1:0]  	D_master_mem_type        ,D_slave_mem_type        ;
wire [2:0]  	D_master_mem_size        ,D_slave_mem_size        ;
wire [4:0]  	D_master_reg_waddr       ,D_slave_reg_waddr       ;
wire        	D_master_reg_wen         ,D_slave_reg_wen         ;
wire        	D_master_unsigned_flag   ,D_slave_unsigned_flag   ;
wire        	D_master_priv_inst       ,D_slave_priv_inst       ;
wire [31:0]     D_master_rs_data         ,D_slave_rs_data         ;
wire [31:0]     D_master_rt_data         ,D_slave_rt_data         ;
wire [31:0]     D_master_rs_value        ,D_slave_rs_value        ;
wire [31:0]     D_master_rt_value        ,D_slave_rt_value        ;
wire [31:0]     D_master_imm_value       ,D_slave_imm_value       ;

wire  	        E_branch_taken;
wire [31:0]     E_pc_branch_target;
wire [ 4:0]     E_master_shamt   ,E_slave_shamt;
wire [31:0]     E_master_rs_value,E_slave_rs_value;
wire [31:0]     E_master_rt_value,E_slave_rt_value;
wire            E_master_alu_sela,E_slave_alu_sela;
wire            E_master_alu_selb,E_slave_alu_selb;
wire [31:0]     E_master_alu_srca,E_slave_alu_srca;
wire [31:0]     E_master_alu_srcb,E_slave_alu_srcb;
wire [31:0]     E_master_alu_res ,E_slave_alu_res;
wire [63:0]     E_master_alu_out64;
wire [ 7:0]     E_master_aluop   ,E_slave_aluop;
wire            E_master_overflow,E_slave_overflow;
wire [31:0]     E_master_imm_value,E_slave_imm_value;

wire            M_master_hilowrite;
wire            M_master_cp0write ,M_slave_cp0write ;


assign M_except = (|M_excepttype);
// TODO 整个pipeline由冒险模块控制 / pipeline_ctrl 
// D_en_master由pipeline_ctrl生成

//========E's variables==========
wire [1:0]      E_mem_type;      
wire [4:0]      E_mem_wb_reg_dst;
// 异常
// TODO except to judge
// assign syscallD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001100);
// assign breakD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001101);
// assign eretD = (instrD == 32'b01000010000000000000000000011000);

// 异常 ? 取指异常？F_pc和F_pc+4吗
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

decoder decoder_master(
	//ports
	.instr            		( D_master_inst            		    ),
	.op               		( D_master_op               		),
	.rs               		( D_master_rs               		),
	.rt               		( D_master_rt               		),
	.rd               		( D_master_rd               		),
	.shamt            		( D_master_shamt            		),
	.funct            		( D_master_funct            		),
	.imm              		( D_master_imm              		),
    .sign_extend_imm_value  ( D_master_imm_value                ),
	.j_target         		( D_master_j_target         		),
	.is_branch_link   		( D_master_is_branch_link   		),
	.is_branch        		( D_master_is_branch        		),
	.is_hilo_accessed 		( D_master_is_hilo_accessed 		),
	.undefined_inst   		( D_master_undefined_inst   		),
	.aluop            		( D_master_aluop            		),
	.alusrc_op        		( D_master_alusrc_op        		),
	.alu_imm_sign     		( D_master_alu_imm_sign     		),
	.mem_type         		( D_master_mem_type         		),
	.mem_size         		( D_master_mem_size         		),
	.reg_waddr      		( D_master_reg_waddr                ),
	.reg_wen        		( D_master_reg_wen           		),
	.unsigned_flag    		( D_master_unsigned_flag    		),
	.priv_inst        		( D_master_priv_inst        		)
);

decoder decoder_slave(
	//ports
	.instr            		( D_slave_inst            		),
	.op               		( D_slave_op               		),
	.rs               		( D_slave_rs               		),
	.rt               		( D_slave_rt               		),
	.rd               		( D_slave_rd               		),
	.shamt            		( D_slave_shamt            		),
	.funct            		( D_slave_funct            		),
	.imm              		( D_slave_imm              		),
    .sign_extend_imm_value  ( D_slave_imm_value             ),
	.j_target         		( D_slave_j_target         		),
	.is_branch_link   		( D_slave_is_branch_link   		),
	.is_branch        		( D_slave_is_branch        		),
	.is_hilo_accessed 		( D_slave_is_hilo_accessed 		),
	.undefined_inst   		( D_slave_undefined_inst   		),
	.aluop            		( D_slave_aluop            		),
	.alusrc_op        		( D_slave_alusrc_op        		),
	.alu_imm_sign     		( D_slave_alu_imm_sign     		),
	.mem_type         		( D_slave_mem_type         		),
	.mem_size         		( D_slave_mem_size         		),
	.reg_waddr        		( D_slave_reg_waddr      		),
	.reg_wen        		( D_slave_reg_wen        		),
	.unsigned_flag    		( D_slave_unsigned_flag    		),
	.priv_inst        		( D_slave_priv_inst        		)
);



// DONE dual_engine signals define and connect
issue_ctrl u_issue_ctrl(
    //master's status
    .D_inst_priv_master         (D_master_priv_inst), // 主分支是否是特权指令
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

   // .D_tlb_error                (),   暂不处理

    .fifo_empty                 (fifo_empty ),
    .fifo_almost_empty          (fifo_almost_empty),

    //raw detection
    // FIXME 应该是E阶段流水中的信号
    .E_mem_type                 (E_master_mem_size ),
    .E_mem_wb_reg_dst           (E_master_mem_wb_reg_dst),

    .D_en_slave                 (D_slave_en)
);

// DONE regfile signals define and connect
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

// ====================================== Execute ======================================
// TODO 流水线寄存器，不知道需要流哪些？
/*
E_master_shamt,E_slave_shamt
E_master_rs_value,E_slave_rs_value
E_master_rt_value,E_slave_rt_value
E_master_alu_srca, E_slave_alu_srcb
aluop
*/

// TODO branch_judge signals redecode
branch_judge u_branch_judge(
    //ports
	// FIXME E_master_jump\E_master_jal\E_master_jr\E_master_is_branch
    .is_branch              ( E_master_is_branch          ), // 是否是branch指令
    .j_instIndex       		( E_master_jump | E_master_jal),
	.jr               		( E_master_jr                 ),
	.op               		( E_master_op                 ), // 其实可以用branch_type代替
	.rt               		( E_master_rt                 ),
	.imm_value        		( E_master_imm_value          ),
	.j_target         		( E_master_D_j_target         ),
	.rs_data          		( E_rs_data          		  ),
	.rt_data          		( E_rt_data          		  ),
	.pc_curr          		( E_pc_curr          		  ),
	.branch_taken     		( E_branch_taken     		  ),
	.pc_branch_target 		( E_pc_branch_target 		  )
);


// 所有的pc要加8的，都在alu执行，进行电路复用
// select_alusrc
// TODO decoder
assign E_master_alu_srca = (balE | jalE | jrE) ? E_master_pc : 
                           (E_master_alu_sela) ? {{27{1'b0}},E_master_shamt} : 
                            E_master_rs_value;
assign E_slave_alu_srca  = (balE | jalE | jrE) ? E_slave_pc :
                           (E_slave_alu_sela ) ? {{27{1'b0}},E_slave_shamt} : 
                            E_slave_rs_value ;                            
assign E_master_alu_srcb = (balE | jalE | jrE) ? 32'd8 :
                           (E_master_alu_selb) ? E_master_imm_value :
                            E_master_rt_value;
assign E_salve_alu_srcb  = (balE | jalE | jrE) ? 32'd8 :
                           (E_slave_alu_selb) ? E_salve_imm_value :
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

// ====================================== Memory ======================================
flopenrc #(32) DFF_pc_nowM         (clk,rst,flushM,~stallM,pc_nowE,pc_nowM);
flopenrc #(1 ) DFF_is_in_delayslotM(clk,rst,flushM,~stallM,is_in_delayslotE,is_in_delayslotM);
flopenrc #(5 ) DFF_reg_waddrM      (clk,rst,flushM,~stallM,reg_waddrE,reg_waddrM);
flopenrc #(5 ) DFF_reg_rdM         (clk,rst,flushM,~stallM,rdE,rdM);
flopenrc #(8 ) DFF_exceptM         (clk,rst,flushM,~stallM,{exceptE[7:3],overflow,exceptE[1:0]},exceptM);
flopenrc #(32) DFF_alu_resM        (clk,rst,flushM,~stallM,alu_resE_real,alu_resM);
flopenrc #(32) DFF_sel_rd2M        (clk,rst,flushM,~stallM,sel_rd2E,sel_rd2M);
flopenrc #(32) DFF_instrM          (clk,rst,flushM,~stallM,instrE,instrM);
flopenrc #(64) DFF_aluout_64M      (clk,rst,flushM,~stallM,aluout_64E,aluout_64M);

// 地址映射
// assign data_sram_waddrM = alu_resM;
assign data_sram_waddrM = (alu_resM[31:28] == 4'hB) ? {4'h1, alu_resM[27:0]} :
                (alu_resM[31:28] == 4'h8) ? {4'h0, alu_resM[27:0]}: alu_resM;

lsmem lsmen(
    .opM(instrM[31:26]),
    .sel_rd2M(sel_rd2M), // writedata_4B
    .alu_resM(alu_resM),
    .data_sram_rdataM(data_sram_rdataM),
    .pcM(pc_nowM),

    .data_sram_wenM(data_sram_wenM),
    .data_sram_wdataM(data_sram_wdataM),
    .read_dataM(read_dataM),
    .adesM(adesM),
    .adelM(adelM),
    .bad_addr(bad_addr)
);

exception exp(
    rst,
    exceptM,
    adelM,
    adesM,
    status_o,
    cause_o,
    excepttypeM
);

// hilo到M阶段处理，W阶段写完


hilo_reg u_hilo_reg(
	//ports
	.clk    		( clk    		   ),
	.rst    		( rst    		   ),
	.we     		( M_master_hilowrite & ~M_except & ~M_stall),
	.hilo_i 		( E_master_alu_out1),
	.hilo   		( hilo   	       )
);

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

mux2 mux2_memtoReg(.a(alu_resM),.b(read_dataM),.sel(memtoRegM),.y(W_master_reg_wdata));

// ====================================== WriteBack ======================================
// W阶段异常刷新
flopenrc #(5 ) DFF_reg_waddrW      (clk,rst,flushW,~stallW,reg_waddrM,reg_waddrW);
flopenrc #(32) DFF_wd3W            (clk,rst,flushW,~stallW,wd3M,wd3W);

// ******************* 冒险处理 *****************
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