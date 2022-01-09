`timescale 1ns / 1ps

// 参考实现：https://github.com/name1e5s/Sirius/blob/SiriusG/hdl/ifu/instruction_fifo.sv
module inst_fifo(
        input                       clk,
        input                       rst,
        input                       fifo_rst,                 // fifo读写指针重置位
        input                       master_is_branch,         // 延迟槽判断
        output logic                master_is_in_delayslot_o, // 延迟槽判断结果

        input                       read_en1,    // master是否发射
        input                       read_en2,    // slave是否发射
        output logic [31:0]         read_data1,  // 指令
        output logic [31:0]         read_data2,
        output logic [31:0]         read_addres1, // 指令地址，即pc
        output logic [31:0]         read_addres2, 

        input                       write_en1, // 数据读回 ==> inst_ok & inst_ok_1
        input                       write_en2, // 数据读回 ==> inst_ok & inst_ok_2
        input [31:0]                write_address1, // pc
        input [31:0]                write_address2,  
        input [31:0]                write_data1, // inst写入
        input [31:0]                write_data2, 
        
        output logic                empty, 
        output logic                almost_empty,  
        output logic                full
);

    // fifo结构
    reg [31:0]  data[0:15];
    reg [31:0]  address[0:15];

    // fifo控制
    reg [3:0] write_pointer;
    reg [3:0] read_pointer;
    reg [3:0] data_count;

    // fifo状态
    assign full     = &data_count[3:1]; // 1110(装不下两条指令了) 
    assign empty    = (data_count == 4'd0); //0000
    assign almost_empty = (data_count == 4'd1); //0001

    // fifo读
    wire [31:0] _read_data1 = data[read_pointer];
    wire [31:0] _read_data2 = data[read_pointer + 4'd1];
    wire [31:0] _read_addres1 = address[read_pointer];
    wire [31:0] _read_addres2 = address[read_pointer + 4'd1];

    // 简易版处理延迟槽：若master是分支指令，slave没发射，则下一次的master一定是在延迟槽，延迟槽不因非except之外的其他因素而清空
    // 取指限制：注意需要保证fifo中至少有一条指令
    always_ff @(posedge clk)begin
        if(rst) 
            master_is_in_delayslot_o = 1'b0;
        else if(master_is_branch) begin 
            if(!read_en2) 
                master_is_in_delayslot_o = 1'b1;
            else 
                master_is_in_delayslot_o = 1'b0;
        end
        else    master_is_in_delayslot_o = 1'b0;
    end

    always_comb begin : read_data
        if(empty) begin
            read_data1      = 32'd0;
            read_data2      = 32'd0;
            read_addres1    = 32'd0;
            read_addres2    = 32'd0;
        end
        else if(almost_empty) begin
            // 只能取一条数据
            read_data1       = _read_data1;
            read_data2       = 32'd0;
            read_addres1    = _read_addres1;
            read_addres2    = 32'd0;
        end 
        else begin
            // 可以取两条数据
            read_data1       = _read_data1;
            read_data2       = _read_data2;
            read_addres1    = _read_addres1;
            read_addres2    = _read_addres2;
        end
    end

    // 写入数据更新
    always_ff @(posedge clk) begin : write_data 
        if(~rst & write_en1) begin
            data[write_pointer] <= write_data1;
            address[write_pointer] <= write_address1;
        end
        if(~rst & write_en2) begin
            data[write_pointer + 4'd1] <= write_data2;
            address[write_pointer + 4'd1] <= write_address2;
        end
    end
    
    always_ff @(posedge clk) begin : update_write_pointer
        if(fifo_rst)
            write_pointer <= 4'd0;
        else if(write_en1 && write_en2)
            write_pointer <= write_pointer + 4'd2;
        else if(write_en1)
            write_pointer <= write_pointer + 4'd1;
    end

    always_ff @(posedge clk) begin : update_read_pointer
        if(fifo_rst)
            read_pointer <= 4'd0;
        else if(empty)
            read_pointer <= read_pointer;
        else if(read_en1 && read_en2)
            read_pointer <= read_pointer + 4'd2;
        else if(read_en1)
            read_pointer <= read_pointer + 4'd1;
    end

    always_ff @(posedge clk) begin : update_counter
        if(fifo_rst)
            data_count <= 4'd0;
        else if(empty) begin
            // 只写不读
            case({write_en1, write_en2})
            2'b10: begin
                data_count  <= data_count + 4'd1;
            end
            2'b11: begin
                data_count  <= data_count + 4'd2;
            end
            default:
                data_count  <= data_count;
            endcase
        end
        else begin
            // 有写有读，且写优先，1优先 ==>{11,10,00}{11,10,00}
            case({write_en1, write_en2, read_en1, read_en2})
            4'b1100: begin
                data_count  <= data_count + 4'd2;
            end
            4'b1110, 4'b1000: begin
                data_count  <= data_count + 4'd1;
            end
            4'b1011, 4'b0010: begin
                data_count  <= data_count - 4'd1;
            end
            4'b0011: begin
                data_count  <= data_count == 4'd1 ? 4'd0 : data_count - 4'd2;
            end
            default:
                data_count  <= data_count;
            endcase
        end
    end


endmodule