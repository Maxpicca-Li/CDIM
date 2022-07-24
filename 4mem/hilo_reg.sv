`timescale 1ns / 1ps
// `include "defines.vh"

module hilo_reg(
        input wire clk,
        input wire rst,
        input wire M_we,
        input wire W_we,
        input wire [63:0] M_hilo,
		input wire [63:0] W_hilo,

        output wire[63:0] hilo_o // hilo当前的值
    );

    reg [63:0] hilo_reg;

    // 写寄存器
	always_ff @(posedge clk) begin
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
    // M阶段数据前推
	assign hilo_o = M_we ? M_hilo : 
					W_we ? W_hilo :
					hilo_reg;

endmodule