`timescale 1ns / 1ps
`include "defines.vh"

module hilo_reg(
	input wire clk,rst,we,		// 时钟,复位,使能
	// input wire[31:0] hi,lo,
	input wire[63:0] hilo_i,
	
	// output reg[31:0] hilo_res,  // 具体的hilo操作直接在alu里面进行了(一定程度上增加了带宽)
	output reg[63:0] hilo  // hilo current data
    );
	
	always @(negedge clk) begin
		if(rst) begin
			// hi_o <= `ZeroWord;
			// lo_o <= `ZeroWord;
			hilo <= {`ZeroWord,`ZeroWord};
		end else if (we) begin
			// hi_o <= hi;
			// lo_o <= lo;
			hilo <= hilo_i;
		end else begin
			hilo <= hilo;
		end
	end
endmodule

// module hilo_reg(
//                 input wire        clk,rst,we, //both write lo and hi
//                 input wire [1:0] mfhi_loM,

//                 input wire [63:0] hilo_i,
//                 output wire [31:0] hilo_o,
//                 output reg [63:0] hilo
//                 );

//    // wire [63:0] hilo_ii;
//    always @(posedge clk) begin
//       if(rst)
//          hilo <= 0;
//       else if(we)
//          hilo <= hilo_i;
//       else
//          hilo <= hilo;
//    end

//    // assign hilo_ii = ( {64{~rst & we}} & hilo_i );

//    // 读hilo逻辑；
//    wire mfhi, mflo;
//    assign mfhi = mfhi_loM[1];
//    assign mflo = mfhi_loM[0];

//    assign hilo_o = ({32{mfhi}} & hilo[63:32]) | ({32{mflo}} & hilo[31:0]);
// endmodule

