`timescale 1ns/1ps

module mux2 #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0]a,b,
    input wire sel,
    output wire [WIDTH-1:0]y
);
    assign y = (sel==1'b0) ? a : b; // 按照上下结构，上0a，下1b
endmodule