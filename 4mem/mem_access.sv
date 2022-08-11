`timescale 1ns / 1ps

module mem_access (
        input               mem_en,
        input        [ 5:0] mem_op,
        input        [31:0] mem_wdata, // writedata_4B
        input        [31:0] mem_addr,
        output logic [31:0] mem_rdata,

        input        [31:0] data_sram_rdata,
        output logic        data_sram_en,
        output logic [ 1:0] data_sram_rlen, // nr_bytes to read. 0: 1, 1: 2, 2: 4
        output logic [ 3:0] data_sram_wen,
        output logic [31:0] data_sram_addr,
        output logic [31:0] data_sram_wdata,

        // 异常处理
        input                      M_master_mem_sel,
        input                      M_slave_mem_sel,
        input  except_bus          M_master_except,
        input  except_bus          M_slave_except
    );

    assign data_sram_en    = mem_en && ((M_master_mem_sel && ~(|M_master_except)) || (M_slave_mem_sel && ~(|M_master_except) && ~(|M_slave_except)));// && mem_addr != 32'hbfaffff0;
    assign data_sram_addr  = mem_addr;
    logic [31:0] mem_init_data;
    assign mem_init_data = mem_wdata;
                
    always_comb begin:mem_access_transform
        data_sram_wen = 4'b0000;
        mem_rdata = 0;
        data_sram_wdata = 0;
        data_sram_rlen = 0;
        case(mem_op)
            `OP_LW: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd2;
                mem_rdata = data_sram_rdata;
            end
            `OP_LL: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd2;
                mem_rdata = data_sram_rdata;
            end
            `OP_LH: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd1;
                mem_rdata = {32{mem_addr[1:0]==2'b10}} & {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]} |
                            {32{mem_addr[1:0]==2'b00}} & {{16{data_sram_rdata[15]}},data_sram_rdata[15: 0]} ;
            end
            `OP_LHU: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd1;
                mem_rdata = {32{mem_addr[1:0]==2'b10}} & {{16{1'b0}},data_sram_rdata[31:16]} |
                            {32{mem_addr[1:0]==2'b00}} & {{16{1'b0}},data_sram_rdata[15: 0]} ;
            end
            `OP_LB: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd0;
                mem_rdata = {32{mem_addr[1:0]==2'b11}} & {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]} |
                            {32{mem_addr[1:0]==2'b10}} & {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]} |
                            {32{mem_addr[1:0]==2'b01}} & {{24{data_sram_rdata[15]}},data_sram_rdata[15: 8]} |
                            {32{mem_addr[1:0]==2'b00}} & {{24{data_sram_rdata[ 7]}},data_sram_rdata[7 : 0]} ;
            end
            `OP_LBU: begin
                data_sram_wen = 4'b0000;
                data_sram_rlen = 2'd0;
                mem_rdata = {32{mem_addr[1:0]==2'b11}} & {{24{1'b0}},data_sram_rdata[31:24]} |
                            {32{mem_addr[1:0]==2'b10}} & {{24{1'b0}},data_sram_rdata[23:16]} |
                            {32{mem_addr[1:0]==2'b01}} & {{24{1'b0}},data_sram_rdata[15: 8]} |
                            {32{mem_addr[1:0]==2'b00}} & {{24{1'b0}},data_sram_rdata[7 : 0]} ;
            end
            `OP_LWL: begin
                data_sram_rlen = 2'd2;
                mem_rdata = {32{mem_addr[1:0]==2'b11}} & ((data_sram_rdata      ) | (mem_init_data & 32'h0       )) |
                            {32{mem_addr[1:0]==2'b10}} & ((data_sram_rdata << 8 ) | (mem_init_data & 32'h000000ff)) |
                            {32{mem_addr[1:0]==2'b01}} & ((data_sram_rdata << 16) | (mem_init_data & 32'h0000ffff)) |
                            {32{mem_addr[1:0]==2'b00}} & ((data_sram_rdata << 24) | (mem_init_data & 32'h00ffffff)) ;
            end
            `OP_LWR: begin
                data_sram_rlen = 2'd2;
                mem_rdata = {32{mem_addr[1:0]==2'b11}} & ((data_sram_rdata >> 24) | (mem_init_data & 32'hffffff00)) |
                            {32{mem_addr[1:0]==2'b10}} & ((data_sram_rdata >> 16) | (mem_init_data & 32'hffff0000)) |
                            {32{mem_addr[1:0]==2'b01}} & ((data_sram_rdata >> 8 ) | (mem_init_data & 32'hff000000)) |
                            {32{mem_addr[1:0]==2'b00}} & ((data_sram_rdata      ) | (mem_init_data & 32'h0       )) ;
            end
            `OP_SW: begin
                data_sram_rlen = 2'd2;
                data_sram_wen = {4{mem_addr[1:0]==2'b00}} & 4'b1111;
                data_sram_wdata = mem_wdata;
            end
            `OP_SWL: begin
                data_sram_rlen = 2'd2;
                data_sram_wen = ~((4'b1110) << mem_addr[1:0]); // ~ 按位取反
                data_sram_wdata = {32{mem_addr[1:0]==2'b11}} & (mem_init_data      ) |
                                  {32{mem_addr[1:0]==2'b10}} & (mem_init_data >> 8 ) |
                                  {32{mem_addr[1:0]==2'b01}} & (mem_init_data >> 16) |
                                  {32{mem_addr[1:0]==2'b00}} & (mem_init_data >> 24) ;
            end
            `OP_SWR: begin
                data_sram_rlen = 2'd2;
                data_sram_wen = (4'b1111) << mem_addr[1:0]; // ~ 按位取反
                data_sram_wdata = {32{mem_addr[1:0]==2'b11}} & (mem_init_data << 24) |
                                  {32{mem_addr[1:0]==2'b10}} & (mem_init_data << 16) |
                                  {32{mem_addr[1:0]==2'b01}} & (mem_init_data << 8 ) |
                                  {32{mem_addr[1:0]==2'b00}} & (mem_init_data      ) ;
            end
            `OP_SC: begin
                data_sram_rlen = 2'd2;
                data_sram_wen = {4{mem_addr[1:0]==2'b00}} & 4'b1111;
                data_sram_wdata = mem_wdata;
            end
            `OP_SH: begin
                data_sram_rlen = 2'd1;
                data_sram_wen = {4{mem_addr[1:0]==2'b10}} & 4'b1100 |
                                {4{mem_addr[1:0]==2'b00}} & 4'b0011 ;
                data_sram_wdata = {mem_wdata[15:0],mem_wdata[15:0]};
            end
            `OP_SB: begin
                data_sram_rlen = 2'd0;
                data_sram_wen = {4{mem_addr[1:0]==2'b11}} & 4'b1000 |
                                {4{mem_addr[1:0]==2'b10}} & 4'b0100 |
                                {4{mem_addr[1:0]==2'b01}} & 4'b0010 |
                                {4{mem_addr[1:0]==2'b00}} & 4'b0001 ;
                data_sram_wdata = {mem_wdata[7:0],mem_wdata[7:0],mem_wdata[7:0],mem_wdata[7:0]};
            end
            default:begin
                data_sram_wen = 4'b0000;
            end
        endcase
    end

endmodule

