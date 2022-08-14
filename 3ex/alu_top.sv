`timescale 1ns/1ps
module alu_top(
    input               clk,rst,
    input               M_ena,
    input               M_flush,

    input               hilo_write1,
    input               mul_en1,
    input               div_en1,
    input               exp1,
    input  logic [7 :0] aluop1,
    input  logic [31:0] a1,
    input  logic [31:0] b1,
    output logic        overflow1,
    output logic [31:0] y1,

    input               hilo_write2,
    input               mul_en2,
    input               div_en2,
    input               exp2,
    input  logic [7 :0] aluop2,
    input  logic [31:0] a2,
    input  logic [31:0] b2,
    output logic        overflow2,
    output logic [31:0] y2,

    // all
    input  logic [31:0] cp0_rdata,
    input  logic [31:0] pc_plus8,
    input               is_link_pc8,
    output              E_alu_stall
);

logic [31:0] y1_tmp;
logic [31:0] mul_a, mul_b, div_a, div_b;
logic        mul_sign1, mul_start1, div_sign1, div_start1;
logic        mul_sign2, mul_start2, div_sign2, div_start2;
logic        mul_sign , mul_start , div_sign , div_start ;
logic        mul_ready, div_ready;
logic        hilo_wen;
logic [63:0] hilo, hilo_wdata, mul_result, div_result;
logic [63:0] alu_out64_1,alu_out64_2;

assign E_alu_stall = ((mul_en1 | mul_en2) & !mul_ready) | ((div_en1 | div_en2) & !div_ready);
assign y1 = {32{ is_link_pc8}} & pc_plus8 |
            {32{!is_link_pc8}} & y1_tmp   ;

alu_master u_aluA(
    //ports
    .clk                   ( clk                    ),
    .rst                   ( rst                    ),
    .aluop                 ( aluop1                 ),
    .a                     ( a1                     ),
    .b                     ( b1                     ),
    .cp0_data              ( cp0_rdata              ),
    .hilo                  ( hilo                   ),
    .y                     ( y1_tmp                 ),
    .aluout_64             ( alu_out64_1            ),
    .overflow              ( overflow1              ),
    .mul_start             ( mul_start1             ),
    .mul_sign              ( mul_sign1              ),
    .div_start             ( div_start1             ),
    .div_sign              ( div_sign1              ),
    .mul_ready             ( mul_ready              ),
    .mul_result            ( mul_result             ),
    .div_ready             ( div_ready              ),
    .div_result            ( div_result             )
);

alu_master u_aluB(
    //ports
    .clk                   ( clk                    ),
    .rst                   ( rst                    ),
    .aluop                 ( aluop2                 ),
    .a                     ( a2                     ),
    .b                     ( b2                     ),
    .cp0_data              ( 0                      ),
    .hilo                  ( hilo                   ),
    .y                     ( y2                     ),
    .aluout_64             ( alu_out64_2            ),
    .overflow              ( overflow2              ),
    .mul_start             ( mul_start2             ),
    .mul_sign              ( mul_sign2              ),
    .div_start             ( div_start2             ),
    .div_sign              ( div_sign2              ),
    .mul_ready             ( mul_ready              ),
    .mul_result            ( mul_result             ),
    .div_ready             ( div_ready              ),
    .div_result            ( div_result             )
);


always_comb begin
    if(mul_en1) begin
        mul_a = a1;
        mul_b = b1;
        mul_sign = mul_sign1;
        mul_start = mul_start1;
    end else begin
        mul_a = a2;
        mul_b = b2;
        mul_sign = mul_sign2;
        mul_start = mul_start2;
    end
end
always_comb begin
    if(div_en1) begin
        div_a = a1;
        div_b = b1;
        div_sign = div_sign1;
        div_start = div_start1;
    end else begin
        div_a = a2;
        div_b = b2;
        div_sign = div_sign2;
        div_start = div_start2;
    end
end
mul mul_inst(
    .clk(clk),
    .rst(rst),
    .a(mul_a),
    .b(mul_b),
    .sign(mul_sign),
    .start(mul_start),
    .result(mul_result),
    .ready(mul_ready)
);
div mydiv(
    .clk(clk),
    .rst(rst),
    .signed_div_i(div_sign), 
    .opdata1_i(div_a),
    .opdata2_i(div_b),
    
    .start_i(div_start),
    .annul_i(1'b0),
    .result_o(div_result),
    .ready_o(div_ready)
);

// E阶段写，M阶段出结果
assign hilo_wen = ((hilo_write2 & !exp1 & !exp2) | (hilo_write1 & !exp1)) & M_ena & !M_flush;
assign hilo_wdata = {64{ hilo_write2}} & alu_out64_2 |
                    {64{!hilo_write2}} & alu_out64_1 ;
hilo_reg u_hilo_reg(
    .clk                ( clk                ),
    .rst                ( rst                ),
    .wen                ( hilo_wen           ),
    .hilo_i             ( hilo_wdata         ),  
    .hilo_o             ( hilo               )
);

endmodule