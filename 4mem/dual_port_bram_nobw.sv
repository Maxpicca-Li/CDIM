module dual_port_bram_nobw #(
    parameter LEN_DATA = 20,
    parameter LEN_ADDR = 8
) (clka,clkb,ena,enb,wea,addra,addrb,dina,doutb);
    input clka,clkb,ena,enb,wea;
    input [LEN_ADDR-1:0] addra,addrb;
    input [LEN_DATA-1:0] dina;
    output [LEN_DATA-1:0] doutb;

    parameter DEPTH = 2**LEN_ADDR;

    (* ram_style="block" *) reg [LEN_DATA-1:0] ram [DEPTH-1:0];

    reg [LEN_DATA-1:0] doutb;

    integer j;
    initial begin
        for (j=0;j<DEPTH;j++) ram[j] = 0;
    end
    
    always @(posedge clka) begin
        if (ena) if (wea) ram[addra] <= dina;
    end
    
    always @(posedge clkb) begin
        if (enb)
            doutb <= ram[addrb];
    end
endmodule