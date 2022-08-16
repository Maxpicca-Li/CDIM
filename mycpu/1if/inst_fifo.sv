`timescale 1ns / 1ps
`include "defines.vh"

// 参考实现：https://github.com/name1e5s/Sirius/blob/SiriusG/hdl/ifu/instruction_fifo.sv
module inst_fifo(
        input                       clk,
        input                       rst,
        input                       fifo_rst,                 // fifo读写指针重置位
        input                       flush_delay_slot,
        input                       delay_sel_rst,
        input                       D_delay_rst,              // 下一条master指令是延迟槽指令，要存起来
        input                       E_delay_rst,              // 下一条master指令是延迟槽指令，要存起来
        input                       D_ena,
        input                       i_stall,
        input                       master_is_branch,         // 延迟槽判断
        output logic                master_is_in_delayslot_o, // 延迟槽判断结果

        input                       read_en1,    // master是否发射
        input                       read_en2,    // slave是否发射                   
        output                      read_tlb_refill1,
        output                      read_tlb_refill2,
        output                      read_tlb_invalid1,
        output                      read_tlb_invalid2,
        output logic [31:0]         read_data1,  // 指令
        output logic [31:0]         read_data2,
        output logic [31:0]         read_address1, // 指令地址，即pc
        output logic [31:0]         read_address2, 

        input                       write_en1, // 数据读回 ==> inst_ok & inst_ok_1
        input                       write_en2, // 数据读回 ==> inst_ok & inst_ok_2
        input                       write_tlb_refill1,
        input                       write_tlb_refill2,
        input                       write_tlb_invalid1,
        input                       write_tlb_invalid2,
        input [31:0]                write_address1, // pc
        input [31:0]                write_address2,  
        input [31:0]                write_data1, // inst写入
        input [31:0]                write_data2, 
        
        output logic                empty, 
        output logic                almost_empty,  
        output logic                full
);

    // fifo结构
    fifo_entry  lines[0:15];
    fifo_entry  read_line1, read_line2;
    fifo_entry  write_line1, write_line2;
    fifo_entry  delayslot_line;
    reg         delayslot_stall; // 还在读取相关数据
    reg         delayslot_enable; // 需要读取延迟槽的数据

    // fifo控制
    reg [3:0] write_pointer;
    reg [3:0] read_pointer;
    reg [3:0] data_count;

    // INPUT and OUTPUT
    assign write_line1 = '{default:'0, refill:write_tlb_refill1, invalid:write_tlb_invalid1, addr:write_address1, data:write_data1};
    assign write_line2 = '{default:'0, refill:write_tlb_refill2, invalid:write_tlb_invalid2, addr:write_address2, data:write_data2};
    assign read_tlb_refill1  = read_line1.refill;
    assign read_tlb_refill2  = read_line2.refill;
    assign read_tlb_invalid1 = read_line1.invalid;
    assign read_tlb_invalid2 = read_line2.invalid;
    assign read_address1     = read_line1.addr;
    assign read_address2     = read_line2.addr;
    assign read_data1        = read_line1.data;
    assign read_data2        = read_line2.data;

    // fifo状态
    assign full     = &data_count[3:1] || (write_pointer+4'd1==read_pointer); // 1110(装不下两条指令了) 
    assign empty    = (data_count == 4'd0); //0000
    assign almost_empty = (data_count == 4'd1); //0001

    // 延迟槽判断
    always_ff @(posedge clk)begin
        if(rst | flush_delay_slot) 
            master_is_in_delayslot_o <= 1'b0;
        else if(!read_en1)
            master_is_in_delayslot_o <= master_is_in_delayslot_o;
        else if(master_is_branch && !read_en2)
            master_is_in_delayslot_o <= 1'b1;
        else 
            master_is_in_delayslot_o <= 1'b0;
    end

    always_ff @(posedge clk) begin // 延迟槽读取信号
        if (rst) begin
            delayslot_stall  <= 1'd0;
        end
        else if(fifo_rst && delay_sel_rst && !flush_delay_slot && i_stall && (read_pointer + 4'd1 == write_pointer || read_pointer == write_pointer)) begin
            delayslot_stall   <= 1'd1;
        end
        else if(delayslot_stall && write_en1)
            delayslot_stall  <= 1'd0;
        else
            delayslot_stall   <= delayslot_stall;
    end
    always_ff @(posedge clk) begin // 下一条指令在需要执行的延迟槽中
        if (rst) begin
            delayslot_enable <= 1'b0;
            delayslot_line   <= '{default:'0};
        end
        else if(fifo_rst & !flush_delay_slot & delay_sel_rst) begin // 初步判断
            if(E_delay_rst) begin
                delayslot_enable <= 1'b1;
                delayslot_line   <= (read_pointer == write_pointer) ? write_line1 : lines[read_pointer];
            end
            else if(D_delay_rst) begin
                delayslot_enable <= 1'b1;
                delayslot_line   <= (read_pointer + 4'd1 == write_pointer) ? write_line1 : lines[read_pointer + 4'd1];
            end
            else begin
                delayslot_enable <= 1'b0;
                delayslot_line   <= '{default:'0};
            end
        end
        else if(!delayslot_stall && read_en1) begin // 清空
            delayslot_enable <= 1'b0;
            delayslot_line   <= '{default:'0};
        end
    end

    /*
    // E阶段跳转判断
    always_ff @(posedge clk) begin  // 当前指令在需要执行的延迟槽中
        if(fifo_rst && D_delay_rst && ~read_en1) begin // 初步判断
            delayslot_enable <= 1'b1;
            delayslot_data  <= read_data1;
            delayslot_addr  <= read_address1;
        end
        else if(read_en1) begin // 清空
            delayslot_enable <= 1'b0;
            delayslot_data   <= 32'd0;
            delayslot_addr   <= 32'd0;
        end
    end
    */

    // fifo读
    always_comb begin  // 取指限制：注意需要保证fifo中至少有一条指令
        if(delayslot_enable) begin
            read_line1 = delayslot_line;
            read_line2 = '{default: '0};
        end
        else if(empty) begin
            read_line1 = '{default: '0};
            read_line2 = '{default: '0};
        end
        else if(almost_empty) begin
            // 只能取一条数据
            read_line1 = lines[read_pointer];
            read_line2 = '{default: '0};
        end 
        else begin
            // 可以取两条数据
            read_line1 = lines[read_pointer];
            read_line2 = lines[read_pointer + 4'd1];
        end
    end

    // fifo写
    always_ff @(posedge clk) begin : write_data 
        if(write_en1) begin
            lines[write_pointer] <= write_line1;
        end
        if(write_en2) begin
            lines[write_pointer + 4'd1] <= write_line2;
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
        end else if(empty || delayslot_enable) begin
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

    // 统计
    reg [64:0] slave_cnt;
    reg [64:0] master_cnt;
    always_ff @(posedge clk) begin
        if(rst)
            master_cnt <= 0;
        else if(read_en1 && (!empty || master_is_in_delayslot_o))
            master_cnt <= master_cnt + 1;
    end
    
    always_ff @(posedge clk) begin
        if(rst)
            slave_cnt <= 0;
        else if(read_en2 && (!empty && !master_is_branch && !almost_empty))
            slave_cnt <= slave_cnt + 1;
    end

    wire [64:0] total_cnt = master_cnt + slave_cnt;

endmodule