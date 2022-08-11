`timescale 1ns/1ps
module pc_reg (
        input               clk,
        input               rst,
        input               pc_en,
        input               M_except,
        input       [31:0]  M_except_addr,
        input               E_pred_fail,
        input               E_branch_take,
        input               E_next_pc8,
        input       [31:0]  E_branch_target,
        input       [31:0]  E_pc_plus4,
        input       [31:0]  E_pc_plus8,
        input               E_jump_conflict,
        input       [31:0]  E_rs_value,
        input               M_flush_all,
        input       [31:0]  M_flush_all_addr,
        input               D_branch_take,
        input       [31:0]  D_branch_target,
        input               D_jump_take,
        input       [31:0]  D_jump_target,
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
        // else if (pc_en) begin
            else if (M_except)
                pc_next = M_except_addr;            
            else if (E_pred_fail & E_branch_take)
                pc_next = E_branch_target;
            else if (E_pred_fail & !E_branch_take)
                pc_next = E_next_pc8 ? E_pc_plus8 : E_pc_plus4;
            else if (E_jump_conflict) 
                pc_next = E_rs_value;
            else if (M_flush_all)
                pc_next = M_flush_all_addr;
            else if (D_branch_take)
                pc_next = D_branch_target;
            else if (D_jump_take) 
                pc_next = D_jump_target;
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
