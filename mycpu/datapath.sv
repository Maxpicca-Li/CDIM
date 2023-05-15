`timescale 1ns / 1ps
`include "defines.vh"

module datapath (
    // ctrl
    input  wire        clk,
    input  wire        rst,
    input  wire [5 :0] ext_int ,
    // inst
    input  wire        i_stall,
    output wire        stallF,
    output wire        inst_sram_en, 
    output wire [31:0] F_pc,
    output wire [31:0] F_pc_next,
    input  wire        inst_data_ok1,
    input  wire        inst_data_ok2,
    input  wire [31:0] inst_rdata1,
    input  wire [31:0] inst_rdata2,
    input  wire        inst_tlb_refill,
    input  wire        inst_tlb_invalid,
    output wire        fence_iE,
    output wire [31:0] fence_addrE,
    output wire        fence_dM,
    output wire [31:0] fence_addrM,
    output wire        fence_tlbE,
    input  wire [31:13]itlb_vpn2,
    output wire        itlb_found,
    output tlb_entry   itlb_entry,
    // data
    input  wire        d_stall,
    output wire        stallM,
    output wire        mem_read_enE,
    output wire        mem_write_enE,
    output wire [31:0] E_mem_va,
    output wire [31:0] mem_addrE, // TODO: delete
    input  wire [31:0] data_sram_rdataM,
    output wire        data_sram_enM,
    output wire [ 1:0] data_sram_rlenM,
    output wire [ 3:0] data_sram_wenM,
    output wire [31:0] M_mem_va,
    output wire [31:0] data_sram_addrM, // TODO: delete
    output wire [31:0] data_sram_wdataM,
    input  wire [31:13]dtlb_vpn2,
    output             dtlb_found,
    output tlb_entry   dtlb_entry,
    output             fence_tlbM,
    input  logic       data_tlb_refill,
    input  logic       data_tlb_invalid,
    input  logic       data_tlb_mod,
    //debug
    output wire [31:0] debug_wb_pc,      
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum, 
    output wire [31:0] debug_wb_rf_wdata,
    output wire [31:0] debug_cp0_count,
    output wire [31:0] debug_cp0_random,
    output wire [31:0] debug_cp0_cause,
    output wire debug_int,
    output wire debug_commit
);

// debug
wire [31:0] E_master_debug_cp0_count;
wire [31:0] E_master_debug_cp0_random;
wire [31:0] E_master_debug_cp0_cause;
wire [31:0] M_master_debug_cp0_count;
wire [31:0] M_master_debug_cp0_random;
wire [31:0] M_master_debug_cp0_cause;
wire        M_master_debug_int;
wire [31:0] W_master_debug_cp0_count;
wire [31:0] W_master_debug_cp0_random;
wire [31:0] W_master_debug_cp0_cause;
wire        W_master_debug_int;

assign debug_cp0_count = W_master_debug_cp0_count;
assign debug_cp0_random = W_master_debug_cp0_random;
assign debug_cp0_cause = W_master_debug_cp0_cause;
assign debug_int = W_master_debug_int;
assign debug_commit = W_ena;

// ====================================== 变量定义区 ======================================
// fifo
wire            fifo_empty;
wire            fifo_almost_empty;
wire            fifo_full;
// 流水线控制信号
wire            F_ena;
wire            D_ena;
wire            D_slave_ena;
wire            E_ena;
wire            M_ena;
wire            W_ena;
wire            F_flush;
wire            D_flush;
wire            E_flush;
wire            M_flush;
wire            W_flush;
wire            E_alu_stall;
wire            delay_slot_flush;
ctrl_sign       D1cs,D2cs;
ctrl_sign       E1cs,E2cs;
ctrl_sign       M1cs,M2cs;
// ctrl_sign       W1cs,W2cs; // There is no need.
wire            D_master_reg_wen,D_slave_reg_wen;
wire            E_master_reg_wen,E_slave_reg_wen; // Separated this signal because it changes in E.
wire            M_master_reg_wen,M_slave_reg_wen;
wire            W_master_reg_wen,W_slave_reg_wen;
// cp0
wire [31:0]     E_cp0_rdata;
wire            M_cp0_jump;
wire [31:0]     M_cp0_jump_pc;
// dtlb
/*
wire [31:13]    dtlb_vpn2;
wire            dtlb_found;
tlb_entry       dtlb_entry;
*/
// ===== F =====
wire            F_pc_except;
wire            pc_en;
// ===== D =====
wire            D_cp0_useable;
wire            D_kernel_mode;
wire            D_interrupt;
int_info        D_int_info;
wire            delay_sel_rst;
wire            D_master_is_bj;
wire            D_master_bj,D_master_is_branch,D_master_is_jump;
wire            D_master_pred_take,D_master_jump_take,D_master_jump_conflict;
wire [31:0]     D_master_branch_target,D_master_jump_target,D_master_pc_plus4,D_master_bj_target;
wire [31:0]     D_master_pc,D_slave_pc;
wire [31:0]     D_master_inst,D_slave_inst;
wire            D_master_tlb_refill,D_slave_tlb_refill;
wire            D_master_tlb_invalid,D_slave_tlb_invalid;
wire            D_master_is_in_delayslot,D_slave_is_in_delayslot;
wire            D_master_is_link_pc8,D_slave_is_link_pc8;
wire [5:0]      D_master_op,D_slave_op;
wire [5:0]      D_master_funct,D_slave_funct;
wire [31:0]     D_master_shamt_value,D_slave_shamt_value;
wire [31:0]     D_master_imm_value,D_slave_imm_value;
wire            D_master_break_inst,D_slave_break_inst;
wire            D_master_syscall_inst,D_slave_syscall_inst;
wire            D_master_eret_inst,D_slave_eret_inst;
wire            D_master_id_cpu,D_slave_id_cpu;
cop0_info       D_master_cop0_info,D_slave_cop0_info;
wire            D_master_undefined_inst,D_slave_undefined_inst;
wire [3:0]      D_master_branch_type,D_slave_branch_type;
wire [3:0]      D_master_trap_type,D_slave_trap_type;
wire [`CmovBus] D_master_cmov_type,D_slave_cmov_type;
wire [4:0]      D_master_rs,D_slave_rs;
wire [4:0]      D_master_rt,D_slave_rt;
wire [4:0]      D_master_rd,D_slave_rd;
wire [31:0]     D_master_rs_value_tmp,D_slave_rs_value_tmp;
wire [31:0]     D_master_rt_value_tmp,D_slave_rt_value_tmp;
wire [31:0]     D_master_rs_value,D_slave_rs_value;
wire [31:0]     D_master_rt_value,D_slave_rt_value;
wire [4:0]      D_master_reg_waddr,D_slave_reg_waddr;
except_bus      D_master_except,D_slave_except;
// ===== E =====
/*
wire            E_mem_writeable;
wire            E_tlb_refill;
wire            E_tlb_invalid;
*/
wire            E_master_exp_trap;
wire [3 :0]     E_master_branch_type;
wire [3 :0]     E_master_trap_type;
wire            E_master_is_branch;
wire            E_master_bj;
wire            E_next_pc8;
wire            E_master_pred_take,E_master_actual_take,E_master_pred_fail;
wire            E_master_jump_conflict_tmp;
wire            E_master_is_link_pc8;
wire [31:0]     E_master_branch_target,E_master_pc_plus4, E_master_pc_plus8, E_master_bj_target;
wire            E_master_alu_stall, E_slave_alu_stall;
wire [4 :0]     E_master_rs,E_slave_rs;
wire [4 :0]     E_master_rt,E_slave_rt;
wire [31:0]     E_master_inst,E_slave_inst;
wire [31:0]     E_master_shamt_value,E_slave_shamt_value;
wire [31:0]     E_master_rs_value,E_slave_rs_value;
wire [31:0]     E_master_rt_value,E_slave_rt_value;
wire [31:0]     E_master_imm_value,E_slave_imm_value;
wire [31:0]     E_master_pc,E_slave_pc;
wire [5 :0]     E_master_op,E_slave_op;
wire [4 :0]     E_master_reg_waddr,E_slave_reg_waddr;
wire            E_master_is_in_delayslot,E_slave_is_in_delayslot;
except_bus      E_master_except_temp,E_slave_except_temp;
except_bus      E_master_except,E_slave_except;
cop0_info       E_master_cop0_info,E_slave_cop0_info,E_cop0_info;
wire [`CmovBus] E_master_cmov_type,E_slave_cmov_type;
wire [31:0]     E_master_mem_addr,E_slave_mem_addr;
wire [31:0]     E_master_alu_srca,E_slave_alu_srca;
wire [31:0]     E_master_alu_srcb,E_slave_alu_srcb;
wire [31:0]     E_master_alu_res_tmp;
wire [31:0]     E_master_alu_res,E_slave_alu_res;
wire [63:0]     E_master_alu_out64,E_slave_alu_out64;
wire            E_master_overflow,E_slave_overflow;
wire [5 :0]     mem_opE;
wire            mem_enE;
wire [31:0]     mem_wdataE;
wire            E_master_mem_sel,E_slave_mem_sel;
wire            E_master_mem_adel,E_slave_mem_adel;
wire            E_master_mem_ades,E_slave_mem_ades;
// ===== M =====
wire            M_master_flush_all;
wire [31:0]     M_master_inst,M_slave_inst;
wire [31:0]     M_master_pc,M_slave_pc;
wire [31:0]     M_master_alu_res,M_slave_alu_res;
wire [ 4:0]     M_master_reg_waddr,M_slave_reg_waddr;
except_bus      M_master_except_temp,M_slave_except_temp;
except_bus      M_master_except,M_slave_except;
wire            M_master_is_in_delayslot, M_slave_is_in_delayslot;
wire [31:0]     M_master_pc_plus4;
wire [31:0]     mem_rdataM;
wire            mem_enM;
wire            mem_renM;
wire            mem_wenM;
wire [5 :0]     mem_opM;
wire [31:0]     mem_addrM;
wire [31:0]     mem_wdataM;
wire            M_master_mem_sel,M_slave_mem_sel;
wire [31:0]     M_master_mem_rdata,M_slave_mem_rdata;
// ===== W =====
wire [31:0]     W_master_inst,W_slave_inst;
wire [31:0]     W_master_pc,W_slave_pc;
wire [31:0]     W_master_alu_res,W_slave_alu_res;
wire [ 4:0]     W_master_reg_waddr,W_slave_reg_waddr;
wire [31:0]     W_master_reg_wdata,W_slave_reg_wdata;
wire [31:0]     M_master_reg_wdata,M_slave_reg_wdata;
except_bus      W_master_except,W_slave_except;

// ====================================== 冒险处理 ======================================
hazard u_hazard(
    //ports
    .D_master_read_rs           ( D1cs.read_rs               ),
    .D_master_read_rt           ( D1cs.read_rt               ),
    .D_master_rs                ( D_master_rs                ),
    .D_master_rt                ( D_master_rt                ),
    .E_master_memtoReg          ( E1cs.mem_write_reg         ),
    .E_master_reg_waddr         ( E_master_reg_waddr         ),
    .E_slave_memtoReg           ( E2cs.mem_write_reg         ),
    .E_slave_reg_waddr          ( E_slave_reg_waddr          ),
    .i_stall                    ( i_stall                    ),
    .E_alu_stall                ( E_alu_stall                ),
    .d_stall                    ( d_stall                    ),
    .M_except                   ( M_cp0_jump                 ),
    .M_flush_all                ( M_master_flush_all         ),
    .E_bj                       ( E_master_bj                ),
    .D_bj                       ( D_master_bj                ),
    .F_ena                      ( F_ena                      ),
    .D_ena                      ( D_ena                      ),
    .E_ena                      ( E_ena                      ),
    .M_ena                      ( M_ena                      ),
    .W_ena                      ( W_ena                      ),
    .F_flush                    ( F_flush                    ),
    .D_flush                    ( D_flush                    ),
    .E_flush                    ( E_flush                    ),
    .M_flush                    ( M_flush                    ),
    .W_flush                    ( W_flush                    ),
    .delay_slot_flush           ( delay_slot_flush           )
);

// fence
assign fence_iE = E1cs.icache_fence;
assign fence_addrE = E_master_alu_res;
assign fence_dM = M1cs.dcache_fence;
assign fence_addrM = M_master_alu_res;
assign fence_tlbE = E1cs.tlb_fence;
assign fence_tlbM = M1cs.tlb_fence;

// ====================================== Fetch ======================================
// NOTE: 与i_stall有关的cache disable，一般修改stallF（即F_ena），而不是inst_sram_en，否则会loop
assign F_pc_except = (|F_pc[1:0]); // 必须是2'b00
// assign inst_sram_en =  !(rst | M_cp0_jump | F_pc_except | fifo_full);
assign inst_sram_en =  !(rst | fifo_full);
assign stallF = ~F_ena;
assign stallM = ~M_ena;
assign pc_en = F_ena | M_cp0_jump; // 异常的优先级最高，必须使能

pc_reg u_pc_reg(
    //ports
    .clk                      ( clk                      ),
    .rst                      ( rst                      ),
    .pc_en                    ( pc_en                    ),
    .M_except                 ( M_cp0_jump               ),
    .M_except_addr            ( M_cp0_jump_pc            ),
    .M_flush_all              ( M_master_flush_all       ),
    .M_flush_all_addr         ( M_master_pc_plus4        ),
    .E_bj                     ( E_master_bj              ),
    .E_bj_target              ( E_master_bj_target       ),
    .D_bj                     ( D_master_bj              ),
    .D_bj_target              ( D_master_bj_target       ),
    .D_fifo_full              ( fifo_full                ),
    .F_inst_data_ok1          ( inst_data_ok1            ),
    .F_inst_data_ok2          ( inst_data_ok2            ),
    .pc_next                  ( F_pc_next                ),
    .pc_curr                  ( F_pc                     )
);

assign E_next_pc8  = E_slave_is_in_delayslot | D_master_is_in_delayslot;
assign delay_sel_rst =  E_master_bj ? !E_next_pc8  :
                        D_master_bj ? !D_slave_ena :
                        1'b0;  // 防止两个女人一台戏！
inst_fifo u_inst_fifo(
    //ports
    .clk                          ( clk                    ),
    .rst                          ( rst                    ),
    .fifo_rst                     ( rst | D_flush          ), // TODO: fix fence_iE
    .flush_delay_slot             ( delay_slot_flush       ),
    .D_ena                        ( D_ena                  ),
    .i_stall                      ( i_stall                ),
    .master_is_branch             ( D_master_is_bj         ), // D阶段的branch
    .delay_sel_rst                ( delay_sel_rst          ),
    .D_delay_rst                  ( D_master_bj            ), // D: next_master_is_in_delayslot
    .E_delay_rst                  ( E_master_bj            ), // D: master_is_in_delayslot
    
    .read_en1                     ( D_ena                  ),
    .read_en2                     ( D_slave_ena            ), // D阶段的发射结果
    .read_tlb_refill1             ( D_master_tlb_refill    ),
    .read_tlb_refill2             ( D_slave_tlb_refill     ),
    .read_tlb_invalid1            ( D_master_tlb_invalid   ),
    .read_tlb_invalid2            ( D_slave_tlb_invalid    ),
    .read_address1                ( D_master_pc            ),
    .read_address2                ( D_slave_pc             ),
    .read_data1                   ( D_master_inst          ),
    .read_data2                   ( D_slave_inst           ),
    
    .write_en1                    ( inst_data_ok1          ),
    .write_en2                    ( inst_data_ok2          ),
    .write_tlb_refill1            ( inst_tlb_refill        ),
    .write_tlb_refill2            ( inst_tlb_refill        ),
    .write_tlb_invalid1           ( inst_tlb_invalid       ),
    .write_tlb_invalid2           ( inst_tlb_invalid       ),
    .write_address1               ( F_pc                   ),
    .write_address2               ( F_pc + 32'd4           ),
    .write_data1                  ( inst_rdata1            ),
    .write_data2                  ( inst_rdata2            ),
    
    .master_is_in_delayslot_o     (D_master_is_in_delayslot),
    .empty                        ( fifo_empty             ),
    .almost_empty                 ( fifo_almost_empty      ),
    .full                         ( fifo_full              )
);


// ====================================== Decode ======================================
assign D_master_except = '{
    default     : '0,
    if_tlbl     : D_master_tlb_refill | D_master_tlb_invalid,
    if_tlbrf    : D_master_tlb_refill,
    if_adel     : (|D_master_pc[1:0]) | (D_master_pc[31] & !D_kernel_mode),
    id_ri       : D_master_undefined_inst,
    id_syscall  : D_master_syscall_inst,
    id_break    : D_master_break_inst,
    id_eret     : D_master_eret_inst,
    id_int      : D_interrupt,
    id_cpu      : D_master_id_cpu
};
assign D_slave_except = '{
    default     : '0,
    if_tlbl     : D_slave_tlb_refill | D_slave_tlb_invalid,
    if_tlbrf    : D_slave_tlb_refill,
    if_adel     : (|D_slave_pc[1:0]) | (D_slave_pc[31] & !D_kernel_mode),
    id_ri       : D_slave_undefined_inst,
    id_syscall  : D_slave_syscall_inst,
    id_break    : D_slave_break_inst,
    id_eret     : D_slave_eret_inst,
    id_cpu      : D_slave_id_cpu
};
int_raiser d_int(
    .info_i ( D_int_info    ),
    .id_ena ( !fifo_empty   ), // skip branch jump
    .int_o  ( D_interrupt   )
);

decoder u_decoder_master(
    //ports
    .instr                         ( D_master_inst              ),
    .c0_useable                    ( D_cp0_useable              ),
    .op                            ( D_master_op                ),
    .rs                            ( D_master_rs                ),
    .rt                            ( D_master_rt                ),
    .rd                            ( D_master_rd                ),
    .funct                         ( D_master_funct             ),
    .reg_waddr                     ( D_master_reg_waddr         ),
    .shamt_value                   ( D_master_shamt_value       ),
    .sign_extend_imm_value         ( D_master_imm_value         ),
    .is_link_pc8                   ( D_master_is_link_pc8       ),
    .branch_type                   ( D_master_branch_type       ),
    .trap_type                     ( D_master_trap_type         ),
    .cmov_type                     ( D_master_cmov_type         ),
    .signsD                        ( D1cs                       ),
    .undefined_inst                ( D_master_undefined_inst    ),
    .syscall_inst                  ( D_master_syscall_inst      ),
    .break_inst                    ( D_master_break_inst        ),
    .eret_inst                     ( D_master_eret_inst         ),
    .id_cpu                        ( D_master_id_cpu            ),
    .cop0_info_out                 ( D_master_cop0_info         )
);

decoder u_decoder_slave(
    //ports
    .instr                         ( D_slave_inst               ),
    .c0_useable                    ( D_cp0_useable              ),
    .op                            ( D_slave_op                 ),
    .rs                            ( D_slave_rs                 ),
    .rt                            ( D_slave_rt                 ),
    .rd                            ( D_slave_rd                 ),
    .funct                         ( D_slave_funct              ),
    .reg_waddr                     ( D_slave_reg_waddr          ),
    .shamt_value                   ( D_slave_shamt_value        ),
    .sign_extend_imm_value         ( D_slave_imm_value          ),
    .is_link_pc8                   ( D_slave_is_link_pc8        ),
    .branch_type                   ( D_slave_branch_type        ),
    .trap_type                     ( D_slave_trap_type          ),
    .cmov_type                     ( D_slave_cmov_type          ),
    .signsD                        ( D2cs                       ),
    .undefined_inst                ( D_slave_undefined_inst     ),
    .syscall_inst                  ( D_slave_syscall_inst       ),
    .break_inst                    ( D_slave_break_inst         ),
    .eret_inst                     ( D_slave_eret_inst          ),
    .id_cpu                        ( D_slave_id_cpu             ),
    .cop0_info_out                 ( D_slave_cop0_info          )
);

regfile u_regfile(
    //ports
    .clk               ( clk                    ),
    .rst               ( rst                    ),
    
    .ra1_a             ( D_master_rs            ),
    .rd1_a             ( D_master_rs_value_tmp  ),
    .ra1_b             ( D_master_rt            ),
    .rd1_b             ( D_master_rt_value_tmp  ),
    .wen1              ( W_master_reg_wen & W_ena & ~(|W_master_except)), 
    .wa1               ( W_master_reg_waddr     ),
    .wd1               ( W_master_reg_wdata     ),
    
    .ra2_a             ( D_slave_rs             ),
    .rd2_a             ( D_slave_rs_value_tmp   ),
    .ra2_b             ( D_slave_rt             ),
    .rd2_b             ( D_slave_rt_value_tmp   ),
    .wen2              ( W_slave_reg_wen & W_ena & ~(|W_master_except) & ~(|W_slave_except)),
    .wa2               ( W_slave_reg_waddr      ),
    .wd2               ( W_slave_reg_wdata      )
);

// 跳转分析
assign D_master_pc_plus4 = D_master_pc + 32'd4;
assign D_master_is_bj = D_master_is_branch | D_master_is_jump;
assign D_master_bj = D_master_pred_take | D_master_jump_take;
assign D_master_bj_target = {32{ D_master_pred_take}} & D_master_branch_target | 
                            {32{!D_master_pred_take}} & D_master_jump_target   ;
branch_predict u_branch_predict(
    //ports
    .clk                    ( clk                    ),
    .rst                    ( rst                    ),
    .enaD                   ( D_ena                  ),
    .instrD                 ( D_master_inst          ),
    .pcD                    ( D_master_pc            ),
    .pc_plus4D              ( D_master_pc_plus4      ),
    .pcE                    ( E_master_pc            ),
    .branchE                ( E_master_is_branch     ),
    .actual_takeE           ( E_master_actual_take   ),
    .branchD                ( D_master_is_branch     ),
    .pred_takeD             ( D_master_pred_take     ),
    .branch_targetD         ( D_master_branch_target )
);
jump_judge u_jump_judge(
    //ports
    .enaD                   ( D_ena                ),
    .instrD                 ( D_master_inst        ),
    .pc_plus4D              ( D_master_pc_plus4    ),
    .rs_valueD              ( D_master_rs_value_tmp), // don't need the forward data, just the data read from regfile is ok.
    .reg_write_enE1         ( E_master_reg_wen     ),
    .reg_write_enM1         ( M_master_reg_wen     ),
    .reg_waddrE1            ( E_master_reg_waddr   ),
    .reg_waddrM1            ( M_master_reg_waddr   ),
    .reg_write_enE2         ( E_slave_reg_wen      ),
    .reg_write_enM2         ( M_slave_reg_wen      ),
    .reg_waddrE2            ( E_slave_reg_waddr    ),
    .reg_waddrM2            ( M_slave_reg_waddr    ),
    .is_jumpD               ( D_master_is_jump     ),
    .jump_conflictD         ( D_master_jump_conflict),
    .jump_takeD             ( D_master_jump_take   ),
    .jump_targetD           ( D_master_jump_target )
);

assign D_master_reg_wen = D1cs.reg_write;
assign D_slave_reg_wen  = D2cs.reg_write;
issue_ctrl u_issue_ctrl(
    //ports
    .D_master_ena               ( D_ena                     ),
    .D_mem_conflict             ( D1cs.mem_en & D2cs.mem_en ),
    .D_mul_conflict             ( D1cs.mul_en & D2cs.mul_en ),
    .D_div_conflict             ( D1cs.div_en & D2cs.div_en ),
    .E_master_memtoReg          ( E1cs.mem_write_reg        ),
    .E_master_reg_waddr         ( E_master_reg_waddr        ),
    .E_slave_memtoReg           ( E2cs.mem_write_reg        ),
    .E_slave_reg_waddr          ( E_slave_reg_waddr         ),
    .D_master_reg_wen           ( D_master_reg_wen          ),
    .D_master_reg_waddr         ( D_master_reg_waddr        ),
    .D_slave_read_rs            ( D2cs.read_rs              ),
    .D_slave_read_rt            ( D2cs.read_rt              ),
    .D_slave_rs                 ( D_slave_rs                ),
    .D_slave_rt                 ( D_slave_rt                ),
    .D_master_hilowrite         ( D1cs.hilo_write           ),
    .D_slave_hiloread           ( D2cs.hilo_read            ),
    .D_slave_hilowrite          ( D2cs.hilo_write           ),
    .D_master_cp0write          ( D1cs.cp0_write            ),
    .D_slave_cp0read            ( D2cs.cp0_read             ),
    .D_master_is_branch         ( D_master_is_bj            ),
    .D_master_only_one_issue    ( D1cs.only_one_issue       ),
    .D_slave_only_one_issue     ( D2cs.only_one_issue       ),
    .D_slave_may_bring_flush    ( D2cs.may_bring_flush      ),
    .fifo_empty                 ( fifo_empty                ),
    .fifo_almost_empty          ( fifo_almost_empty         ),
    .D_slave_is_in_delayslot    ( D_slave_is_in_delayslot   ),
    .D_slave_ena                ( D_slave_ena               )
);


// in the end 前推计算结果和访存结果 EM->D
forward_top u_forward_top(
    //ports
    .alu_wen1                   ( E_slave_reg_wen & (!E2cs.mem_write_reg)), // The "alu_wen1" here means to forward it first
    .alu_waddr1                 ( E_slave_reg_waddr         ),
    .alu_wdata1                 ( E_slave_alu_res           ), // 计算结果
    .alu_wen2                   ( E_master_reg_wen & (!E1cs.mem_write_reg)),
    .alu_waddr2                 ( E_master_reg_waddr        ),
    .alu_wdata2                 ( E_master_alu_res          ),
    .alu_wen3                   ( M_slave_reg_wen            ),
    .alu_waddr3                 ( M_slave_reg_waddr         ),
    .alu_wdata3                 ( M_slave_reg_wdata         ), // 计算结果和访存结果
    .alu_wen4                   ( M_master_reg_wen            ),
    .alu_waddr4                 ( M_master_reg_waddr        ),
    .alu_wdata4                 ( M_master_reg_wdata        ),
    // .memtoReg                    ( M1cs.mem_write_reg        ),
    // .mem_waddr                   ( M_master_reg_waddr        ),
    // .mem_rdata                   ( M_master_mem_rdata        ),
    .master_rs                  ( D_master_rs               ),
    .master_rs_value_tmp        ( D_master_rs_value_tmp     ),
    .master_rs_value            ( D_master_rs_value         ),
    .master_rt                  ( D_master_rt               ),
    .master_rt_value_tmp        ( D_master_rt_value_tmp     ),
    .master_rt_value            ( D_master_rt_value         ),
    .slave_rs                   ( D_slave_rs                ),
    .slave_rs_value_tmp         ( D_slave_rs_value_tmp      ),
    .slave_rs_value             ( D_slave_rs_value          ),
    .slave_rt                   ( D_slave_rt                ),
    .slave_rt_value_tmp         ( D_slave_rt_value_tmp      ),
    .slave_rt_value             ( D_slave_rt_value          )
);

// ====================================== Execute ======================================
wire D2E_clear1,D2E_clear2;
// wire [31:0] E_master_rs_value_tmp,E_master_rt_value_tmp,E_slave_rs_value_tmp,E_slave_rt_value_tmp;
// 在使能的情况下跳转清空才成立
assign D2E_clear1 = M_cp0_jump | M_master_flush_all | (!D_master_is_in_delayslot & E_flush & E_ena) | (!D_ena & E_ena);
assign D2E_clear2 = M_cp0_jump | M_master_flush_all | (E_flush & D_slave_ena) || (E_ena & !D_slave_ena);
id_ex u_id_ex(
    //ports
    .clk                      ( clk                          ),
    .rst                      ( rst                          ),
    .clear1                   ( D2E_clear1                   ),
    .clear2                   ( D2E_clear2                   ),
    .ena1                     ( E_ena                        ),
    .ena2                     ( D_slave_ena                  ), // NOTE: this is D_slave_ena, which means D_slave_inst can go E
    .D_master_ctrl_sign       ( D1cs                         ),
    .D_master_except          ( D_master_except              ),
    .D_master_cop0_info       ( D_master_cop0_info           ),
    .D_master_is_link_pc8     ( D_master_is_link_pc8         ),
    .D_master_is_in_delayslot ( D_master_is_in_delayslot     ),
    .D_master_is_branch       ( D_master_is_branch           ),
    .D_master_pred_take       ( D_master_pred_take           ),
    .D_master_jump_conflict   ( D_master_jump_conflict       ),
    .D_master_branch_type     ( D_master_branch_type         ),
    .D_master_trap_type       ( D_master_trap_type           ),
    .D_master_rs              ( D_master_rs                  ),
    .D_master_rt              ( D_master_rt                  ),
    .D_master_reg_waddr       ( D_master_reg_waddr           ),
    .D_master_op              ( D_master_op                  ),
    .D_master_cmov_type       ( D_master_cmov_type           ),
    .D_master_pc              ( D_master_pc                  ),
    .D_master_inst            ( D_master_inst                ),
    .D_master_rs_value        ( D_master_rs_value            ),
    .D_master_rt_value        ( D_master_rt_value            ),
    .D_master_imm_value       ( D_master_imm_value           ),
    .D_master_shamt_value     ( D_master_shamt_value         ),
    .D_master_pc_plus4        ( D_master_pc_plus4            ),
    .D_master_branch_target   ( D_master_branch_target       ),
    .D_slave_ctrl_sign        ( D2cs                         ),
    .D_slave_except           ( D_slave_except               ),
    .D_slave_cop0_info        ( D_slave_cop0_info            ),
    .D_slave_is_in_delayslot  ( D_slave_is_in_delayslot      ),
    .D_slave_rs               ( D_slave_rs                   ),
    .D_slave_rt               ( D_slave_rt                   ),
    .D_slave_reg_waddr        ( D_slave_reg_waddr            ),
    .D_slave_op               ( D_slave_op                   ),
    .D_slave_cmov_type        ( D_slave_cmov_type            ),
    .D_slave_pc               ( D_slave_pc                   ),
    .D_slave_inst             ( D_slave_inst                 ),
    .D_slave_rs_value         ( D_slave_rs_value             ),
    .D_slave_rt_value         ( D_slave_rt_value             ),
    .D_slave_imm_value        ( D_slave_imm_value            ),
    .D_slave_shamt_value      ( D_slave_shamt_value          ),
    .E_master_ctrl_sign       ( E1cs                         ),
    .E_master_except          ( E_master_except_temp         ),
    .E_master_cop0_info       ( E_master_cop0_info           ),
    .E_master_is_link_pc8     ( E_master_is_link_pc8         ),
    .E_master_is_in_delayslot ( E_master_is_in_delayslot     ),
    .E_master_is_branch       ( E_master_is_branch           ),
    .E_master_pred_take       ( E_master_pred_take           ),
    .E_master_jump_conflict   ( E_master_jump_conflict_tmp   ),
    .E_master_branch_type     ( E_master_branch_type         ),
    .E_master_trap_type       ( E_master_trap_type           ),
    .E_master_rs              ( E_master_rs                  ),
    .E_master_rt              ( E_master_rt                  ),
    .E_master_reg_waddr       ( E_master_reg_waddr           ),
    .E_master_op              ( E_master_op                  ),
    .E_master_cmov_type       ( E_master_cmov_type           ),
    .E_master_pc              ( E_master_pc                  ),
    .E_master_inst            ( E_master_inst                ),
    .E_master_rs_value        ( E_master_rs_value            ),
    .E_master_rt_value        ( E_master_rt_value            ),
    .E_master_imm_value       ( E_master_imm_value           ),
    .E_master_shamt_value     ( E_master_shamt_value         ),
    .E_master_pc_plus4        ( E_master_pc_plus4            ),
    .E_master_branch_target   ( E_master_branch_target       ),
    .E_slave_ctrl_sign        ( E2cs                         ),
    .E_slave_except           ( E_slave_except_temp         ),
    .E_slave_cop0_info        ( E_slave_cop0_info            ),
    .E_slave_is_in_delayslot  ( E_slave_is_in_delayslot      ),
    .E_slave_rs               ( E_slave_rs                   ),
    .E_slave_rt               ( E_slave_rt                   ),
    .E_slave_reg_waddr        ( E_slave_reg_waddr            ),
    .E_slave_op               ( E_slave_op                   ),
    .E_slave_cmov_type        ( E_slave_cmov_type            ),
    .E_slave_pc               ( E_slave_pc                   ),
    .E_slave_inst             ( E_slave_inst                 ),
    .E_slave_rs_value         ( E_slave_rs_value             ),
    .E_slave_rt_value         ( E_slave_rt_value             ),
    .E_slave_imm_value        ( E_slave_imm_value            ),
    .E_slave_shamt_value      ( E_slave_shamt_value          )
);

assign E_master_except = '{
    default     : '0,
    if_adel     : E_master_except_temp.if_adel,
    if_tlbl     : E_master_except_temp.if_tlbl,
    if_tlbrf    : E_master_except_temp.if_tlbrf,
    id_ri       : E_master_except_temp.id_ri,
    id_syscall  : E_master_except_temp.id_syscall,
    id_break    : E_master_except_temp.id_break,
    id_eret     : E_master_except_temp.id_eret,
    id_int      : E_master_except_temp.id_int,
    id_cpu      : E_master_except_temp.id_cpu,
    ex_ov       : E_master_overflow,
    ex_adel     : E_master_mem_adel,
    ex_ades     : E_master_mem_ades
    /*
    ex_tlbl     : (E_tlb_invalid | E_tlb_refill) & mem_read_enE & E1cs.mem_en,
    ex_tlbs     : (E_tlb_invalid | E_tlb_refill) & mem_write_enE & E1cs.mem_en,
    ex_tlbm     : !E_mem_writeable & mem_write_enE & E1cs.mem_en,
    ex_tlbrf    : E_tlb_refill & E1cs.mem_en,
    ex_trap     : E_master_exp_trap & E1cs.mem_en
     */
};
assign E_slave_except = '{
    default     : '0,
    if_adel     : E_slave_except_temp.if_adel,
    if_tlbl     : E_slave_except_temp.if_tlbl,
    if_tlbrf    : E_slave_except_temp.if_tlbrf,
    id_ri       : E_slave_except_temp.id_ri,
    id_syscall  : E_slave_except_temp.id_syscall,
    id_break    : E_slave_except_temp.id_break,
    id_eret     : E_slave_except_temp.id_eret,
    id_int      : E_slave_except_temp.id_int,
    id_cpu      : E_slave_except_temp.id_cpu,
    ex_ov       : E_slave_overflow,
    ex_adel     : E_slave_mem_adel,
    ex_ades     : E_slave_mem_ades
    /*
    ex_tlbl     : (E_tlb_invalid | E_tlb_refill) & mem_read_enE & E2cs.mem_en,
    ex_tlbs     : (E_tlb_invalid | E_tlb_refill) & mem_write_enE & E2cs.mem_en,
    ex_tlbm     : !E_mem_writeable & mem_write_enE & E2cs.mem_en,
    ex_tlbrf    : E_tlb_refill & E2cs.mem_en
     */
};

assign E_mem_va = mem_addrE;

assign E_cop0_info = E_master_cop0_info & {$bits(E_master_cop0_info){~(|E_master_except_temp)}};

// branch and jump
assign E_master_bj = E_ena & (E_master_jump_conflict_tmp | E_master_pred_fail);
assign E_master_bj_target = {32{E_master_pred_fail &  E_master_actual_take}}                  & E_master_branch_target | 
                            {32{E_master_pred_fail & !E_master_actual_take &  E_next_pc8}}    & E_master_pc_plus8 | 
                            {32{E_master_pred_fail & !E_master_actual_take & !E_next_pc8}}    & E_master_pc_plus4 | 
                            {32{E_master_jump_conflict_tmp}}                                  & E_master_rs_value;
branch_judge u_branch_judge(
    //ports
    .branch_type                   ( E_master_branch_type ),
    .rs_value                      ( E_master_rs_value    ),
    .rt_value                      ( E_master_rt_value    ),
    .branch_take                   ( E_master_actual_take ),
    .pred_take                     ( E_master_pred_take   ),
    .pred_fail                     ( E_master_pred_fail   )
);

trap_judge u_trap_judge_master(
    //ports
    .trap_type      ( E_master_trap_type        ),
    .value1         ( E_master_alu_srca         ),
    .value2         ( E_master_alu_srcb         ),
    .exp_trap       ( E_master_exp_trap         )
);

// alu + hilo + compute
assign E_master_alu_srca =  E1cs.read_rs ? E_master_rs_value : E_master_shamt_value;
assign E_master_alu_srcb =  E1cs.read_rt ? E_master_rt_value : E_master_imm_value;
assign E_slave_alu_srca  =  E2cs.read_rs ? E_slave_rs_value  : E_slave_shamt_value;
assign E_slave_alu_srcb  =  E2cs.read_rt ? E_slave_rt_value  : E_slave_imm_value;
assign E_master_reg_wen =   E_master_cmov_type==`C_MOVN ? (|E_master_rt_value):    // !=0
                            E_master_cmov_type==`C_MOVZ ? (!(|E_master_rt_value)): // ==0
                            E1cs.reg_write;
assign E_slave_reg_wen  =   E_slave_cmov_type==`C_MOVN ? (|E_slave_rt_value):    // !=0
                            E_slave_cmov_type==`C_MOVZ ? (!(|E_slave_rt_value)): // ==0
                            E2cs.reg_write;
assign E_master_pc_plus8 = E_master_pc + 32'd8;
alu_top u_alu_top(
    //ports
    .clk                 ( clk              ),
    .rst                 ( rst              ),
    .M_ena               ( M_ena            ),
    .M_flush             ( M_flush          ),
    .hilo_write1         ( E1cs.hilo_write  ),
    .mul_en1             ( E1cs.mul_en      ),
    .div_en1             ( E1cs.div_en      ),
    .exp1                ( |E_master_except ),
    .aluop1              ( E1cs.aluop       ),
    .a1                  ( E_master_alu_srca),
    .b1                  ( E_master_alu_srcb),
    .overflow1           ( E_master_overflow),
    .y1                  ( E_master_alu_res ),
    .hilo_write2         ( E2cs.hilo_write  ),
    .mul_en2             ( E2cs.mul_en      ),
    .div_en2             ( E2cs.div_en      ),
    .exp2                ( |E_slave_except  ),
    .aluop2              ( E2cs.aluop       ),
    .a2                  ( E_slave_alu_srca ),
    .b2                  ( E_slave_alu_srcb ),
    .overflow2           ( E_slave_overflow ),
    .y2                  ( E_slave_alu_res  ),
    .cp0_rdata           ( E_cp0_rdata      ),
    .pc_plus8            ( E_master_pc_plus8),
    .is_link_pc8         ( E_master_is_link_pc8),
    .E_alu_stall         ( E_alu_stall      )
);

// 提前访存
// mem_addr: base(rs value) + offset(immediate value)
assign E_master_mem_addr = E_master_rs_value + E_master_imm_value;
assign E_slave_mem_addr = E_slave_rs_value + E_slave_imm_value; 

// Note: only care about except signals from D for load/store.
// FIXME: add adel/ades exception when reading kernel memory in usermode.
struct_conflict u_struct_conflict(
    // datapath ctrl
    .E_exp1             ( |E_master_except_temp ),
    .E_exp2             ( |E_slave_except_temp  ),
    .M_flush            ( M_flush           ),
    .M_ena              ( M_ena             ),
    // master
    .E_mem_en1          ( E1cs.mem_en       ),
    .E_mem_ren1         ( E1cs.mem_read     ),
    .E_mem_wen1         ( E1cs.mem_write    ),
    .E_mem_op1          ( E_master_op       ),
    .E_mem_addr1        ( E_master_mem_addr ),
    .E_mem_wdata1       ( E_master_rt_value ),
    .M_mem_sel1         ( M_master_mem_sel  ),
    .E_mem_adel1        ( E_master_mem_adel ),
    .E_mem_ades1        ( E_master_mem_ades ),
    .E_mem_sel1         ( E_master_mem_sel  ),
    .M_mem_rdata1       ( M_master_mem_rdata),
    // slave
    .E_mem_en2          ( E2cs.mem_en       ),
    .E_mem_ren2         ( E2cs.mem_read     ),
    .E_mem_wen2         ( E2cs.mem_write    ),
    .E_mem_op2          ( E_slave_op        ),
    .E_mem_addr2        ( E_slave_mem_addr  ),
    .E_mem_wdata2       ( E_slave_rt_value  ),
    .M_mem_sel2         ( M_slave_mem_sel   ),
    .E_mem_adel2        ( E_slave_mem_adel ),
    .E_mem_ades2        ( E_slave_mem_ades ),
    .E_mem_sel2         ( E_slave_mem_sel   ),
    .M_mem_rdata2       ( M_slave_mem_rdata ),
    // mem
    .E_mem_en           ( mem_enE           ),
    .E_mem_ren          ( mem_read_enE      ),
    .E_mem_wen          ( mem_write_enE     ),
    .E_mem_op           ( mem_opE           ),
    .E_mem_addr         ( mem_addrE         ),
    .E_mem_wdata        ( mem_wdataE        ),
    .M_mem_rdata        ( mem_rdataM        )
);


// ====================================== Memory ======================================
ex_mem u_ex_mem(
    //ports
    .clk                        ( clk                         ),
    .rst                        ( rst                         ),
    .clear1                     ( M_flush                     ),
    .clear2                     ( M_flush                     ),
    .ena1                       ( M_ena                       ),
    .ena2                       ( M_ena                       ),
    .E_mem_en                   ( mem_enE                     ),
    .E_mem_ren                  ( mem_read_enE                ),
    .E_mem_wen                  ( mem_write_enE               ),
    .E_mem_op                   ( mem_opE                     ),
    .E_mem_addr                 ( mem_addrE                   ),
    .E_mem_wdata                ( mem_wdataE                  ),
    .E_mem_va                   ( E_mem_va                    ),
    .M_mem_en                   ( mem_enM                     ),
    .M_mem_ren                  ( mem_renM                    ),
    .M_mem_wen                  ( mem_wenM                    ),
    .M_mem_op                   ( mem_opM                     ),
    .M_mem_addr                 ( mem_addrM                   ),
    .M_mem_wdata                ( mem_wdataM                  ),
    .M_mem_va                   ( M_mem_va                    ),
    .E_master_ctrl_sign         ( E1cs                        ),
    .E_master_except            ( E_master_except             ),
    .E_master_reg_wen           ( E_master_reg_wen            ),
    .E_master_mem_sel           ( E_master_mem_sel            ),
    .E_master_is_in_delayslot   ( E_master_is_in_delayslot    ),
    .E_master_reg_waddr         ( E_master_reg_waddr          ),
    .E_master_inst              ( E_master_inst               ),
    .E_master_alu_res           ( E_master_alu_res            ),
    .E_master_pc                ( E_master_pc                 ),
    .E_slave_ctrl_sign          ( E2cs                        ),
    .E_slave_except             ( E_slave_except              ),
    .E_slave_reg_wen            ( E_slave_reg_wen             ),
    .E_slave_mem_sel            ( E_slave_mem_sel             ),
    .E_slave_is_in_delayslot    ( E_slave_is_in_delayslot     ),
    .E_slave_reg_waddr          ( E_slave_reg_waddr           ),
    .E_slave_pc                 ( E_slave_pc                  ),
    .E_slave_inst               ( E_slave_inst                ),
    .E_slave_alu_res            ( E_slave_alu_res             ),
    .M_master_ctrl_sign         ( M1cs                        ),
    .M_master_except            ( M_master_except_temp        ),
    .M_master_reg_wen           ( M_master_reg_wen            ),
    .M_master_mem_sel           ( M_master_mem_sel            ),
    .M_master_is_in_delayslot   ( M_master_is_in_delayslot    ),
    .M_master_reg_waddr         ( M_master_reg_waddr          ),
    .M_master_inst              ( M_master_inst               ),
    .M_master_alu_res           ( M_master_alu_res            ),
    .M_master_pc                ( M_master_pc                 ),
    .M_slave_ctrl_sign          ( M2cs                        ),
    .M_slave_except             ( M_slave_except_temp         ),
    .M_slave_reg_wen            ( M_slave_reg_wen             ),
    .M_slave_mem_sel            ( M_slave_mem_sel             ),
    .M_slave_is_in_delayslot    ( M_slave_is_in_delayslot     ),
    .M_slave_reg_waddr          ( M_slave_reg_waddr           ),
    .M_slave_pc                 ( M_slave_pc                  ),
    .M_slave_inst               ( M_slave_inst                ),
    .M_slave_alu_res            ( M_slave_alu_res             ),
    .E_master_debug_cp0_count   ( E_master_debug_cp0_count    ),  
    .E_master_debug_cp0_random  ( E_master_debug_cp0_random   ),
    .E_master_debug_cp0_cause   ( E_master_debug_cp0_cause    ),
    .M_master_debug_cp0_count   ( M_master_debug_cp0_count    ),  
    .M_master_debug_cp0_random  ( M_master_debug_cp0_random   ),
    .M_master_debug_cp0_cause   ( M_master_debug_cp0_cause    )
);

assign M_master_except = '{
    default     : '0,
    if_adel     : M_master_except_temp.if_adel,
    if_tlbl     : M_master_except_temp.if_tlbl,
    if_tlbrf    : M_master_except_temp.if_tlbrf,
    id_ri       : M_master_except_temp.id_ri,
    id_syscall  : M_master_except_temp.id_syscall,
    id_break    : M_master_except_temp.id_break,
    id_eret     : M_master_except_temp.id_eret,
    id_int      : M_master_except_temp.id_int,
    id_cpu      : M_master_except_temp.id_cpu,
    ex_ov       : M_master_except_temp.ex_ov,
    ex_adel     : M_master_except_temp.ex_adel,
    ex_ades     : M_master_except_temp.ex_ades,
    ex_tlbl     : (data_tlb_invalid | data_tlb_refill) & data_sram_enM & M1cs.mem_en & !(|data_sram_wenM),
    ex_tlbs     : (data_tlb_invalid | data_tlb_refill) & data_sram_enM & M1cs.mem_en & (|data_sram_wenM),
    ex_tlbm     : data_tlb_mod & (|data_sram_wenM) & M1cs.mem_en,
    ex_tlbrf    : data_tlb_refill & M1cs.mem_en,
    ex_trap     : M_master_except_temp.ex_trap
};

assign M_slave_except = '{
    default     : '0,
    if_adel     : M_slave_except_temp.if_adel,
    if_tlbl     : M_slave_except_temp.if_tlbl,
    if_tlbrf    : M_slave_except_temp.if_tlbrf,
    id_ri       : M_slave_except_temp.id_ri,
    id_syscall  : M_slave_except_temp.id_syscall,
    id_break    : M_slave_except_temp.id_break,
    id_eret     : M_slave_except_temp.id_eret,
    id_int      : M_slave_except_temp.id_int,
    id_cpu      : M_slave_except_temp.id_cpu,
    ex_ov       : M_slave_except_temp.ex_ov,
    ex_adel     : M_slave_except_temp.ex_adel,
    ex_ades     : M_slave_except_temp.ex_ades,
    ex_tlbl     : (data_tlb_invalid | data_tlb_refill) & data_sram_enM & M2cs.mem_en & !(|data_sram_wenM),
    ex_tlbs     : (data_tlb_invalid | data_tlb_refill) & data_sram_enM & M2cs.mem_en & (|data_sram_wenM),
    ex_tlbm     : data_tlb_mod & (|data_sram_wenM) & M2cs.mem_en,
    ex_tlbrf    : data_tlb_refill & M2cs.mem_en,
    ex_trap     : M_slave_except_temp.ex_trap
};

assign M_master_pc_plus4 = M_master_pc + 32'd4;
assign M_master_flush_all = M1cs.flush_all & M_ena;
/*
d_tlb dtlb_inst(
    .clk                ( clk               ),
    .rst                ( rst               ),
    .E_mem_en           ( mem_enE           ),
    .E_mem_va           ( mem_addrE         ),
    .E_mem_pa           ( E_mem_pa          ),
    .E_mem_uncached     ( E_mem_uncached    ),
    .E_mem_writeable    ( E_mem_writeable   ),
    .E_tlb_refill       ( E_tlb_refill      ),
    .E_tlb_invalid      ( E_tlb_invalid     ),
    // to hazard
    .E_ready_go         ( M_ena             ),
    .E_dtlb_stall       ( E_dtlb_stall      ),
    // to l2 tlb
    .dtlb_vpn2          ( dtlb_vpn2         ),
    .dtlb_found         ( dtlb_found        ),
    .fence_tlb          ( fence_tlbE        ),
    .dtlb_entry         ( dtlb_entry        )
);
*/
mem_access u_mem_access(
    //ports
    .mem_en                 ( mem_enM                   ),
    .mem_op                 ( mem_opM                   ),
    .mem_wdata              ( mem_wdataM                ),
    .mem_addr               ( mem_addrM                 ),
    .mem_rdata              ( mem_rdataM                ),
    .data_sram_rdata        ( data_sram_rdataM          ),
    .data_sram_en           ( data_sram_enM             ),
    .data_sram_rlen         ( data_sram_rlenM           ),
    .data_sram_wen          ( data_sram_wenM            ),
    .data_sram_addr         ( data_sram_addrM           ), // TODO: delete
    .data_sram_wdata        ( data_sram_wdataM          ),
    // 异常处理及其选择
    .M_master_mem_sel       ( M_master_mem_sel          ),
    .M_slave_mem_sel        ( M_slave_mem_sel           ),
    .M_master_except        ( M_master_except_temp      ),
    .M_slave_except         ( M_slave_except_temp       )
);

// new CP0
cp0 cp0_inst(
    .clk            ( clk                       ),
    .rst            ( rst                       ),
    .stallE         ( ~E_ena                    ),
    .stallM         ( ~M_ena                    ),
    .E_cop0_info    ( E_cop0_info               ),
    .E_master_pc    ( E_master_pc               ),
    .E_mfc0_rdata   ( E_cp0_rdata               ),
    .E_mtc0_wdata   ( E_master_rt_value         ),
    .ext_int        ( ext_int[4:0]              ),    // ext_int async
    .M_master_except( M_master_except           ),
    .M_slave_except ( M_slave_except            ),
    .M_master_pc    ( M_master_pc               ),
    .M_slave_pc     ( M_slave_pc                ),
    .M_master_bd    ( M_master_is_in_delayslot  ), // bd => branch delay slot
    .M_slave_bd     ( M_slave_is_in_delayslot   ),
    .M_mem_va       ( mem_addrM                 ),
    .M_cp0_jump_pc  ( M_cp0_jump_pc             ),
    .M_cp0_jump     ( M_cp0_jump                ),
    .D_cp0_useable  ( D_cp0_useable             ),
    .D_kernel_mode  ( D_kernel_mode             ),
    .D_int_info     ( D_int_info                ),
    .tlb1_vpn2      ( itlb_vpn2                 ),
    .tlb1_found     ( itlb_found                ),
    .tlb1_entry     ( itlb_entry                ),
    .tlb2_vpn2      ( dtlb_vpn2                 ),
    .tlb2_found     ( dtlb_found                ),
    .tlb2_entry     ( dtlb_entry                ),
    .debug_cp0_countE( E_master_debug_cp0_count ),
    .debug_cp0_randomE(E_master_debug_cp0_random),
    .debug_cp0_causeE( E_master_debug_cp0_cause )
);

assign M_master_reg_wdata = M1cs.mem_write_reg  ? M_master_mem_rdata : M_master_alu_res;
assign M_slave_reg_wdata  =  M2cs.mem_write_reg ? M_slave_mem_rdata  : M_slave_alu_res ;

assign M_master_debug_int = M_master_except.id_int;

// ====================================== WriteBack ======================================
mem_wb u_mem_wb(
    //ports
    .clk                ( clk                   ),
    .rst                ( rst                   ),
    .clear1             ( W_flush /*|M_master_except*/      ),
    .clear2             ( W_flush /*(|M_master_except) | (|M_slave_except)*/),
    .ena1               ( W_ena                 ),
    .ena2               ( W_ena                 ),
    // .M_master_ctrl_sign ( M1cs                  ),
    .M_master_except    ( M_master_except       ),
    .M_master_reg_wen   ( M_master_reg_wen      ),
    .M_master_reg_waddr ( M_master_reg_waddr    ),
    .M_master_inst      ( M_master_inst         ),
    .M_master_pc        ( M_master_pc           ),
    .M_master_reg_wdata ( M_master_reg_wdata    ),
    // .M_slave_ctrl_sign  ( M2cs                  ),
    .M_slave_except     ( M_slave_except        ),
    .M_slave_reg_wen    ( M_slave_reg_wen       ),
    .M_slave_reg_waddr  ( M_slave_reg_waddr     ),
    .M_slave_inst       ( M_slave_inst          ),
    .M_slave_pc         ( M_slave_pc            ),
    .M_slave_reg_wdata  ( M_slave_reg_wdata     ),
    // .W_master_ctrl_sign ( W1cs                  ),
    .W_master_except    ( W_master_except       ),
    .W_master_reg_wen   ( W_master_reg_wen      ),
    .W_master_reg_waddr ( W_master_reg_waddr    ),
    .W_master_inst      ( W_master_inst         ),
    .W_master_pc        ( W_master_pc           ),
    .W_master_reg_wdata ( W_master_reg_wdata    ),
    // .W_slave_ctrl_sign  ( W2cs                  ),
    .W_slave_except     ( W_slave_except        ),
    .W_slave_reg_wen    ( W_slave_reg_wen       ),
    .W_slave_reg_waddr  ( W_slave_reg_waddr     ),
    .W_slave_inst       ( W_slave_inst          ),
    .W_slave_pc         ( W_slave_pc            ),
    .W_slave_reg_wdata  ( W_slave_reg_wdata     ),
    .M_master_debug_cp0_count (M_master_debug_cp0_count ),
    .M_master_debug_cp0_random(M_master_debug_cp0_random),
    .M_master_debug_cp0_cause (M_master_debug_cp0_cause ),
    .M_master_debug_int       (M_master_debug_int       ),
    .W_master_debug_cp0_count (W_master_debug_cp0_count ),
    .W_master_debug_cp0_random(W_master_debug_cp0_random),
    .W_master_debug_cp0_cause (W_master_debug_cp0_cause ),
    .W_master_debug_int       (W_master_debug_int       )
);

// debug
assign debug_wb_pc          = (clk) ? (W_master_pc) : ({32{~(|W_master_except)}} & W_slave_pc);
assign debug_wb_rf_wen      = (rst) ? 4'b0000 : ((clk) ? {4{u_regfile.wen1}} : {4{u_regfile.wen2}});
assign debug_wb_rf_wnum     = (clk) ? u_regfile.wa1 : u_regfile.wa2;
assign debug_wb_rf_wdata    = (clk) ? u_regfile.wd1 : u_regfile.wd2;
// ascii
wire [47:0] master_asciiF;
wire [47:0] master_asciiD;
wire [47:0] master_asciiE;
wire [47:0] master_asciiM;
wire [47:0] master_asciiW;
wire [47:0] slave_asciiF ;
wire [47:0] slave_asciiD ;
wire [47:0] slave_asciiE ;
wire [47:0] slave_asciiM ;
wire [47:0] slave_asciiW ;
instdec u_master_asciiF(inst_rdata1,master_asciiF);
instdec u_master_asciiD(D_master_inst,master_asciiD);
instdec u_master_asciiE(E_master_inst,master_asciiE);
instdec u_master_asciiM(M_master_inst,master_asciiM);
instdec u_master_asciiW(W_master_inst,master_asciiW);
instdec u_slave_asciiF (inst_rdata2,slave_asciiF );
instdec u_slave_asciiD (D_slave_inst ,slave_asciiD );
instdec u_slave_asciiE (E_slave_inst ,slave_asciiE );
instdec u_slave_asciiM (M_slave_inst ,slave_asciiM );
instdec u_slave_asciiW (W_slave_inst ,slave_asciiW );


endmodule
