module mmu (
    input wire [31:0] inst_vaddr,
    input wire [31:0] inst_vaddr2,
    input wire [31:0] data_vaddr,
    input wire [31:0] data_vaddr2,

    output wire [31:0] data_paddr,
    output wire [31:0] data_paddr2,
    output wire [31:0] inst_paddr,
    output wire [31:0] inst_paddr2,

    output wire no_cache_d,
    output wire no_cache_E,
    output wire no_cache_i
);

    assign inst_paddr = inst_vaddr[31:30]==2'b10 ? //kseg0 + kseg1
                {3'b0, inst_vaddr[28:0]} :          //直接映射：去掉高3位
                inst_vaddr;

    assign inst_paddr2 = inst_vaddr2[31:30]==2'b10 ?
                {3'b0, inst_vaddr2[28:0]} :         
                inst_vaddr2;

    assign data_paddr = data_vaddr[31:30]==2'b10 ?
                {3'b0, data_vaddr[28:0]} :        
                data_vaddr;

    assign data_paddr2 = data_vaddr2[31:30]==2'b10 ?
                {3'b0, data_vaddr2[28:0]} :         
                data_vaddr2;
    
    assign no_cache_d = (data_vaddr[31:29] == 3'b101) //kseg1
                        ? 1'b1 : 1'b0;
    assign no_cache_E = (data_vaddr2[31:29] == 3'b101) //kseg1
                        ? 1'b1 : 1'b0;
    assign no_cache_i = (inst_vaddr[31:29] == 3'b101) //kseg1
                        ? 1'b1 : 1'b0;
    
endmodule
