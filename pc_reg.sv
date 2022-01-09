`timescale 1ns/1ps
module pc_reg (
        input               clk,
        input               rst,
        input               pc_en,
        input               inst_data_ok1,
        input               inst_data_ok2,
        input               fifo_full,
        input               is_except,
        input       [31:0]  except_addr,
        input               branch_taken,
        input       [31:0]  branch_addr,

        output logic[31:0]  pc_curr
    );
    
    reg [31:0] pc_reg;
    logic[31:0] pc_next;
    assign pc_curr = pc_reg;

    always_ff @(posedge clk) begin
        if(rst)
            pc_reg <= 32'hbfc00000;
        else if(pc_en)
            pc_reg <= pc_next;
        else
            pc_reg <= pc_reg;
    end

    always_comb begin : compute_pc_next
        if (is_except) // 异常跳转
            pc_next = except_addr;
        else if(branch_taken) // 分支跳转
            pc_next = branch_addr;
        else if(fifo_full) // full保持
            pc_next = pc_curr;
        else if(inst_data_ok1 && inst_data_ok2)
            pc_next = pc_curr + 32'd8;
        else if(inst_data_ok1)
            pc_next = pc_curr + 32'd4;
        else
            pc_next = pc_curr;
    end

endmodule
