module forward_top(
    input                   E_slave_reg_wen,
    input [ 4:0]            E_slave_reg_waddr,
    input [31:0]            E_slave_reg_wdata,
    input                   E_master_reg_wen,
    input [ 4:0]            E_master_reg_waddr,
    input [31:0]            E_master_reg_wdata,
    input                   M_slave_reg_wen,
    input [ 4:0]            M_slave_reg_waddr,
    input [31:0]            M_slave_reg_wdata,
    input                   M_master_reg_wen,
    input [ 4:0]            M_master_reg_waddr,
    input [31:0]            M_master_reg_wdata,
    
    input [ 4:0]            D_master_rs,
    input [31:0]            D_master_rs_data,
    output logic [31:0]     D_master_rs_value,
    input [ 4:0]            D_master_rt,
    input [31:0]            D_master_rt_data,
    output logic [31:0]     D_master_rt_value,
    
    input [ 4:0]            D_slave_rs,
    input [31:0]            D_slave_rs_data,
    output logic [31:0]     D_slave_rs_value,
    input [ 4:0]            D_slave_rt,
    input [31:0]            D_slave_rt_data,
    output logic [31:0]     D_slave_rt_value

);

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
	.reg_data           		( D_master_rs_data ),
	.result_data        		( D_master_rs_value)
);

forwarding_mux forwarding_mux_rt_master(
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
	.reg_addr           		( D_master_rt           	),
	.reg_data           		( D_master_rt_data          ),
	.result_data        		( D_master_rt_value         )
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

forwarding_mux forwarding_mux_rt_slave(
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
	.reg_addr           		( D_slave_rt            	),
	.reg_data           		( D_slave_rt_data           ),
	.result_data        		( D_slave_rt_value          )
);
endmodule