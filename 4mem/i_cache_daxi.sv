`timescale 1ns / 1ps

module i_cache_daxi (
    input wire clk, rst,
    input wire no_cache,
    
    //datapath
    input wire inst_en,
    input wire [31:0] pc_next,
    input wire [31:0] pcF,
    input wire stallF,
    output wire stall,
    output wire inst_data_ok1,
    output wire inst_data_ok2,
    output wire [31:0] inst_rdata1,
    output wire [31:0] inst_rdata2,

    //arbitrater
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire [2:0] arsize,
    output wire arvalid,
    input wire arready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready
);

//变量声明
    //cache configure
    parameter TAG_WIDTH = 19, INDEX_WIDTH = 8, OFFSET_WIDTH = 5;    //[WARNING]: OFFSET_WIDTH不能�?2
    parameter WAY_NUM = 2;
    localparam BLOCK_NUM= 1<<(OFFSET_WIDTH-2);
    localparam CACHE_LINE_NUM = 1<<INDEX_WIDTH;
    // parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;

    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, index_next;
    wire [OFFSET_WIDTH-3 : 0] offset1, offset2;   //字偏移量
    wire available;
    //这里注意index和indexE的区别, //indexE领先index一个周期, 这样做的目的是消除bram取值需要延迟一个周期的影响
    assign tag        = pcF     [31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index      = pcF     [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign index_next = pc_next [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset1    = pcF     [OFFSET_WIDTH-1             : 2                       ];
    assign offset2    = pcF     [OFFSET_WIDTH-1             : 2                       ] + 1;
    // assign available  = (|offset2) && (~(&offset2)); // offset2不等于0和7（7，刚好rlast=1）
    assign available  = (|offset2); // offset2不等于0

    wire enb;       //cache读使能
    wire [INDEX_WIDTH-1:0] addrb;     //cache读的地址

    wire [TAG_WIDTH:0] tag_way[WAY_NUM-1:0];           
    wire [31:0] block_way[WAY_NUM-1:0][BLOCK_NUM-1:0];    
    
    wire [31:0] block_sel_way1[WAY_NUM-1:0];     //根据offest选出的字
    wire [31:0] block_sel_way2[WAY_NUM-1:0];     

    assign block_sel_way1[0] = block_way[0][offset1];
    assign block_sel_way1[1] = block_way[1][offset1];
    assign block_sel_way2[0] = available ? block_way[0][offset2] : 32'b0;
    assign block_sel_way2[1] = available ? block_way[1][offset2] : 32'b0;

    //write
    wire [INDEX_WIDTH-1:0] addra;       //cache写地址
        //tag ram
    wire [WAY_NUM-1:0] wena_tag_ram_way;
    wire [TAG_WIDTH:0] tag_ram_dina;     
        //data bank
    wire [BLOCK_NUM-1:0] data_wdata[WAY_NUM-1:0];     //每路每个data_bank的写使能
    wire [31:0] data_bank_dina;          
    //LRU 
    reg [WAY_NUM-2:0] LRU_bit[CACHE_LINE_NUM-1:0];  //2路采用1个bit的替换算法
    //valid reg
    reg [CACHE_LINE_NUM-1:0] valid_bits_way[WAY_NUM-1:0];
    wire hit, miss;
    wire sel;
    wire [WAY_NUM-1:0] sel_mask;
    assign sel_mask[0] = tag_way[0] == {tag,1'b1}; 
    assign sel_mask[1] = tag_way[1] == {tag,1'b1}; 
    assign sel = sel_mask[1];
    assign hit = inst_en & (|sel_mask);
    assign miss = inst_en & ~(|sel_mask);
    //evict
    wire evict_way;   //改变WAY_NUM�?同时改变
    wire [WAY_NUM-1:0] evict_mask;
    assign evict_way = LRU_bit[index];
//    decoder2x4 decoder1(evict_way, evict_mask);
    assign evict_mask[0] = ~evict_way;
    assign evict_mask[1] = evict_way;                
    //AXI req
    reg read_req;       //�?次读事务
    reg addr_rcv;       //地址握手成功
    wire data_back;     //�?次数据握手成�?
    wire read_finish;   //读事务结�?
    reg  read_finish_save;
//FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, HitJudge = 2'b01, LoadMemory = 2'b11, NoCache=2'b10;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= ~stallF ? HitJudge : IDLE;
                HitJudge    : state <= inst_en & no_cache ? NoCache:
                                       inst_en & miss     ? LoadMemory : 
                                       stallF             ? IDLE : HitJudge;
                LoadMemory  : state <= read_finish ? IDLE : state; //icache不需要写回,所以这里的状态直接就是读ram
                NoCache     : state <= read_finish ? IDLE : NoCache;
            endcase
        end
    end

//AXI
    reg [31:0] saved_rdata1, saved_rdata2;
    always @(posedge clk) begin
        read_req <= (rst)               ? 1'b0 :
                    inst_en & (state == HitJudge) & miss & ~read_req ? 1'b1 :
                    inst_en & no_cache & (state == HitJudge) & ~read_req ? 1'b1 :
                    read_finish         ? 1'b0 : read_req;
    end
    
    always @(posedge clk) begin
        addr_rcv <= rst              ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : addr_rcv;
    end

    reg [OFFSET_WIDTH-3:0] cnt;  //burst传输，计数当前传递的bank的编�?
    always @(posedge clk) begin
        cnt <= rst |read_finish|no_cache ? 0 :
               data_back        ? cnt + 1 : cnt;
    end
    always @(posedge clk) begin
        saved_rdata1 <= rst                     ? 32'b0 :
                       (data_back & (cnt==offset1) & ~no_cache) | (no_cache & read_finish) ? rdata : saved_rdata1;
        saved_rdata2 <= rst                     ? 32'b0 :
                       (data_back & (cnt==offset2) & ~no_cache) | (no_cache & read_finish) ? rdata : saved_rdata2;
        read_finish_save <= rst ? 1'b0 : read_finish;
    end
    assign data_back = addr_rcv & (rvalid & rready);
    assign read_finish = addr_rcv & (rvalid & rready & rlast);

//LRU
    wire write_LRU_en;
    assign write_LRU_en = ~no_cache & hit | ~no_cache & read_finish;
    integer tt;
    always @(posedge clk) begin
        if(rst) begin
            LRU_bit <= '{default:'0};
        end
        else begin
            if(write_LRU_en) begin
                //如果这次写lru是命中引起的,那么就把该index的lru值换为sel_mask[0],否则取反.关于为什么是这样的逻辑,可以简单推导下,这里不再赘述
                LRU_bit[index] <= |(sel_mask) ? sel_mask[0] : ~LRU_bit[index];   //LOG2_WAY_NUM
            end
        end
    end
//cache ram
    //read
    assign enb = ~stallF; // assign enb = 1'b1;

    reg before_start_clk;  //标识rst结束后的第一个上升沿之前
    always @(posedge clk) begin
        before_start_clk <= rst ? 1'b1 : 1'b0;
    end
    assign addrb = before_start_clk ? index : index_next;

    //write
    assign addra = index;
        //tag ram
    assign wena_tag_ram_way = {WAY_NUM{read_finish}} & evict_mask;

    assign tag_ram_dina = {tag, 1'b1};

        //data bank
    wire [BLOCK_NUM-1:0] wena_data_mask;
        //解码�?
    decoder38 decoder0(cnt, wena_data_mask);
    
    assign data_wdata[0] = wena_data_mask & {BLOCK_NUM{data_back & evict_mask[0]}};
    assign data_wdata[1] = wena_data_mask & {BLOCK_NUM{data_back & evict_mask[1]}};
    assign data_bank_dina = rdata;
    genvar i, j;
    generate
        for(i = 0; i < WAY_NUM; i=i+1) begin: way
            i_tag_ram tag_ram (
                .clka(clk), 
                .ena(~no_cache),  
                .wea(wena_tag_ram_way[i]),  
                .addra(addra), 
                .dina(tag_ram_dina),  
                .clkb(clk),  
                .enb(enb),  
                .addrb(addrb),
                .doutb(tag_way[i])  
            );
            for(j = 0; j < BLOCK_NUM; j=j+1) begin: bank
                i_data_bank data_bank (
                    .clka(clk),  
                    .ena(~no_cache),    
                    .wea({4{data_wdata[i][j]}}),  
                    .addra(addra), 
                    .dina(data_bank_dina),   
                    .clkb(clk), 
                    .enb(enb),   
                    .addrb(addrb),  
                    .doutb(block_way[i][j])  
                );
            end
        end
    endgenerate

//DATAPATH OUTPUT
    assign stall = ~(state==IDLE || (state==HitJudge) && ~miss && ~no_cache);
    assign inst_data_ok1 = state==HitJudge & hit & ~no_cache & ~stallF ? 1'b1 : read_finish_save;              // 控制信号，需要受限制
    assign inst_data_ok2 = (state==HitJudge & hit & ~no_cache & ~stallF ? 1'b1: read_finish_save) & available; // 控制信号，需要受限制
    assign inst_rdata1 = hit & ~no_cache ? block_sel_way1[sel] : saved_rdata1;
    assign inst_rdata2 = hit & ~no_cache ? block_sel_way2[sel] : saved_rdata2;
//AXI OUTPUT
    assign araddr = ~no_cache ? {tag, index, {OFFSET_WIDTH{1'b0}} } : pcF; //如果是可以cache的数据,就把8个字的起始地址传过去,否则只传一个字的地址
    assign arlen = ~no_cache ? BLOCK_NUM-1 : 8'd0;
    assign arsize = 3'd2;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;
endmodule
