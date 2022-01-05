`timescale 1ns / 1ps
`include "defines.vh"

module issue_ctrl (
    //master's status
    input           D_master_en,
    input           D_master_reg_wen,
    input [4:0]     D_master_reg_waddr,
    input           E_master_memtoReg,
    input [4:0]     E_master_reg_waddr,
    //slave's status
    input  [5:0]    D_slave_op,
    input  [4:0]    D_slave_rs,
    input  [4:0]    D_slave_rt,
    input           D_slave_mem_en,
    input           D_slave_is_branch,
    input           D_slave_is_hilo_accessed,
    //FIFO's status
    input           fifo_empty,
    input           fifo_almost_empty,

    output logic    D_slave_en

);
    
    logic load_stall;
    logic _en_slave;
    wire fifo_crtl = ~(fifo_empty || fifo_almost_empty); // fifo 限制

    assign D_slave_en = _en_slave && fifo_crtl && (!load_stall); 

    always_comb begin : define_slave_en
        if( !D_master_en || D_slave_is_branch || D_slave_mem_en || D_slave_is_hilo_accessed)
            _en_slave = 1'b0;
        else begin
            if(D_master_reg_wen && (D_master_reg_waddr != 5'd0)) begin
                if(D_slave_op == `OP_R_TYPE) begin 
                    _en_slave = (D_slave_rs != D_master_reg_waddr) && (D_slave_rt != D_master_reg_waddr);
                end
                else begin
                    _en_slave = D_slave_rs != D_master_reg_waddr;
                end
            end
            else begin
                _en_slave = 1'b1;
            end
        end
    end

    always_comb begin : define_load_stall
        if(E_master_memtoReg && ((D_slave_rs == E_master_reg_waddr) || (D_slave_rt == E_master_reg_waddr) )) begin
            load_stall = 1'b1;
        end
        else begin
            load_stall = 1'b0;
        end
    end

endmodule