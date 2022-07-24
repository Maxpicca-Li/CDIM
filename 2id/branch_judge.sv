`timescale 1ns / 1ps
//`include "defines.vh"

module branch_judge(
        input [ 3:0]        branch_type,
        input [31:0]        offset,
        input [25:0]        j_target,
        input [31:0]        rs_value,rt_value,
        input [31:0]        pc_plus4,

        output logic        branch_taken,
        output logic [31:0] pc_branch_address

    );

    always_comb begin :branch_compute
        if(branch_type == `BT_BEQ && rs_value==rt_value) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if(branch_type == `BT_BNE && rs_value!=rt_value) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BGTZ  && ((rs_value[31]==1'b0)&&(rs_value!=32'h0))) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BLEZ  && ((rs_value[31]==1'b1)||(rs_value==32'h0))) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BGEZ_ &&  rs_value[31]==1'b0) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BLTZ_ &&  rs_value[31]==1'b1) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_J) begin
            branch_taken = 1'b1;
            pc_branch_address = {pc_plus4[31:28], j_target, 2'b00};
        end
        else if (branch_type == `BT_JREG) begin
            branch_taken = 1'b1;
            pc_branch_address = rs_value;
        end
        else begin // branch_type = `BT_NOP
            branch_taken = 1'b0;
            pc_branch_address = 32'hxxxxxxxx;
        end
    end

endmodule
