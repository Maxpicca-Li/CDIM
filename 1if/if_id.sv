`timescale 1ns / 1ps

module if_id(
    input  logic                clk,
    input  logic                rst,
    input  logic                flush,
    input  logic                delay_rst,                // 下一条master指令是延迟槽指令，要存起来
    input  logic                master_is_branch,         // 延迟槽判断
    output logic                master_is_in_delayslot_o, // 延迟槽判断结果
    output logic                occupy,                   // 表示register占位

    input  logic                D_ena1,    // master是否发射
    input  logic                D_en2,    // slave是否发射
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
    logic [31:0]  delayslot_data;
    logic [31:0]  delayslot_addr;
    logic         delayslot_stall; // 还在读取相关数据
    logic         delayslot_enable; // 需要读取延迟槽的数据
    
    // delayslot judge
    always_ff @(posedge clk)begin
        if(rst) 
            master_is_in_delayslot_o <= 1'b0;
        else if(!D_ena1)
            master_is_in_delayslot_o <= master_is_in_delayslot_o;
        else if(master_is_branch && !D_en2)
            master_is_in_delayslot_o <= 1'b1;
        else 
            master_is_in_delayslot_o <= 1'b0;
    end

    // E阶段跳转判断
    always_ff @(posedge clk) begin  // 当前指令在需要执行的延迟槽中
        if(delay_rst && ~D_ena1) begin // 初步判断
            delayslot_enable <= 1'b1;
            delayslot_data  <= D_data1;
            delayslot_addr  <= D_addr1;
        end
        else if(D_ena1) begin // 清空
            delayslot_enable <= 1'b0;
            delayslot_data   <= 32'd0;
            delayslot_addr   <= 32'd0;
        end
    end

    // occupy judge
    always_ff @(posedge clk) begin
        if({F_inst_ok1, F_inst_ok2, D_ena1, D_en2}==4'b1110) begin
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
            occupy_data <= D_data2;
            occupy_addr <= D_addr2;
        end
        else begin
            occupy      <= 0;
            occupy_data <= 0;
            occupy_addr <= 0;
        end
    end

    // if_id
    always_comb begin
        if(rst | flush) begin
            D_data1   <= 0;
            D_data2   <= 0;
            D_addr1   <= 0;
            D_addr2   <= 0;
            D_inst_ok1<= 0;
            D_inst_ok2<= 0;
        end
        else if(delayslot_enable) begin
            D_data1   <= delayslot_data;
            D_data2   <= 0;
            D_addr1   <= delayslot_addr;
            D_addr2   <= 0;
            D_inst_ok1<= 1;
            D_inst_ok2<= 0;
        end
        else if(occupy) begin
            D_data1   <= occupy_data;
            D_data2   <= 0;
            D_addr1   <= occupy_addr;
            D_addr2   <= 0;
            D_inst_ok1<= 1;
            D_inst_ok2<= 0;
        end
        else if(F_inst_ok1 & F_inst_ok2) begin
            D_data1   <= F_data1;
            D_data2   <= F_data2;
            D_addr1   <= F_addr1;
            D_addr2   <= F_addr2;
            D_inst_ok1<= 1;
            D_inst_ok2<= 1;
        end 
        else if(F_inst_ok1) begin
            D_data1   <= F_data1;
            D_data2   <= 0;
            D_addr1   <= F_addr1;
            D_addr2   <= 0;
            D_inst_ok1<= 1;
            D_inst_ok2<= 0;
        end 
        else begin
            D_data1   <= D_data1;
            D_data2   <= D_data2;
            D_addr1   <= D_addr1;
            D_addr2   <= D_addr2;
            D_inst_ok1<= 0;
            D_inst_ok2<= 0;
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
        else if(D_en2)
            slave_cnt <= slave_cnt + 1;
    end
    wire [64:0] total_cnt = master_cnt + slave_cnt;

endmodule