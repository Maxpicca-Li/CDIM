`timescale 1ns / 1ps

module if_id(
    input  logic                clk,
    input  logic                rst,
    input  logic                flush_rst,
    input  logic                delay_rst,                // 下一条master指令是延迟槽指令，要存起来
    input  logic                master_is_branch,         // 延迟槽判断
    output logic                master_is_in_delayslot_o, // 延迟槽判断结果
    output logic                occupy,                   // 表示register占位

    input  logic                D_ena1,    // master是否发射
    input  logic                D_ena2,    // slave是否发射
    output logic                D_inst_ok1,  
    output logic                D_inst_ok2,
    output logic [31:0]         D_data1,  
    output logic [31:0]         D_data2,
    output logic [31:0]         D_addr1,
    output logic [31:0]         D_addr2, 

    input logic                 F_inst_ok1,
    input logic                 F_inst_ok2,
    input logic [31:0]          F_addr1,
    input logic [31:0]          F_addr2,  
    input logic [31:0]          F_data1,
    input logic [31:0]          F_data2        
);
    // occupy
    logic [31:0]  occupy_data;
    logic [31:0]  occupy_addr;
    // delay
    logic         delayslot_stall; // 还在读取相关数据
    logic         delayslot_enable; // 需要读取延迟槽的数据
    logic [31:0]  delayslot_data;
    logic [31:0]  delayslot_addr;
    // save reg
    logic [31:0] D_data1_save;
    logic [31:0] D_data2_save;
    logic [31:0] D_addr1_save;
    logic [31:0] D_addr2_save;
    logic        D_inst_ok1_save;
    logic        D_inst_ok2_save;
    
    // if_id
    always_ff @(posedge clk) begin
        if(rst | flush_rst) begin
            D_data1_save    <= 0;
            D_data2_save    <= 0;
            D_addr1_save    <= 0;
            D_addr2_save    <= 0;
            D_inst_ok1_save <= 0;
            D_inst_ok2_save <= 0;
        end 
        else if (D_ena1 & !occupy) begin
            D_data1_save    <= F_data1;
            D_data2_save    <= F_data2;
            D_addr1_save    <= F_addr1;
            D_addr2_save    <= F_addr2;
            D_inst_ok1_save <= F_inst_ok1;
            D_inst_ok2_save <= F_inst_ok2;
        end
    end

    always_ff @(posedge clk)begin : get_master_is_in_delayslot
        if(rst) 
            master_is_in_delayslot_o <= 1'b0;
        else if(!D_ena1)
            master_is_in_delayslot_o <= master_is_in_delayslot_o;
        else if(master_is_branch && !D_ena2)
            master_is_in_delayslot_o <= 1'b1;
        else 
            master_is_in_delayslot_o <= 1'b0;
    end

    // delayslot judge in E
    always_ff @(posedge clk) begin   // 当前指令在需要执行的延迟槽中
        if(delay_rst && ~D_ena1) begin // 初步判断
            delayslot_enable <= 1'b1;
            delayslot_data   <= D_data1;
            delayslot_addr   <= D_addr1;
        end
        else if(D_ena1) begin // 清空
            delayslot_enable <= 1'b0;
            delayslot_data   <= 32'd0;
            delayslot_addr   <= 32'd0;
        end
    end

    // occupy judge
    always_ff @(posedge clk) begin
        if(rst | flush_rst) begin
            occupy      <= 0;
            occupy_data <= 0;
            occupy_addr <= 0;
        end
        else if({D_inst_ok1, D_inst_ok2, D_ena1, D_ena2}==4'b1110) begin
            occupy      <= 1'b1;
            occupy_data <= D_data2;
            occupy_addr <= D_addr2;
        end 
        else if (!occupy && {D_inst_ok1, D_inst_ok2, D_ena1, D_ena2}==4'b0010) begin
            occupy      <= 1'b1;
            occupy_data <= D_data2;
            occupy_addr <= D_addr2;
        end
        else if (occupy && D_ena1) begin
            occupy      <= 0;
            occupy_data <= 0;
            occupy_addr <= 0;
        end
        else if(!D_ena1) begin
            occupy      <= occupy;
            occupy_data <= occupy_data;
            occupy_addr <= occupy_addr;
        end
        else begin
            occupy      <= 0;
            occupy_data <= 0;
            occupy_addr <= 0;
        end
    end

    // 输出判断
    always_comb begin
        if(delayslot_enable) begin
            D_data1    = delayslot_data;
            D_data2    = 0;
            D_addr1    = delayslot_addr;
            D_addr2    = 0;
            D_inst_ok1 = 1;
            D_inst_ok2 = 0;
        end
        else if(occupy) begin
            D_data1    = occupy_data;
            D_data2    = 0;
            D_addr1    = occupy_addr;
            D_addr2    = 0;
            D_inst_ok1 = 1;
            D_inst_ok2 = 0;
        end
        else if(delay_rst) begin
            D_data1    = D_data1_save;
            D_data2    = 0;
            D_addr1    = D_addr1_save;
            D_addr2    = 0;
            D_inst_ok1 = 1;
            D_inst_ok2 = 0;
        end
        else begin
            if(D_inst_ok1_save) begin
                D_data1    = D_data1_save   ;
                D_addr1    = D_addr1_save   ;
                D_inst_ok1 = D_inst_ok1_save;
            end
            else begin
                D_data1    = 0;
                D_addr1    = 0;
                D_inst_ok1 = 0;
            end
            
            if(D_inst_ok2_save) begin
                D_data2    = D_data2_save   ;
                D_addr2    = D_addr2_save   ;
                D_inst_ok2 = D_inst_ok2_save;    
            end
            else begin
                D_data2    = 0;
                D_addr2    = 0;
                D_inst_ok2 = 0;
            end
        end
    end

    // stat
    reg [64:0] slave_cnt;
    reg [64:0] master_cnt;
    always_ff @(posedge clk) begin
        if(rst)
            master_cnt <= 0;
        else if(D_ena1 && (master_is_in_delayslot_o || occupy))
            master_cnt <= master_cnt + 1;
    end
    always_ff @(posedge clk) begin
        if(rst)
            slave_cnt <= 0;
        else if(D_ena2)
            slave_cnt <= slave_cnt + 1;
    end
    wire [64:0] total_cnt = master_cnt + slave_cnt;

endmodule