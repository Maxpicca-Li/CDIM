module i_data_bank #(
    parameter LEN_DATA = 32,
    parameter LEN_ADDR = 8
) (clka,clkb,ena,enb,wea,addra,addrb,dina,doutb);

    input clka,clkb,ena,enb;
    input [LEN_DATA/8-1:0]wea;
    input [LEN_ADDR-1:0] addra,addrb;
    input [LEN_DATA-1:0] dina;
    output [LEN_DATA-1:0] doutb;

    dual_port_bram_bw8 #(.LEN_ADDR(LEN_ADDR)) bram_inst(clka,clkb,ena,enb,wea,addra,addrb,dina,doutb);

endmodule