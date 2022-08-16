`timescale 1ns / 1ps

module regfile(
    input                       clk,
    input                       rst,

    input [4:0]					ra1_a,
    output logic [31:0] 		rd1_a,

    input [4:0]					ra1_b,
    output logic [31:0] 		rd1_b,

    input 						wen1,
    input [4:0]					wa1,
    input [31:0]				wd1,

    input [4:0]					ra2_a,
    output logic [31:0] 		rd2_a,

    input [4:0]					ra2_b,
    output logic [31:0] 		rd2_b,

    input 						wen2,
    input [4:0]					wa2,
    input [31:0]				wd2
);

    reg [31:0] rf[31:0] = '{default:'0};

    // slave流水线处于更高的优先级，因为slave更接近下一条指令，故先前推slave
    assign rd1_a =  (~(|ra1_a))                  ? 32'h0000_0000 : 
                    (wen2 && ~(|(wa2 ^ ra1_a))) ? wd2 :
                    (wen1 && ~(|(wa1 ^ ra1_a))) ? wd1 :
                    rf[ra1_a];
    assign rd1_b =  (~(|ra1_b))                 ? 32'h0000_0000 : 
                    (wen2 && ~(|(wa2 ^ ra1_b))) ? wd2 :
                    (wen1 && ~(|(wa1 ^ ra1_b))) ? wd1 :
                    rf[ra1_b];
    assign rd2_a =  (~(|ra2_a))                 ? 32'h0000_0000 : 
                    (wen2 && ~(|(wa2 ^ ra2_a))) ? wd2 :
                    (wen1 && ~(|(wa1 ^ ra2_a))) ? wd1 :
                    rf[ra2_a];
    assign rd2_b =  (~(|ra2_b))                 ? 32'h0000_0000 : 
                    (wen2 && ~(|(wa2 ^ ra2_b))) ? wd2 :
                    (wen1 && ~(|(wa1 ^ ra2_b))) ? wd1 :
                    rf[ra2_b];

    always_ff @(posedge clk) begin : write_data     // sram_func
        if(wen1 && wen2 && ~(|(wa1 ^ wa2)))
            rf[wa2] <= wd2;
        else begin
            if(wen1)
                rf[wa1] <= wd1;
            if(wen2)
                rf[wa2] <= wd2;
        end
    end
endmodule
