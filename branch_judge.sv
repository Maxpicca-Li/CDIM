`timescale 1ns / 1ps
`include "defines.vh"

// EX: judge, compute pc_branch_target
module branch_judge(
        input [ 3:0]        branch_type,
        input [31:0]        offset,
        input [25:0]        j_target,
        input [31:0]        rs_data,rt_data,
        input [31:0]        pc_plus4,

        output logic        branch_taken,
        output logic [31:0] pc_branch_address

    );
    // TODO: optmize==> which quiker: unique case? assign? if-elseif-else?
    // unique case: need decode branch_type in ID
    always_comb begin :branch_compute
        if(branch_type == `BT_BEQ && rs_data==rt_data) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if(branch_type == `BT_BNE && rs_data!=rt_data) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BGTZ  && ((rs_data[31]==1'b0)&&(rs_data!=32'h0))) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BLEZ  && ((rs_data[31]==1'b1)||(rs_data==32'h0))) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BGEZ_ &&  rs_data[31]==1'b0) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_BLTZ_ &&  rs_data[31]==1'b1) begin
            branch_taken = 1'b1;
            pc_branch_address = pc_plus4 + offset;
        end
        else if (branch_type ==`BT_J) begin
            branch_taken = 1'b1;
            pc_branch_address = {pc_plus4[31:28], j_target, 2'b00};
        end
        else if (branch_type == `BT_JREG) begin
            branch_taken = 1'b1;
            pc_branch_address = rs_data;
        end
        else begin // branch_type = `BT_NOP
            branch_taken = 1'b0;
            pc_branch_address = 32'hxxxxxxxx;
        end
    end

endmodule
