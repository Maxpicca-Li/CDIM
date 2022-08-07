`timescale 1ns/1ps
module hazard (
    input wire       i_stall,
    input wire       d_stall,
    input wire       D_master_read_rs,
    input wire       D_master_read_rt,
    input wire [4:0] D_master_rs,
    input wire [4:0] D_master_rt,
    input wire       E_master_memtoReg,
    input wire [4:0] E_master_reg_waddr,
    input wire       E_slave_memtoReg,
    input wire [4:0] E_slave_reg_waddr,
    input wire       E_branch_taken,
    input wire       E_alu_stall,
    input wire       D_flush_all, // 暂时用不上这个信号
    input wire       fifo_empty,
    
    //except
    input wire M_except,
    output wire pc_en,
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
    wire lwstall, longest_stall,is_flush,M_except_ok;
    // FIXME: lwstall优化问题
    /*
    如下情况
        lb   $1,0x3($0)       ## $1 = 0xffffffff
        lbu  $1,0x2($0)       ## $1 = 0x000000ee
    这种情况感觉不用stall lbu（会导致3个周期的延迟）
    */
    // D后影响PC变化的因素
    assign is_flush = M_except | E_branch_taken | D_flush_all;
    // D前stall: i_stall
    // D时stall
    assign lwstall = (E_master_memtoReg & (|E_master_reg_waddr) & ((D_master_read_rs & D_master_rs == E_master_reg_waddr) | (D_master_read_rt & D_master_rt == E_master_reg_waddr))) || 
                     (E_slave_memtoReg  & (|E_slave_reg_waddr)  & ((D_master_read_rs & D_master_rs == E_slave_reg_waddr)  | (D_master_read_rt & D_master_rt == E_slave_reg_waddr)));
    // D后stall
    assign longest_stall = E_alu_stall | d_stall;
    // FD冲突信号（会导致各个部件耦合性太强，使其成为关键路径 ==> 如果FD没能带来太大提升，不推荐这样做）
    assign FD_conflict_stall = longest_stall & is_flush;
    assign FD_wait_stall = i_stall & is_flush;
    assign M_except_ok = M_except & !FD_wait_stall;
    // pc_en
    assign pc_en = !FD_wait_stall;
    
    assign F_ena = ~(i_stall | FD_conflict_stall); // 存在fifo情况下，d_stall不影响取指
    assign D_ena = ~(lwstall | longest_stall | FD_wait_stall); //  | fifo_empty  一旦此时I_stall的是延迟槽，|fifo_empty会让D_ena一直拉低，导致延迟槽穿不下去
    assign E_ena = ~(longest_stall | FD_wait_stall);
    assign M_ena = ~(longest_stall | FD_wait_stall);
    assign W_ena = ~(longest_stall | FD_wait_stall) | M_except_ok;

    assign F_flush = 1'b0;
    assign D_flush = M_except_ok | E_branch_taken;
    assign E_flush = M_except_ok | E_branch_taken; // pclk-fifo, nclk-ibram
    // assign E_flush = M_except_ok;                     // nclk-fifo, pclk-ibram
    assign M_flush = M_except_ok;
    assign W_flush = 1'b0;


endmodule
