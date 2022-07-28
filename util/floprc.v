`timescale 1ns/1ps
// 带有 reset 与 clear 的触发器
module floprc #(parameter WIDTH = 32) (
    input wire clk,rst,clear,
    input wire[WIDTH-1:0]d,
    output reg[WIDTH-1:0]q
);
    always @(posedge clk) begin
        if(rst) q<=0;
        else if (clear) q<=0;
        else q<=d;
    end
    
endmodule