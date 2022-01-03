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
    input wire inst_data_ok1,
    input wire inst_data_ok2,
    input wire [31:0]inst_data1,
    input wire [31:0]inst_data2,
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

wire [31:0] 	D_inst_master;
wire [31:0] 	D_inst_slave;
wire [11:0] 	D_inst_exp1;
wire [11:0] 	D_inst_exp2;
wire [31:0] 	D_pc_master;
wire [31:0] 	D_pc_slave;
wire D_read_en1;
wire D_read_en2;
wire        	fifo_empty;
wire        	fifo_almost_empty;
wire        	fifo_full;

// 异常 ? 取指异常？F_pc和F_pc+4吗
assign pc_exceptF = (F_pc[1:0] == 2'b00) ? 1'b0 : 1'b1;
assign inst_sram_en =  1'b1; // !except_logicM & !pc_exceptF;

// ====================================== Fetch ======================================

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
	.read_en1         		( D_read_en1         		),
	.read_en2         		( D_read_en2         		),
	.read_data1       		( D_inst_master       		),
	.read_data2       		( D_inst_slave      		),
	.read_addres1     		( D_pc_master     		),
	.read_addres2     		( D_pc_slave     		),
	.inst_exp1        		( D_inst_exp1        		),
	.inst_exp2        		( D_inst_exp2        		),
	.write_en1        		( inst_ok && inst_data_ok1        		),
	.write_en2        		( inst_ok && inst_data_ok2        		),
	.write_inst_exp1  		( 12'b0  		),
	.write_address1   		( F_pc   		),
	.write_address2   		( F_pc + 32'd4   		),
	.write_data1      		( inst_data1 ),
	.write_data2      		( inst_data2 ),
	.empty            		( fifo_empty            		),
	.almost_empty     		( fifo_almost_empty     		),
	.full             		( fifo_full             		)
);



adder adder(
    .a(pc_nowF),
    .b(32'd4),
    .y(pc_plus4F)
);

// ====================================== Decoder ======================================
// always @(posedge clk) begin
//     if (rst | flushD) begin

//     end 
//     else if(~stallD)begin

//     end
// end
flopenrc #(32) DFF_pc_nowD         (clk,rst,flushD,~stallD & ~(|excepttypeM),pc_nowF,pc_nowD);
flopenrc #(1 ) DFF_is_in_delayslotD(clk,rst,flushD,~stallD,is_in_delayslotF,is_in_delayslotD);
flopenrc #(1 ) DFF_pc_exceptD      (clk,rst,flushD,~stallD,pc_exceptF,pc_exceptD);
flopenrc #(32) DFF_instrD          (clk,rst,flushD,~stallD,instrF,instrD);
flopenrc #(32) DFF_pc_plus4D       (clk,rst,flushD,~stallD,pc_plus4F,pc_plus4D);

// 异常
// assign syscallD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001100);
// assign breakD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001101);
assign eretD = (instrD == 32'b01000010000000000000000000011000);

// instrD 分解
assign opD = instrD[31:26];
assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];
assign saD = instrD[10:6];
assign functD = instrD[5:0];

main_dec main_dec(
    .clk(clk),
    .rst(rst),
    .flushE(flushE),
    .flushM(flushM),
    .flushW(flushW),
    .stallE(stallE),
    .stallM(stallM),
    .stallW(stallW),
    .op(opD),
    .funct(functD),
    .rs(rsD),
    .rt(rtD),
    
    .regwriteW(regwriteW),
    .regdstE(regdstE),
    .alusrcAE(alusrcAE),
    .alusrcBE(alusrcBE),
    .branchD(branchD),
    .memWriteM(memWriteM),
    .memtoRegW(memtoRegW),
    .jumpD(jumpD),
    .regwriteE(regwriteE),
    .regwriteM(regwriteM),
    .memtoRegE(memtoRegE),
    .memtoRegM(memtoRegM),
    .hilowriteM(hilowriteM),
    .cp0writeM(cp0writeM),
    .balD(balD),
    .balE(balE),
    .balW(balW),
    .jalD(jalD),
    .jalE(jalE),
    .jalW(jalW),
    .jrD(jrD),
    .jrE(jrE),
    .memenM(memenM),
    .invalid(invalidD)
);

alu_dec alu_decoder(
    .clk(clk), 
    .rst(rst),
    .flushE(flushE),
    .stallE(stallE),
    .op(opD),
    .funct(functD),
    .rs(rsD),
    .aluopE(alucontrolE)
);

regfile regfile(
	.clk(clk),
	.we3(regwriteM & ~stallW & !except_logicM), // 数据在M阶段准备，W阶段写回
	.ra1(instrD[25:21]), 
    .ra2(instrD[20:16]),
    .wa3(reg_waddrM),
	.wd3(wd3M), 
	.rd1(rd1D),
    .rd2(rd2D)
);
                            
// ******************* 控制冒险 *****************
// 在 regfile 输出后添加一个判断相等的模块，即可提前判断 beq，以将分支指令提前到Decode阶段（预测）
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