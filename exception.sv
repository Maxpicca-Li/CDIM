`timescale 1ns / 1ps

// _except = [8trap, 7pc_exp, 6syscall, 5break, 4eret, 3undefined, 2overflow, 1adel, 0ades]
module exception(
    // 异常处理，master优先
    input              rst            ,
    input              master_is_in_delayslot,
    input  except_bus  master_except  ,
    input [31:0]       master_pc      ,
    input [31:0]       mem_addr   ,
    input              slave_is_in_delayslot,
    input  except_bus  slave_except   ,
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

    except_bus except; 
    assign except              = (|master_except || (~(|slave_except))) ? master_except:slave_except;
    assign except_inst_addr    = (|master_except || (~(|slave_except))) ? master_pc    :slave_pc    ;
    assign except_in_delayslot = (|master_except || (~(|slave_except))) ? master_is_in_delayslot : slave_is_in_delayslot;

    always_comb begin: excepttype_define
        except_target = 32'hBFC00380;
        except_bad_addr = 0;
        if(rst) begin
            excepttype = 32'b0;
        end else begin
            if(except.id_int) begin
                excepttype = 32'h00000001;
            end else if(except.ex_adel) begin
                // data load出错
                excepttype = 32'h00000004;
                except_bad_addr = mem_addr;
            end else if(except.if_adel) begin
                // inst load出错
                excepttype = 32'h00000004;
                except_bad_addr = master_pc;
            end else if(except.ex_ades) begin
                // data store出错
                excepttype = 32'h00000005;
                except_bad_addr = mem_addr;
            end else if(except.id_syscall) begin
                excepttype = 32'h00000008;
            end else if(except.id_break) begin
                excepttype = 32'h00000009;
            end else if(except.id_eret) begin
                excepttype = 32'h0000000e;
                except_target = cp0_epc;
            end else if(except.id_ri) begin
                excepttype = 32'h0000000a;
            end else if(except.ex_ov) begin
                excepttype = 32'h0000000c;
            end else begin // make vivado happy (●'◡'●) and lyq will be happy (●ˇ∀ˇ●)
                excepttype = 32'b0;
            end
        end
    end

endmodule
