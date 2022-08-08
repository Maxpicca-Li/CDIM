`timescale 1ns / 1ps
`include "defines.vh"

module branch_judge(
        input               branch_ena,
        input [ 3:0]        branch_type,
        input [31:0]        rs_value,rt_value,
        output logic        branch_take,
        input               pred_take,
        output logic        pred_fail
);
    assign pred_fail = branch_ena & (pred_take ^ branch_take);
    assign branch_take  =   (branch_ena & branch_type == `BT_BEQ   & rs_value==rt_value) |
                            (branch_ena & branch_type == `BT_BNE   & rs_value!=rt_value) |
                            (branch_ena & branch_type == `BT_BGTZ  & ((rs_value[31]==1'b0)&&(rs_value!=32'h0))) |
                            (branch_ena & branch_type == `BT_BLEZ  & ((rs_value[31]==1'b1)||(rs_value==32'h0))) |
                            (branch_ena & branch_type == `BT_BGEZ_ &  rs_value[31]==1'b0) |
                            (branch_ena & branch_type == `BT_BLTZ_ &  rs_value[31]==1'b1) ;

endmodule
