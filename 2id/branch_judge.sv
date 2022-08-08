`timescale 1ns / 1ps
`include "defines.vh"

module branch_judge(
        input               branch_ena,
        input [ 3:0]        branch_type,
        input [31:0]        offset,
        input [25:0]        j_target,
        input [31:0]        rs_value,rt_value,
        input [31:0]        pc_plus4,

        output logic        branch_taken,
        output logic [31:0] pc_branch_address

    );
    logic [31:0] pc_branch;
    assign pc_branch = pc_plus4 + offset;
    assign pc_branch_address =  {32{branch_type == `BT_BEQ   && rs_value==rt_value}}                        & pc_branch |
                                {32{branch_type == `BT_BNE   && rs_value!=rt_value}}                        & pc_branch |
                                {32{branch_type == `BT_BGTZ  && ((rs_value[31]==1'b0)&&(rs_value!=32'h0))}} & pc_branch |
                                {32{branch_type == `BT_BLEZ  && ((rs_value[31]==1'b1)||(rs_value==32'h0))}} & pc_branch |
                                {32{branch_type == `BT_BGEZ_ &&  rs_value[31]==1'b0}}                       & pc_branch |
                                {32{branch_type == `BT_BLTZ_ &&  rs_value[31]==1'b1}}                       & pc_branch |
                                {32{branch_type == `BT_JREG}}                                               & rs_value  |
                                {32{branch_type == `BT_J}}                                                  & {pc_plus4[31:28], j_target, 2'b00};
    assign branch_taken =   (branch_ena & branch_type == `BT_BEQ   && rs_value==rt_value) |
                            (branch_ena & branch_type == `BT_BNE   && rs_value!=rt_value) |
                            (branch_ena & branch_type == `BT_BGTZ  && ((rs_value[31]==1'b0)&&(rs_value!=32'h0))) |
                            (branch_ena & branch_type == `BT_BLEZ  && ((rs_value[31]==1'b1)||(rs_value==32'h0))) |
                            (branch_ena & branch_type == `BT_BGEZ_ &&  rs_value[31]==1'b0) |
                            (branch_ena & branch_type == `BT_BLTZ_ &&  rs_value[31]==1'b1) |
                            (branch_ena & branch_type == `BT_JREG) |
                            (branch_ena & branch_type == `BT_J) ;

endmodule
