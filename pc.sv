`timescale 1ns/1ps

module pc (
    input                   clk,
    input                   rst,
    input                   pc_en,
    input                   inst_valid_1,    //指令是否有效
    input                   inst_valid_2,
    input                   fifo_full,

    input                   branchD,    //确认跳转
    input                   pc_branchD,  //branch target addr
 //   TODO 异常没管

    output logic [31:0]     pc_addr

);
    reg   [31:0] cur_pc_addr;
    logic [31:0] pc_addr_tmp;

    assign pc_addr = cur_pc_addr;

    always_comb begin : define_next_pc_addr
        if(rst)
            pc_addr_tmp = 32'hbfc0_0000; 
        else if(pc_en) begin
            if (branchD) begin
                pc_addr_tmp =  pc_branchD;
            end
            else if (fifo_full) begin
                pc_addr_tmp = cur_pc_addr;
            end
            else if (inst_valid_1 && inst_valid_2) begin
                pc_addr_tmp = cur_pc_addr + 32'd8;
            end
            else if (inst_valid_1) begin
                pc_addr_tmp = cur_pc_addr + 32'd4;
            end
            else begin
                pc_addr_tmp = cur_pc_addr;
            end
        end
        else begin
            pc_addr_tmp = cur_pc_addr;
        end
    end
    
        always_ff @( posedge clk ) begin : update_cur_addr
            cur_pc_addr <= pc_addr_tmp;
        end
        
endmodule
