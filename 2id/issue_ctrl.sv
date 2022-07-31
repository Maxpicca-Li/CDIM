`timescale 1ns / 1ps
`include "defines.vh"

module issue_ctrl (
    //master's status
    input           D_master_en,
    input           D_master_reg_wen,
    input           D_master_mem_en,
    input [4:0]     D_master_reg_waddr,
    input           D_master_is_branch,
    input           D_master_is_spec_inst,
    input           E_master_memtoReg,
    input [4:0]     E_master_reg_waddr,
    //slave's status
    input  [5:0]    D_slave_op,
    input  [4:0]    D_slave_rs,
    input  [4:0]    D_slave_rt,
    input           D_slave_mem_en,
    input           D_slave_is_branch,
    input           D_slave_is_spec_inst,
    input           D_slave_is_only_in_master,
    //FIFO's status
    input           fifo_empty,
    input           fifo_almost_empty,

    output logic    D_slave_is_in_delayslot,
    output logic    D_slave_en

);
    
    logic load_stall;
    logic fifo_disable;
    logic struct_conflict;

    assign D_slave_is_in_delayslot = D_master_is_branch & D_slave_en;
    assign fifo_disable = fifo_empty || fifo_almost_empty; // fifo 限制
    assign struct_conflict = (D_master_mem_en & D_slave_mem_en);
    assign load_stall = (E_master_memtoReg & ((|D_slave_rs & D_slave_rs == E_master_reg_waddr) | (|D_slave_rt & D_slave_rt == E_master_reg_waddr)));

    /* 
    数据冲突 WAR
        - D_master 
        - E_master/E_slave load_stall
    结构冲突
        - 访存
        - 乘除法 ==> 应该可以同时发射
        - CP0 ==> 目前只master发射
    数据有效性
        - D_ena
        - fifo是否为空
    防刷新
        - branch只放在master执行，slave可放延迟槽
        - spec_inst只放在master执行，slave不放指令
    */
    always_comb begin : define_slave_en
        if( !D_master_en || fifo_disable || load_stall || D_slave_is_branch || D_master_is_spec_inst || D_slave_is_spec_inst || D_slave_is_only_in_master || struct_conflict)
            D_slave_en = 1'b0;
        else begin
            if(D_master_reg_wen && (D_master_reg_waddr != 5'd0)) begin
                D_slave_en = ((|D_slave_rs) & D_slave_rs != D_master_reg_waddr) && ((|D_slave_rt) & D_slave_rt != D_master_reg_waddr);
            end
            else begin
                D_slave_en = 1'b1;
            end
        end
    end

endmodule