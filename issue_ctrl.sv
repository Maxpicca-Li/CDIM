`timescale 1ns / 1ps
`include "defines.vh"

module issue_ctrl (
    //master's status
    input           D_inst_priv_master,
    input           D_reg_en_master,
    input  [4:0]    D_reg_dst_master,
    input           D_hilo_accessed_master,
    input           D_en_master,

    //slave's status
    input  [5:0]    D_op_slave,
    input  [4:0]    D_rs_slave,
    input  [4:0]    D_rt_slave,
    input  [1:0]    D_mem_type_slave,
    input           D_branch_slave,
    input           D_inst_priv_slave,
    input           D_hilo_accessed_slave,
    input           D_tlb_error,

    //FIFO's status
    input           fifo_empty,
    input           fifo_almost_empty,

    //raw detection
    input [1:0]     E_mem_type,
    input [4:0]     E_mem_wb_reg_dst,

    output logic    D_en_slave

);

    logic raw_stall_slave;
    logic _en_slave;
    wire fifo_crtl = ~(fifo_empty || fifo_almost_empty);

    assign D_slave_en = _en_slave && fifo_crtl && (!raw_stall_slave);

    always_comb begin : define_slave_en
        if( (!D_en_master) ||      //2、主流水线不发，辅流水线一定不发
            (D_inst_priv_master) ||   //3、master在访问特权指令
            (D_inst_priv_slave) ||    //3、slave在访问特权指令
            (D_branch_slave) ||     //解码的是分支指令
            (D_mem_type_slave != `MEM_NOOP) ||   
            (D_hilo_accessed_slave) ||   //3、master访问hilo
            (D_tlb_error)) 
            begin
            _en_slave = 1'b0;
        end
        else begin
            if(D_reg_en_master && (D_reg_dst_master != 5'd0)) begin
                if(D_op_slave == 6'd0) begin 
                    //raw
                    _en_slave = (|((D_reg_dst_master ^ D_rs_slave) & (D_reg_dst_master ^ D_rt_slave)));
                end
                else begin
                    _en_slave = (|((D_reg_dst_master ^ D_rs_slave)));
                end
            end
            else begin
                _en_slave = 1'b1;
            end
        end
    end

    always_comb begin : define_load_stall
        if(E_mem_type == `MEM_LOAD && ((E_mem_wb_reg_dst == D_rs_slave) || (E_mem_wb_reg_dst == D_rt_slave) )) begin
            raw_stall_slave = 1'b1;
        end
        else begin
            raw_stall_slave = 1'b0;
        end
    end


endmodule