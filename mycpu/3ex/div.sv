`include "defines.vh"

module div(
    input wire clk,
    input wire rst,

    input wire signed_div_i, 
    input wire start_i,
    input wire annul_i,
    input wire[31:0] opdata1_i,
    input wire[31:0] opdata2_i,

    output reg[63:0] result_o,
    output reg ready_o
);

wire[32:0] div_temp;
wire[31:0] temp_op1,temp_op2;
reg[1:0] state;
reg[5:0] cnt;
reg[64:0] dividend;
reg[31:0] divisor;	 
reg sign1,sign2;

assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};
assign temp_op1= (signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) ? (~opdata1_i + 1):opdata1_i;
assign temp_op2= (signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) ? (~opdata2_i + 1):opdata2_i;

always_ff @ (posedge clk) begin
    if (rst == `RstEnable) begin
        state <= `DivFree;
        ready_o <= `DivResultNotReady;
        result_o <= {`ZeroWord,`ZeroWord};
        sign1 <= 1'b0;
        sign2 <= 1'b0;
        cnt <= 6'b000000;
    end else begin
        case (state)
            `DivFree: begin
                if(start_i == `DivStart && annul_i == 1'b0) begin
                    if(opdata2_i == `ZeroWord) begin
                        state <= `DivByZero;
                    end else begin
                        state <= `DivOn;
                        cnt <= 6'b000000;
                        if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
                            // temp_op1 = ~opdata1_i + 1;
                            sign1 <= opdata1_i[31];
                        end else begin
                            // temp_op1 = opdata1_i;
                            sign1 <= 1'b0;
                        end
                        if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
                            // temp_op2 = ~opdata2_i + 1;
                            sign2 <= opdata2_i[31];
                        end else begin
                            // temp_op2 = opdata2_i;
                            sign2 <= 1'b0;
                        end
                        dividend <= 0;
                        dividend[32:1] <= temp_op1;
                        divisor <= temp_op2;
                        // $display("除法开始");
                    end
                end else begin
                    ready_o <= `DivResultNotReady;
                    result_o <= {`ZeroWord,`ZeroWord};
                end          	
            end
            `DivByZero: begin
                dividend <= 0;
                state <= `DivEnd;		 		
            end
            `DivOn: begin
                if(annul_i == 1'b0) begin
                    if(cnt != 6'b100000) begin
                        if(div_temp[32] == 1'b1) begin
                            dividend <= {dividend[63:0] , 1'b0};
                        end else begin
                            dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
                        end
                        cnt <= cnt + 1;
                    end else begin
                        // if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                        if((signed_div_i == 1'b1) && ((sign1 ^ sign2) == 1'b1)) begin
                            // 商 lo
                            dividend[31:0] <= (~dividend[31:0] + 1);
                        end
                        // if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin 
                        if((signed_div_i == 1'b1) && ((sign1 ^ dividend[64]) == 1'b1)) begin              
                            // 余数 hi
                            dividend[64:33] <= (~dividend[64:33] + 1);
                        end
                        state <= `DivEnd;
                        cnt <= 6'b000000;            	
                    end
                end else begin
                    state <= `DivFree;
                end	
            end
            `DivEnd: begin
                result_o <= {dividend[64:33], dividend[31:0]};  
                ready_o <= `DivResultReady;
                if(start_i == `DivStop) begin
                    state <= `DivFree;
                    ready_o <= `DivResultNotReady;
                    result_o <= {`ZeroWord,`ZeroWord};       	
                end		  	
            end
        endcase
    end
end

endmodule