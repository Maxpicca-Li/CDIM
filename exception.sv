`timescale 1ns / 1ps
module exception(
    // 异常处理，master优先
    input              rst            ,
    input              master_is_in_delayslot,
    input [ 7:0]       master_except  ,
    input [31:0]       master_pc      ,
    input [31:0]       master_daddr   ,
    input              slave_is_in_delayslot,
    input [ 7:0]       slave_except   ,
    input [31:0]       slave_pc       ,
    input [31:0]       cp0_status     ,
    input [31:0]       cp0_cause      ,
    input [31:0]       cp0_epc       ,
    
    output logic [31:0] except_inst_addr   ,
    output logic [31:0] except_bad_addr    ,
    output logic        except_in_delayslot,
    output logic [31:0] except_target      ,
    output logic [31:0] excepttype         
);

    wire [ 7:0] except; 
    assign except              = (|master_except) ? master_except:slave_except;
    assign except_inst_addr    = (|master_except) ? master_pc    :slave_pc    ;
    assign except_in_delayslot = (|master_except) ? master_is_in_delayslot : slave_is_in_delayslot;

    always_comb begin: excepttype_define
        except_target = 32'hBFC00380;
        except_bad_addr = 0;
        if(rst) begin
            excepttype = 32'b0;
        end else begin
            if(((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) &&  (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1) && (|slave_pc)) begin
                excepttype = 32'h00000001;
            end else if(except[1] == 1'b1) begin
                // data load出错
                excepttype = 32'h00000004;
                except_bad_addr = master_daddr;
            end else if(except[7] == 1'b1) begin
                // inst load出错
                excepttype = 32'h00000004;
                except_bad_addr = master_pc;
            end else if(except[0] == 1'b1) begin
                // data store出错
                excepttype = 32'h00000005;
                except_bad_addr = master_daddr;
            end else if(except[6] == 1'b1) begin
                excepttype = 32'h00000008;
            end else if(except[5] == 1'b1) begin
                excepttype = 32'h00000009;
            end else if(except[4] == 1'b1) begin
                excepttype = 32'h0000000e;
                except_target = cp0_epc;
            end else if(except[3] == 1'b1) begin
                excepttype = 32'h0000000a;
            end else if(except[2] == 1'b1) begin
                excepttype = 32'h0000000c;
            end else begin // make vivado happy (●'◡'●) and lyq will be happy (●ˇ∀ˇ●)
                excepttype = 32'b0;
            end
        end
    end

endmodule
