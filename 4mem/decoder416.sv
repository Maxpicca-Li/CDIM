`timescale 1ns/1ps
module decoder416 (
    // input wire [WIDTH-1 : 0] x,
    input wire [3 : 0] x,

    // output wire [(1<<WIDTH-1 : 0] y
    output wire [15 : 0] y

);
    assign y[0] = x==4'b0000;
    assign y[1] = x==4'b0001;
    assign y[2] = x==4'b0010;
    assign y[3] = x==4'b0011;
    assign y[4] = x==4'b0100;
    assign y[5] = x==4'b0101;
    assign y[6] = x==4'b0110;
    assign y[7] = x==4'b0111;
    assign y[8] = x==4'b1000;
    assign y[9] = x==4'b1001;
    assign y[10] = x==4'b1010;
    assign y[11] = x==4'b1011;
    assign y[12] = x==4'b1100;
    assign y[13] = x==4'b1101;
    assign y[14] = x==4'b1110;
    assign y[15] = x==4'b1111;
    /*
    always @(x) begin
        case(x)
            3'b000 : y = 8'b0000_0001;
            3'b001 : y = 8'b0000_0010;
            3'b010 : y = 8'b0000_0100;
            3'b011 : y = 8'b0000_1000;
            3'b100 : y = 8'b0001_0000;
            3'b101 : y = 8'b0010_0000;
            3'b110 : y = 8'b0100_0000;
            3'b111 : y = 8'b1000_0000;
        endcase
    end
    */
endmodule