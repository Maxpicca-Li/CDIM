`timescale 1ns / 1ps
`include "defines.vh"

module alu_top(
    input  logic clk,rst,M_except,
    input  logic [7 :0] E_master_aluop,
    input  logic [31:0] E_master_alu_srca,
    input  logic [31:0] E_master_alu_srcb,
    output logic        E_master_overflow,
    input  logic [7 :0] E_slave_aluop,
    input  logic [31:0] E_slave_alu_srca,
    input  logic [31:0] E_slave_alu_srcb,
    input  logic        E_slave_overflow,
    
    
    input  logic [31:0]cp0_data,
    input  logic [63:0]hilo, // hilo source data
    output logic stall_alu,
    output logic [31:0] y,
    output logic [63:0]aluout_64,
    output logic overflow
);

assign E_alu_stall = E_master_alu_stall | E_slave_alu_stall;
assign E_master_alu_res = {32{E_master_is_link_pc8==1'b1}} & (E_master_pc + 32'd8) |
                          {32{E_master_is_link_pc8==1'b0}} & E_master_alu_res_tmp  ;

alu_master u_aluA(
//ports
.clk                   ( clk                    ),
.rst                   ( rst | M_except         ),
.aluop                 ( E_master_aluop         ),
.a                     ( E_master_alu_srca      ),
.b                     ( E_master_alu_srcb      ),
.cp0_data              ( cp0_data               ),
.hilo                  ( hilo                   ),
.stall_alu             ( E_master_alu_stall     ),
.y                     ( E_master_alu_res_tmp   ),
.aluout_64             ( E_master_alu_out64     ),
.overflow              ( E_master_overflow      )
);

alu_master u_aluB(
    //ports
    .clk                   ( clk                    ),
    .rst                   ( rst | M_except         ),
    .aluop                 ( E_slave_aluop          ),
    .a                     ( E_slave_alu_srca       ),
    .b                     ( E_slave_alu_srcb       ),
    .cp0_data              ( cp0_data               ),
    .hilo                  ( hilo                   ),
    .stall_alu             ( E_slave_alu_stall      ),
    .y                     ( E_slave_alu_res        ),
    .aluout_64             ( E_slave_alu_out64      ),
    .overflow              ( E_slave_overflow       )
);

endmodule