`timescale 1ns/1ps
module hazard (
    input wire       i_stall,
    input wire       d_stall,
    output wire      longest_stall,
    input wire [4:0] D_master_rs,
    input wire [4:0] D_master_rt,
    input wire       E_master_memtoReg,
    input wire [4:0] E_master_reg_waddr,
    input wire       M_master_memtoReg,
    input wire [4:0] M_master_reg_waddr,
    input wire       E_branch_taken,
    input wire       E_alu_stall,
    input wire       D_flush_all, // 暂时用不上这个信号
    
    //except
    input wire M_except,

    output wire F_ena, 
    output wire D_ena, 
    output wire E_ena, 
    output wire M_ena, 
    output wire W_ena,

    output wire F_flush, 
    output wire D_flush, 
    output wire E_flush, 
    output wire M_flush, 
    output wire W_flush

);
    
    // 阻塞
    wire lwstall;
    // FIXME: lwstall优化问题
    /*
    如下情况
        lb   $1,0x3($0)       ## $1 = 0xffffffff
        lbu  $1,0x2($0)       ## $1 = 0x000000ee
    这种情况感觉不用stall lbu（会导致3个周期的延迟）
    */
    // FIXME: 这里没有考虑 D_slave_rs 和 D_slave_rt 
    assign lwstall = (E_master_memtoReg & (D_master_rs == E_master_reg_waddr | D_master_rt == E_master_reg_waddr)) || 
                     (M_master_memtoReg & (D_master_rs == M_master_reg_waddr | D_master_rt == M_master_reg_waddr));
    assign longest_stall = E_alu_stall | i_stall | d_stall;
    
    assign F_ena = ~i_stall; // 存在fifo情况下，d_stall不影响取指
    assign D_ena = ~(lwstall | longest_stall);
    assign E_ena = ~longest_stall;
    assign M_ena = ~longest_stall;
    assign W_ena = ~longest_stall | (E_alu_stall & M_except); // FIXME: M阶段异常不影响W阶段 ==> 该逻辑根据波形图硬改的

    assign F_flush = 1'b0;
    assign D_flush = M_except | E_branch_taken;
    assign E_flush = M_except | E_branch_taken; // pclk-fifo, nclk-ibram
    // assign E_flush = M_except;                     // nclk-fifo, pclk-ibram
    assign M_flush = M_except;
    assign W_flush = 1'b0;


endmodule
