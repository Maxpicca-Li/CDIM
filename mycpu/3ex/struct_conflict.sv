`timescale 1ns / 1ps
module struct_conflict(
    // ctrl
    input  logic        E_exp1,
    input  logic        E_exp2,
    input  logic        M_flush, 
    input  logic        M_ena, 
    // A
    input  logic        E_mem_en1,
    input  logic        E_mem_ren1,
    input  logic        E_mem_wen1,
    input  logic [5 :0] E_mem_op1,
    input  logic [31:0] E_mem_addr1,
    input  logic [31:0] E_mem_wdata1,
    input  logic        M_mem_sel1,
    output logic        E_mem_adel1,
    output logic        E_mem_ades1,
    output logic        E_mem_sel1,
    output logic [31:0] M_mem_rdata1,
    // B
    input  logic        E_mem_en2,
    input  logic        E_mem_ren2,
    input  logic        E_mem_wen2,
    input  logic [5 :0] E_mem_op2,
    input  logic [31:0] E_mem_addr2,
    input  logic [31:0] E_mem_wdata2,
    input  logic        M_mem_sel2,
    output logic        E_mem_adel2,
    output logic        E_mem_ades2,
    output logic        E_mem_sel2,
    output logic [31:0] M_mem_rdata2,
    // mem
    output logic        E_mem_en,
    output logic        E_mem_ren,
    output logic        E_mem_wen,
    output logic [5 :0] E_mem_op,
    output logic [31:0] E_mem_addr,
    output logic [31:0] E_mem_wdata,
    input  logic [31:0] M_mem_rdata
);

    assign E_mem_op = ({6{E_mem_en1}} & E_mem_op1) | ({6{E_mem_en2}} & E_mem_op2);
    // 读指令地址错例外
    assign E_mem_adel1= E_mem_op1 == `OP_LW  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_LL  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_LH  & E_mem_addr1[0]      ? 1'b1 : 
                        E_mem_op1 == `OP_LHU & E_mem_addr1[0]      ? 1'b1 : 
                        1'b0;
    // 写指令地址错例外
    assign E_mem_ades1= E_mem_op1 == `OP_SW  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_SC  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_SH  & E_mem_addr1[0]      ? 1'b1 : 
                        1'b0;
    assign E_mem_adel2= E_mem_op2 == `OP_LW  & (|E_mem_addr2[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_LL  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op2 == `OP_LH  & E_mem_addr2[0]      ? 1'b1 : 
                        E_mem_op2 == `OP_LHU & E_mem_addr2[0]      ? 1'b1 : 
                        1'b0;
    assign E_mem_ades2= E_mem_op2 == `OP_SW  & (|E_mem_addr2[1:0]) ? 1'b1 : 
                        E_mem_op1 == `OP_SC  & (|E_mem_addr1[1:0]) ? 1'b1 : 
                        E_mem_op2 == `OP_SH  & E_mem_addr2[0]      ? 1'b1 : 
                        1'b0;
    // & E_mem_addr1 != 32'hbfaffff0; (the trick of accesssing confreg ==> Commented for that we don't use it) 
    // & M_ena;    (Guarantee that mem_en can flow from E to M ==> Commented for that d_stall is used to control mem_en which will cause a combination loop)
    // & !M_flush; (Guarantee that mem_en can flow from E to M ==> Commented for reducing the control signal)
    assign E_mem_sel1 = E_mem_en1 & !E_exp1;
    assign E_mem_sel2 = E_mem_en2 & !E_exp1 & !E_exp2;
    assign E_mem_en = E_mem_sel1 | E_mem_sel2; // & M_ena;
    assign E_mem_ren = (E_mem_sel1 & E_mem_ren1) | (E_mem_sel2 & E_mem_ren2);
    assign E_mem_wen = (E_mem_sel1 & E_mem_wen1) | (E_mem_sel2 & E_mem_wen2);
    assign E_mem_addr = ({32{E_mem_en1}} & E_mem_addr1) | ({32{E_mem_en2}} & E_mem_addr2);
    assign E_mem_wdata = ({32{E_mem_en1}} & E_mem_wdata1) | ({32{E_mem_en2}} & E_mem_wdata2);
    assign M_mem_rdata1 = {32{M_mem_sel1}} & M_mem_rdata;
    assign M_mem_rdata2 = {32{M_mem_sel2}} & M_mem_rdata;

endmodule