module mycpu_top(
    input clk,
    input resetn,  //low active
    input [5:0]ext_int,  //interrupt,high active
    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
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
	.rst              		( ~resetn        		),
	.ext_int          		( ext_int          		),
	.except_logicM    		(                		),
	.i_stall          		( i_stall          		),
	.d_stall          		( d_stall          		),
	.longest_stall    		( longest_stall    		),
	.inst_data_ok    		( inst_data_ok    		),
    .inst_data_ok1    		( inst_data_ok1    		),
	.inst_data_ok2    		( inst_data_ok2    		),
	.inst_rdata1      		( inst_rdata1      		),
	.inst_rdata2      		( inst_rdata2      		),
	.inst_sram_en     		( inst_sram_en     		),
	.F_pc             		( pc_fetch   		),
	.data_sram_enM    		( data_sram_en    		),
	.data_sram_wenM   		( data_sram_wen   		),
	.data_sram_waddrM 		( data_sram_addr 		),
    .data_sram_rdataM 		( data_sram_wdata 		),
	.data_sram_wdataM 		( data_sram_rdata 		)
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
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 64'b0;

    // debug
    assign debug_wb_pc          = datapath.pc_nowM;
    assign debug_wb_rf_wen      = {4{datapath.regfile.we3}};
    assign debug_wb_rf_wnum     = datapath.regfile.wa3;
    assign debug_wb_rf_wdata    = datapath.regfile.wd3;

    //ascii
    instdec instdec(
        .instr(inst_sram_rdata)
    );

endmodule