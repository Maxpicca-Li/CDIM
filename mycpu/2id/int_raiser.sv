`include "defines.vh"

module int_raiser(
    input int_info info_i,
    input id_ena,
    output int_o
);

assign int_o = info_i.int_allowed & id_ena & (|(info_i.IM & info_i.IP));

endmodule