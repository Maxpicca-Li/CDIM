`timescale 1ns / 1ps
`include "defines.vh"
module trap_judge(
        input [ 3:0]        trap_type,
        input [31:0]        value1,value2,

        output logic        exp_trap
    );

    /*
    // Controlled Variable Experiment: wns = -0.167 ns
    assign exp_trap = trap_type == `TT_TEQ  ? !(|(value1^value2)) :
                      trap_type == `TT_TNE  ?  (|(value1^value2)) :
                      trap_type == `TT_TGE  ? $signed(value1) >= $signed(value2) :
                      trap_type == `TT_TGEU ? value1 >= value2 :
                      trap_type == `TT_TLT  ? $signed(value1) < $signed(value2) :
                      trap_type == `TT_TLTU ? value1 < value2 :
                      1'b0;
    */
    
    // Controlled Variable Experiment: wns = 0.039 ns
    assign exp_trap = (trap_type == `TT_TEQ ) & !(|(value1^value2)) |
                      (trap_type == `TT_TNE ) &  (|(value1^value2)) |
                      (trap_type == `TT_TGE ) & $signed(value1) >= $signed(value2) |
                      (trap_type == `TT_TGEU) & value1 >= value2 |
                      (trap_type == `TT_TLT ) & $signed(value1) < $signed(value2) |
                      (trap_type == `TT_TLTU) & value1 < value2 ;

endmodule
