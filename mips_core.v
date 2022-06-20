// 结构
//           ---------------------------------------
//        |   -------------------------    mips core|
//        |   |        data_path       |            |
//        |   -------------------------             |
//        |        | sram       | sram              |
//        |      ----           ----                |
//        |     |    |         |    |               |
//        |      ----           ----                |
//        |        | sram-like    | sram-like       |
//           ---------------------------------------
//                 |              |

module mips_core (
    input wire clk, rst,
    input wire [5:0] ext_int,

    //instr
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok1,
    input wire inst_data_ok2,
    input wire [31:0] inst_rdata1,
    input wire [31:0] inst_rdata2,

    //data
    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata,

    //debug
    output wire [31:0]  debug_wb_pc,      
    output wire [3:0]   debug_wb_rf_wen,
    output wire [4:0]   debug_wb_rf_wnum, 
    output wire [31:0]  debug_wb_rf_wdata
);
    //datapath传出来的sram信号
    wire        inst_sram_en    ;
    wire [31:0] inst_sram_addr  ;
    wire [31:0]	inst_sram_rdata1;
    wire [31:0]	inst_sram_rdata2;
    wire        data_sram_en    ;
    wire [31:0] data_sram_addr  ;
    wire [31:0] data_sram_rdata ;
    wire [ 3:0] data_sram_wen   ;
    wire [31:0] data_sram_wdata ;
    
    wire i_stall          ;
    wire d_stall          ;
    wire longest_stall    ;

    datapath u_datapath(
        //ports
        .clk             		( clk             		),
        .rst             		( rst             		),
        .ext_int         		( ext_int         		),
        .inst_data_ok1   		( inst_data_ok1   		),
        .inst_data_ok2   		( inst_data_ok2   		), 
        .inst_rdata1     		( inst_rdata1     		), // 这里应该是 cpu_inst_rdata1
        .inst_rdata2     		( inst_rdata2     		),
        .inst_sram_en    		( inst_sram_en    		),
        .F_pc            		( inst_sram_addr        ), // 32bit的地址，但是一次传回2个数据
        .data_sram_rdata 		( data_sram_rdata 		),
        .data_sram_en    		( data_sram_en    		),
        .data_sram_wen   		( data_sram_wen   		),
        .data_sram_addr  		( data_sram_addr  		),
        .data_sram_wdata 		( data_sram_wdata 		),
        .i_stall                ( i_stall               ),
        .d_stall                ( d_stall               ),
        .longest_stall          ( longest_stall         )
    );

    i_sram_to_sram_like u_i_sram_to_sram_like(
        //ports
        .clk              		( clk              		),
        .rst              		( rst              		),
        .inst_sram_en     		( inst_sram_en     		),
        .inst_sram_addr   		( inst_sram_addr   		),
        .inst_sram_rdata1 		( inst_sram_rdata1 		),
        .inst_sram_rdata2 		( inst_sram_rdata2 		),
        .i_stall          		( i_stall          		),
        .inst_req         		( inst_req         		),
        .inst_wr          		( inst_wr          		),
        .inst_size        		( inst_size        		),
        .inst_addr        		( inst_addr        		),
        .inst_wdata       		( inst_wdata       		),
        .inst_addr_ok     		( inst_addr_ok     		),
        .inst_data_ok1    		( inst_data_ok1    		),
        .inst_data_ok2    		( inst_data_ok2    		),
        .inst_rdata1      		( inst_rdata1      		),
        .inst_rdata2      		( inst_rdata2      		),
        .longest_stall    		( longest_stall    		)
    );

    //data sram to sram-like
    d_sram_to_sram_like d_sram_to_sram_like(
        .clk(clk), .rst(rst),
        //sram
        .data_sram_en(data_sram_en),
        .data_sram_addr(data_sram_addr),
        .data_sram_rdata(data_sram_rdata),
        .data_sram_wen(data_sram_wen),
        .data_sram_wdata(data_sram_wdata),
        .d_stall(d_stall),
        //sram like
        .data_req(data_req),    
        .data_wr(data_wr),
        .data_size(data_size),
        .data_addr(data_addr),   
        .data_wdata(data_wdata),
        .data_addr_ok(data_addr_ok),
        .data_data_ok(data_data_ok),
        .data_rdata(data_rdata),

        .longest_stall(longest_stall)
    );

    assign debug_wb_pc          = (~clk) ? u_datapath.W_master_pc : u_datapath.W_slave_pc;
    assign debug_wb_rf_wen      = (~rst) ? 4'b0000 : ((~clk) ? {4{u_datapath.u_regfile.wen1}} : {4{u_datapath.u_regfile.wen2}});
    assign debug_wb_rf_wnum     = (~clk) ? u_datapath.u_regfile.wa1 : u_datapath.u_regfile.wa2;
    assign debug_wb_rf_wdata    = (~clk) ? u_datapath.u_regfile.wd1 : u_datapath.u_regfile.wd2;

endmodule