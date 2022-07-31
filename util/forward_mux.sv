`timescale 1ns / 1ps

module forward_mux(
    input                   alu_wen1,
    input [ 4:0]            alu_waddr1,
    input [31:0]            alu_wdata1,
    input                   alu_wen2,
    input [ 4:0]            alu_waddr2,
    input [31:0]            alu_wdata2,
    input                   alu_wen3,
    input [ 4:0]            alu_waddr3,
    input [31:0]            alu_wdata3,
    input                   alu_wen4,
    input [ 4:0]            alu_waddr4,
    input [31:0]            alu_wdata4,
    
    // input                   memtoReg,
    // input [ 4:0]            mem_waddr,
    // input [31:0]            mem_rdata,

    input [ 4:0]            reg_addr,
    input [31:0]            reg_data_tmp,
    output logic [31:0]     reg_data
);
    
    always_comb begin : get_result
        if(alu_wen1 && ~(|(alu_waddr1 ^ reg_addr)))
            reg_data = alu_wdata1;
        else if(alu_wen2 && ~(|(alu_waddr2 ^ reg_addr)))
            reg_data = alu_wdata2;
        else if(alu_wen3 && ~(|(alu_waddr3 ^ reg_addr)))
            reg_data = alu_wdata3;
        else if(alu_wen4 && ~(|(alu_waddr4 ^ reg_addr)))
            reg_data = alu_wdata4;
        // else if(memtoReg && ~(|(mem_waddr ^ reg_addr)))
        //     reg_data = mem_rdata;
        else
            reg_data = reg_data_tmp;
    end

endmodule