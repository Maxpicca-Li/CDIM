`timescale 1ns / 1ps

module d_confreg(
    input wire clk, rst,
    //tlb
    input wire no_cache,
    //datapath
    input wire data_enE,
    input wire data_en,
    input wire [31:0] data_addr,
    output wire [31:0] data_rdata,
    input wire [1:0] data_rlen,
    input wire [3:0] data_wen,
    input wire [31:0] data_wdata,
    output wire stall,
    input wire [31:0] mem_addrE,
    input wire mem_read_enE,
    input wire mem_write_enE,
    input wire stallM,
    //arbitrater
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire [2:0] arsize,
    output wire arvalid,
    input wire arready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready,

    //write
    output wire [31:0] awaddr,
    output wire awvalid,
    input wire awready,
    
    output wire [31:0] wdata,
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,

    input wire bvalid,
    output wire bready,
    output wire cfg_writting
    );
    wire read, write; //表示此条访存指令是写还是读
    assign read = data_en & ~(|data_wen);   //load
    assign write = data_en & |data_wen;     //store

    reg read_req;       //一次读事务
    reg write_req;      //一次写事务
    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功
    wire data_back;     //读事务一次数据握手成功
    wire data_go;       //写事务一次数据握手成功
    wire read_finish;   //读事务完毕
    wire write_finish;  //写事务完毕
    reg [31:0] saved_rdata;
        //reg [7:0] awlen_test;
    wire data_go;
    assign data_go = waddr_rcv & (wvalid & wready); 
    assign cfg_writting = write_req;

    reg [1:0] state;
    parameter IDLE = 2'b00, Judge = 2'b01 , READ = 2'b10, WRITE = 2'b11;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin 
            case(state)
                IDLE : state <= data_enE & ~stallM ? Judge : IDLE;
                Judge: state <= data_en & read ? READ : WRITE;
                READ : state <= ~read_req ? IDLE : state;
                WRITE: state <= ~write_req ? IDLE : state;
            endcase
        end
    end
    always @(posedge clk) begin
        read_req <=  (rst) ?  1'b0 :
                    (state==Judge) & data_en & read & ~read_req ? 1'b1 :
                    read_finish      ? 1'b0 : read_req;
        
        write_req <= (rst) ?  1'b0 : 
                    (state==Judge) & data_en && write? 1'b1 :
                     write_finish       ? 1'b0 : write_req;
    end

    always @(posedge clk) begin
        raddr_rcv <= rst             ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : raddr_rcv;
        waddr_rcv <= rst             ? 1'b0 :
                    awvalid&&awready ? 1'b1 :
                    write_finish     ? 1'b0 : waddr_rcv;
        wdata_rcv <= rst                  ? 1'b0 :
                    wvalid&&wready&&wlast ? 1'b1 :
                    write_finish          ? 1'b0 : wdata_rcv;
    end

    assign arvalid = read_req & ~raddr_rcv;
    assign awvalid = write_req & ~waddr_rcv;
    
    always @(posedge clk) begin
        saved_rdata <= no_cache & read_finish ? rdata : saved_rdata;
    end

    assign read_finish = raddr_rcv & (rvalid & rready & rlast);
    assign write_finish = waddr_rcv & wdata_rcv & (bvalid & bready);
    assign stall = ~(state==IDLE || state==WRITE&&~data_enE);

    assign wvalid = waddr_rcv & ~wdata_rcv;
    assign bready = waddr_rcv;

    assign data_rdata = saved_rdata;

    assign araddr = data_addr;
    assign rready = raddr_rcv;

    assign wlast = write_req & ~write_finish;
    //assign awlen = 8'd0;
    assign arlen = 8'd0;
    assign arsize = {1'b0,data_rlen};

    
    assign awaddr = data_addr;
    assign wdata  = data_wdata;
    assign wstrb  = data_wen;
endmodule
