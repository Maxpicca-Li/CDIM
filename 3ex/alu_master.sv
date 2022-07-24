`timescale 1ns / 1ps
`include "defines.vh"

module alu_master(
    input  logic clk,rst,
    input  logic [7:0]aluop,
    input  logic [31:0]a,
    input  logic [31:0]b,
    input  logic [31:0]cp0_data,
    input  logic [63:0]hilo, // hilo source data

    output logic stall_alu,
    output logic [31:0] y,
    output logic [63:0]aluout_64,
    output logic overflow
    );
    
    logic stall_div;
    logic stall_mul;
    assign stall_alu = stall_mul | stall_div;

    logic start_mul;
    logic mul_sign;
    logic [63:0] mul_result;
    logic mul_ready;

    logic start_div;
    logic signed_div;
    logic div_ready;
    logic [7 :0] save_div_type;
    logic [31:0] multa,multb;
    logic [31:0] save_div_a,save_div_b;
    logic [63:0] save_div_result;
    logic [63:0] div_result;
    logic [63:0] temp_aluout_64;

    integer i;
    
    //multiply module
    assign multa = (aluop == `ALUOP_MULT) && (a[31] == 1'b1) ? (~a + 1) : a;
    assign multb = (aluop == `ALUOP_MULT) && (b[31] == 1'b1) ? (~b + 1) : b;
    
    assign aluout_64= temp_aluout_64;

    always_comb begin
        stall_mul = 1'b0;
        stall_div = 1'b0;
        start_mul = 1'b0;
        mul_sign = 1'b0;
        overflow = 1'b0;
        start_div = `DivStop;
        signed_div =1'b0;
        temp_aluout_64 = 0;
        y = 0;
        case (aluop)
            //算术指令
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
            `ALUOP_SLT   : y = {31'd0,$signed(a) < $signed(b)};
            `ALUOP_SLTU  : y = {31'd0,a < b};
            `ALUOP_SLTI  :  begin//y = a < b;
                case(a[31])
                    1'b1: begin
                        if(b[31] == 1'b1) begin
                            y = {31'd0,a < b};
                        end
                        else begin
                            y = {31'd0,1'b1};
                        end
                    end
                    1'b0: begin
                        if(b[31] == 1'b1) begin
                            y = 0;
                        end
                        else begin
                            y = {31'd0,a < b};
                        end
                    end
                endcase
            end
            `ALUOP_SLTIU : y = {31'd0,a < b};
            //逻辑指令
            `ALUOP_AND   : y = a & b;
            `ALUOP_OR    : y = a | b;
            `ALUOP_NOR   : y = ~ (a | b);
            `ALUOP_XOR   : y = a ^ b;
            `ALUOP_LUI   : y ={b[15:0],16'b0};
            // 移位指令
            `ALUOP_SLL   : y = b << a[4:0];
            `ALUOP_SLLV: y = b << a[4:0];
            `ALUOP_SRL: y = b >> a[4:0];
            `ALUOP_SRLV: y = b >> a[4:0];
            `ALUOP_SRA: y = $signed(b) >>> a[4:0];
            `ALUOP_SRAV: y = $signed(b) >>> a[4:0];
            // 数据移动指令
            `ALUOP_MTHI: temp_aluout_64 = {a,hilo[31:0]};
            `ALUOP_MTLO: temp_aluout_64 = {hilo[63:32],a};
            `ALUOP_MFHI: y = hilo[63:32];
            `ALUOP_MFLO: y = hilo[31:0];
            `ALUOP_MFC0: y = cp0_data;
            // 旋转指令
            `ALUOP_ROTR  : y = (b << (32 - a[4:0])) + (b >> a[4:0]);
            // 前导计数指令
            `ALUOP_CLO: begin
                y = 32;
                for(i=31;i>=0;i--) begin // FIXME: 可以直接写for循环吗
                    if(!a[i]) begin
                        y = 31-i;
                        break;
                    end
                end
            end
            `ALUOP_CLZ: begin
                y = 32;
                for(i=31;i>=0;i--) begin
                    if(a[i]) begin
                        y = 31-i;
                        break;
                    end
                end
            end
            // 乘除法指令
            `ALUOP_MULT  : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    mul_sign = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    mul_sign = 1'b1;
                    stall_mul = 1'b0;
                    temp_aluout_64 = mul_result;
                    y = mul_result[31:0];
                end
            end
            `ALUOP_MULTU : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    stall_mul = 1'b0;
                    temp_aluout_64 = mul_result;
                    y = mul_result[31:0];
                end
            end
            `ALUOP_MADD  : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    mul_sign = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    mul_sign = 1'b1;
                    stall_mul = 1'b0;
                    temp_aluout_64 = hilo + mul_result;  // 无算数异常
                end
            end
            `ALUOP_MSUB  : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    mul_sign = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    mul_sign = 1'b1;
                    stall_mul = 1'b0;
                    temp_aluout_64 = hilo - mul_result;  // 无算数异常
                end
            end
            `ALUOP_MADDU : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    stall_mul = 1'b0;
                    temp_aluout_64 = hilo + mul_result;
                end
            end
            `ALUOP_MSUBU : begin
                if (!mul_ready) begin
                    start_mul = 1'b1;
                    stall_mul = 1'b1;
                end else if (mul_ready) begin
                    start_mul = 1'b0;
                    stall_mul = 1'b0;
                    temp_aluout_64 = hilo - mul_result;
                end
            end
            `ALUOP_DIV   :begin
                if(!div_ready && save_div_a==a && save_div_b==b && save_div_type==aluop) begin
                    start_div = 1'b0;
                    signed_div =1'b1;
                    stall_div =1'b0;
                    temp_aluout_64 = save_div_result;
                end else if(div_ready ==1'b0) begin // 没准备好
                    start_div = 1'b1;
                    signed_div =1'b1;
                    stall_div =1'b1;
                end else begin // 准备好了
                    start_div = 1'b0;
                    signed_div =1'b1;
                    stall_div =1'b0;
                    temp_aluout_64 = div_result;
                end 
            end
            `ALUOP_DIVU :begin
                if(!div_ready && save_div_a==a && save_div_b==b && save_div_type==aluop) begin
                    start_div = 1'b0;
                    signed_div =1'b0;
                    stall_div =1'b0; 
                    temp_aluout_64 = save_div_result;
                end else if(div_ready ==1'b0) begin // 没准备好
                    start_div = 1'b1;
                    signed_div =1'b0;
                    stall_div =1'b1;
                end else begin // 准备好了
                    start_div = 1'b0;
                    signed_div =1'b0;
                    stall_div =1'b0;
                    temp_aluout_64 = div_result;
                end 
            end
            default      : y = 32'b0;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if(div_ready) begin
            save_div_a <= a;
            save_div_b <= b;
            save_div_result <= div_result;
            save_div_type <= aluop;
        end else begin
            save_div_a <= save_div_a;
            save_div_b <= save_div_b;
            save_div_result <= save_div_result;
            save_div_type <= save_div_type;
        end
    end
    
    mul mul_inst(
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .sign(mul_sign),
        .start(start_mul),
        .result(mul_result),
        .ready(mul_ready)
    );

    div mydiv(
        .clk(clk),
        .rst(rst),
        .signed_div_i(signed_div), 
        .opdata1_i(a),
        .opdata2_i(b),
        
        .start_i(start_div),
        .annul_i(1'b0),
        .result_o(div_result),
        .ready_o(div_ready)
);
    
endmodule
