`timescale 1ns / 1ps

module trap_judge(
        input [ 3:0]        trap_type,
        input [31:0]        rs_value,rt_value,

        output logic        exp_trap
    );

    assign exp_trap = trap_type == `TT_TEQ  ? !(|(rs_value^rt_value)) :
                      trap_type == `TT_TNE  ?  (|(rs_value^rt_value)) :
                      trap_type == `TT_TGE  ? $signed(rs_value) >= $signed(rt_value) :
                      trap_type == `TT_TGEU ? rs_value >= rt_value :
                      trap_type == `TT_TLT  ? $signed(rs_value) < $signed(rt_value) :
                      trap_type == `TT_TLTU ? rs_value < rt_value :
                      1'b0;

endmodule
