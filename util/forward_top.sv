`timescale 1ns/1ps
module forward_top(
	// 计算结果
	input                   alu_wen1,
    input [ 4:0]            alu_waddr1,
    input [31:0]            alu_wdata1,
    input                   alu_wen2,
    input [ 4:0]            alu_waddr2,
    input [31:0]            alu_wdata2,
    input                   alu_wen3,
    input [ 4:0]            alu_waddr3,
    input [31:0]            alu_wdata3,
    input                   alu_wen4,
    input [ 4:0]            alu_waddr4,
    input [31:0]            alu_wdata4,
    // 访存结果
    // input                   memtoReg,
    // input [ 4:0]            mem_waddr,
    // input [31:0]            mem_rdata,
    
    input [ 4:0]            master_rs,
    input [31:0]            master_rs_value_tmp,
    output logic [31:0]     master_rs_value,
    input [ 4:0]            master_rt,
    input [31:0]            master_rt_value_tmp,
    output logic [31:0]     master_rt_value,
    
    input [ 4:0]            slave_rs,
    input [31:0]            slave_rs_value_tmp,
    output logic [31:0]     slave_rs_value,
    input [ 4:0]            slave_rt,
    input [31:0]            slave_rt_value_tmp,
    output logic [31:0]     slave_rt_value

);

forward_mux u_forward_mux_master_rs_value(
	//ports
	.alu_wen1     		( alu_wen1     		),
	.alu_waddr1   		( alu_waddr1   		),
	.alu_wdata1   		( alu_wdata1   		),
	.alu_wen2     		( alu_wen2     		),
	.alu_waddr2   		( alu_waddr2   		),
	.alu_wdata2   		( alu_wdata2   		),
	.alu_wen3     		( alu_wen3     		),
	.alu_waddr3   		( alu_waddr3   		),
	.alu_wdata3   		( alu_wdata3   		),
	.alu_wen4     		( alu_wen4     		),
	.alu_waddr4   		( alu_waddr4   		),
	.alu_wdata4   		( alu_wdata4   		),
	// .memtoReg     		( memtoReg     		),
	// .mem_waddr    		( mem_waddr    		),
	// .mem_rdata    		( mem_rdata    		),
	.reg_addr     		( master_rs     	),
	.reg_data_tmp 		( master_rs_value_tmp ),
	.reg_data     		( master_rs_value )
);

forward_mux u_forward_mux_master_rt_value(
	//ports
	.alu_wen1     		( alu_wen1     		),
	.alu_waddr1   		( alu_waddr1   		),
	.alu_wdata1   		( alu_wdata1   		),
	.alu_wen2     		( alu_wen2     		),
	.alu_waddr2   		( alu_waddr2   		),
	.alu_wdata2   		( alu_wdata2   		),
	.alu_wen3     		( alu_wen3     		),
	.alu_waddr3   		( alu_waddr3   		),
	.alu_wdata3   		( alu_wdata3   		),
	.alu_wen4     		( alu_wen4     		),
	.alu_waddr4   		( alu_waddr4   		),
	.alu_wdata4   		( alu_wdata4   		),
	// .memtoReg     		( memtoReg     		),
	// .mem_waddr    		( mem_waddr    		),
	// .mem_rdata    		( mem_rdata    		),
	.reg_addr     		( master_rt     	),
	.reg_data_tmp 		( master_rt_value_tmp ),
	.reg_data     		( master_rt_value )
);

forward_mux u_forward_mux_slave_rs_value(
	//ports
	.alu_wen1     		( alu_wen1     		),
	.alu_waddr1   		( alu_waddr1   		),
	.alu_wdata1   		( alu_wdata1   		),
	.alu_wen2     		( alu_wen2     		),
	.alu_waddr2   		( alu_waddr2   		),
	.alu_wdata2   		( alu_wdata2   		),
	.alu_wen3     		( alu_wen3     		),
	.alu_waddr3   		( alu_waddr3   		),
	.alu_wdata3   		( alu_wdata3   		),
	.alu_wen4     		( alu_wen4     		),
	.alu_waddr4   		( alu_waddr4   		),
	.alu_wdata4   		( alu_wdata4   		),
	// .memtoReg     		( memtoReg     		),
	// .mem_waddr    		( mem_waddr    		),
	// .mem_rdata    		( mem_rdata    		),
	.reg_addr     		( slave_rs     	),
	.reg_data_tmp 		( slave_rs_value_tmp ),
	.reg_data     		( slave_rs_value  )
);

forward_mux u_forward_mux_slave_rt_value(
	//ports
	.alu_wen1     		( alu_wen1     		),
	.alu_waddr1   		( alu_waddr1   		),
	.alu_wdata1   		( alu_wdata1   		),
	.alu_wen2     		( alu_wen2     		),
	.alu_waddr2   		( alu_waddr2   		),
	.alu_wdata2   		( alu_wdata2   		),
	.alu_wen3     		( alu_wen3     		),
	.alu_waddr3   		( alu_waddr3   		),
	.alu_wdata3   		( alu_wdata3   		),
	.alu_wen4     		( alu_wen4     		),
	.alu_waddr4   		( alu_waddr4   		),
	.alu_wdata4   		( alu_wdata4   		),
	// .memtoReg     		( memtoReg     		),
	// .mem_waddr    		( mem_waddr    		),
	// .mem_rdata    		( mem_rdata    		),
	.reg_addr     		( slave_rt     	),
	.reg_data_tmp 		( slave_rt_value_tmp ),
	.reg_data     		( slave_rt_value  )
);


endmodule