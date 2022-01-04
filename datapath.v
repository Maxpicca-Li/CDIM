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

wire        	fifo_empty;
wire        	fifo_almost_empty;
wire        	fifo_full;

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
wire [4:0]  	D_master_wb_reg_dest     ,D_slave_wb_reg_dest     ;
wire        	D_master_wb_reg_en       ,D_slave_wb_reg_en       ;
wire        	D_master_unsigned_flag   ,D_slave_unsigned_flag   ;
wire        	D_master_priv_inst       ,D_slave_priv_inst       ;
wire [31:0]     D_master_rs_data         ,D_slave_rs_data         ;
wire [31:0]     D_master_rs_value        ,D_slave_rs_value        ;


wire  	    E_branch_taken;
wire [31:0] E_pc_branch_target;

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
	.wb_reg_dest      		( D_master_wb_reg_dest      		),
	.wb_reg_en        		( D_master_wb_reg_en        		),
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
	.wb_reg_dest      		( D_slave_wb_reg_dest      		),
	.wb_reg_en        		( D_slave_wb_reg_en        		),
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

// TODO regfile signals define and connect
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

// DONE forward_mux
forwarding_mux forwarding_mux_rs_master(
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
	.reg_addr           		( D_master_rs           		),
	.reg_data           		( D_master_rs_dara ),
	.result_data        		( D_master_rs_value)
);

forwarding_mux forwarding_mux_rd_master(
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
	.reg_addr           		( D_master_rd           	),
	.reg_data           		( D_master_rd_data          ),
	.result_data        		( D_master_rd_value         )
);

forwarding_mux forwarding_mux_rs_slave(
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
	.reg_addr           		( D_slave_rs            	),
	.reg_data           		( D_slave_rs_data           ),
	.result_data        		( D_slave_rs_value          )
);

forwarding_mux forwarding_mux_rd_slave(
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
	.reg_addr           		( D_slave_rd            	),
	.reg_data           		( D_slave_rd_data           ),
	.result_data        		( D_slave_rd_value          )
);


// TODO branch_judge signals define and connect



branch_judge u_branch_judge(
    //ports
	// FIXME E_master_jump\E_master_jal\E_master_jr\E_master_is_branch
    .is_branch              ( E_master_is_branch          ), // 是否是branch指令
    .j_instIndex       		( E_master_jump | E_master_jal),
	.jr               		( E_master_jr                 ),
	.op               		( E_master_op                 ), // 其实可以用branch_type代替
	.rt               		( E_master_rt                 ),
	.imm              		( E_master_imm                ),
	.j_target         		( E_master_D_j_target         ),
	.rs_data          		( E_rs_data          		  ),
	.rt_data          		( E_rt_data          		  ),
	.pc_curr          		( E_pc_curr          		  ),
	.branch_taken     		( E_branch_taken     		  ),
	.pc_branch_target 		( E_pc_branch_target 		  )
);

/* old logical
mux2 #(32) mux2_forwardAD(rd1D,alu_resM,forwardAD,rd1D_branch);
mux2 #(32) mux2_forwardBD(rd2D,alu_resM,forwardBD,rd2D_branch);
eqcmp pc_predict(
    .a(rd1D_branch),
    .b(rd2D_branch),
    .op(instrD[31:26]),
    .rt(rtD),
    .y(equalD)
);
assign branch_taken = equalD & (branchD|balD);
assign pc_next_jump={pc_plus4D[31:28],instrD[25:0],2'b00};
assign pc_next_jr=rd1D_branch;
*/




// pc_b 
signext sign_extend(
    .a(instrD[15:0]), 
    .type(instrD[29:28]),
    .y(sign_immD) 
);
adder adder_branch(
    .a({sign_immD[29:0],2'b00}),
    .b(pc_plus4D),
    .y(pc_branchD)
);

// ====================================== Execute ======================================
flopenrc #(32) DFF_pc_nowE         (clk,rst,flushE,~stallE & ~(|excepttypeM),pc_nowD,pc_nowE);
flopenrc #(1 ) DFF_is_in_delayslotE(clk,rst,flushE,~stallE,is_in_delayslotD,is_in_delayslotE);
flopenrc #(5 ) DFF_rtE             (clk,rst,flushE,~stallE,rtD,rtE);
flopenrc #(5 ) DFF_rdE             (clk,rst,flushE,~stallE,rdD,rdE);
flopenrc #(5 ) DFF_rsE             (clk,rst,flushE,~stallE,rsD,rsE);
flopenrc #(5 ) DFF_saE             (clk,rst,flushE,~stallE,saD,saE);
flopenrc #(8 ) DFF_exceptE         (clk,rst,flushE,~stallE,{pc_exceptD,syscallD,breakD,eretD,invalidD,3'b0},exceptE);
flopenrc #(32) DFF_instrE          (clk,rst,flushE,~stallE,instrD,instrE);
flopenrc #(32) DFF_pc_plus4E       (clk,rst,flushE,~stallE,pc_plus4D,pc_plus4E);
flopenrc #(32) DFF_rd1E            (clk,rst,flushE,~stallE,rd1D,rd1E);
flopenrc #(32) DFF_rd2E            (clk,rst,flushE,~stallE,rd2D,rd2E);
flopenrc #(32) DFF_sign_immE       (clk,rst,flushE,~stallE,sign_immD,sign_immE);

// link指令对寄存器的选择
mux3 #(5) mux3_regDst(
    .d0(rtE),
    .d1(rdE),
    .d2(5'b11111),
    .sel({balE|jalE,regdstE}),
    .y(reg_waddrE)
);
mux2 #(32) mux2_alusrcAE(
    .a(rd1E),
    .b({{27{1'b0}},saE}),
    .sel(alusrcAE),
    .y(rd1_saE)
);
// ******************* 数据冒险 *****************
// 00原结果，01写回结果_W， 10计算结果_M
mux3 #(32) mux3_forwardAE(rd1_saE,wd3W,alu_resM,forwardAE,sel_rd1E);
mux3 #(32) mux3_forwardBE(rd2E,wd3W,alu_resM,forwardBE,sel_rd2E);

mux2 mux2_aluSrcBE(
    .a(sel_rd2E),
    .b(sign_immE),
    .sel(alusrcBE),
    .y(srcB)
);

alu alu(
    .clk(clk),
    .rst(rst),
    .a(sel_rd1E),
    .b(srcB),
    .aluop(alucontrolE),
    .hilo(hilo),
    .cp0_data_o(cp0_data_oE),
    .stall_div(stall_divE),
    .y(alu_resE),
    .aluout_64(aluout_64E),
    .overflow(overflow),
    .zero()
);

adder pc_8(
    .a(pc_plus4E),
    .b(32'h4),
    .y(pc_plus8E)
);

// 若有延迟槽，则link到pc+8
mux2 alu_pc8(
    .a(alu_resE),
    .b(pc_plus8E),
    .sel((balE | jalE) | jrE),
    .y(alu_resE_real)
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

hilo_reg hilo_reg(
	.clk(clk),.rst(rst),.we(hilowriteM & ~(|excepttypeM)  & (~stallM)), // 写的时候没有异常，无阻塞
	.hilo_i(aluout_64M),
	// .hilo_res(hilo_res)
	.hilo(hilo)  // hilo current data
);

cp0_reg CP0(
    .clk(clk),
	.rst(rst),
    .we_i(cp0writeM & ~stallM),
	.waddr_i(rdM),  // M阶段写入CP0
	.raddr_i(rdE),  // E阶段读取CP0，这两步可以避免数据冒险处理
	.data_i(sel_rd2M),

	.int_i(ext_int),

	.excepttype_i(excepttypeM),
	.current_inst_addr_i(pc_nowM),
	.is_in_delayslot_i(is_in_delayslotM),
	.bad_addr_i(bad_addr),

	.data_o(cp0_data_oE),
	.count_o(count_o),
	.compare_o(compare_o),
	.status_o(status_o),
	.cause_o(cause_o),
	.epc_o(epc_o),
	.config_o(config_o),
	.prid_o(prid_o),
	.badvaddr_o(badvaddr),
	.timer_int_o(timer_int_o)
);

mux2 mux2_memtoReg(.a(alu_resM),.b(read_dataM),.sel(memtoRegM),.y(wd3M));

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