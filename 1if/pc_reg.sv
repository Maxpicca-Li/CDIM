`timescale 1ns/1ps
module pc_reg (
        input               clk,
        input               rst,
        input               pc_en,
        input               M_except,
        input       [31:0]  M_except_addr,
        input               M_flush_all,
        input       [31:0]  M_flush_all_addr,
        input               E_bj,
        input       [31:0]  E_bj_target,
        input               D_bj,
        input       [31:0]  D_bj_target,
        input               D_fifo_full,
        input               F_inst_data_ok1,
        input               F_inst_data_ok2,

        output logic[31:0]  pc_next,
        output      [31:0]  pc_curr
    );

    // 中间逻辑
    reg  [31:0] pc_reg;
    always_ff @(posedge clk) begin
        pc_reg <= pc_next;
    end

    always_comb begin : compute_pc_next
        if (rst) 
            pc_next = 32'hbfc00000;
            // pc_next = 32'h80100000;
            // pc_next = 32'h80000000;
        // else if (pc_en) begin
            else if (M_except)
                pc_next = M_except_addr;
            else if (M_flush_all)
                pc_next = M_flush_all_addr;            
            else if (E_bj)
                pc_next = E_bj_target;
            else if (D_bj)
                pc_next = D_bj_target;
            else if (D_fifo_full)
                pc_next = pc_curr;
            else if (F_inst_data_ok1 && F_inst_data_ok2)
                pc_next = pc_curr + 32'd8;
            else if (F_inst_data_ok1)
                pc_next = pc_curr + 32'd4;
            else
                pc_next = pc_curr;
        // end else begin
        //     pc_next = pc_curr;
        // end
    end

    // OUTPUT
    assign pc_curr = pc_reg;

endmodule
