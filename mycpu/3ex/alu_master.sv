`timescale 1ns / 1ps
`include "defines.vh"

module alu_master(
    input  logic clk,rst,
    input  logic [7:0]aluop,
    input  logic [31:0]a,
    input  logic [31:0]b,
    input  logic [31:0]cp0_data,
    input  logic [63:0]hilo, // hilo source data

    output logic        mul_start,
    output logic        mul_sign,
    input  logic        mul_ready,
    input  logic [63:0] mul_result,
    output logic        div_start,
    output logic        div_sign,
    input  logic        div_ready,
    input  logic [63:0] div_result,
    
    output logic [31:0] y,
    output logic [63:0]aluout_64,
    output logic overflow
);
    
    logic [63:0] temp_aluout_64;
    integer i;

    assign aluout_64= temp_aluout_64;
    
    // logic [7 :0] save_div_type;
    // logic [31:0] save_div_a,save_div_b;
    // logic [63:0] save_div_result;
    // always_ff @(posedge clk) begin
    //     if(div_ready) begin
    //         save_div_a <= a;
    //         save_div_b <= b;
    //         save_div_result <= div_result;
    //         save_div_type <= aluop;
    //     end else begin
    //         save_div_a <= save_div_a;
    //         save_div_b <= save_div_b;
    //         save_div_result <= save_div_result;
    //         save_div_type <= save_div_type;
    //     end
    // end

    always_comb begin
        // stall_mul = 1'b0;
        // stall_div = 1'b0;
        mul_start = 1'b0;
        mul_sign = 1'b0;
        overflow = 1'b0;
        div_start = `DivStop;
        div_sign =1'b0;
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
            `ALUOP_MOV : y = a;
            // 特殊指令
            `ALUOP_SC  : y = 32'd1;
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
                    mul_start = 1'b1;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = mul_result;
                    y = mul_result[31:0];
                end
            end
            `ALUOP_MULTU : begin
                if (!mul_ready) begin
                    mul_start = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = mul_result;
                    y = mul_result[31:0];
                end
            end
            `ALUOP_MADD  : begin
                if (!mul_ready) begin
                    mul_start = 1'b1;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = hilo + mul_result;  // 无算数异常
                end
            end
            `ALUOP_MSUB  : begin
                if (!mul_ready) begin
                    mul_start = 1'b1;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    mul_sign = 1'b1;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = hilo - mul_result;  // 无算数异常
                end
            end
            `ALUOP_MADDU : begin
                if (!mul_ready) begin
                    mul_start = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = hilo + mul_result;
                end
            end
            `ALUOP_MSUBU : begin
                if (!mul_ready) begin
                    mul_start = 1'b1;
                    // stall_mul = 1'b1;
                end else if (mul_ready) begin
                    mul_start = 1'b0;
                    // stall_mul = 1'b0;
                    temp_aluout_64 = hilo - mul_result;
                end
            end
            `ALUOP_DIV   :begin
                /* if(!div_ready && save_div_a==a && save_div_b==b && save_div_type==aluop) begin
                    div_start = 1'b0;
                    div_sign =1'b1;
                    stall_div =1'b0;
                    temp_aluout_64 = save_div_result;
                end else */
                if(div_ready ==1'b0) begin // 没准备好
                    div_start = 1'b1;
                    div_sign =1'b1;
                    // stall_div =1'b1;
                end else begin // 准备好了
                    div_start = 1'b0;
                    div_sign =1'b1;
                    // stall_div =1'b0;
                    temp_aluout_64 = div_result;
                end 
            end
            `ALUOP_DIVU :begin
                /*if(!div_ready && save_div_a==a && save_div_b==b && save_div_type==aluop) begin
                    div_start = 1'b0;
                    div_sign =1'b0;
                    stall_div =1'b0; 
                    temp_aluout_64 = save_div_result;
                end else */
                if(div_ready ==1'b0) begin // 没准备好
                    div_start = 1'b1;
                    div_sign =1'b0;
                    // stall_div =1'b1;
                end else begin // 准备好了
                    div_start = 1'b0;
                    div_sign =1'b0;
                    // stall_div =1'b0;
                    temp_aluout_64 = div_result;
                end 
            end
            default      : y = 32'b0;
        endcase
    end
        
endmodule
