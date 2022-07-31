

`timescale 1ns / 1ps
module d_cache_daxi (
    input wire clk, rst,
    //tlb
    input wire data_en_E,
    // input wire no_cache,
    input wire cfg_writting,
    //datapath
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
    output wire [7:0] awlen,
    //output wire [2:0] awsize,
    output wire awvalid,
    input wire awready,
    
    output wire [31:0] wdata,
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,

    input wire bvalid,
    output wire bready    
); 

    //16KB,2路组相联
    parameter TAG_WIDTH = 19, INDEX_WIDTH = 8, OFFSET_WIDTH = 5;
    parameter WAY_NUM = 2;
    localparam BLOCK_NUM= 1<<(OFFSET_WIDTH-2);
    localparam CACHE_LINE_NUM = 1<<INDEX_WIDTH;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, indexE;
    wire [OFFSET_WIDTH-3 : 0] offset;    //字里的偏移

    //这里注意index和indexE的区别, //indexE领先index一个周期, 这样做的目的是消除bram取值需要延迟一个周期的影响
    assign tag      = data_addr[31                         : INDEX_WIDTH+OFFSET_WIDTH ];  
    assign index    = data_addr[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];    
    assign indexE   = mem_addrE[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset   = data_addr[OFFSET_WIDTH-1             : 2                        ];

    //read
    wire read, write; //表示此条访存指令是写还是读
    assign read = data_en & ~(|data_wen);   //load
    assign write = data_en & |data_wen;     //store

    //cache ram
    //read
    wire [INDEX_WIDTH-1:0] addrb;

    wire [TAG_WIDTH:0] tag_way[WAY_NUM-1:0];                //读出来的tag值
    wire [31:0] block_way[WAY_NUM-1:0][BLOCK_NUM-1:0];      //读出的cache line的block
    wire [31:0] block_sel_way[WAY_NUM-1:0];                 //根据offest选出的字
    assign block_sel_way[0] = block_way[0][offset];
    assign block_sel_way[1] = block_way[1][offset];
    wire [INDEX_WIDTH-1:0] addra;       //写地址
        //tag ram
    wire [WAY_NUM-1:0] wena_tag_ram_way;
    wire [TAG_WIDTH:0] tag_ram_dina;        //tag_ram写数�?
        //data bank
    wire [3:0] wena_data_bank_way[WAY_NUM-1:0][BLOCK_NUM-1:0];     //每路每个data_bank的写使能
    wire [31:0] data_bank_dina;
    //LRU & dirty bit
    reg LRU_bit[CACHE_LINE_NUM-1:0];  //4路采�?3bit作为伪LRU算法
    reg [CACHE_LINE_NUM-1:0] dirty_bits_way[WAY_NUM-1:0];
    //hit & miss
    wire hit, miss;
    wire sel;
    wire [WAY_NUM-1:0] sel_mask;

    assign sel_mask[0] = tag_way[0] == {tag,1'b1}; 
    assign sel_mask[1] = tag_way[1] == {tag,1'b1}; 

    assign sel = sel_mask[1];
                 
    assign hit = data_en & (|sel_mask);
    assign miss = data_en & ~(|sel_mask);
    
    //evict_way
    wire evict_way;
    wire [WAY_NUM-1:0] evict_mask;

    assign evict_way = LRU_bit[index];  //根据LRU_bit选中需要替换的块,evict_way为1表示替换第1块,为0表示替换第0块

    assign evict_mask[0] = ~evict_way;  //evict_mask中哪一位为1,表示替换哪一位
    assign evict_mask[1] = evict_way;
    
    //dirty
    wire dirty;
    assign dirty = evict_mask[0] & tag_way[0][0] & dirty_bits_way[0][index] |  //该块被替换 & 该块有效 & 该块脏
                   evict_mask[1] & tag_way[1][0] & dirty_bits_way[1][index] ;
    //axi req
    reg read_req;       //一次读事务
    reg write_req;      //一次写事务
    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功
    wire data_back;     //读事务一次数据握手成功
    wire data_go;       //写事务一次数据握手成功
    wire read_finish;   //读事务完毕
    wire write_finish;  //写事务完毕
//FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, HitJudge = 2'b01, MissHandle=2'b11;
    parameter WaitCfg = 2'b10;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= (mem_read_enE | mem_write_enE) & ~stallM & data_en_E ? HitJudge : IDLE;  
                HitJudge    : state <= data_en & miss &~cfg_writting  ? MissHandle :
                                       mem_read_enE | mem_write_enE ? HitJudge :
                                       cfg_writting & miss? WaitCfg :
                                       IDLE;
                MissHandle  : state <= ~read_req & ~write_req & ~cfg_writting ? IDLE : state;
                WaitCfg     : state <= cfg_writting ? WaitCfg : MissHandle;
            endcase
        end
    end
//DATAPATH
    reg [31:0] saved_rdata;  //这是用于如果现在是写数据,马上下一条指令需要读这个数据,那么就将现在写的数据准备好,下次网上传
    wire collisionE;
    reg collisionM;
    reg [31:0] data_wdata_r;

    assign collisionE = mem_read_enE & write & hit & (mem_addrE == data_addr);
    always@(posedge clk) begin
        if(collisionE) begin
            collisionM <= 1'b1;
            data_wdata_r <= data_wdata;
        end
        else if(~stallM) begin
            collisionM <= 1'b0;
            data_wdata_r <= 32'b0;
        end
    end


    assign stall = ~(state==IDLE || state==HitJudge && !miss);
    assign data_rdata = collisionM ? data_wdata_r:
                        hit        ? block_sel_way[sel]: saved_rdata;
//AXI
    always @(posedge clk) begin
        read_req <= (rst)            ? 1'b0 : 
                    data_en && (state == HitJudge || state==WaitCfg) && miss && ~read_req && ~cfg_writting ? 1'b1 :  
                    read_finish      ? 1'b0 : read_req;
        write_req <= (rst)              ? 1'b0 :
                     data_en && (state == HitJudge || state==WaitCfg) && miss && dirty && ~read_req && ~cfg_writting ? 1'b1 :
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
    //读事务burst传输，计数当前传递的bank的编�?
    reg [OFFSET_WIDTH-3:0] cnt;  
    always @(posedge clk) begin
        cnt <= rst | ~data_en |read_finish ? 0 :
                data_back                   ? cnt + 1 : cnt;
    end
    //写事务burst传输，计数当前传递的bank的编�?
    reg [OFFSET_WIDTH-3:0] wcnt; 
    always @(posedge clk) begin
        wcnt <= rst | ~data_en |write_finish ? 0 :
                data_go                       ? wcnt + 1 : wcnt;
    end

    always @(posedge clk) begin
        saved_rdata <= rst ? 32'b0 :
                      data_back & (cnt==offset) ? rdata : saved_rdata;
    end
    assign data_back = raddr_rcv & (rvalid & rready);
    assign data_go   = waddr_rcv & (wvalid & wready); 
    assign read_finish = raddr_rcv & (rvalid & rready & rlast);
    assign write_finish = waddr_rcv & wdata_rcv & (bvalid & bready);
    //AXI signal
    //read
    assign araddr = {tag,index,5'b0}; //如果是可以cache的数据,就把8个字的起始地址传过去,否则只传一个字的地址
    assign arlen = BLOCK_NUM-1;
    assign arsize = 3'd2 ;
    assign arvalid = read_req & ~raddr_rcv & ~cfg_writting;  //assign arvalid = read_req & ~raddr_rcv;
    assign rready = raddr_rcv;
    //write
    wire [31:0] dirty_write_addr;
    assign dirty_write_addr =  //{tag, index} << OFFSET
        {(
            {TAG_WIDTH{evict_mask[0]}} & tag_way[0][TAG_WIDTH : 1]|
            {TAG_WIDTH{evict_mask[1]}} & tag_way[1][TAG_WIDTH : 1]
        ), index, {OFFSET_WIDTH{1'b0}}};
    assign awaddr = dirty_write_addr;
    assign awlen = write_req ? BLOCK_NUM-1 : 8'd0;
    //assign awsize = 3'b10 ;
    assign awvalid = write_req & ~waddr_rcv & ~cfg_writting;  //assign awvalid = write_req & ~waddr_rcv;
    assign wdata = block_way[evict_way][wcnt];
    assign wstrb = 4'b1111;
    assign wlast = {5'd0,wcnt}==awlen;
    assign wvalid = waddr_rcv & ~wdata_rcv;
    assign bready = waddr_rcv;
//LRU
    wire write_LRU_en;
    assign write_LRU_en = hit & ~stallM | read_finish;
    always @(posedge clk) begin
        if(rst) begin
            LRU_bit <= '{default:'0};
        end
        //更新LRU
        else begin
            if(write_LRU_en) begin
                //如果这次写lru是命中引起的,那么就把该index的lru值换为sel_mask[0],否则取反.关于为什么是这样的逻辑,可以简单推导下,这里不再赘述
                LRU_bit[index] <= |(sel_mask) ? sel_mask[0] : ~LRU_bit[index];
            end
        end
    end
//dirty bit
    wire write_dirty_bit_en;
    wire write_way_sel;
    wire write_dirty_bit;   //dirty被修改成�?�?
    assign write_dirty_bit_en =      read & read_finish | write & hit & ~stallM |
                                    (state==MissHandle) & read_finish;

    assign write_way_sel = write & hit ? sel : evict_way;
    assign write_dirty_bit = read ? 1'b0 : 1'b1;
    always @(posedge clk) begin
        if(rst) begin
            dirty_bits_way <= '{default:'0};
        end
        else begin
            if(write_dirty_bit_en) begin
                dirty_bits_way[write_way_sel][index] <= write_dirty_bit;
            end
        end
    end
//cache ram
    assign addrb = indexE;  //读地址. 
    //write
    assign addra = index;   //写地址
    assign wena_tag_ram_way = {WAY_NUM{read_finish}} & evict_mask;
    assign tag_ram_dina = {tag, 1'b1}; //末位是valid位
    wire [BLOCK_NUM-1:0] wena_data_bank_mask;

    decoder38 decoder0(cnt, wena_data_bank_mask); //三八译码器,根据返回回来的数据次数,选择写入到哪一个字
    genvar i;
    generate
        for(i = 0; i< BLOCK_NUM; i=i+1) begin: wena_data_bank
            mux2 #(4) mux2_way0({4{data_back & wena_data_bank_mask[i] & evict_mask[0]}}, data_wen, write & hit & (i==offset) & sel_mask[0], wena_data_bank_way[0][i]);
            mux2 #(4) mux2_way1({4{data_back & wena_data_bank_mask[i] & evict_mask[1]}}, data_wen, write & hit & (i==offset) & sel_mask[1], wena_data_bank_way[1][i]);
        end
    endgenerate
    
    wire [31:0] data_wen32;  //传进来要写的数
    assign data_wen32 = {{8{data_wen[3]}}, {8{data_wen[2]}}, {8{data_wen[1]}}, {8{data_wen[0]}}};
    assign data_bank_dina = (write & hit) ? data_wdata :
                            (write & (cnt == offset)) ? (rdata & ~data_wen32) | (data_wdata & data_wen32) :
                            rdata;
    genvar j;
    generate
        for(i = 0; i < WAY_NUM; i=i+1) begin: way
            d_tag_ram tag_ram (
                .clka(clk),  
                .ena(1'b1),   
                .wea(wena_tag_ram_way[i]),   
                .addra(addra), 
                .dina(tag_ram_dina),  

                .clkb(clk),  
                .enb(~stallM & ~collisionE),  //.enb(~stallM & ~collisionE),  
                .addrb(addrb),  
                .doutb(tag_way[i]) 
            );
            for(j = 0; j < BLOCK_NUM; j=j+1) begin: bank
                d_data_bank data_bank (
                    .clka(clk), 
                    .ena(1'b1),  
                    .wea(wena_data_bank_way[i][j]),   
                    .addra(addra), 
                    .dina(data_bank_dina),  

                    .clkb(clk),  
                    .enb(~stallM & ~collisionE), //.enb(~stallM & ~collisionE),
                    .addrb(addrb),  
                    .doutb(block_way[i][j]) 
                );
            end
        end
    endgenerate
endmodule