`timescale 1ns/1ps
module forwardE_top(
    // M的计算结果
    input                   M_slave_alu_wen,
    input [ 4:0]            M_slave_alu_waddr,
    input [31:0]            M_slave_alu_wdata,
    input                   M_master_alu_wen,
    input [ 4:0]            M_master_alu_waddr,
    input [31:0]            M_master_alu_wdata,
    input                   W_slave_alu_wen,
    input [ 4:0]            W_slave_alu_waddr,
    input [31:0]            W_slave_alu_wdata,
    input                   W_master_alu_wen,
    input [ 4:0]            W_master_alu_waddr,
    input [31:0]            W_master_alu_wdata,
    // W的访存结果
    input                   W_master_memtoReg,
    input [ 4:0]            W_master_mem_waddr,
    input [31:0]            W_master_mem_rdata,
    
    input [ 4:0]            E_master_rs,
    input [31:0]            E_master_rs_value_a,
    output logic [31:0]     E_master_rs_value,
    input [ 4:0]            E_master_rt,
    input [31:0]            E_master_rt_value_a,
    output logic [31:0]     E_master_rt_value,
    
    input [ 4:0]            E_slave_rs,
    input [31:0]            E_slave_rs_value_a,
    output logic [31:0]     E_slave_rs_value,
    input [ 4:0]            E_slave_rt,
    input [31:0]            E_slave_rt_value_a,
    output logic [31:0]     E_slave_rt_value

);

forwardE_mux forwardE_mux_rs_master(
	//ports
	.M_slave_alu_wen    		( M_slave_alu_wen    		),
	.M_slave_alu_waddr  		( M_slave_alu_waddr  		),
	.M_slave_alu_wdata  		( M_slave_alu_wdata  		),
	.M_master_alu_wen   		( M_master_alu_wen   		),
	.M_master_alu_waddr 		( M_master_alu_waddr 		),
	.M_master_alu_wdata 		( M_master_alu_wdata 		),
	.W_slave_alu_wen    		( W_slave_alu_wen    		),
	.W_slave_alu_waddr  		( W_slave_alu_waddr  		),
	.W_slave_alu_wdata  		( W_slave_alu_wdata  		),
	.W_master_alu_wen   		( W_master_alu_wen   		),
	.W_master_alu_waddr 		( W_master_alu_waddr 		),
	.W_master_alu_wdata 		( W_master_alu_wdata 		),
	.W_master_memtoReg  		( W_master_memtoReg  		),
	.W_master_mem_waddr 		( W_master_mem_waddr 		),
	.W_master_mem_rdata 		( W_master_mem_rdata 		),
	.reg_addr           		( E_master_rs           	),
	.reg_data           		( E_master_rs_value_a       ),
	.result_data        		( E_master_rs_value         )
);

forwardE_mux forwardE_mux_rt_master(
	//ports
	.M_slave_alu_wen    		( M_slave_alu_wen    		),
	.M_slave_alu_waddr  		( M_slave_alu_waddr  		),
	.M_slave_alu_wdata  		( M_slave_alu_wdata  		),
	.M_master_alu_wen   		( M_master_alu_wen   		),
	.M_master_alu_waddr 		( M_master_alu_waddr 		),
	.M_master_alu_wdata 		( M_master_alu_wdata 		),
	.W_slave_alu_wen    		( W_slave_alu_wen    		),
	.W_slave_alu_waddr  		( W_slave_alu_waddr  		),
	.W_slave_alu_wdata  		( W_slave_alu_wdata  		),
	.W_master_alu_wen   		( W_master_alu_wen   		),
	.W_master_alu_waddr 		( W_master_alu_waddr 		),
	.W_master_alu_wdata 		( W_master_alu_wdata 		),
	.W_master_memtoReg  		( W_master_memtoReg  		),
	.W_master_mem_waddr 		( W_master_mem_waddr 		),
	.W_master_mem_rdata 		( W_master_mem_rdata 		),
	.reg_addr           		( E_master_rt           	),
	.reg_data           		( E_master_rt_value_a       ),
	.result_data        		( E_master_rt_value         )
);

forwardE_mux forwardE_mux_rs_slave(
	//ports
	.M_slave_alu_wen    		( M_slave_alu_wen    		),
	.M_slave_alu_waddr  		( M_slave_alu_waddr  		),
	.M_slave_alu_wdata  		( M_slave_alu_wdata  		),
	.M_master_alu_wen   		( M_master_alu_wen   		),
	.M_master_alu_waddr 		( M_master_alu_waddr 		),
	.M_master_alu_wdata 		( M_master_alu_wdata 		),
	.W_slave_alu_wen    		( W_slave_alu_wen    		),
	.W_slave_alu_waddr  		( W_slave_alu_waddr  		),
	.W_slave_alu_wdata  		( W_slave_alu_wdata  		),
	.W_master_alu_wen   		( W_master_alu_wen   		),
	.W_master_alu_waddr 		( W_master_alu_waddr 		),
	.W_master_alu_wdata 		( W_master_alu_wdata 		),
	.W_master_memtoReg  		( W_master_memtoReg  		),
	.W_master_mem_waddr 		( W_master_mem_waddr 		),
	.W_master_mem_rdata 		( W_master_mem_rdata 		),
	.reg_addr           		( E_slave_rs            	),
	.reg_data           		( E_slave_rs_value_a        ),
	.result_data        		( E_slave_rs_value          )
);

forwardE_mux forwardE_mux_rt_slave(
	//ports
	.M_slave_alu_wen    		( M_slave_alu_wen    		),
	.M_slave_alu_waddr  		( M_slave_alu_waddr  		),
	.M_slave_alu_wdata  		( M_slave_alu_wdata  		),
	.M_master_alu_wen   		( M_master_alu_wen   		),
	.M_master_alu_waddr 		( M_master_alu_waddr 		),
	.M_master_alu_wdata 		( M_master_alu_wdata 		),
	.W_slave_alu_wen    		( W_slave_alu_wen    		),
	.W_slave_alu_waddr  		( W_slave_alu_waddr  		),
	.W_slave_alu_wdata  		( W_slave_alu_wdata  		),
	.W_master_alu_wen   		( W_master_alu_wen   		),
	.W_master_alu_waddr 		( W_master_alu_waddr 		),
	.W_master_alu_wdata 		( W_master_alu_wdata 		),
	.W_master_memtoReg  		( W_master_memtoReg  		),
	.W_master_mem_waddr 		( W_master_mem_waddr 		),
	.W_master_mem_rdata 		( W_master_mem_rdata 		),
	.reg_addr           		( E_slave_rt            	),
	.reg_data           		( E_slave_rt_value_a        ),
	.result_data        		( E_slave_rt_value          )
);
endmodule