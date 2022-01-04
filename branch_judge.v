`timescale 1ns / 1ps
`include "defines.vh"

// EX: judge, compute pc_branch_target
module branch_judge(
        input wire j_instIndex, // juml | jal
        input wire jr,
        input wire [5:0] op,
        input wire [4:0] rt,
        input wire [15:0] imm,
        input wire [25:0] j_target,
        input wire [31:0] rs_data,rt_data,
        input wire [31:0] pc_curr,

        output wire branch_taken,
        output wire pc_branch_target

    );
    // TODO: optmize==> which quiker: unique case? assign? if-elseif-else?
    // unique case: need decode branch_type in ID
    wire b_taken;
    wire[31:0] pc_plus4;
    wire[31:0] b_target;
    assign pc_plus4 = pc_curr + 32'd4;
    assign b_target = pc_curr + 32'd4 + {{14{imm[15]}}, imm, 2'b00};

    // TODO: optimize ==> branch type优化
    assign b_taken =( op==`OP_BEQ)                                       ?( rs_data==rt_data)                    ://beq
           ( op==`OP_BNE)                                       ?( rs_data!=rt_data)                    ://bne
           ( op==`OP_BGTZ)                                      ?((rs_data[31]==1'b0)&&(rs_data!=32'h0))://bgtz
           ( op==`OP_BLEZ)                                      ?((rs_data[31]==1'b1)||(rs_data==32'h0))://blez
           ((op==`OP_BGEZ_)&&((rt==`RT_BGEZ)||(rt==`RT_BGEZAL)))?( rs_data[31]==1'b0)                   ://bgez,bgezal
           ((op==`OP_BLTZ_)&&((rt==`RT_BLTZ)||(rt==`RT_BLTZAL)))?( rs_data[31]==1'b1)                   ://bltz,bltzal
           1'b0;
    assign branch_taken = (b_taken || j_instIndex || jr);
    assign pc_branch_target = (j_instIndex) ? {pc_plus4[31:28], j_target, 2'b00} :
           jr ? rs_data:
           b_taken ?b_target:
           32'hxxxxxxxx;
endmodule
