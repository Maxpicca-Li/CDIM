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

        output      [31:0]  pc_next,
        output      [31:0]  pc_curr
    );
    
    reg  [31:0] pc_reg;
    logic [31:0] pc_next_wire;
    
    // OUTPUT
    assign pc_curr = pc_reg;
    assign pc_next = pc_next_wire;

    // 中间逻辑
    always_ff @(posedge clk) begin
        pc_reg <= pc_next_wire;
    end

    always_comb begin : compute_pc_next
        if (rst) 
            pc_next_wire = 32'hbfc00000;
        else if (is_except) // 异常跳转
            pc_next_wire = except_addr;
        else if(branch_taken) // 分支跳转
            pc_next_wire = branch_addr;
        else if(fifo_full) // full保持
            pc_next_wire = pc_curr;
        else if(inst_data_ok1 && inst_data_ok2)
            pc_next_wire = pc_curr + 32'd8;
        else if(inst_data_ok1)
            pc_next_wire = pc_curr + 32'd4;
        else
            pc_next_wire = pc_curr;
    end

endmodule
