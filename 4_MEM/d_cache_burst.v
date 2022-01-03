// ��sram�ӿ� ת ��axi�ӿ�
module d_cache_burst (
    input wire clk, rst, // except,no_cache,       // ���ﲻ��ʵ�� except �� no_cache �����ӿ�
    //mips core --> cache
    input  wire        cpu_data_req     ,      //Mipscore�����д����  mips->cache
    input  wire        cpu_data_wr      ,      //����ǰ�����Ƿ���д����
    input  wire [1 :0] cpu_data_size    ,      //ȷ�����ݵ���Ч�ֽ�
    input  wire [31:0] cpu_data_addr    ,       
    input  wire [31:0] cpu_data_wdata   ,
    output wire [31:0] cpu_data_rdata   ,      //cache���ظ�mips������  cache->mips
    output wire        cpu_data_addr_ok ,      //Cache�C>Mipscore  Cache ���ظ� Mipscore �ĵ�ַ���ֳɹ�
    output wire        cpu_data_data_ok ,

    // dcache ����
    // ������
    output wire [31:0] araddr       ,
    output wire [3 :0] arlen        ,
    output wire [2 :0] arsize       ,
    output wire        arvalid      ,
    input  wire        arready      ,
    // ����Ӧ
    input  wire [31:0] rdata        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output wire        rready       ,

    // д����
    output wire [31:0] awaddr       ,
    output wire [3 :0] awlen        ,
    output wire [2 :0] awsize       ,
    output wire        awvalid      ,
    input  wire        awready      ,
    // д����
    output wire [31:0] wdata        ,
    output wire [3 :0] wstrb        ,
    output wire        wlast        ,
    output wire        wvalid       ,
    input  wire        wready       ,
    // д��Ӧ
    input  wire        bvalid       ,
    output wire        bready       
);
//Cache����
    // TODO �ܲ������۾ͻ���4kB,cache��������Ϊ8KB 
    parameter  INDEX_WIDTH  = 7, OFFSET_WIDTH = 5, WAY_NUM = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam BLOCK_NUM = (1<<(OFFSET_WIDTH-2)); // 1��1block
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
//Cache�洢��Ԫ
    reg                 cache_lastused[CACHE_DEEPTH - 1 : 0]; // ÿ��cache����1bit lastused��־��0:way1,1:way2
    reg                 cache_valid   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag     [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0];
    // TODO ����ռ��reg��Դ�ܶ�
    reg [31:0]          cache_block   [WAY_NUM-1 : 0][CACHE_DEEPTH - 1 : 0][BLOCK_NUM-1:0];
    
//CPU���ʽ���
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    wire [OFFSET_WIDTH-3:0] blocki;
    wire [31:0] write_cache_data;
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    assign blocki=cpu_data_addr[OFFSET_WIDTH-1:2];

    // ͨ������ȷ��д������ݣ�λΪ1�Ĵ�����Ҫ���µġ�
    wire [3:0] write_mask4;
    wire [31:0] write_mask32;
    //���ݵ�ַ����λ��size������д���루���sb��sh�Ȳ���д����һ���ֵ�ָ���4λ��Ӧ1���֣�4�ֽڣ���ÿ���ֵ�дʹ��
    assign write_mask4 = cpu_data_size==2'd0 ? 4'b0001<<cpu_data_addr[1:0] :
                        cpu_data_size==2'd1 ? 4'b0011<<cpu_data_addr[1:0] : 4'b1111;
    //λ��չ��{8{1'b1}} -> 8'b11111111
    assign write_mask32 = { {8{write_mask4[3]}}, {8{write_mask4[2]}}, {8{write_mask4[1]}}, {8{write_mask4[0]}} };
    assign write_cache_data = cache_block[currused][index][blocki] & ~write_mask32 | cpu_data_wdata & write_mask32; // Ĭ��ԭ���ݣ���д������д�����������

//cache��index�µ�cache line����
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
    
//�ж��Ƿ�����
    wire hit, miss;
    assign hit  = c_valid & (c_tag == tag);  //cache line��validλΪ1����tag���ַ��tag���
    assign miss = ~hit;

//����д
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
                // �µ����
                IDLE:   state <= cpu_data_req & miss & !c_dirty ? RM :
                                 cpu_data_req & miss &  c_dirty ? WM :
                                 IDLE;
                RM:     state <= read_finish ? IDLE : RM;
                WM:     state <= miss & c_dirty & write_finish ? RM : WM;
                
                // �����ǻ���һ����
                // IDLE:   state <= cpu_data_req & read & miss & !c_dirty ? RM :                            // ��ȱʧ�Ҹ�λû�б��޸�
                //                  cpu_data_req & read & miss &  c_dirty ? WM :                            // ��ȱʧ�Ҹ�λ�޸Ĺ�
                //                  cpu_data_req & read & hit  ? IDLE :                                     // ������
                //                  // cpu_data_req & write & miss & c_dirty & !write_miss_nodirty_save ? WM : // дȱʧ����dirty��д�ڴ�
                //                  cpu_data_req & write & miss & c_dirty ? WM : // дȱʧ����dirty��д�ڴ�
                //                  IDLE;   
                // RM:     state <= read & read_finish ? IDLE : RM;
                // WM:     state <= read & miss & c_dirty & write_finish ? RM :                              // ��ȱʧ���࣬д����Ϻ����
                //                  write_finish ? IDLE :                                     // дȱʧд�࣬д����Ϻ�ָ�IDLE
                //                  WM;
            endcase
        end
    end

// �ô�������
    reg  read_req;      //һ�������Ķ����񣬴ӷ��������󵽽���;��ȡ�ڴ�����
    reg  raddr_rcv;      //��ַ���ճɹ�(addr_ok)�󵽽���,�����ַ�Ѿ��յ���
    wire read_one; // д��ÿһ�����ݳɹ�
    wire read_finish;   //���ݽ��ճɹ�(data_ok)�������������
    reg  read_finish_save;

    reg  write_req;     
    reg  waddr_rcv; 
    reg  wdata_rcv;     
    wire write_one; // ����ÿһ�����ݷ���
    wire write_finish;
    
    assign read_one = raddr_rcv && (rvalid && rready);
    assign write_one = waddr_rcv && (wvalid && wready);
    assign read_finish = raddr_rcv && (rvalid && rready && rlast);
    assign write_finish = waddr_rcv && wdata_rcv && (bvalid && bready);

    always @(posedge clk) begin
        // ������
        read_req <= rst ? 1'b0 :
                    (state==RM) & ~read_req ? 1'b1 : // ����������RM�׶� ~read_req
                    read_finish ? 1'b0 :read_req;
        // д����
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
    
// ���ݶԽ�
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

// CPU�ӿڵ�����Խ�
wire no_mem;
assign no_mem = (state==IDLE) && cpu_data_req && hit;
assign cpu_data_rdata   = hit ? cache_block[currused][index][blocki] : rdata_blocki; 
assign cpu_data_addr_ok = no_mem | (read && arvalid && arready) ||(write && awvalid && awready); // FIXME �о�����Ҫ�ϵ�3������
// assign cpu_data_data_ok = no_mem || (raddr_rcv && rvalid && rready && rlast) || (waddr_rcv && bvalid && bready); // ����״̬��ģʽ��ȱʧ�ô棬����RM��β������ֻ��Ҫ�ж�RM���ɡ�
// assign cpu_data_data_ok = no_mem || read_finish_save; // ����ӳ�һ�����ڣ���������blocki=7�����ݣ����ܹ���ʱ���� // FIXME �о�����д���ܶ����ڣ�������һ���ж������blocki==7���͵�һ�£�<7����ֱ�ӷ���read_finish
assign cpu_data_data_ok = no_mem || (blocki_save==3'b111 ? read_finish_save : read_finish); // ����ӳ�һ�����ڣ���������blocki=7�����ݣ����ܹ���ʱ���� // FIXME �о�����д���ܶ����ڣ�������һ���ж������blocki==7���͵�һ�£�<7����ֱ�ӷ���read_finish

// ��AXI�ӿڵ�����Խ�
// ������
assign araddr  = {tag,index}<<OFFSET_WIDTH;// output wire [31:0] 
assign arlen   = BLOCK_NUM-1; // output wire [3 :0] 
assign arsize  = cpu_data_size;// output wire [2 :0] 
assign arvalid = read_req && !raddr_rcv;// output wire
// ����Ӧ
assign rready  = raddr_rcv;// output wire
// д����
assign awaddr  =  {c_tag,index} << OFFSET_WIDTH ;// output wire [31:0] 
assign awlen   = BLOCK_NUM-1;// output wire [3 :0] 
assign awsize  = 2'b10;// output wire [2 :0] 
assign awvalid = write_req && !waddr_rcv;// output wire        
// д����
assign wdata   = cache_block[currused_save][index_save][wi];// output wire [31:0]����Ϊֻ���漰��д�����ݣ������漰��cpu_data_wdataд���ڴ������
assign wstrb = 4'b1111;  // д�ص����ݣ�����Ҫȫ��д��Ŷ
// assign wstrb   = cpu_data_size==2'd0 ? 4'b0001<<cpu_data_addr[1:0] :
//                  cpu_data_size==2'd1 ? 4'b0011<<cpu_data_addr[1:0] : 4'b1111; // output wire [3 :0] 
assign wlast   = wi==awlen;// output wire        
assign wvalid  = waddr_rcv & ~wdata_rcv;// output wire        
// д��Ӧ
assign bready  = waddr_rcv;// output wire        


//����cache
    

    //�����ַ�е�tag, index����ֹaddr�����ı�
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

    // дcache
    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //�տ�ʼ��Cache��Ϊ��Ч
                cache_valid[0][t] <= 1'b0;
                cache_valid[1][t] <= 1'b0;
                
                cache_dirty[0][t] <= 1'b0; 
                cache_dirty[1][t] <= 1'b0; 
                
                cache_lastused[t] <= 1'b0;
            end
        end
        else begin
            // ȱʧ�漰���滻way���漰���ô����д�ģ�**��ַ����**��������Ҫʹ��_save�ź�
            if(read_one) begin  // ��ȱʧ�������������ʱ**��ַ����**�Ѿ����
                // $display("ȱʧ����"); // ֱ��д
                cache_valid[currused_save][index_save] <= 1'b1;             //��Cache line��Ϊ��Ч
                cache_tag  [currused_save][index_save] <= tag_save;
                cache_block[currused_save][index_save][ri] <= rdata; //д��Cache line
                cache_dirty[currused_save][index_save] <= 1'b0;
                cache_lastused[index_save] <= currused_save;
            end
            if(cpu_data_req & read & hit) begin
                // $display("������"); // ֱ��д
                cache_lastused[index] <= currused;
            end
            if(cpu_data_req & write & hit) begin   // д����ʱ��ҪдCache
                // $display("д����"); // ֱ��д
                cache_block[currused][index][blocki] <= write_cache_data;             // д��Cache line��ʹ��index������index_save
                cache_dirty[currused][index] <= 1'b1;                         // д����ʱ��Ҫ����λ��Ϊ1
                cache_lastused[index] <= currused;
            end
            if(write & (state==RM) & read_finish) begin
                // $display("дȱʧ���ȶ����дcache");
                cache_lastused[index_save] <= currused_save;
                cache_valid[currused_save][index_save] <= 1'b1;             //��Cache line��Ϊ��Ч
                cache_dirty[currused_save][index_save] <= 1'b1;
                cache_tag  [currused_save][index_save] <= tag_save;
                cache_block[currused_save][index_save][blocki_save] <= write_cache_data_save;
            end 
        end
    end
endmodule