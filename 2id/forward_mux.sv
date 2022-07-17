`timescale 1ns / 1ps

module forwarding_mux(
    input                   E_slave_reg_wen,
    input [ 4:0]            E_slave_reg_waddr,
    input [31:0]            E_slave_reg_wdata,
    input                   E_master_reg_wen,
    input [ 4:0]            E_master_reg_waddr,
    input [31:0]            E_master_reg_wdata,
    input                   M_slave_reg_wen,
    input [ 4:0]            M_slave_reg_waddr,
    input [31:0]            M_slave_reg_wdata,
    input                   M_master_reg_wen,
    input [ 4:0]            M_master_reg_waddr,
    input [31:0]            M_master_reg_wdata,
    input [ 4:0]            reg_addr,
    input [31:0]            reg_data,
    output logic [31:0]     result_data
);

    always_comb begin : get_result
        if(|reg_addr) begin
            if(E_slave_reg_wen && E_slave_reg_waddr == reg_addr)
                result_data = E_slave_reg_wdata;
            else if(E_master_reg_wen && E_master_reg_waddr == reg_addr)
                result_data = E_master_reg_wdata;
            else if(M_slave_reg_wen && M_slave_reg_waddr == reg_addr)
                result_data = M_slave_reg_wdata;
            else if(M_master_reg_wen && M_master_reg_waddr == reg_addr)
                result_data = M_master_reg_wdata;
            else
                result_data = reg_data;
        end
        else begin
            result_data = 32'd0;
        end
    end

endmodule