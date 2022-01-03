// 类sram接口 转 类axi接口
module i_cache_burst (
    input  clk, 
    input  rst,

    // cpu come
    input         cpu_inst_req     , 
    input         cpu_inst_wr      , 
    input  [31:0] cpu_inst_wdata   ,
    input  [1 :0] cpu_inst_size    , 
    input  [31:0] cpu_inst_addr    ,
    output logic [31:0] cpu_inst_rdata1  , 
    output logic [31:0] cpu_inst_rdata2  , 
    output logic        cpu_inst_addr_ok , 
    output logic        cpu_inst_data_ok,
    output logic        cpu_inst_data_ok1,
    output logic        cpu_inst_data_ok2,

    // icache 主方
    // 读请求
    output logic [31:0] araddr       ,
    output logic [3 :0] arlen        ,
    output logic [2 :0] arsize       ,
    output logic        arvalid      ,
    input         arready      ,
    // 读响应
    input  [31:0] rdata        ,
    input         rlast        ,
    input         rvalid       ,
    output logic        rready       
);

//Cache配置
    parameter  INDEX_WIDTH  = 7, OFFSET_WIDTH = 5, WAY_NUM = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam BLOCK_NUM = (1<<(OFFSET_WIDTH-2)); // 1字1block
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
//Cache存储单元
    reg                 cache_lastused[CACHE_DEEPTH - 1 : 0]; // 每行cache都有1bit lastused标志，0:way1,1:way2
    reg                 cache_valid   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag     [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    // TODO 这样占用reg资源很多
    reg [31:0]          cache_block   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0][BLOCK_NUM-1:0];
    
//CPU访问解析
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    wire [OFFSET_WIDTH-3:0] blocki;
    // TODO 需要提供当前的block_num吗？
    assign index = cpu_inst_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_inst_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    assign blocki=cpu_inst_addr[OFFSET_WIDTH-1:2];


//cache的index下的cache line解析
    wire currused;
    wire c_valid;
    wire c_lastused;
    wire [TAG_WIDTH-1:0] c_tag;
    assign currused = (cache_valid[1][index] & (cache_tag[1][index]==tag)) ? 1'b1 : 
                      (cache_valid[0][index] & (cache_tag[0][index]==tag)) ? 1'b0 : 
                      !c_lastused;
    assign c_valid = cache_valid[currused][index];
    assign c_tag   = cache_tag  [currused][index];
    assign c_lastused = cache_lastused[index];
    
//判断是否命中
    wire hit, miss;
    assign hit  = cpu_inst_req & c_valid & (c_tag == tag);  //cache line的valid位为1，且tag与地址中tag相等
    assign miss = cpu_inst_req & ~hit;

//读或写
    wire read;
    assign read  = 1'b1;

// 访存事务线
    reg  read_req;      //一次完整的读事务，从发出读请求到结束;读取内存请求
    reg  raddr_rcv;      //地址接收成功(addr_ok)后到结束,代表地址已经收到了
    wire read_one; // 写的每一拍数据成功
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    
//FSM
    localparam IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:   state <= cpu_inst_req & read & miss ? RM : IDLE;
                RM:     state <= read_finish ? IDLE : RM;
            endcase
        end
    end

    always @(posedge clk) begin
        // 读事务
        read_req <= rst ? 1'b0 :
                    (state==RM)&~read_req ? 1'b1 :  // 过滤一层判断
                    read_finish ? 1'b0 :read_req;
        
        raddr_rcv<= rst ? 1'b0 :
                    read_req & arvalid & arready ? 1'b1:
                    read_finish ? 1'b0 :raddr_rcv;
    end
    
    assign read_one = raddr_rcv && (rvalid && rready);
    assign read_finish = raddr_rcv && (rvalid && rready && rlast);

    
// 数据对接
reg [OFFSET_WIDTH-3:0]ri;
reg [31:0] rdata_blocki;
reg [31:0] rdata_blockii;
always @(posedge clk) begin
    ri <= rst ? 1'd0:
          read_finish ? 1'b0:
          read_one ? ri+1 : ri;
    // BUG 感觉这里会延迟一个周期
    rdata_blocki <= rst ? 32'b0:
                    (read_one && ri==blocki) ? rdata:
                    rdata_blocki;
    rdata_blockii <= rst ? 32'b0:
                    (read_one && ri==blocki+3'd1) ? rdata:
                    rdata_blocki;
end


// CPU接口的输出对接
wire no_mem;
assign no_mem = (state==IDLE) && cpu_inst_req & read & hit;
assign cpu_inst_addr_ok = no_mem | (arvalid && arready);

// [VRFC 10-1280] procedural assignment to a non-register cpu_inst_data_ok1 is not permitted, left-hand side should be reg/integer/time/genvarHDL:undefined(VRFC 10-1280)
// why? I also hate verilog!
// okk! I love system verilog!
always_comb begin: set_cpu_output_
    cpu_inst_data_ok  = 1'b0;
    cpu_inst_data_ok1 = 1'b0;
    cpu_inst_data_ok2 = 1'b0;
    cpu_inst_rdata1   = 32'd0;
    cpu_inst_rdata2   = 32'd0;
    if(no_mem) begin
        // TODO icache取指比较稳定，其实可以到16字
        cpu_inst_data_ok = 1'b1;
        cpu_inst_data_ok1 = 1'b1;
        cpu_inst_data_ok2 = ~(&blocki); // 如果data1在多字中的最后一个字，则data2不处理
        cpu_inst_rdata1 = cache_block[currused][index][blocki];
        cpu_inst_rdata2 = (&blocki) ? 32'd0 : cache_block[currused][index][blocki+1];
    end
    else if (raddr_rcv && rvalid && rready && rlast) begin
        cpu_inst_data_ok = 1'b1;
        cpu_inst_data_ok1 = raddr_rcv && rvalid && rready && rlast;
        cpu_inst_data_ok2 = raddr_rcv && rvalid && rready && rlast && (~(&blocki)); // 如果data1在多字中的最后一个字，则data2不处理
        cpu_inst_rdata1 = rdata_blocki;
        cpu_inst_rdata2 = (&blocki) ? 32'd0 : rdata_blockii;
    end
end

// 类AXI接口的输出对接
// 读请求
assign araddr  = {tag,index}<<OFFSET_WIDTH;// output wire [31:0] 
assign arlen   = BLOCK_NUM-1; // output wire [3 :0] 
assign arsize  = cpu_inst_size;// output wire [2 :0] 
assign arvalid = read_req && !raddr_rcv;// output wire
// 读响应
assign rready  = raddr_rcv;// output wire


//更新cache
    
    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    reg [OFFSET_WIDTH-3:0] blocki_save;
    reg c_lastused_save;
    reg currused_save;
    always @(posedge clk) begin
        tag_save        <= rst ? 0 :
                         cpu_inst_req ? tag : tag_save;
        index_save      <= rst ? 0 :
                         cpu_inst_req ? index : index_save;
        blocki_save <=  rst ? 0 :
                        cpu_inst_req ? blocki : blocki_save;
        c_lastused_save <= rst ? 0 :
                         cpu_inst_req ? c_lastused : c_lastused_save;
        currused_save <= rst ? 0 :
                         cpu_inst_req ? currused : currused_save;
    end

    // 写cache
    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache置为无效
                cache_valid[0][t] <= 1'b0;
                cache_valid[1][t] <= 1'b0;
                cache_lastused[t] <= 1'b0;
            end
        end
        else begin
            // 缺失涉及到替换way，涉及到访存后再写的（**地址握手**），都需要使用_save信号
            if(read_one) begin  // 读缺失，读存结束，此时**地址握手**已经完成
                // $display("读缺失读存结束"); 
                // $display("currused_save = %h",currused_save);
                cache_valid[currused_save][index_save] <= 1'b1;             //将Cache line置为有效
                cache_tag  [currused_save][index_save] <= tag_save;
                cache_block[currused_save][index_save][ri] <= rdata; //写入Cache line
                cache_lastused[index_save] <= currused_save;
            end
            else if(cpu_inst_req & read & hit) begin
                // $display("读命中"); 更新lastused
                cache_lastused[index] <= currused;
            end
        end
    end
endmodule