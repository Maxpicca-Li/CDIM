// 结构
//           ---------------------------------------    mycpu_top.v
//        |   -------------------------    mips core|
//        |   |        data_path       |            |
//        |   -------------------------             |
//        |        | sram       | sram              |
//        |      ----           ----                |
//        |     |    |         |    |               |
//        |      ----           ----                |
//        |        | sram-like    | sram-like       |
//           ---------------------------------------
//                 | sram-like    | sram-like
//           ---------------------------------------
//        |    								cache    |
//        |    								         |
//           ---------------------------------------
//                 | sram-like    | sram-like
//           ---------------------------------------
//        |    			cpu_axi_interface(longsoon)  |
//        |    								         |
//           ---------------------------------------
//          			        | axi

module mycpu_top(
    input [5:0] ext_int,   //high active

    input wire aclk,    
    input wire aresetn,   //low active

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[3:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
                
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready, 
               
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[3:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,

    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
wire clk, rst;
assign clk = aclk;
assign rst = ~aresetn;

wire        cpu_inst_req  ;
wire [31:0] cpu_inst_addr ;
wire        cpu_inst_wr   ;
wire [1:0]  cpu_inst_size ;
wire [63:0] cpu_inst_wdata;
wire [63:0] cpu_inst_rdata;
wire        cpu_inst_addr_ok;
wire        cpu_inst_data_ok;

wire        cpu_data_req  ;
wire [31:0] cpu_data_addr ;
wire        cpu_data_wr   ;
wire [1:0]  cpu_data_size ;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;
wire        cpu_data_addr_ok;
wire        cpu_data_data_ok;

wire        ram_data_req  ;
wire [31:0] ram_data_addr ;
wire        ram_data_wr   ;
wire [1:0]  ram_data_size ;
wire [31:0] ram_data_wdata;
wire [31:0] ram_data_rdata;
wire        ram_data_addr_ok;
wire        ram_data_data_ok;

wire        conf_data_req  ;
wire [31:0] conf_data_addr ;
wire        conf_data_wr   ;
wire [1:0]  conf_data_size ;
wire [31:0] conf_data_wdata;
wire [31:0] conf_data_rdata;
wire        conf_data_addr_ok;
wire        conf_data_data_ok;

wire [31:0] i_araddr  ;
wire [3 :0] i_arlen   ;
wire [2 :0] i_arsize  ;
wire        i_arvalid ;
wire        i_arready ;
wire [31:0] i_rdata   ;
wire        i_rlast   ;
wire        i_rvalid  ;
wire        i_rready  ;

wire [31:0] cache_araddr  ;
wire [3 :0] cache_arlen   ;
wire [2 :0] cache_arsize  ;
wire        cache_arvalid ;
wire        cache_arready ;
wire [31:0] cache_rdata   ;
wire        cache_rlast   ;
wire        cache_rvalid  ;
wire        cache_rready  ;
wire [31:0] cache_awaddr  ;
wire [3 :0] cache_awlen   ;
wire [2 :0] cache_awsize  ;
wire        cache_awvalid ;
wire        cache_awready ;
wire [31:0] cache_wdata   ;
wire [3 :0] cache_wstrb   ;
wire        cache_wlast   ;
wire        cache_wvalid  ;
wire        cache_wready  ;
wire        cache_bvalid  ;
wire        cache_bready  ;

wire [31:0] conf_araddr  ;
wire [3 :0] conf_arlen   ;
wire [2 :0] conf_arsize  ;
wire        conf_arvalid ;
wire        conf_arready ;
wire [31:0] conf_rdata   ;
wire        conf_rlast   ;
wire        conf_rvalid  ;
wire        conf_rready  ;
wire [31:0] conf_awaddr  ;
wire [3 :0] conf_awlen   ;
wire [2 :0] conf_awsize  ;
wire        conf_awvalid ;
wire        conf_awready ;
wire [31:0] conf_wdata   ;
wire [3 :0] conf_wstrb   ;
wire        conf_wlast   ;
wire        conf_wvalid  ;
wire        conf_wready  ;
wire        conf_bvalid  ;
wire        conf_bready  ;

wire [31:0] wrap_araddr  ;
wire [3 :0] wrap_arlen   ;
wire [2 :0] wrap_arsize  ;
wire        wrap_arvalid ;
wire        wrap_arready ;
wire [31:0] wrap_rdata   ;
wire        wrap_rlast   ;
wire        wrap_rvalid  ;
wire        wrap_rready  ;
wire [31:0] wrap_awaddr  ;
wire [3 :0] wrap_awlen   ;
wire [2 :0] wrap_awsize  ;
wire        wrap_awvalid ;
wire        wrap_awready ;
wire [31:0] wrap_wdata   ;
wire [3 :0] wrap_wstrb   ;
wire        wrap_wlast   ;
wire        wrap_wvalid  ;
wire        wrap_wready  ;
wire        wrap_bvalid  ;
wire        wrap_bready  ;


mips_core u_mips_core(
	//ports
	.clk               		( clk               		),
	.resetn            		( resetn            		),
	.int               		( int               		),
	
    .inst_sram_en      		( inst_sram_en      		),
	.inst_sram_wen     		( inst_sram_wen     		),
	.inst_sram_addr    		( inst_sram_addr    		),
	.inst_sram_wdata   		( inst_sram_wdata   		),
	.inst_sram_rdata   		( inst_sram_rdata   		),

	.data_sram_en      		( data_sram_en      		),
	.data_sram_wen     		( data_sram_wen     		),
	.data_sram_addr    		( data_sram_addr    		),
	.data_sram_wdata   		( data_sram_wdata   		),
	.data_sram_rdata   		( data_sram_rdata   		),
    
	.debug_wb_pc       		( debug_wb_pc       		),
	.debug_wb_rf_wen   		( debug_wb_rf_wen   		),
	.debug_wb_rf_wnum  		( debug_wb_rf_wnum  		),
	.debug_wb_rf_wdata 		( debug_wb_rf_wdata 		)
);

wire [31:0] cpu_inst_paddr;
wire [31:0] cpu_data_paddr;
wire no_dcache;

//将虚拟地址转换成物理地址，并判断是否需要经过Data Cache
mmu mmu(
    .inst_vaddr(cpu_inst_addr ),
    .inst_paddr(cpu_inst_paddr),
    .data_vaddr(cpu_data_addr ),
    .data_paddr(cpu_data_paddr),
    .no_dcache (no_dcache    )
);

//根据是否经过Cache，将信号分为两路
bridge_1x2 bridge_1x2(
    .no_dcache        (no_dcache    ),

    .cpu_data_req     (cpu_data_req  ),
    .cpu_data_wr      (cpu_data_wr   ),
    .cpu_data_addr    (cpu_data_paddr ),    //paddr
    .cpu_data_wdata   (cpu_data_wdata),
    .cpu_data_size    (cpu_data_size ),
    .cpu_data_rdata   (cpu_data_rdata),
    .cpu_data_addr_ok (cpu_data_addr_ok),
    .cpu_data_data_ok (cpu_data_data_ok),

    .ram_data_req     (ram_data_req  ),
    .ram_data_wr      (ram_data_wr   ),
    .ram_data_addr    (ram_data_addr ),
    .ram_data_wdata   (ram_data_wdata),
    .ram_data_size    (ram_data_size ),
    .ram_data_rdata   (ram_data_rdata),
    .ram_data_addr_ok (ram_data_addr_ok),
    .ram_data_data_ok (ram_data_data_ok),

    .conf_data_req     (conf_data_req  ),
    .conf_data_wr      (conf_data_wr   ),
    .conf_data_addr    (conf_data_addr ),
    .conf_data_wdata   (conf_data_wdata),
    .conf_data_size    (conf_data_size ),
    .conf_data_rdata   (conf_data_rdata),
    .conf_data_addr_ok (conf_data_addr_ok),
    .conf_data_data_ok (conf_data_data_ok)
);

//conf-->axi信号
sram_like_to_axi sram_like_to_axi (
    .clk(clk), .rst(rst),
    // sram_like
    .sraml_req     (conf_data_req     ),
    .sraml_wr      (conf_data_wr      ),
    .sraml_size    (conf_data_size    ),
    .sraml_addr    (conf_data_addr    ),
    .sraml_wdata   (conf_data_wdata   ),
    .sraml_rdata   (conf_data_rdata   ),
    .sraml_addr_ok (conf_data_addr_ok ),
    .sraml_data_ok (conf_data_data_ok ),

    // axi
    // ar
    .araddr  (conf_araddr  ),
    .arlen   (conf_arlen   ),
    .arsize  (conf_arsize  ),
    .arvalid (conf_arvalid ),
    .arready (conf_arready ),
    // r
    .rdata   (conf_rdata   ),
    .rlast   (conf_rlast   ),
    .rvalid  (conf_rvalid  ),
    .rready  (conf_rready  ),
    // aw
    .awaddr  (conf_awaddr  ),
    .awlen   (conf_awlen   ),
    .awsize  (conf_awsize  ),
    .awvalid (conf_awvalid ),
    .awready (conf_awready ),
    // w
    .wdata   (conf_wdata   ),
    .wstrb   (conf_wstrb   ),
    .wlast   (conf_wlast   ),
    .wvalid  (conf_wvalid  ),
    .wready  (conf_wready  ),
    // b
    .bvalid  (conf_bvalid  ),
    .bready  (conf_bready  )
);

//cache-->axi信号
cache cache (
    .clk(clk), .rst(rst),
    //mips core
    .cpu_inst_req     (cpu_inst_req     ),
    .cpu_inst_wr      (cpu_inst_wr      ),
    .cpu_inst_size    (cpu_inst_size    ),
    .cpu_inst_addr    (cpu_inst_addr    ),
    .cpu_inst_wdata   (cpu_inst_wdata   ),
    .cpu_inst_rdata   (cpu_inst_rdata   ),
    .cpu_inst_addr_ok (cpu_inst_addr_ok ),
    .cpu_inst_data_ok (cpu_inst_data_ok ),

    .cpu_data_req     (ram_data_req     ),
    .cpu_data_wr      (ram_data_wr      ),
    .cpu_data_size    (ram_data_size    ),
    .cpu_data_addr    (ram_data_addr    ),
    .cpu_data_wdata   (ram_data_wdata   ),
    .cpu_data_rdata   (ram_data_rdata   ),
    .cpu_data_addr_ok (ram_data_addr_ok ),
    .cpu_data_data_ok (ram_data_data_ok ),

    //axi interface
    // icache
    // ar
    .i_araddr  (i_araddr  ),
    .i_arlen   (i_arlen   ),
    .i_arsize  (i_arsize  ),
    .i_arvalid (i_arvalid ),
    .i_arready (i_arready ),
    // r
    .i_rdata   (i_rdata   ),
    .i_rlast   (i_rlast   ),
    .i_rvalid  (i_rvalid  ),
    .i_rready  (i_rready  ),

    // dcache
    // ar
    .d_araddr  (cache_araddr  ),
    .d_arlen   (cache_arlen   ),
    .d_arsize  (cache_arsize  ),
    .d_arvalid (cache_arvalid ),
    .d_arready (cache_arready ),
    // r
    .d_rdata   (cache_rdata   ),
    .d_rlast   (cache_rlast   ),
    .d_rvalid  (cache_rvalid  ),
    .d_rready  (cache_rready  ),
    // aw
    .d_awaddr  (cache_awaddr  ),
    .d_awlen   (cache_awlen   ),
    .d_awsize  (cache_awsize  ),
    .d_awvalid (cache_awvalid ),
    .d_awready (cache_awready ),
    // w
    .d_wdata   (cache_wdata   ),
    .d_wstrb   (cache_wstrb   ),
    .d_wlast   (cache_wlast   ),
    .d_wvalid  (cache_wvalid  ),
    .d_wready  (cache_wready  ),
    // b
    .d_bvalid  (cache_bvalid  ),
    .d_bready  (cache_bready  )
);

bridge_2x1_axi bridge_2x1_axi (
    .no_dcache(no_dcache),

    // 主方
    .cache_araddr  (cache_araddr ),
    .cache_arlen   (cache_arlen  ),
    .cache_arsize  (cache_arsize ),
    .cache_arvalid (cache_arvalid),
    .cache_arready (cache_arready),
    .cache_rdata   (cache_rdata  ),
    .cache_rlast   (cache_rlast  ),
    .cache_rvalid  (cache_rvalid ),
    .cache_rready  (cache_rready ),
    .cache_awaddr  (cache_awaddr ),
    .cache_awlen   (cache_awlen  ),
    .cache_awsize  (cache_awsize ),
    .cache_awvalid (cache_awvalid),
    .cache_awready (cache_awready),
    .cache_wdata   (cache_wdata  ),
    .cache_wstrb   (cache_wstrb  ),
    .cache_wlast   (cache_wlast  ),
    .cache_wvalid  (cache_wvalid ),
    .cache_wready  (cache_wready ),
    .cache_bvalid  (cache_bvalid ),
    .cache_bready  (cache_bready ),

    .conf_araddr   (conf_araddr  ),
    .conf_arlen    (conf_arlen   ),
    .conf_arsize   (conf_arsize  ),
    .conf_arvalid  (conf_arvalid ),
    .conf_arready  (conf_arready ),
    .conf_rdata    (conf_rdata   ),
    .conf_rlast    (conf_rlast   ),
    .conf_rvalid   (conf_rvalid  ),
    .conf_rready   (conf_rready  ),
    .conf_awaddr   (conf_awaddr  ),
    .conf_awlen    (conf_awlen   ),
    .conf_awsize   (conf_awsize  ),
    .conf_awvalid  (conf_awvalid ),
    .conf_awready  (conf_awready ),
    .conf_wdata    (conf_wdata   ),
    .conf_wstrb    (conf_wstrb   ),
    .conf_wlast    (conf_wlast   ),
    .conf_wvalid   (conf_wvalid  ),
    .conf_wready   (conf_wready  ),
    .conf_bvalid   (conf_bvalid  ),
    .conf_bready   (conf_bready  ),
    
    // 从方
    .wrap_araddr   (wrap_araddr  ),
    .wrap_arlen    (wrap_arlen   ),
    .wrap_arsize   (wrap_arsize  ),
    .wrap_arvalid  (wrap_arvalid ),
    .wrap_arready  (wrap_arready ),
    .wrap_rdata    (wrap_rdata   ),
    .wrap_rlast    (wrap_rlast   ),
    .wrap_rvalid   (wrap_rvalid  ),
    .wrap_rready   (wrap_rready  ),
    .wrap_awaddr   (wrap_awaddr  ),
    .wrap_awlen    (wrap_awlen   ),
    .wrap_awsize   (wrap_awsize  ),
    .wrap_awvalid  (wrap_awvalid ),
    .wrap_awready  (wrap_awready ),
    .wrap_wdata    (wrap_wdata   ),
    .wrap_wstrb    (wrap_wstrb   ),
    .wrap_wlast    (wrap_wlast   ),
    .wrap_wvalid   (wrap_wvalid  ),
    .wrap_wready   (wrap_wready  ),
    .wrap_bvalid   (wrap_bvalid  ),
    .wrap_bready   (wrap_bready  )
);

axi_arbitrater axi_arbitrater(
    .clk(clk), .rst(rst),
    //I CACHE 从方
    .i_araddr      (i_araddr     ),
    .i_arlen       (i_arlen      ),
    .i_arvalid     (i_arvalid    ),
    .i_arready     (i_arready    ),

    .i_rdata       (i_rdata      ),
    .i_rlast       (i_rlast      ),
    .i_rvalid      (i_rvalid     ),
    .i_rready      (i_rready     ),

    //D CACHE 从方
    .d_araddr      (wrap_araddr     ),
    .d_arlen       (wrap_arlen      ),
    .d_arsize      (wrap_arsize     ),
    .d_arvalid     (wrap_arvalid    ),
    .d_arready     (wrap_arready    ),

    .d_rdata       (wrap_rdata      ),
    .d_rlast       (wrap_rlast      ),
    .d_rvalid      (wrap_rvalid     ),
    .d_rready      (wrap_rready     ),
    //write
    .d_awaddr      (wrap_awaddr     ),
    .d_awlen       (wrap_awlen      ),
    .d_awsize      (wrap_awsize     ),
    .d_awvalid     (wrap_awvalid    ),
    .d_awready     (wrap_awready    ),
    
    .d_wdata       (wrap_wdata      ),
    .d_wstrb       (wrap_wstrb      ),
    .d_wlast       (wrap_wlast      ),
    .d_wvalid      (wrap_wvalid     ),
    .d_wready      (wrap_wready     ),

    .d_bvalid      (wrap_bvalid     ),
    .d_bready      (wrap_bready     ),
    
    //Outer 主方
    .arid(arid)             ,
    .araddr(araddr)         ,
    .arlen(arlen)           ,
    .arsize(arsize)         ,
    .arburst(arburst)       ,
    .arlock(arlock)         ,
    .arcache(arcache)       ,
    .arprot(arprot)         ,
    .arvalid(arvalid)       ,
    .arready(arready)       ,
                
    .rid(rid)               ,
    .rdata(rdata)           ,
    .rresp(rresp)           ,
    .rlast(rlast)           ,
    .rvalid(rvalid)         ,
    .rready(rready)         ,
               
    .awid(awid)             ,
    .awaddr(awaddr)         ,
    .awlen(awlen)           ,
    .awsize(awsize)         ,
    .awburst(awburst)       ,
    .awlock(awlock)         ,
    .awcache(awcache)       ,
    .awprot(awprot)         ,
    .awvalid(awvalid)       ,
    .awready(awready)       ,
    
    .wid(wid)               ,
    .wdata(wdata)           ,
    .wstrb(wstrb)           ,
    .wlast(wlast)           ,
    .wvalid(wvalid)         ,
    .wready(wready)         ,
    
    .bid(bid)               ,
    .bresp(bresp)           ,
    .bvalid(bvalid)         ,
    .bready(bready)
);

endmodule