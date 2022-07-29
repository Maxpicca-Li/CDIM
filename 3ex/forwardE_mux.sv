`timescale 1ns / 1ps

module forwardE_mux(
    // M的计算结果
    input                   M_slave_alu_wen,
    input [ 4:0]            M_slave_alu_waddr,
    input [31:0]            M_slave_alu_wdata,
    input                   M_master_alu_wen,
    input [ 4:0]            M_master_alu_waddr,
    input [31:0]            M_master_alu_wdata,
    input                   W_slave_alu_wen,
    input [ 4:0]            W_slave_alu_waddr,
    input [31:0]            W_slave_alu_wdata,
    input                   W_master_alu_wen,
    input [ 4:0]            W_master_alu_waddr,
    input [31:0]            W_master_alu_wdata,
    // W的访存结果
    input                   W_master_memtoReg,
    input [ 4:0]            W_master_mem_waddr,
    input [31:0]            W_master_mem_rdata,

    input [ 4:0]            reg_addr,
    input [31:0]            reg_data,
    output logic [31:0]     result_data
);
    // FIXME: W_alu_res和W_mem_rdata是否可以整合？
    always_comb begin : get_result
        if(M_slave_alu_wen && ~(|(M_slave_alu_waddr ^ reg_addr)))
            result_data = M_slave_alu_wdata;
        else if(M_master_alu_wen && ~(|(M_master_alu_waddr ^ reg_addr)))
            result_data = M_master_alu_wdata;
        else if(W_slave_alu_wen && ~(|(W_slave_alu_waddr ^ reg_addr)))
            result_data = W_slave_alu_wdata;
        else if(W_master_alu_wen && ~(|(W_master_alu_waddr ^ reg_addr)))
            result_data = W_master_alu_wdata;
        else if(W_master_memtoReg && ~(|(W_master_mem_waddr ^ reg_addr)))
            result_data = W_master_mem_rdata;
        else
            result_data = reg_data;
    end

endmodule