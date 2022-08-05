`include "defines.vh"

module int_raiser(
    input int_info info_i,
    output int_o
);

assign int_o = info_i.int_allowed & (|(info_i.IM & info_i.IP));

endmodule