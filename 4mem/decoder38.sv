`timescale 1ns/1ps
module decoder38 (
    // input wire [WIDTH-1 : 0] x,
    input wire [2 : 0] x,

    // output wire [(1<<WIDTH-1 : 0] y
    output wire [7 : 0] y

);
    assign y[0] = x==3'b000;
    assign y[1] = x==3'b001;
    assign y[2] = x==3'b010;
    assign y[3] = x==3'b011;
    assign y[4] = x==3'b100;
    assign y[5] = x==3'b101;
    assign y[6] = x==3'b110;
    assign y[7] = x==3'b111;
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