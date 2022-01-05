`timescale 1ns/1ps
module hazard (
    input wire [4:0] D_master_rs,
    input wire [4:0] D_master_rt,
    input wire       E_master_memtoReg,
    input wire [4:0] E_master_reg_waddr,
    input wire       E_branch_taken,
    input wire       M_master_memtoReg,
    input wire [4:0] M_master_reg_waddr,
    
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
    assign lwstall = (E_master_memtoReg & (D_master_rs == E_master_reg_waddr | D_master_rt == E_master_reg_waddr)) || 
                     (M_master_memtoReg & (D_master_rs == M_master_reg_waddr | D_master_rt == M_master_reg_waddr));
    assign F_ena = ~lwstall;
    assign D_ena = ~lwstall;
    assign E_ena = 1'b1;
    assign M_ena = 1'b1; 
    assign W_ena = 1'b1;

    assign F_flush = 1'b0;
    assign D_flush = E_branch_taken;
    assign E_flush = E_branch_taken;
    assign M_flush = 1'b0;
    assign W_flush = 1'b0;
    
endmodule
