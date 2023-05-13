`include "defines.vh"

// CP0 and L2 TLB

// import "DPI-C" function void report_tlb_exception();

module cp0(
    input               clk,
    input               rst,
    input               stallM,
    input               stallE,
    input  cop0_info    E_cop0_info,
    input  [31:0]       E_master_pc, // only for debug cop0
    output logic [31:0] E_mfc0_rdata,
    input  [31:0]       E_mtc0_wdata,
    input  [4:0]        ext_int,    // ext_int async
    // except in
    input  except_bus   M_master_except,
    input  except_bus   M_slave_except,
    input  [31:0]       M_master_pc,
    input  [31:0]       M_slave_pc,
    input               M_master_bd, // bd => branch delay slot
    input               M_slave_bd,
    input  [31:0]       M_mem_va,
    // except out
    output logic [31:0] M_cp0_jump_pc,
    output logic        M_cp0_jump,
    output              D_cp0_useable,
    output              D_kernel_mode,
    // int out
    output int_info     D_int_info,
    // I-TLB read port
    input  [31:13]      tlb1_vpn2,
    output logic        tlb1_found,
    output tlb_entry    tlb1_entry,
    // D-TLB read port
    input  [31:13]      tlb2_vpn2,
    output logic        tlb2_found,
    output tlb_entry    tlb2_entry,
    // debug
    output [31:0]       debug_cp0_countE,
    output [31:0]       debug_cp0_randomE,
    output [31:0]       debug_cp0_causeE
);

// ERRATA: eret with ERL=1 and pipeline is stalling will cause jump to epc, but it will not used by this CPU with linux.
wire master_except = |M_master_except || (~(|M_slave_except));

except_bus      except;
logic [31:0]    except_pc;
logic           except_bd;
assign except       = master_except ? M_master_except   : M_slave_except;
assign except_pc    = master_except ? M_master_pc       : M_slave_pc;
assign except_bd    = master_except ? M_master_bd       : M_slave_bd;

logic use_if_badva;
logic [31:0] badva_in;

assign use_if_badva = except.if_adel | except.if_tlbl;
assign badva_in = use_if_badva ? except_pc : M_mem_va;

// CP0 regfile {
cp0_index       index_reg;
logic [31:0]    random_reg;
cp0_entrylo     entrylo0_reg, entrylo1_reg;
cp0_context     context_reg;
// only 4KB supported, pagemask read as zero and ignore on write
logic [31:0]    wired_reg;
logic [31:0]    badva_reg;
cp0_count       count_reg;
cp0_entryhi     entryhi_reg;
logic [31:0]    compare_reg;
cp0_status      status_reg = '{default: '0, BEV: 1'b1};
cp0_cause       cause_reg;
logic [31:0]    epc_reg;
logic [31:0]    prid = 32'h00018003;
logic [31:0]    ebase_reg;
cp0_config0     config0 = '{default: '0, k0: 3'b011, MT: 3'd1, M: 1'b1};
cp0_config1     config1 = '{default: '0, DA: 3'd1, DL: 3'd5, DS: 3'd0, IA: 3'd1, IL: 3'd5, IS: 3'd0, MS: NR_TLB_ENTRY - 1};
logic [31:0]    taglo_reg;
logic [31:0]    taghi_reg;
logic [31:0]    errorepc_reg;
// CP0 regfile }


tlb_entry tlb[NR_TLB_ENTRY-1:0] = '{default: '0};

wire is_kernel_mode = (status_reg.EXL & (!(except.id_eret&status_reg.ERL))) | (status_reg.ERL & (!except.id_eret)) | (~status_reg.UM) | ((|except) & (!except.id_eret));
assign D_cp0_useable = is_kernel_mode | status_reg.CU0;
assign D_kernel_mode = is_kernel_mode;

assign D_int_info.IM = status_reg.IM;
assign D_int_info.IP = cause_reg.IP;
assign D_int_info.int_allowed = status_reg.IE & !status_reg.EXL & !status_reg.ERL;

// TODO: add EBASE if need.
always_comb begin : mfc0_read
    case (E_cop0_info.reg_addr)
        `CP0_REG_INDEX: E_mfc0_rdata = index_reg;
        `CP0_REG_RANDOM: E_mfc0_rdata = random_reg;
        `CP0_REG_ENTRYLO0: E_mfc0_rdata = entrylo0_reg;
        `CP0_REG_ENTRYLO1: E_mfc0_rdata = entrylo1_reg;
        `CP0_REG_CONTEXT: E_mfc0_rdata = context_reg;
        `CP0_REG_PAGEMASK: E_mfc0_rdata = 0;
        `CP0_REG_WIRED: E_mfc0_rdata = wired_reg;
        `CP0_REG_BADVADDR: E_mfc0_rdata = badva_reg;
        `CP0_REG_COUNT: E_mfc0_rdata = count_reg.count;
        `CP0_REG_ENTRYHI: E_mfc0_rdata = entryhi_reg;
        `CP0_REG_COMPARE: E_mfc0_rdata = compare_reg;
        `CP0_REG_STATUS: E_mfc0_rdata = status_reg;
        `CP0_REG_CAUSE: E_mfc0_rdata = cause_reg;
        `CP0_REG_EPC: E_mfc0_rdata = epc_reg;
        `CP0_REG_PRID_EBASE: begin
            case (E_cop0_info.sel_addr)
                0:
                    E_mfc0_rdata = prid;
                1:
                    E_mfc0_rdata = ebase_reg;
                default:
                    E_mfc0_rdata = 0;
            endcase 
        end
        `CP0_REG_CONFIG: begin
            case (E_cop0_info.sel_addr)
                0:
                    E_mfc0_rdata = config0;
                1:
                    E_mfc0_rdata = config1;
                default:
                    E_mfc0_rdata = 0;
            endcase
        end
        `CP0_REG_TAGLO: E_mfc0_rdata = taglo_reg;
        `CP0_REG_TAGHI: E_mfc0_rdata = taghi_reg;
        `CP0_REG_ERREPC: E_mfc0_rdata = errorepc_reg;
        default: E_mfc0_rdata = 0;
    endcase
end

wire [31:0] trap_base = status_reg.BEV ? 32'hbfc00200 : ebase_reg;
wire i_tlb_rf = (except.if_tlbl & except.if_tlbrf);
wire d_tlb_rf = ((~(|{except.if_adel,except.if_tlbl})) & (except.ex_tlbl | except.ex_tlbs) & except.ex_tlbrf);
wire tlb_rf = i_tlb_rf | d_tlb_rf;

always_comb begin // except_target
    // We should sure that there is no exception in IF stage
    M_cp0_jump = 1'b0;
    M_cp0_jump_pc = 32'd0;
    // TODO: add CP0 unuseable signal to decoder. If there is except in IF or CP0 unuseable, all enable signals must be zero.
    if (except.id_eret) begin
        M_cp0_jump_pc = status_reg.ERL ? errorepc_reg : epc_reg;
        M_cp0_jump = 1'b1 && !stallM;
    end
    else if (|except) begin
        M_cp0_jump = 1'b1  && !stallM;
        if (!status_reg.EXL) begin
            M_cp0_jump_pc = trap_base + ( (except.id_int & cause_reg.IV & !status_reg.BEV) ? 32'h200 : ( (tlb_rf & !except.id_int) ? 32'h0 : 32'h180) );
        end
        else M_cp0_jump_pc = trap_base + 32'h180;
    end
end

wire [NR_TLB_ENTRY-1:0] tlb_matched [2:0];
wire [18:0] tlb_find_vpn2 [2:0];
wire [$clog2(NR_TLB_ENTRY)-1:0] tlb_matched_index [2:0];

assign tlb_find_vpn2[0] = entryhi_reg.VPN2;
assign tlb_find_vpn2[1] = tlb1_vpn2;
assign tlb_find_vpn2[2] = tlb2_vpn2;

generate
    for (genvar j=0;j<3;j++) begin
        for (genvar i=0;i<=NR_TLB_ENTRY-1;i++) begin
            assign tlb_matched[j][i] = (tlb[i].G || tlb[i].ASID == entryhi_reg.ASID) && (tlb[i].VPN2 == tlb_find_vpn2[j]);
        end
        assign tlb_matched_index[j] = 
            {3{tlb_matched[j][0 ]}} & 3'd0 |
            {3{tlb_matched[j][1 ]}} & 3'd1 |
            {3{tlb_matched[j][2 ]}} & 3'd2 |
            {3{tlb_matched[j][3 ]}} & 3'd3 |
            {3{tlb_matched[j][4 ]}} & 3'd4 |
            {3{tlb_matched[j][5 ]}} & 3'd5 |
            {3{tlb_matched[j][6 ]}} & 3'd6 | 
            {3{tlb_matched[j][7 ]}} & 3'd7 ;
    end
endgenerate

assign tlb1_found = |tlb_matched[1];
assign tlb2_found = |tlb_matched[2];
assign tlb1_entry = tlb[tlb_matched_index[1]];
assign tlb2_entry = tlb[tlb_matched_index[2]];

cp0_entrylo entrylo0_wdata;
assign entrylo0_wdata = E_mtc0_wdata;
cp0_entrylo entrylo1_wdata;
assign entrylo1_wdata = E_mtc0_wdata;
cp0_context context_wdata;
assign context_wdata = E_mtc0_wdata;
cp0_entryhi entryhi_wdata;
assign entryhi_wdata = E_mtc0_wdata;
cp0_status status_wdata;
assign status_wdata = E_mtc0_wdata;
cp0_cause cause_wdata;
assign cause_wdata = E_mtc0_wdata;

always_ff @(posedge clk) begin // note: mtc0 should be done in exec stage.
    if (rst) begin
        index_reg <= 0;
        random_reg <= NR_TLB_ENTRY - 1;
        entrylo0_reg <= 0;
        entrylo1_reg <= 0;
        context_reg <= 0;
        wired_reg <= 0;
        badva_reg <= 0;
        count_reg <= '{default: '0, count: 1};
        entryhi_reg <= 0;
        compare_reg <= 0;
        status_reg <= '{default: '0, BEV: 1'b1};
        cause_reg <= 0;
        epc_reg <= 0;
        ebase_reg <= 32'h80000000;
        taglo_reg <= 0;
        taghi_reg <= 0;
        errorepc_reg <= 0;
        tlb <= '{default: '0};
    end
    else begin
        count_reg <= count_reg + 1;
        random_reg <= (random_reg == wired_reg) ? (NR_TLB_ENTRY - 1) : (random_reg - 1);
        cause_reg.IP <= {cause_reg.IP[7] | (count_reg.count == compare_reg),ext_int,cause_reg.IP[1:0]};
        if (except.id_eret && !stallM) begin
            if (status_reg.ERL) status_reg.ERL <= 0;
            else status_reg.EXL <= 0;
        end
        else if ( (|except) && !stallM) begin // all except rather than eret
            if (!status_reg.EXL) begin
                epc_reg <= except_bd ? except_pc - 4 : except_pc;
                cause_reg.BD <= except_bd;
            end
            status_reg.EXL <= 1'b1;
            // exccode
            if (except.id_int) cause_reg.exccode <= `EXC_INT;
            else if (except.if_adel | except.ex_adel) begin
                cause_reg.exccode <= `EXC_ADEL;
                // $display("adel at pc %x",except_pc);
            end
            else if (except.ex_ades) begin
                cause_reg.exccode <= `EXC_ADES;
                // $display("ades at pc %x",except_pc);
            end
            else if (except.ex_tlbl | except.if_tlbl) begin
                cause_reg.exccode <= `EXC_TLBL;
                // $display("tlbl at pc %x, badva = %x",except_pc,badva_in);
            end
            else if (except.ex_tlbs) begin
                cause_reg.exccode <= `EXC_TLBS;
                // $display("tlbs at pc %x, badva = %x",except_pc,badva_in);
            end
            else if (except.ex_tlbm) begin
                cause_reg.exccode <= `EXC_MOD;
                // $display("tlbm at pc %x, badva = %x",except_pc,badva_in);
            end
            else if (except.id_syscall) begin
                cause_reg.exccode <= `EXC_SYS;
                // $display("syscall at pc %x",except_pc);
            end
            else if (except.id_break) begin
                cause_reg.exccode <= `EXC_BP;
                // $display("break at pc %x",except_pc);
            end
            else if (except.id_ri) begin
                cause_reg.exccode <= `EXC_RI;
                // $display("ri at pc %x",except_pc);
            end
            else if (except.id_cpu) begin
                cause_reg.exccode <= `EXC_CPU;
                // $display("cpu at pc %x",except_pc);
            end
            else if (except.ex_ov) begin
                cause_reg.exccode <= `EXC_OV;
                // $display("ov at pc %x",except_pc);
            end
            else if (except.ex_trap) begin
                cause_reg.exccode <= `EXC_TR;
                // $display("trap at pc %x",except_pc);
            end
            if ( (except.if_adel | except.if_tlbl | except.ex_adel | except.ex_ades | except.ex_tlbl | except.ex_tlbs | except.ex_tlbm) && (!except.id_int)) begin
                badva_reg <= badva_in;
            end
            if ( (except.if_tlbl | except.ex_tlbl | except.ex_tlbs | except.ex_tlbm) && (!except.id_int)) begin
                context_reg.badvpn2 <= badva_in[31:13];
                entryhi_reg.VPN2 <= badva_in[31:13];
            end
        end
        else if (E_cop0_info.mtc0_en && !stallE) begin // mtc0 {
            case (E_cop0_info.reg_addr)
                `CP0_REG_INDEX: index_reg.index <= E_mtc0_wdata[$clog2(NR_TLB_ENTRY)-1:0];
                `CP0_REG_ENTRYLO0: begin
                    entrylo0_reg.G <= entrylo0_wdata.G;
                    entrylo0_reg.V <= entrylo0_wdata.V;
                    entrylo0_reg.D <= entrylo0_wdata.D;
                    entrylo0_reg.C <= entrylo0_wdata.C;
                    entrylo0_reg.PFN <= entrylo0_wdata.PFN;
                    // $display("write entrylo0 PFN = %x, V = %x",entrylo0_wdata.PFN,entrylo0_wdata.V);
                end
                `CP0_REG_ENTRYLO1: begin
                    entrylo1_reg.G <= entrylo1_wdata.G;
                    entrylo1_reg.V <= entrylo1_wdata.V;
                    entrylo1_reg.D <= entrylo1_wdata.D;
                    entrylo1_reg.C <= entrylo1_wdata.C;
                    entrylo1_reg.PFN <= entrylo1_wdata.PFN;
                    // $display("write entrylo1 PFN = %x, V = %x",entrylo1_wdata.PFN,entrylo1_wdata.V);
                end
                `CP0_REG_CONTEXT: begin
                    context_reg.ptebase <= context_wdata.ptebase;
                end
                `CP0_REG_WIRED: begin
                    wired_reg <= {{(32-$clog2(NR_TLB_ENTRY)){1'b0}},E_mtc0_wdata[$clog2(NR_TLB_ENTRY)-1:0]};
                    random_reg <= NR_TLB_ENTRY-1;
                end
                `CP0_REG_COUNT: count_reg.count <= E_mtc0_wdata;
                `CP0_REG_ENTRYHI: begin
                    entryhi_reg.ASID <= entryhi_wdata.ASID;
                    entryhi_reg.VPN2 <= entryhi_wdata.VPN2;
                end
                `CP0_REG_COMPARE: begin
                    compare_reg <= E_mtc0_wdata;
                    cause_reg.IP[7] <= 0;
                end
                `CP0_REG_STATUS: begin
                    status_reg.CU0 <= status_wdata.CU0;
                    status_reg.IE <= status_wdata.IE;
                    status_reg.EXL <= status_wdata.EXL;
                    status_reg.ERL <= status_wdata.ERL;
                    status_reg.UM <= status_wdata.UM;
                    status_reg.IM <= status_wdata.IM;
                    status_reg.BEV <= status_wdata.BEV;
                end
                `CP0_REG_CAUSE: begin
                    cause_reg.IP[1:0] <= cause_wdata.IP[1:0];
                    cause_reg.IV <= cause_wdata.IV;
                end
                `CP0_REG_EPC: epc_reg <= E_mtc0_wdata;
                `CP0_REG_PRID_EBASE: begin
                    if (E_cop0_info.sel_addr == 1) begin
                        ebase_reg[29:0] <= E_mtc0_wdata[29:0];
                    end
                end
                `CP0_REG_TAGLO: taglo_reg <= E_mtc0_wdata;
                `CP0_REG_TAGHI: taghi_reg <= E_mtc0_wdata;
                `CP0_REG_ERREPC: errorepc_reg <= E_mtc0_wdata;
                default: begin
                    // do nothing
                end
            endcase
        end // mtc0 }
        else if (E_cop0_info.TLBWI && !stallE) begin
            // $display("TLBWI at pc %x, VPN2 = %x, index=%x",E_master_pc,entryhi_reg.VPN2,index_reg.index);
            tlb[index_reg.index] <= '{
                default: '0,
                G: (entrylo0_reg.G & entrylo1_reg.G),
                V0: entrylo0_reg.V,
                V1: entrylo1_reg.V,
                D0: entrylo0_reg.D,
                D1: entrylo1_reg.D,
                C0: entrylo0_reg.C[0],
                C1: entrylo1_reg.C[0],
                PFN0: entrylo0_reg.PFN,
                PFN1: entrylo1_reg.PFN,
                VPN2: entryhi_reg.VPN2,
                ASID: entryhi_reg.ASID
            };
        end
        else if (E_cop0_info.TLBWR && !stallE) begin
            // $display("TLBWR at pc %x, VPN2 = %x, index=%x",E_master_pc,entryhi_reg.VPN2,random_reg[$clog2(NR_TLB_ENTRY)-1:0]);
            tlb[random_reg[$clog2(NR_TLB_ENTRY)-1:0]] <= '{
                default: '0,
                G: (entrylo0_reg.G & entrylo1_reg.G),
                V0: entrylo0_reg.V,
                V1: entrylo1_reg.V,
                D0: entrylo0_reg.D,
                D1: entrylo1_reg.D,
                C0: entrylo0_reg.C[0],
                C1: entrylo1_reg.C[0],
                PFN0: entrylo0_reg.PFN,
                PFN1: entrylo1_reg.PFN,
                VPN2: entryhi_reg.VPN2,
                ASID: entryhi_reg.ASID
            };
        end
        else if (E_cop0_info.TLBP && !stallE) begin
            // $display("TLBP at pc %x, VPN2 = %x, index=%x, ok=%d",E_master_pc,entryhi_reg.VPN2,tlbp_result,tlbp_ok);
            if (|tlb_matched[0]) begin
                index_reg.index <= tlb_matched_index[0];
                index_reg.p <= 1'b0;
            end
            else index_reg.p <= 1'b1;
        end
        else if (E_cop0_info.TLBR && !stallE) begin
            entrylo0_reg.G <= tlb[index_reg.index].G;
            entrylo0_reg.V <= tlb[index_reg.index].V0;
            entrylo0_reg.D <= tlb[index_reg.index].D0;
            entrylo0_reg.C <= {2'd1,tlb[index_reg.index].C0};
            entrylo0_reg.PFN <= tlb[index_reg.index].PFN0;
            entrylo1_reg.G <= tlb[index_reg.index].G;
            entrylo1_reg.V <= tlb[index_reg.index].V1;
            entrylo1_reg.D <= tlb[index_reg.index].D1;
            entrylo1_reg.C <= {2'd1,tlb[index_reg.index].C1};
            entrylo1_reg.PFN <= tlb[index_reg.index].PFN1;
            entryhi_reg.VPN2 <= tlb[index_reg.index].VPN2;
            entryhi_reg.ASID <= tlb[index_reg.index].ASID;
        end
    end
end

// debug
assign debug_cp0_causeE = cause_reg;
assign debug_cp0_randomE = random_reg;
assign debug_cp0_countE = count_reg.count;

endmodule