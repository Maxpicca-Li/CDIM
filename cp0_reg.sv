 `timescale 1ns / 1ps

 `include "defines.vh" 
 module cp0_reg(
 	input  wire clk,
 	input  wire rst,
 	input  wire we_i,
	input  wire is_in_delayslot_i,
 	input  wire[4:0] waddr_i,
 	input  wire[4:0] raddr_i,
 	input  wire[5:0] int_i,
	input  wire[`RegBus] data_i,
 	input  wire[`RegBus] excepttype_i,
 	input  wire[`RegBus] current_inst_addr_i,
 	input  wire[`RegBus] bad_addr_i,

	output wire[`RegBus] data_o,
	output reg timer_int_o,
 	output reg[`RegBus] count_o,
 	output reg[`RegBus] compare_o,
 	output reg[`RegBus] status_o,
 	output reg[`RegBus] cause_o,
 	output reg[`RegBus] epc_o,
 	output reg[`RegBus] config_o,
 	output reg[`RegBus] prid_o,
 	output reg[`RegBus] badvaddr_o
);

 	always_ff @( posedge clk ) begin : get_reg_value
 		if(rst == `RstEnable) begin
 			count_o <= `ZeroWord;
 			compare_o <= `ZeroWord;
 			status_o <= 32'b00000000010000000000000000000000;  // bev??????????1
 			cause_o <= `ZeroWord;
 			epc_o <= `ZeroWord;
 			config_o <= 32'b00000000000000001000000000000000;
 			prid_o <= 32'b00000000010011000000000100000010;
 			timer_int_o <= `InterruptNotAssert;
 		end else begin
 			count_o <= count_o + 1;
			cause_o[15:10] <= int_i;
 			if(compare_o != `ZeroWord && count_o == compare_o) begin
 				/* code */
 				timer_int_o <= `InterruptAssert;
 			end
 			if(we_i == `WriteEnable) begin
 				/* code */
 				case (waddr_i)
 					`CP0_REG_COUNT:begin 
 						count_o <= data_i;
 					end
 					`CP0_REG_COMPARE:begin 
 						compare_o <= data_i;
 						timer_int_o <= `InterruptNotAssert;
 					end
 					`CP0_REG_STATUS:begin 
 						// status_o <= data_i;
						 status_o[0] <= data_i[0];
						 status_o[15:8] <= data_i[15:8];
 					end
 					`CP0_REG_CAUSE:begin 
 						cause_o[9:8] <= data_i[9:8];
 					end
 					`CP0_REG_EPC:begin 
 						epc_o <= data_i;
 					end
 					default : /* default */;
 				endcase
 			end
 			case (excepttype_i)
 				// INT
 				32'h00000001:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b00000;
 				end
 				// AdEL
 				32'h00000004:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b00100;
 					badvaddr_o <= bad_addr_i;
 				end
 				//AdES
 				32'h00000005:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b00101;
 					badvaddr_o <= bad_addr_i;
 				end
 				// SYSCALL
 				32'h00000008:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b01000;
 				end
 				// BREAK
 				32'h00000009:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b01001;
 				end
 				// RI
 				32'h0000000a:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b01010;
 				end
 				// Ov
 				32'h0000000c:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b01100;
 				end
 				32'h0000000d:begin 
 					if(is_in_delayslot_i == `InDelaySlot) begin
 						/* code */
 						epc_o <= current_inst_addr_i - 4;
 						cause_o[31] <= 1'b1;
 					end else begin 
 						epc_o <= current_inst_addr_i;
 						cause_o[31] <= 1'b0;
 					end
 					status_o[1] <= 1'b1;
 					cause_o[6:2] <= 5'b01101;
 				end
 				32'h0000000e:begin 
 					status_o[1] <= 1'b0;
 				end
 				default : /* default */;
 			endcase
 		end
 	end

	//read
	wire count, compare, status, cause, epc, prid, config1, badvaddr;
	assign count    = (~rst & ~(|( raddr_i ^ `CP0_REG_COUNT     )));
	assign compare  = (~rst & ~(|( raddr_i ^ `CP0_REG_COMPARE   )));
	assign status   = (~rst & ~(|( raddr_i ^ `CP0_REG_STATUS    )));
	assign cause    = (~rst & ~(|( raddr_i ^ `CP0_REG_CAUSE     )));
	assign epc      = (~rst & ~(|( raddr_i ^ `CP0_REG_EPC       )));
	assign prid     = (~rst & ~(|( raddr_i ^ `CP0_REG_PRID      )));
	assign config1  = (~rst & ~(|( raddr_i ^ `CP0_REG_CONFIG    )));
	assign badvaddr = (~rst & ~(|( raddr_i ^ `CP0_REG_BADVADDR  )));

	assign data_o =   ( {32{rst}     } & 32'd0     )
					| ( {32{count}   } & count_o   )
					| ( {32{compare} } & compare_o )
					| ( {32{status}  } & status_o  )
					| ( {32{cause}   } & cause_o   )
					| ( {32{epc}     } & epc_o     )
					| ( {32{prid}    } & prid_o    )
					| ( {32{config1} } & config_o  )
					| ( {32{badvaddr}} & badvaddr_o);

 endmodule
