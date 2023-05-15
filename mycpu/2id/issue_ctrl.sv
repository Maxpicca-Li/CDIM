`timescale 1ns / 1ps
`include "defines.vh"

module issue_ctrl (
    input           D_master_ena,
    // mem
    input           D_mem_conflict,
    input           D_mul_conflict,
    input           D_div_conflict,
    input           E_master_memtoReg,
    input [4:0]     E_master_reg_waddr,
    input           E_slave_memtoReg,
    input [4:0]     E_slave_reg_waddr,
    // war
    input           D_master_reg_wen,
    input [4:0]     D_master_reg_waddr,
    input           D_slave_read_rs,
    input           D_slave_read_rt,
    input  [4:0]    D_slave_rs,
    input  [4:0]    D_slave_rt,
    input           D_master_hilowrite,
    input           D_slave_hilowrite,
    input           D_slave_hiloread,
    input           D_master_cp0write,
    input           D_slave_cp0read,
    // other
    input           D_master_is_branch,
    input           D_master_only_one_issue,
    input           D_slave_only_one_issue,
    input           D_slave_may_bring_flush,
    //FIFO's status
    input           fifo_empty,
    input           fifo_almost_empty,

    output logic    D_slave_is_in_delayslot,
    output logic    D_slave_ena

);
    assign D_slave_is_in_delayslot = D_master_is_branch & D_slave_ena;
    // 控制信号
    logic load_stall, fifo_disable, struct_conflict, war_reg, war_hilo, war_cp0, data_conflict;
    assign fifo_disable = fifo_empty | fifo_almost_empty; // fifo 限制
    assign struct_conflict = D_mem_conflict | D_mul_conflict | D_div_conflict;
    assign load_stall = (E_master_memtoReg & ((D_slave_read_rs & D_slave_rs == E_master_reg_waddr) | (D_slave_read_rt & D_slave_rt == E_master_reg_waddr))) |
                        (E_slave_memtoReg  & ((D_slave_read_rs & D_slave_rs == E_slave_reg_waddr)  | (D_slave_read_rt & D_slave_rt == E_slave_reg_waddr)));
    assign war_reg    = D_master_reg_wen & ((D_slave_read_rs & D_slave_rs == D_master_reg_waddr) | (D_slave_read_rt & D_slave_rt == D_master_reg_waddr));
    assign war_hilo   = (D_master_hilowrite & D_slave_hiloread) | (D_master_hilowrite & D_slave_hilowrite);
    assign war_cp0    = D_master_cp0write & D_slave_cp0read; 
    assign data_conflict = war_reg | war_hilo | war_cp0 | load_stall;
    // 汇总
    assign D_slave_ena = !(!D_master_ena | fifo_disable | D_master_only_one_issue | D_slave_only_one_issue | D_slave_may_bring_flush | struct_conflict | data_conflict);
    /* 
    数据冲突 
        - WAR
            - D_master 
            - hilo
            - CP0
        - load_stall
            E_master/E_slave 
        - 
    结构冲突
        - 访存
        - 乘除法 ==> 应该可以同时发射
        - CP0 ==> 目前只master发射
    数据有效性
        - D_ena
        - fifo是否为空
    防刷新
        - 只放在master执行，slave可放延迟槽[may_bring_flush]: 跳转指令
        - 只放在master执行，slave不放指令[only_one_issue]: SYSCALL, BREAK明显异常; MTC0可能带来异常
        - 
    */

endmodule
