module mycpu_top(
    input clk,
    input resetn,  //low active
    input [5:0]int,  //interrupt,high active
    //cpu inst sram
    output        inst_sram_en   ,
    output [7 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [63:0] inst_sram_wdata,
    input  [63:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);

    wire [31:0]pc_fetch;
    wire [31:0]inst_rdata1;
    wire [31:0]inst_rdata2;
    wire inst_data_ok;
    wire inst_data_ok1;
    wire inst_data_ok2;
    wire i_stall;
    wire d_stall;

    assign i_stall = 1'b0;
    assign d_stall = 1'b0;
    
    // cpu master
datapath u_datapath(
	//ports
	.clk              		( ~clk              	),
	.rst              		( ~resetn        		), // to high active
	.ext_int          		( int          		),
	.inst_data_ok    		( inst_data_ok    		),
    .inst_data_ok1    		( inst_data_ok1    		),
	.inst_data_ok2    		( inst_data_ok2    		),
	.inst_rdata1      		( inst_rdata1      		),
	.inst_rdata2      		( inst_rdata2      		),
	.inst_sram_en     		( inst_sram_en     		),
	.F_pc             		( pc_fetch   		),
	.data_sram_en   		( data_sram_en    		),
	.data_sram_wen  		( data_sram_wen   		),
	.data_sram_addr 		( data_sram_addr 		),
    .data_sram_rdata		( data_sram_rdata 		),
	.data_sram_wdata		( data_sram_wdata 		)
);

inst_diff u_inst_diff(
	//ports
	.inst_sram_en    		( inst_sram_en    		),
	.pc_fetch        		( pc_fetch        		),
	.inst_data_ok    		( inst_data_ok    		),
	.inst_data_ok1   		( inst_data_ok1   		),
	.inst_data_ok2   		( inst_data_ok2   		),
	.inst_rdata1     		( inst_rdata1     		),
	.inst_rdata2     		( inst_rdata2     		),
	.inst_sram_rdata 		( inst_sram_rdata 		),
	.inst_sram_addr  		( inst_sram_addr  		)
);


    // instr
    assign inst_sram_wen = 8'b0;
    assign inst_sram_wdata = 64'b0;

    // debug
    assign debug_wb_pc          = (~clk) ? u_datapath.W_master_pc : u_datapath.W_slave_pc;
    assign debug_wb_rf_wen      = (~resetn) ? 4'b0000 : ((~clk) ? {4{u_datapath.u_regfile.wen1}} : {4{u_datapath.u_regfile.wen2}});
    assign debug_wb_rf_wnum     = (~clk) ? u_datapath.u_regfile.wa1 : u_datapath.u_regfile.wa2;
    assign debug_wb_rf_wdata    = (~clk) ? u_datapath.u_regfile.wd1 : u_datapath.u_regfile.wd2;

endmodule