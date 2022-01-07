`timescale 1ns / 1ps
`include "defines.vh"

module hilo_reg(
        input wire clk,
        input wire rst,
        input wire M_we,
        input wire W_we,
        input wire [63:0] M_hilo,
		input wire [63:0] W_hilo,

        output wire[63:0] hilo_o  // hilo current data
    );

    reg [63:0] hilo_reg;

    // 写寄存器
	always @(posedge clk) begin
        if(rst) begin
            hilo_reg <= {`ZeroWord,`ZeroWord};
        end
        else if (W_we) begin
            hilo_reg <= W_hilo;
        end
        else begin
            hilo_reg <= hilo_reg;
        end
    end

	// 读寄存器：前MUL后MF*这种需要在MUL的M阶段，返回给MF*的E阶段数据
	assign hilo_o = M_we ? M_hilo : 
					W_we ? W_hilo :
					hilo_reg;

endmodule


// module hilo_reg(
// 	input wire clk,rst,we,		// 时钟,复位,使能
// 	// input wire[31:0] hi,lo,
// 	input wire[63:0] hilo_i,
	
// 	// output reg[31:0] hilo_res,  // 具体的hilo操作直接在alu里面进行了(一定程度上增加了带宽)
// 	output reg[63:0] hilo  // hilo current data
//     );
	
// 	always @(negedge clk) begin
// 		if(rst) begin
// 			// hi_o <= `ZeroWord;
// 			// lo_o <= `ZeroWord;
// 			hilo <= {`ZeroWord,`ZeroWord};
// 		end else if (we) begin
// 			// hi_o <= hi;
// 			// lo_o <= lo;
// 			hilo <= hilo_i;
// 		end else begin
// 			hilo <= hilo;
// 		end
// 	end
// endmodule