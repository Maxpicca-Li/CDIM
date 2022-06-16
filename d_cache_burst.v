// 类sram接口 转 类axi接口
module d_cache_burst (
    input wire clk, rst, // except,no_cache,       // 这里不用实现 except 和 no_cache 两个接口
    //mips core --> cache
    input  wire        cpu_data_req     ,      //Mipscore发起读写请求  mips->cache
    input  wire        cpu_data_wr      ,      //代表当前请求是否是写请求
    input  wire [1 :0] cpu_data_size    ,      //确定数据的有效字节
    input  wire [31:0] cpu_data_addr    ,       
    input  wire [31:0] cpu_data_wdata   ,
    output wire [31:0] cpu_data_rdata   ,      //cache返回给mips的数据  cache->mips
    output wire        cpu_data_addr_ok ,      //Cache–>Mipscore  Cache 返回给 Mipscore 的地址握手成功
    output wire        cpu_data_data_ok ,

    // dcache 主方
    // 读请求
    output wire [31:0] araddr       ,
    output wire [3 :0] arlen        ,
    output wire [2 :0] arsize       ,
    output wire        arvalid      ,
    input  wire        arready      ,
    // 读响应
    input  wire [31:0] rdata        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output wire        rready       ,

    // 写请求
    output wire [31:0] awaddr       ,
    output wire [3 :0] awlen        ,
    output wire [2 :0] awsize       ,
    output wire        awvalid      ,
    input  wire        awready      ,
    // 写返回
    output wire [31:0] wdata        ,
    output wire [3 :0] wstrb        ,
    output wire        wlast        ,
    output wire        wvalid       ,
    input  wire        wready       ,
    // 写响应
    input  wire        bvalid       ,
    output wire        bready       
);
//Cache配置
    // TODO 跑不起来咱就换成4kB,cache数据容量为8KB 
    parameter  INDEX_WIDTH  = 7, OFFSET_WIDTH = 5, WAY_NUM = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam BLOCK_NUM = (1<<(OFFSET_WIDTH-2)); // 1字1block
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
//Cache存储单元
    reg                 cache_lastused[CACHE_DEEPTH - 1 : 0]; // 每行cache都有1bit lastused标志，0:way1,1:way2
    reg                 cache_valid   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag     [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    // TODO 这样占用reg资源很多
    reg [31:0]          cache_block   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0][BLOCK_NUM-1:0];
    
//CPU访问解析
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    wire [OFFSET_WIDTH-3:0] blocki;
    wire [31:0] write_cache_data;
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    assign blocki=cpu_data_addr[OFFSET_WIDTH-1:2];

    // 通过掩码确认写入的数据，位为1的代表需要更新的。
    wire [3:0] write_mask4;
    wire [31:0] write_mask32;
    //根据地址低两位和size，生成写掩码（针对sb，sh等不是写完整一个字的指令），4位对应1个字（4字节）中每个字的写使能
    assign write_mask4 = cpu_data_size==2'd0 ? 4'b0001<<cpu_data_addr[1:0] :
                        cpu_data_size==2'd1 ? 4'b0011<<cpu_data_addr[1:0] : 4'b1111;
    //位拓展：{8{1'b1}} -> 8'b11111111
    assign write_mask32 = { {8{write_mask4[3]}}, {8{write_mask4[2]}}, {8{write_mask4[1]}}, {8{write_mask4[0]}} };
    assign write_cache_data = cache_block[currused][index][blocki] & ~write_mask32 | cpu_data_wdata & write_mask32; // 默认原数据，有写请求再写入读到的数据

//cache的index下的cache line解析
    wire currused;
    wire c_valid;
    wire c_dirty;
    wire c_lastused;
    wire [TAG_WIDTH-1:0] c_tag;
    assign currused = (cache_valid[1][index] & (cache_tag[1][index]==tag)) ? 1'b1 : 
                      (cache_valid[0][index] & (cache_tag[0][index]==tag)) ? 1'b0 : 
                      !c_lastused;
    assign c_valid = cache_valid[currused][index];
    assign c_tag   = cache_tag  [currused][index];
    assign c_dirty = cache_dirty[currused][index];
    assign c_lastused = cache_lastused[index];
    
//判断是否命中
    wire hit, miss;
    assign hit  = c_valid & (c_tag == tag);  //cache line的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;

//读或写
    wire read, write;
    assign write = cpu_data_wr;
    assign read  = ~cpu_data_wr;

//FSM
    localparam IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                // 新的理解
                IDLE:   state <= cpu_data_req & miss & !c_dirty ? RM :
                                 cpu_data_req & miss &  c_dirty ? WM :
                                 IDLE;
                RM:     state <= read_finish ? IDLE : RM;
                WM:     state <= miss & c_dirty & write_finish ? RM : WM;
                
                // 不考虑缓存一致性
                // IDLE:   state <= cpu_data_req & read & miss & !c_dirty ? RM :                            // 读缺失且该位没有被修改
                //                  cpu_data_req & read & miss &  c_dirty ? WM :                            // 读缺失且该位修改过
                //                  cpu_data_req & read & hit  ? IDLE :                                     // 读命中
                //                  // cpu_data_req & write & miss & c_dirty & !write_miss_nodirty_save ? WM : // 写缺失并且dirty才写内存
                //                  cpu_data_req & write & miss & c_dirty ? WM : // 写缺失并且dirty才写内存
                //                  IDLE;   
                // RM:     state <= read & read_finish ? IDLE : RM;
                // WM:     state <= read & miss & c_dirty & write_finish ? RM :                              // 读缺失读脏，写存完毕后读存
                //                  write_finish ? IDLE :                                     // 写缺失写脏，写存完毕后恢复IDLE
                //                  WM;
            endcase
        end
    end

// 访存事务线
    reg  read_req;      //一次完整的读事务，从发出读请求到结束;读取内存请求
    reg  raddr_rcv;      //地址接收成功(addr_ok)后到结束,代表地址已经收到了
    wire read_one; // 写的每一拍数据成功
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    reg  read_finish_save;

    reg  write_req;     
    reg  waddr_rcv; 
    reg  wdata_rcv;     
    wire write_one; // 读的每一拍数据返回
    wire write_finish;
    
    assign read_one = raddr_rcv && (rvalid && rready);
    assign write_one = waddr_rcv && (wvalid && wready);
    assign read_finish = raddr_rcv && (rvalid && rready && rlast);
    assign write_finish = waddr_rcv && wdata_rcv && (bvalid && bready);

    always @(posedge clk) begin
        // 读事务
        read_req <= rst ? 1'b0 :
                    (state==RM) & ~read_req ? 1'b1 : // 避免阻塞在RM阶段 ~read_req
                    read_finish ? 1'b0 :read_req;
        // 写事务
        write_req<= rst ? 1'b0 :
                    (state==WM) & ~write_req ? 1'b1 :
                    write_finish ? 1'b0 :write_req;

        raddr_rcv<= rst ? 1'b0 :
                    arvalid & arready ? 1'b1:
                    read_finish ? 1'b0 :raddr_rcv;

        waddr_rcv<= rst ? 1'b0 :
                    awvalid & awready ? 1'b1:
                    write_finish ? 1'b0 :waddr_rcv;

        wdata_rcv<= rst        ? 1'b0 :
                    write_req && wvalid && wready && wlast ? 1'b1 :
                    write_finish    ? 1'b0 : wdata_rcv;
        
        read_finish_save <= rst ? 1'b0:
                            read_finish ? 1'b1 :
                            1'b0;
    end
    
// 数据对接
reg [OFFSET_WIDTH-3:0]ri;
reg [OFFSET_WIDTH-3:0]wi;
reg [31:0] rdata_blocki;
always @(posedge clk) begin
    ri <= rst ? 1'd0:
          read_finish ? 1'b0:
          read_one ? ri+1 : ri;
    wi <= rst ? 1'd0:
          write_finish ? 1'b0:
          write_one ? wi+1 : wi;
    rdata_blocki <= rst ? 32'b0:
                    read_one && ri==blocki ? rdata:
                    rdata_blocki;
end

// CPU接口的输出对接
wire no_mem;
assign no_mem = (state==IDLE) && cpu_data_req && hit;
assign cpu_data_rdata   = hit ? cache_block[currused][index][blocki] : rdata_blocki; 
assign cpu_data_addr_ok = no_mem | (read && arvalid && arready) ||(write && awvalid && awready); // FIXME 感觉这里要拖到3个周期
// assign cpu_data_data_ok = no_mem || (raddr_rcv && rvalid && rready && rlast) || (waddr_rcv && bvalid && bready); // 按照状态机模式，缺失访存，都以RM收尾，所以只需要判断RM即可。
// assign cpu_data_data_ok = no_mem || read_finish_save; // 最好延迟一个周期，遇到读存blocki=7的数据，不能够及时返回 // FIXME 感觉这样写会多很多周期，可以做一个判断吗？如果blocki==7，就等一下；<7，就直接返回read_finish
assign cpu_data_data_ok = no_mem || (blocki_save==3'b111 ? read_finish_save : read_finish); // 最好延迟一个周期，遇到读存blocki=7的数据，不能够及时返回 // FIXME 感觉这样写会多很多周期，可以做一个判断吗？如果blocki==7，就等一下；<7，就直接返回read_finish

// 类AXI接口的输出对接
// 读请求
assign araddr  = {tag,index}<<OFFSET_WIDTH;// output wire [31:0] 
assign arlen   = BLOCK_NUM-1; // output wire [3 :0] 
assign arsize  = cpu_data_size;// output wire [2 :0] 
assign arvalid = read_req && !raddr_rcv;// output wire
// 读响应
assign rready  = raddr_rcv;// output wire
// 写请求
assign awaddr  =  {c_tag,index} << OFFSET_WIDTH ;// output wire [31:0] 
assign awlen   = BLOCK_NUM-1;// output wire [3 :0] 
assign awsize  = 2'b10;// output wire [2 :0] 
assign awvalid = write_req && !waddr_rcv;// output wire        
// 写返回
assign wdata   = cache_block[currused_save][index_save][wi];// output wire [31:0]，因为只会涉及到写脏数据，不会涉及将cpu_data_wdata写入内存的问题
assign wstrb = 4'b1111;  // 写回的数据，是需要全部写回哦
// assign wstrb   = cpu_data_size==2'd0 ? 4'b0001<<cpu_data_addr[1:0] :
//                  cpu_data_size==2'd1 ? 4'b0011<<cpu_data_addr[1:0] : 4'b1111; // output wire [3 :0] 
assign wlast   = wi==awlen;// output wire        
assign wvalid  = waddr_rcv & ~wdata_rcv;// output wire        
// 写响应
assign bready  = waddr_rcv;// output wire        


//更新cache
    

    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    reg [OFFSET_WIDTH-3:0] blocki_save;
    reg c_lastused_save;
    reg currused_save;
    reg [31:0]write_cache_data_save;
    always @(posedge clk) begin
        tag_save        <= rst ? 0 :
                         cpu_data_req ? tag : tag_save;
        index_save      <= rst ? 0 :
                         cpu_data_req ? index : index_save;
        blocki_save <=  rst ? 0 :
                        cpu_data_req ? blocki : blocki_save;
        c_lastused_save <= rst ? 0 :
                         cpu_data_req ? c_lastused : c_lastused_save;
        currused_save <= rst ? 0 :
                         cpu_data_req ? currused : currused_save;
        write_cache_data_save <= rst ? 0 : 
                                 cpu_data_req ? write_cache_data : write_cache_data_save;
    end

    // 写cache
    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache置为无效
                cache_valid[0][t] <= 1'b0;
                cache_valid[1][t] <= 1'b0;
                
                cache_dirty[0][t] <= 1'b0; 
                cache_dirty[1][t] <= 1'b0; 
                
                cache_lastused[t] <= 1'b0;
            end
        end
        else begin
            // 缺失涉及到替换way，涉及到访存后再写的（**地址握手**），都需要使用_save信号
            if(read_one) begin  // 读缺失，读存结束，此时**地址握手**已经完成
                // $display("缺失读存"); // 直接写
                cache_valid[currused_save][index_save] <= 1'b1;             //将Cache line置为有效
                cache_tag  [currused_save][index_save] <= tag_save;
                cache_block[currused_save][index_save][ri] <= rdata; //写入Cache line
                cache_dirty[currused_save][index_save] <= 1'b0;
                cache_lastused[index_save] <= currused_save;
            end
            if(cpu_data_req & read & hit) begin
                // $display("读命中"); // 直接写
                cache_lastused[index] <= currused;
            end
            if(cpu_data_req & write & hit) begin   // 写命中时需要写Cache
                // $display("写命中"); // 直接写
                cache_block[currused][index][blocki] <= write_cache_data;             // 写入Cache line，使用index而不是index_save
                cache_dirty[currused][index] <= 1'b1;                         // 写命中时需要将脏位置为1
                cache_lastused[index] <= currused;
            end
            if(write & (state==RM) & read_finish) begin
                // $display("写缺失，先读存后写cache");
                cache_lastused[index_save] <= currused_save;
                cache_valid[currused_save][index_save] <= 1'b1;             //将Cache line置为有效
                cache_dirty[currused_save][index_save] <= 1'b1;
                cache_tag  [currused_save][index_save] <= tag_save;
                cache_block[currused_save][index_save][blocki_save] <= write_cache_data_save;
            end 
        end
    end
endmodule