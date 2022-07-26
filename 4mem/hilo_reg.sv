`timescale 1ns / 1ps

module hilo_reg(
        input wire clk,
        input wire rst,
        input wire wen,
        input wire [63:0] hilo_i,
        output wire[63:0] hilo_o // hilo当前的值
    );

    reg [63:0] hilo_reg;

    // 写寄存器
	always_ff @(posedge clk) begin
        if(rst) begin
            hilo_reg <= 0;
        end
        else if (wen) begin
            hilo_reg <= hilo_i;
        end
        else begin
            hilo_reg <= hilo_reg;
        end
    end

	// 读寄存器：前MUL后MF*这种需要在MUL的M阶段，返回给MF*的E阶段数据
    // M阶段数据前推
	assign hilo_o = hilo_reg;

endmodule