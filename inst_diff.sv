module inst_diff(
    // datapath
    input inst_sram_en,
    input [31:0] pc_fetch,
    output logic        inst_data_ok,
    output logic        inst_data_ok1,
    output logic        inst_data_ok2,
    output logic [31:0] inst_rdata1,
    output logic [31:0] inst_rdata2,
    
    // inst_ram_64
    input [63:0] inst_sram_rdata,
    output logic [31:0] inst_sram_addr
);
    
    // FIXME 这里是否需要时许逻辑，检测clk下降沿
    assign inst_sram_addr = {pc_fetch[31:3],3'b000};
    assign inst_data_ok = inst_sram_en;
    assign inst_data_ok1 = inst_sram_en;
    assign inst_data_ok2 = pc_fetch[2]==1'b0;
    assign inst_rdata1 = pc_fetch[2] ? inst_sram_rdata[31:0] : inst_sram_rdata[63:32];
    assign inst_rdata2 = pc_fetch[2] ? 32'd0 : inst_sram_rdata[31:0];

endmodule