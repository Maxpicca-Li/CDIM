`timescale 1ns / 1ps
`include "defines.vh"

module alu_slave(
    input  logic [7:0]aluop,
    input  logic [31:0]a,
    input  logic [31:0]b,
    output logic [31:0] y,
    output logic overflow
    );

    always_comb begin
        overflow = 1'b0;
        case (aluop)
            // arith
            `ALUOP_ADD   : begin
               y = a + b; 
               overflow = (a[31] == b[31]) & (y[31] != a[31]);
            end
            `ALUOP_ADDU  : begin
                y = a + b;
            end
            `ALUOP_SUB   : begin 
                y = a - b;
                overflow = (a[31]^b[31]) & (y[31]==b[31]);
            end
            `ALUOP_SUBU  : begin 
                y = a - b;
            end
            `ALUOP_SLT   : y = $signed(a) < $signed(b);
            `ALUOP_SLTU  : y = a < b;
            `ALUOP_SLTI  :  begin//y = a < b;
                case(a[31])
                    1'b1: begin
                        if(b[31] == 1'b1) begin
                            y = a < b;
                        end
                        else begin
                            y = 1'b1;
                        end
                    end
                    1'b0: begin
                        if(b[31] == 1'b1) begin
                            y = 1'b0;
                        end
                        else begin
                            y = a < b;
                        end
                    end
                endcase
            end
            `ALUOP_SLTIU : y = a < b;
            // logic
            `ALUOP_AND   : y = a & b;
            `ALUOP_OR    : y = a | b;
            `ALUOP_NOR   : y = ~ (a | b);
            `ALUOP_XOR   : y = a ^ b;
            `ALUOP_LUI   : y ={b[15:0],16'b0};
            // shift
            `ALUOP_SLL   : y = b << a[4:0];
            `ALUOP_SLLV: y = b << a[4:0];
            `ALUOP_SRL: y = b >> a[4:0];
            `ALUOP_SRLV: y = b >> a[4:0];
            `ALUOP_SRA: y = $signed(b) >>> a[4:0];
            `ALUOP_SRAV: y = $signed(b) >>> a[4:0];
            default      : y = 32'b0;
        endcase
    end
        
endmodule
