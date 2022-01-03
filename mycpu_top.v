module mycpu_top(
    input wire [5:0] ext_int   ,   // interrupt,high active
    input wire       aclk      ,
    input wire       aresetn   ,   // low active

    //ar
    output [3 :0] arid   ,
    output [31:0] araddr ,
    output [3 :0] arlen  ,
    output [2 :0] arsize ,
    output [1 :0] arburst,
    output [1 :0] arlock ,
    output [3 :0] arcache,
    output [2 :0] arprot ,
    output        arvalid,
    input         arready,
    //r
    input  [3 :0] rid    ,
    input  [31:0] rdata  ,
    input  [1 :0] rresp  ,
    input         rlast  ,
    input         rvalid ,
    output        rready ,
    //aw
    output [3 :0] awid   ,
    output [31:0] awaddr ,
    output [3 :0] awlen  ,
    output [2 :0] awsize ,
    output [1 :0] awburst,
    output [1 :0] awlock ,
    output [3 :0] awcache,
    output [2 :0] awprot ,
    output        awvalid,
    input         awready,
    //w
    output [3 :0] wid    ,
    output [31:0] wdata  ,
    output [3 :0] wstrb  ,
    output        wlast  ,
    output        wvalid ,
    input         wready ,
    //b
    input  [3 :0] bid    ,
    input  [1 :0] bresp  ,
    input         bvalid ,
    output        bready ,

    //debug interface
    output [31:0] debug_wb_pc      ,
    output [3 :0] debug_wb_rf_wen  ,
    output [4 :0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);

    // inst mem access
     wire        inst_req    ;
    wire        inst_wr     ;
    wire [1 :0] inst_size   ;
    wire [31:0] inst_addr   ;
    wire [31:0] inst_wdata  ;
    wire [31:0] 	inst_rdata1;
    wire [31:0] 	inst_rdata2;
    wire            inst_data_ok;
    wire        	inst_data_ok1;
    wire        	inst_data_ok2;

    wire        	i_arready;
    wire [31:0] 	i_rdata;
    wire        	i_rlast;
    wire        	i_rvalid;

    wire        inst_en   ;
    wire [3 :0] inst_sram_wen  ;
    wire [31:0] inst_paddr ;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;
    
    // data mem access
    wire        data_sram_en   ;
    wire [3 :0] data_sram_wen  ;
    wire [31:0] data_paddr ;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    wire        data_req    ;
    wire        data_wr     ;
    wire [1 :0] data_size   ;
    wire [31:0] data_addr   ;
    wire [31:0] data_wdata  ;
    wire [31:0] data_rdata  ;
    wire        data_addr_ok;
    wire        data_data_ok;


    wire        no_dcache     ;
    wire        cache_data_req    ;
    wire        cache_data_wr     ;
    wire [1 :0] cache_data_size   ;
    wire [31:0] cache_data_addr   ;
    wire [31:0] cache_data_wdata  ;
    wire [31:0] cache_data_rdata  ;
    wire        cache_data_addr_ok;
    wire        cache_data_data_ok;

    wire        	d_arready;
    wire [31:0] 	d_rdata;
    wire        	d_rlast;
    wire        	d_rvalid;
    wire        	d_awready;
    wire        	d_wready;
    wire        	d_bvalid;
    
    // datapath
    wire except;
    wire longest_stall;
    wire i_stall;
    wire d_stall;
    wire [31:0] instrF,data_vaddr,inst_vaddr;
    
    // debug
    assign debug_wb_pc          = datapath.pc_nowM;
    assign debug_wb_rf_wen      = {4{datapath.regfile.we3}};
    assign debug_wb_rf_wnum     = datapath.regfile.wa3;
    assign debug_wb_rf_wdata    = datapath.regfile.wd3;
    
    datapath u_datapath(
        //ports
        .clk              		( clk              		),
        .rst              		( ~aresetn       		),
        .ext_int          		( ext_int          		),
        .except_logicM    		( except         		),
        .i_stall          		( i_stall          		),
        .d_stall          		( d_stall          		),
        .longest_stall    		( longest_stall    		),
        .inst_data_ok1    		( inst_data_ok1    		),
        .inst_data_ok2    		( inst_data_ok2    		),
        .inst_data1       		( inst_rdata1      		),
        .inst_data2       		( inst_rdata2      		),
        .inst_sram_en     		( inst_en     		),
        .F_pc             		( inst_addr ),
        .data_sram_rdataM 		( data_sram_rdataM 		),
        .data_sram_enM    		( data_sram_enM    		),
        .data_sram_wenM   		( data_sram_wenM   		),
        .data_sram_waddrM 		( data_sram_waddrM 		),
        .data_sram_wdataM 		( data_sram_wdataM 		)
    );

    // datapath datapath(
	// 	.clk(aclk),
    //     .rst(~aresetn), // to high active
    //     .i_stall(i_stall), // input
    //     .d_stall(d_stall), // input
    //     .longest_stall(longest_stall), // output
    //     // instr
    //     .pc_nowF(inst_vaddr),
    //     .inst_sram_rdataF(inst_sram_rdata),
    //     .inst_sram_enF(inst_sram_en),
    //     // data
    //     .data_sram_enM(data_sram_en),
    //     .data_sram_wenM(data_sram_wen),
    //     .data_sram_waddrM(data_vaddr),
    //     .data_sram_wdataM(data_sram_wdata),
    //     .data_sram_rdataM(data_sram_rdata),
    //     // except
    //     .ext_int(ext_int),
    //     .except_logicM(except)
	// );

    mmu u_mmu(
        .inst_vaddr 		( inst_vaddr 		),
        .inst_paddr 		( inst_paddr 		),
        .data_vaddr 		( data_vaddr 		),
        .data_paddr 		( data_paddr 		),
        .no_icache  		( no_icache  		),
        .no_dcache  		( no_dcache  		)
    );

    // instr
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    assign instrF = inst_sram_rdata;

    i_cache_top u_i_cache_top(
        //ports
        .clk           		( clk           		),
        .rst           		( rst           		),
        .longest_stall 		( longest_stall 		),
        .i_stall       		( i_stall       		),
        .inst_en       		( inst_en       		),
        .inst_wen      		( inst_wen      		),
        .inst_addr     		( inst_addr     		),
        .inst_data_ok  		( inst_data_ok  		),
        .inst_data_ok1 		( inst_data_ok1 		),
        .inst_data_ok2 		( inst_data_ok2 		),
        .inst_rdata1   		( inst_rdata1   		),
        .inst_rdata2   		( inst_rdata2   		),
        .arready       		( arready       		),
        .araddr        		( araddr        		),
        .arlen         		( arlen         		),
        .arsize        		( arsize        		),
        .arvalid       		( arvalid       		),
        .rdata         		( rdata         		),
        .rlast         		( rlast         		),
        .rvalid        		( rvalid        		),
        .rready        		( rready        		)
    );


    // data: cpu --> sramlike
    d_sramlike_interface dsramlike_interface(
        .clk(aclk),
        .rst(~aresetn),
        .longest_stall(longest_stall), // one pipline stall -->  one mem visit
        
        // data sram
        .data_sram_en   (data_sram_en   ),
        .data_sram_wen  (data_sram_wen  ),
        .data_sram_addr (data_paddr ),
        .data_sram_wdata(data_sram_wdata),
        .data_sram_rdata(data_sram_rdata),
        .d_stall        (d_stall        ) ,  // to let cpu wait return_data

        // sram_like
        .data_req     (data_req     ),
        .data_wr      (data_wr      ),
        .data_size    (data_size    ),
        .data_addr    (data_addr    ),
        .data_wdata   (data_wdata   ),
        .data_rdata   (data_rdata   ),
        .data_addr_ok (data_addr_ok ),
        .data_data_ok (data_data_ok )
    );

    // data: sramlike --> cache(sramlike)
    d_cache_write_through d_cache(
        .clk(aclk),    
        .rst(~aresetn),
        .except(except),
        .no_cache(no_dcache),
        // mips core 
        .cpu_data_req    (data_req     ),
        .cpu_data_wr     (data_wr      ),
        .cpu_data_size   (data_size    ),
        .cpu_data_addr   (data_addr    ),
        .cpu_data_wdata  (data_wdata   ),
        .cpu_data_rdata  (data_rdata   ),
        .cpu_data_addr_ok(data_addr_ok ),
        .cpu_data_data_ok(data_data_ok ),

        // axi interface
        .cache_data_req    (cache_data_req    ),
        .cache_data_wr     (cache_data_wr     ),
        .cache_data_size   (cache_data_size   ),
        .cache_data_addr   (cache_data_addr   ),
        .cache_data_wdata  (cache_data_wdata  ),
        .cache_data_rdata  (cache_data_rdata  ),
        .cache_data_addr_ok(cache_data_addr_ok),
        .cache_data_data_ok(cache_data_data_ok)
    );



wire [3:0]  	arid;
wire [31:0] 	araddr;
wire [3:0]  	arlen;
wire [2:0]  	arsize;
wire [1:0]  	arburst;
wire [1:0]  	arlock;
wire [3:0]  	arcache;
wire [2:0]  	arprot;
wire        	arvalid;
wire        	rready;
wire [3:0]  	awid;
wire [31:0] 	awaddr;
wire [3:0]  	awlen;
wire [2:0]  	awsize;
wire [1:0]  	awburst;
wire [1:0]  	awlock;
wire [3:0]  	awcache;
wire [2:0]  	awprot;
wire        	awvalid;
wire [3:0]  	wid;
wire [31:0] 	wdata;
wire [3:0]  	wstrb;
wire        	wlast;
wire        	wvalid;
wire        	bready;

axi_arbitrater u_axi_arbitrater(
	//ports
	.clk       		( clk       		),
	.rst       		( rst       		),
	.i_araddr  		( i_araddr  		),
	.i_arlen   		( i_arlen   		),
	.i_arvalid 		( i_arvalid 		),
	.i_arready 		( i_arready 		),
	.i_rdata   		( i_rdata   		),
	.i_rlast   		( i_rlast   		),
	.i_rvalid  		( i_rvalid  		),
	.i_rready  		( i_rready  		),
	.d_araddr  		( d_araddr  		),
	.d_arlen   		( d_arlen   		),
	.d_arsize  		( d_arsize  		),
	.d_arvalid 		( d_arvalid 		),
	.d_arready 		( d_arready 		),
	.d_rdata   		( d_rdata   		),
	.d_rlast   		( d_rlast   		),
	.d_rvalid  		( d_rvalid  		),
	.d_rready  		( d_rready  		),
	.d_awaddr  		( d_awaddr  		),
	.d_awlen   		( d_awlen   		),
	.d_awsize  		( d_awsize  		),
	.d_awvalid 		( d_awvalid 		),
	.d_awready 		( d_awready 		),
	.d_wdata   		( d_wdata   		),
	.d_wstrb   		( d_wstrb   		),
	.d_wlast   		( d_wlast   		),
	.d_wvalid  		( d_wvalid  		),
	.d_wready  		( d_wready  		),
	.d_bvalid  		( d_bvalid  		),
	.d_bready  		( d_bready  		),
	.arid      		( arid      		),
	.araddr    		( araddr    		),
	.arlen     		( arlen     		),
	.arsize    		( arsize    		),
	.arburst   		( arburst   		),
	.arlock    		( arlock    		),
	.arcache   		( arcache   		),
	.arprot    		( arprot    		),
	.arvalid   		( arvalid   		),
	.arready   		( arready   		),
	.rid       		( rid       		),
	.rdata     		( rdata     		),
	.rresp     		( rresp     		),
	.rlast     		( rlast     		),
	.rvalid    		( rvalid    		),
	.rready    		( rready    		),
	.awid      		( awid      		),
	.awaddr    		( awaddr    		),
	.awlen     		( awlen     		),
	.awsize    		( awsize    		),
	.awburst   		( awburst   		),
	.awlock    		( awlock    		),
	.awcache   		( awcache   		),
	.awprot    		( awprot    		),
	.awvalid   		( awvalid   		),
	.awready   		( awready   		),
	.wid       		( wid       		),
	.wdata     		( wdata     		),
	.wstrb     		( wstrb     		),
	.wlast     		( wlast     		),
	.wvalid    		( wvalid    		),
	.wready    		( wready    		),
	.bid       		( bid       		),
	.bresp     		( bresp     		),
	.bvalid    		( bvalid    		),
	.bready    		( bready    		)
);


    // ascii
    instdec instdec(
        .instr(instrF)
    );
   
endmodule