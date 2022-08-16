`timescale 1ns/1ps
module hazard (
    // judge
    input wire       D_master_read_rs,
    input wire       D_master_read_rt,
    input wire [4:0] D_master_rs,
    input wire [4:0] D_master_rt,
    input wire       E_master_memtoReg,
    input wire [4:0] E_master_reg_waddr,
    input wire       E_slave_memtoReg,
    input wire [4:0] E_slave_reg_waddr,
    // stall
    input wire       i_stall,
    input wire       E_alu_stall,
    input wire       d_stall,
    // flush: phase越靠后越先处理
    input wire       M_except,
    input wire       M_flush_all, // 暂时用不上这个信号
    input wire       E_bj,
    input wire       D_bj,
    // out
    output wire F_ena, 
    output wire D_ena, 
    output wire E_ena, 
    output wire M_ena, 
    output wire W_ena,
    output wire F_flush, 
    output wire D_flush, 
    output wire E_flush, 
    output wire M_flush, 
    output wire W_flush,
    output wire delay_slot_flush

);
    wire lwstall, longest_stall;
    // D阶段的
    assign lwstall = (E_master_memtoReg & (|E_master_reg_waddr) & ((D_master_read_rs & D_master_rs == E_master_reg_waddr) | (D_master_read_rt & D_master_rt == E_master_reg_waddr))) || 
                     (E_slave_memtoReg  & (|E_slave_reg_waddr)  & ((D_master_read_rs & D_master_rs == E_slave_reg_waddr)  | (D_master_read_rt & D_master_rt == E_slave_reg_waddr)));
    assign longest_stall = E_alu_stall | i_stall | d_stall;

    assign F_ena = ~i_stall; // 存在fifo情况下，d_stall不影响取指
    assign D_ena = ~(lwstall | longest_stall);
    assign E_ena = ~longest_stall;
    assign M_ena = ~longest_stall;
    assign W_ena = ~longest_stall | M_except | M_flush_all;

    assign F_flush = 1'b0;
    assign D_flush = M_except | M_flush_all | E_bj | D_bj; // D\E branch
    assign E_flush = M_except | M_flush_all | E_bj ;    // E branch
    assign M_flush = M_except | M_flush_all;
    assign W_flush = 1'b0; // TODO:0xbfc7cbe8 异常绑定
    assign delay_slot_flush = M_except | M_flush_all;

    /* 
    // TODO: 需要好好涉及hazard的信号和刷新逻辑
    其他的刷新信号
    fifo_rst = rst | D_flush | D_master_flush_all
    flush_delay_slot = M_cp0_jump | D_master_flush_all
    delay_rst = D_branch_taken && ~D_slave_ena  // 跳转时没带延迟槽
    assign D2E_clear1 = M_cp0_jump | (!D_master_is_in_delayslot & E_flush & E_ena) | (!D_ena & E_ena);
    assign D2E_clear2 = M_cp0_jump | (E_flush & D_slave_ena) || (E_ena & !D_slave_ena);
    */
endmodule
