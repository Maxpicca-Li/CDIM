module mycpu_top (
    input wire aclk,
    input wire aresetn,

    input [5:0] ext_int,            //interrupt

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
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
    output wire[7:0] awlen,
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
    output wire[31:0] debug_wb_rf_wdata,
    // soc-simulator + cemu debug interface
    output wire [31:0] debug_cp0_count,
    output wire [31:0] debug_cp0_random,
    output wire [31:0] debug_cp0_cause,
    output wire debug_int,
    output wire debug_commit
);
    wire clk, rst;
    assign clk = aclk; // assign clk = aclk;
    assign rst = ~aresetn;

    //d_tlb - d_cache
    wire no_cache_d         ;   //数据
    wire no_cache_i         ;   //指令

    //datapath - cache
    wire inst_en            ;
    wire [31:0] pcF         ;
    wire [31:0] pcF_dp     ;
    wire [31:0] pc_next     ;
    wire [31:0] pc_next_dp ;
    wire i_cache_stall      ;
    wire stallF             ;
    wire stallM             ;
    wire inst_data_ok1      ;
    wire inst_data_ok2      ;
    wire inst_tlb_refill    ;
    wire inst_tlb_invalid   ;
    wire [31:0] inst_rdata1 ;
    wire [31:0] inst_rdata2 ;
    wire        fence_iE;
    wire [31:0] fence_addrE;
    wire        fence_dM;
    wire [31:0] fence_addrM;
    wire        fence_tlbE;
    wire [31:13]itlb_vpn2;
    wire        itlb_found;
    tlb_entry   itlb_entry;

    wire data_en            ;
    wire [31:0] data_addr   ;
    wire [31:0] data_addr_dp;
    wire [31:0] data_rdata  ;
    wire [ 1:0] data_rlen   ;
    wire [3:0] data_wen     ;
    wire [31:0] data_wdata  ;
    wire d_cache_stall      ;
    wire [31:0] mem_addrE   ;
    wire [31:0] mem_addrE_dp;
    wire mem_read_enE       ;
    wire mem_write_enE      ;

    //i_cache - arbitrater
    wire [31:0] i_araddr    ;
    wire [7:0] i_arlen      ;
    wire [2:0] i_arsize     ;
    wire i_arvalid          ;
    wire i_arready          ;

    wire [31:0] i_rdata     ;
    wire i_rlast            ;
    wire i_rvalid           ;
    wire i_rready           ;

    //d_cache - arbitrater
    wire [31:0] d_araddr    ;
    wire [7:0] d_arlen      ;
    wire [2:0] d_arsize     ;
    wire d_arvalid          ;
    wire d_arready          ;

    wire[31:0] d_rdata      ;
    wire d_rlast            ;
    wire d_rvalid           ;
    wire d_rready           ;

    wire [31:0] d_awaddr    ;
    wire [7:0] d_awlen      ;
    wire [2:0] d_awsize     ;
    wire d_awvalid          ;
    wire d_awready          ;

    wire [31:0] d_wdata     ;
    wire [3:0] d_wstrb      ;
    wire d_wlast            ;
    wire d_wvalid           ;
    wire d_wready           ;

    wire d_bvalid           ;
    wire d_bready           ;

    wire [31:13]    dtlb_vpn2;
    wire            dtlb_found;
    tlb_entry       dtlb_entry;
    wire            fence_tlbM;

    wire            data_tlb_refill;
    wire            data_tlb_invalid;
    wire            data_tlb_mod;

    wire no_cache_E         ;
    datapath u_datapath(
        //ports
        .clk               		( clk               		),
        .rst               		( rst               		),
        .ext_int           		( ext_int           		),
        // inst
        .i_stall           		( i_cache_stall        		),
        .stallF            		( stallF            		),
        .inst_sram_en      		( inst_en            		),
        .F_pc              		( pcF_dp              		),
        .F_pc_next         		( pc_next_dp         		),
        .inst_data_ok1     		( inst_data_ok1     		),
        .inst_data_ok2     		( inst_data_ok2     		),
        .inst_tlb_refill        ( inst_tlb_refill           ),
        .inst_tlb_invalid       ( inst_tlb_invalid          ),
        .inst_rdata1       		( inst_rdata1       		),
        .inst_rdata2       		( inst_rdata2       		),
        .fence_iE               ( fence_iE                  ),
        .fence_addrE            ( fence_addrE               ),
        .fence_dM               ( fence_dM                  ),
        .fence_addrM            ( fence_addrM               ),
        .fence_tlbE             ( fence_tlbE                ),
        .itlb_vpn2              ( itlb_vpn2                 ),
        .itlb_found             ( itlb_found                ),
        .itlb_entry             ( itlb_entry                ),
        // data
        .d_stall           		( d_cache_stall           	),
        .stallM            		( stallM            		),
        .mem_read_enE      		( mem_read_enE      		),
        .mem_write_enE     		( mem_write_enE     		),
        .E_mem_va               ( mem_addrE                 ),
        .mem_addrE         		( mem_addrE_dp      		), // TODO: delete
        .data_sram_enM     		( data_en           		),
        .data_sram_rdataM  		( data_rdata          		),
        .data_sram_rlenM   		( data_rlen           		),
        .data_sram_wenM    		( data_wen             		),
        .M_mem_va               ( data_addr                 ),
        .data_sram_addrM   		( data_addr_dp         		), // TODO: delete
        .data_sram_wdataM  		( data_wdata          		),
        .dtlb_vpn2              ( dtlb_vpn2                 ),
        .dtlb_found             ( dtlb_found                ),
        .dtlb_entry             ( dtlb_entry                ),
        .fence_tlbM             ( fence_tlbM                ),
        .data_tlb_refill        ( data_tlb_refill           ),
        .data_tlb_invalid       ( data_tlb_invalid          ),
        .data_tlb_mod           ( data_tlb_mod              ),
        // debug
        .debug_wb_pc       		( debug_wb_pc       		),
        .debug_wb_rf_wen   		( debug_wb_rf_wen   		),
        .debug_wb_rf_wnum  		( debug_wb_rf_wnum  		),
        .debug_wb_rf_wdata 		( debug_wb_rf_wdata 		),
        .debug_cp0_count        ( debug_cp0_count           ),
        .debug_cp0_random       ( debug_cp0_random          ),
        .debug_cp0_cause        ( debug_cp0_cause           ),
        .debug_int              ( debug_int                 ),
        .debug_commit           ( debug_commit              )
    );

    i_cache i_cache_inst (
        .clk                ( clk           ),
        .rst                ( rst           ),
        .inst_en            ( inst_en       ),
        .inst_va            ( pcF_dp        ),
        .inst_va_next       ( pc_next_dp    ),
        .inst_rdata0        ( inst_rdata1   ),
        .inst_rdata1        ( inst_rdata2   ),
        .inst_ok0           ( inst_data_ok1 ),
        .inst_ok1           ( inst_data_ok2 ),
        .inst_tlb_refill    (inst_tlb_refill  ),
        .inst_tlb_invalid   (inst_tlb_invalid ),
        .stallF             ( stallF        ),
        .istall             ( i_cache_stall ),
        .fence_i            ( fence_iE      ),
        .fence_addr         ( fence_addrE   ),
        .fence_tlb          ( fence_tlbE    ),
        .itlb_vpn2          ( itlb_vpn2     ),
        .itlb_found         ( itlb_found    ),
        .itlb_entry         ( itlb_entry    ),
        .araddr             ( i_araddr      ),
        .arlen              ( i_arlen       ),
        .arsize             ( i_arsize      ),
        .arvalid            ( i_arvalid     ),
        .arready            ( i_arready     ),
        .rdata              ( i_rdata       ),
        .rlast              ( i_rlast       ),
        .rvalid             ( i_rvalid      ),
        .rready             ( i_rready      )
    );
    
    d_cache d_cache_inst (
        .clk                ( clk           ),
        .rst                ( rst           ),
        .stallM             ( stallM        ),
        .dstall             ( d_cache_stall ),
        .E_mem_va           ( mem_addrE     ), // only used for match bram
        .M_mem_va           ( data_addr     ),
        .M_fence_addr       ( fence_addrM   ), // used for fence
        .M_fence_d          ( fence_dM      ), // fence address reuse the M_memva. Note: we shouldn't raise M_fence_en with M_mem_en.
        .M_mem_en           ( data_en       ),
        .M_mem_write        ( |data_wen     ),
        .M_wmask            ( data_wen      ),
        .M_mem_size         ( data_rlen     ),
        .M_wdata            ( data_wdata    ),
        .M_rdata            ( data_rdata    ),
        .dtlb_vpn2          ( dtlb_vpn2     ),
        .dtlb_found         ( dtlb_found    ),
        .dtlb_entry         ( dtlb_entry    ),
        .fence_tlb          ( fence_tlbM    ),
        .data_tlb_refill    ( data_tlb_refill),
        .data_tlb_invalid   ( data_tlb_invalid),
        .data_tlb_mod       ( data_tlb_mod  ),
        .araddr             ( d_araddr      ),
        .arlen              ( d_arlen       ),
        .arsize             ( d_arsize      ),
        .arvalid            ( d_arvalid     ),
        .arready            ( d_arready     ),
        .rdata              ( d_rdata       ),
        .rlast              ( d_rlast       ),
        .rvalid             ( d_rvalid      ),
        .rready             ( d_rready      ),
        .awaddr             ( d_awaddr      ),
        .awlen              ( d_awlen       ),
        .awsize             ( d_awsize      ),
        .awvalid            ( d_awvalid     ),
        .awready            ( d_awready     ),
        .wdata              ( d_wdata       ),
        .wstrb              ( d_wstrb       ),
        .wlast              ( d_wlast       ),
        .wvalid             ( d_wvalid      ),
        .wready             ( d_wready      ),
        .bvalid             ( d_bvalid      ),
        .bready             ( d_bready      )
    );

    arbitrater u_arbitrater(
        .clk(clk), 
        .rst(rst),
    //I CACHE
        .i_araddr          (i_araddr ),
        .i_arlen           (i_arlen  ),
        .i_arsize          (i_arsize ),
        .i_arvalid         (i_arvalid),
        .i_arready         (i_arready),
                  
        .i_rdata           (i_rdata ),
        .i_rlast           (i_rlast ),
        .i_rvalid          (i_rvalid),
        .i_rready          (i_rready),
        
    //D CACHE
        .d_araddr          (d_araddr ),
        .d_arlen           (d_arlen  ),
        .d_arsize          (d_arsize ),
        .d_arvalid         (d_arvalid),
        .d_arready         (d_arready),

        .d_rdata           (d_rdata ),
        .d_rlast           (d_rlast ),
        .d_rvalid          (d_rvalid),
        .d_rready          (d_rready),

        .d_awaddr          (d_awaddr ),
        .d_awlen           (d_awlen  ),
        .d_awsize          (d_awsize ),
        .d_awvalid         (d_awvalid),
        .d_awready         (d_awready),

        .d_wdata           (d_wdata ),
        .d_wstrb           (d_wstrb ),
        .d_wlast           (d_wlast ),
        .d_wvalid          (d_wvalid),
        .d_wready          (d_wready),

        .d_bvalid          (d_bvalid),
        .d_bready          (d_bready),
    //Outer
        .arid            (arid   ),
        .araddr          (araddr ),
        .arlen           (arlen  ),
        .arsize          (arsize ),
        .arburst         (arburst),
        .arlock          (arlock ),
        .arcache         (arcache),
        .arprot          (arprot ),
        .arvalid         (arvalid),
        .arready         (arready),
                   
        .rid             (rid   ),
        .rdata           (rdata ),
        .rresp           (rresp ),
        .rlast           (rlast ),
        .rvalid          (rvalid),
        .rready          (rready),
               
        .awid            (awid   ),
        .awaddr          (awaddr ),
        .awlen           (awlen  ),
        .awsize          (awsize ),
        .awburst         (awburst),
        .awlock          (awlock ),
        .awcache         (awcache),
        .awprot          (awprot ),
        .awvalid         (awvalid),
        .awready         (awready),
        
        .wid             (wid   ),
        .wdata           (wdata ),
        .wstrb           (wstrb ),
        .wlast           (wlast ),
        .wvalid          (wvalid),
        .wready          (wready),
        .bid             (bid   ),
        .bresp           (bresp ),
        .bvalid          (bvalid),
        .bready          (bready)
    );
endmodule