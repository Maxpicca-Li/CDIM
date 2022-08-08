`timescale 1ns / 1ps
module ex_mem(
    input wire clk,
    input wire rst,
    input wire clear1,
    input wire clear2, 
    input wire ena1,
    input wire ena2,

    input wire E_mem_en,
    input wire E_mem_ren,
    input wire E_mem_wen,
    input wire [5 :0] E_mem_op,
    input wire [31:0] E_mem_addr,
    input wire [31:0] E_mem_wdata,
    input wire [31:0] E_mem_pa,
    input wire        E_mem_uncached,
    output reg M_mem_en,
    output reg M_mem_ren,
    output reg M_mem_wen,
    output reg [5 :0] M_mem_op,
    output reg [31:0] M_mem_addr,
    output reg [31:0] M_mem_wdata,
    output reg [31:0] M_mem_pa,
    output reg        M_mem_uncached,

    input wire E_master_mem_sel,
    input wire E_master_hilowrite,
    input wire E_master_memtoReg,
    input wire E_master_reg_wen,
    input wire E_master_cp0write,
    input wire E_master_is_in_delayslot,
    input wire [4 :0]E_master_reg_waddr,
    input wire [4 :0]E_master_rd,
    input wire [5 :0]E_master_op,
    input wire [7 :0]E_master_aluop,
    input except_bus E_master_except,
    input wire [31:0]E_master_inst,
    input wire [31:0]E_master_rt_value,
    input wire [31:0]E_master_alu_res,
    input wire [31:0]E_master_pc,
    input wire [31:0]E_master_mem_addr,
    input wire [63:0]E_master_alu_out64,

    input wire E_slave_mem_sel,
    input wire E_slave_reg_wen,
    input wire E_slave_memtoReg,
    input wire E_slave_cp0write,
    input wire E_slave_is_in_delayslot,
    input wire [4 :0]E_slave_reg_waddr,
    input wire [7 :0]E_slave_aluop,
    input except_bus E_slave_except,
    input wire [31:0]E_slave_pc,
    input wire [31:0]E_slave_inst,
    input wire [31:0]E_slave_alu_res,

    output reg M_master_mem_sel,
    output reg M_master_hilowrite,
    output reg M_master_memtoReg,
    output reg M_master_reg_wen,
    output reg M_master_cp0write,
    output reg M_master_is_in_delayslot,
    output reg [4 :0]M_master_reg_waddr,
    output reg [4 :0]M_master_rd,
    output reg [5 :0]M_master_op,
    output reg [7 :0]M_master_aluop,
    output except_bus M_master_except,
    output reg [31:0]M_master_inst,
    output reg [31:0]M_master_rt_value,
    output reg [31:0]M_master_alu_res,
    output reg [31:0]M_master_pc,
    output reg [31:0]M_master_mem_addr,
    output reg [63:0]M_master_alu_out64,
    
    output reg M_slave_mem_sel,
    output reg M_slave_reg_wen,
    output reg M_slave_memtoReg,
    output reg M_slave_cp0write,
    output reg M_slave_is_in_delayslot,
    output reg [4 :0]M_slave_reg_waddr,
    output reg [7 :0]M_slave_aluop,
    output except_bus M_slave_except,
    output reg [31:0]M_slave_pc,
    output reg [31:0]M_slave_inst,
    output reg [31:0]M_slave_alu_res
); 

    always_ff @(posedge clk) begin
        if(rst | clear1) begin
            M_master_mem_sel <= 0;
            M_master_hilowrite <= 0;
            M_master_memtoReg <= 0;
            M_master_reg_wen <= 0;
            M_master_cp0write <= 0;
            M_master_is_in_delayslot <= 0;
            M_master_reg_waddr <= 0;
            M_master_rd <= 0;
            M_master_op <= 0;
            M_master_except <= 0;
            M_master_inst <= 0;
            M_master_rt_value <= 0;
            M_master_alu_res <= 0;
            M_master_pc <= 0;
            M_master_alu_out64 <= 0;
            M_master_mem_addr <= 0;
            M_master_aluop <= 0;
            M_mem_en <= 0;
            M_mem_ren <= 0;
            M_mem_wen <= 0;
            M_mem_op <= 0;
            M_mem_addr <= 0;
            M_mem_wdata <= 0;
            M_mem_pa <= 0;
            M_mem_uncached <= 0;
        end
        else if (ena1) begin
            M_master_mem_sel <= E_master_mem_sel;
            M_master_hilowrite <= E_master_hilowrite;
            M_master_memtoReg <= E_master_memtoReg;
            M_master_reg_wen <= E_master_reg_wen;
            M_master_cp0write <= E_master_cp0write;
            M_master_is_in_delayslot <= E_master_is_in_delayslot;
            M_master_reg_waddr <= E_master_reg_waddr;
            M_master_rd <= E_master_rd;
            M_master_op <= E_master_op;
            M_master_except <= E_master_except;
            M_master_inst <= E_master_inst;
            M_master_rt_value <= E_master_rt_value;
            M_master_alu_res <= E_master_alu_res;
            M_master_pc <= E_master_pc;
            M_master_alu_out64 <= E_master_alu_out64;
            M_master_mem_addr <= E_master_mem_addr;
            M_master_aluop <= E_master_aluop;
            M_mem_en <= E_mem_en;
            M_mem_ren <= E_mem_ren;
            M_mem_wen <= E_mem_wen;
            M_mem_op <= E_mem_op;
            M_mem_addr <= E_mem_addr;
            M_mem_wdata <= E_mem_wdata;
            M_mem_pa <= E_mem_pa;
            M_mem_uncached <= E_mem_uncached;
        end
    end

    always_ff @(posedge clk) begin
        if(rst | clear2) begin
            M_slave_reg_wen <= 0;
            M_slave_memtoReg <= 0;
            M_slave_cp0write <= 0;
            M_slave_is_in_delayslot <= 0;
            M_slave_reg_waddr <= 0;
            M_slave_except <= 0;
            M_slave_pc <= 0;
            M_slave_inst <= 0;
            M_slave_alu_res <= 0;
            M_slave_aluop <= 0;
            M_slave_mem_sel <= 0;
        end
        else if (ena2) begin
            M_slave_reg_wen <= E_slave_reg_wen;
            M_slave_memtoReg <= E_slave_memtoReg;
            M_slave_cp0write <= E_slave_cp0write;
            M_slave_is_in_delayslot <= E_slave_is_in_delayslot;
            M_slave_reg_waddr <= E_slave_reg_waddr;
            M_slave_except <= E_slave_except;
            M_slave_pc <= E_slave_pc;
            M_slave_inst <= E_slave_inst;
            M_slave_alu_res <= E_slave_alu_res;
            M_slave_aluop <= E_slave_aluop;
            M_slave_mem_sel <= E_slave_mem_sel;
        end
    end

endmodule