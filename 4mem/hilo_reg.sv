`timescale 1ns / 1ps
/*
`include "defines.vh"
module hilo_reg(
        input wire clk,
        input wire rst,
        input wire wen,
        input wire [7 :0] aluop,
        input wire [31:0] rs_value,
        input wire [63:0] hilo_i,
        output wire[63:0] hilo_o // hilo当前的值
    );

    reg [63:0] hilo_reg;

    // 写寄存器
    // 1. MTHI {rs_value, lo}
    // 2. MTLO {hi, rs_value}
    // 3. hilo_i
	always_ff @(posedge clk) begin
        if(rst)
            hilo_reg <= 0;
        else if(wen) begin
            if (~(|(aluop ^ `ALUOP_MTHI))) 
                hilo_reg <= {rs_value,hilo_reg[31:0]};
            else if (~(|(aluop ^ `ALUOP_MTLO))) 
                hilo_reg <= {hilo_reg[63:32],rs_value};
            else if (~(|(aluop ^ `ALUOP_MADD)) || ~(|(aluop ^ `ALUOP_MADDU))) 
                hilo_reg <= hilo_reg + hilo_i;
            else if (~(|(aluop ^ `ALUOP_MSUB)) || ~(|(aluop ^ `ALUOP_MSUBU))) 
                hilo_reg <= hilo_reg - hilo_i;
            else
                hilo_reg <= hilo_i;
        end else 
            hilo_reg <= hilo_reg;
    end

	// 读寄存器：前MUL后MF*这种需要在MUL的M阶段，返回给MF*的E阶段数据
    // M阶段数据前推
	assign hilo_o = hilo_reg;

endmodule
*/

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