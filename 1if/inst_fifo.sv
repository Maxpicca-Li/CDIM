`timescale 1ns / 1ps

// 参考实现：https://github.com/name1e5s/Sirius/blob/SiriusG/hdl/ifu/instruction_fifo.sv
module inst_fifo(
        input                       clk,
        input                       rst,
        input                       fifo_rst,                 // fifo读写指针重置位
        input                       delay_rst,                // 下一条master指令是延迟槽指令，要存起来
        input                       F_ena,
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
    reg [31:0]  delayslot_data;
    reg [31:0]  delayslot_addr;
    reg         delayslot_stall; // 还在读取相关数据

    // fifo控制
    reg [3:0] write_pointer;
    reg [3:0] read_pointer;
    reg [3:0] data_count;

    // fifo状态
    assign full     = &data_count[3:1]; // 1110(装不下两条指令了) 
    assign empty    = (data_count == 4'd0); //0000
    assign almost_empty = (data_count == 4'd1); //0001

    // 延迟槽处理  ==> 参考sirius延迟槽的处理方式
    // 升级版处理延迟槽：若master是分支指令，slave没发射，则下一次的master一定是在延迟槽，延迟槽不因非except之外的其他因素而清空; 且要保存相关数据
    always_ff @(posedge clk) begin // 延迟槽读取信号
        if(fifo_rst && delay_rst && !write_en1 && (read_pointer + 4'd1 == write_pointer || read_pointer == write_pointer)) begin
            delayslot_stall   <= 1'd1;
        end
        else if(delayslot_stall && write_en1)
            delayslot_stall   <= 1'd0;
        else if(delayslot_stall)
            delayslot_stall   <= delayslot_stall;
        else
            delayslot_stall   <= 1'd0;
    end

    always_ff @(posedge clk) begin // 下一条指令是延迟槽，存储延迟槽数据
        if(fifo_rst && delay_rst) begin // 初步判断
            master_is_in_delayslot_o <= 1'b1;
            delayslot_data  <= (read_pointer + 4'd1 == write_pointer || read_pointer == write_pointer)? write_data1 : data[read_pointer + 4'd1];
            delayslot_addr  <= (read_pointer + 4'd1 == write_pointer || read_pointer == write_pointer)? write_address1 : address[read_pointer + 4'd1];
        end
        else if(delayslot_stall && write_en1) begin // 要写的数据回来了
            delayslot_data    <= write_data1;
        end
        else if(!delayslot_stall && read_en1) begin // 清空
            master_is_in_delayslot_o <= 1'b0;
            delayslot_data           <= 32'd0;
            delayslot_addr           <= 32'd0;
        end
    end
    
    // fifo读
    // 1、取指限制：注意需要保证fifo中至少有一条指令
    // always_comb begin : read_data
    // 2、转成时序逻辑, 其中read_pointer和master_is_in_delayslot_o需要1个周期
    // 故read_data共要2个周期，达成同步
    // always_ff @(posedge clk)begin
    // 3、下降沿读，去模拟组合逻辑，但是留给D阶段的只剩半个clk了（因为单独的组合逻辑会导致：FATAL_ERROR: Iteration limit 10000 is reached. Possible zero delay oscillation detected where simulation time can not advance. Please check your source code. Note that the iteration limit can be changed using switch -maxdeltaid.）
    always_ff @(negedge clk)begin 
        if(master_is_in_delayslot_o) begin
            read_data1      <= delayslot_data;
            read_data2      <= 32'd0;
            read_addres1    <= delayslot_addr;
            read_addres2    <= 32'd0;
        end
        else if(empty || fifo_rst) begin
            read_data1      <= 32'd0;
            read_data2      <= 32'd0;
            read_addres1    <= 32'd0;
            read_addres2    <= 32'd0;
        end
        else if(!F_ena) begin
            read_data1      <= read_data1;
            read_data2      <= read_data2;
            read_addres1    <= read_addres1;
            read_addres2    <= read_addres2;
        end
        else if(!F_ena || almost_empty) begin
            // 只能取一条数据
            read_data1      <= data[read_pointer];
            read_data2      <= 32'd0;
            read_addres1    <= address[read_pointer];
            read_addres2    <= 32'd0;
        end 
        else begin
            // 可以取两条数据
            read_data1      <= data[read_pointer];
            read_data2      <= data[read_pointer + 4'd1];
            read_addres1    <= address[read_pointer];
            read_addres2    <= address[read_pointer + 4'd1];
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
        if(fifo_rst) begin
            read_pointer <= 4'd0;
        end else if(empty || !F_ena) begin
            read_pointer <= read_pointer;
        end else if(read_en1 && read_en2) begin
            read_pointer <= read_pointer + 4'd2;
        end else if(read_en1) begin
            read_pointer <= read_pointer + 4'd1;
        end
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