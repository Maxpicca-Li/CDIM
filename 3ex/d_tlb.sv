`include "defines.vh"

// L1 D TLB

module d_tlb #(
    parameter NR_DTLB_ENTRY = 1
) (
    input               clk,
    input               rst,
    input               E_mem_en,
    input  [31:0]       E_mem_va,
    output [31:0]       E_mem_pa,
    output              E_mem_uncached,
    output              E_mem_writeable,
    output logic        E_tlb_refill,
    output logic        E_tlb_invalid,
    // to hazard
    input               E_ready_go,
    output              E_dtlb_stall,
    // to l2 tlb
    output logic [31:13]dtlb_vpn2,
    input               dtlb_found,
    input  tlb_entry    dtlb_entry,
    input               fence_tlb
);


// define dtlb

typedef struct packed {
    logic [31:12] vpn;
    logic [31:12] ppn;
    logic uncached;
    logic dirty;
} l1_dtlb;

l1_dtlb dtlb[NR_DTLB_ENTRY-1:0];
logic [NR_DTLB_ENTRY-1:0] dtlb_valid;

// dtlb match {
logic dtlb_matched;
logic [31:12] dtlb_ppn;
logic dtlb_uncached;
logic dtlb_dirty;

generate 
if (NR_DTLB_ENTRY > 1) begin
    logic [$clog2(NR_DTLB_ENTRY):0] dtlb_index;
    logic [$clog2(NR_DTLB_ENTRY)-1:0] dtlb_i;
    always_comb begin
        dtlb_matched = 0;
        dtlb_ppn = 0;
        dtlb_uncached = 0;
        dtlb_dirty = 0;
        for (dtlb_index=0;dtlb_index<NR_DTLB_ENTRY;dtlb_index++) begin
            dtlb_i = dtlb_index[$clog2(NR_DTLB_ENTRY)-1:0];
            if (dtlb_valid[dtlb_i] && dtlb[dtlb_i].vpn == E_mem_va[31:12]) begin
                dtlb_matched = 1'b1;
                dtlb_ppn = dtlb[dtlb_i].ppn;
                dtlb_uncached = dtlb[dtlb_i].uncached;
                dtlb_dirty = dtlb[dtlb_i].dirty;
            end
        end
    end
end
else begin
    assign dtlb_matched = dtlb[0].vpn == E_mem_va[31:12] & dtlb_valid[0];
    assign dtlb_ppn = dtlb[0].ppn;
    assign dtlb_uncached = dtlb[0].uncached;
    assign dtlb_dirty = dtlb[0].dirty;
end
endgenerate

// dtlb match }

// refill fsm status
enum { IDLE, TLB_REFILL, TLB_EXCEPTION } dtlb_status;

// assign match result
wire direct_mapped = E_mem_va[31:30] == 2'b10; // kseg0 and kseg1
wire [31:12] tag = direct_mapped ? {3'd0,E_mem_va[28:12]} : dtlb_ppn;

wire translation_ok = direct_mapped | dtlb_matched;

assign E_dtlb_stall = (!( (dtlb_status == IDLE && translation_ok) || dtlb_status == TLB_EXCEPTION)) & E_mem_en; 

assign E_mem_pa = {tag,E_mem_va[11:0]};
assign E_mem_uncached = direct_mapped ? E_mem_va[29] : dtlb_uncached;
assign E_mem_writeable = direct_mapped | dtlb_dirty;

generate if (NR_DTLB_ENTRY > 1) begin
    logic [$clog2(NR_DTLB_ENTRY)-1:0] refill_index;
    // refill fsm
    always_ff @(posedge clk) begin
        if (rst) begin
            refill_index <= 0;
            dtlb_valid <= 0;
            dtlb_status <= IDLE;
            E_tlb_refill <= 0;
            E_tlb_invalid <= 0;
        end
        else begin
            if (fence_tlb & E_ready_go) dtlb_valid <= 0;
            case (dtlb_status)
                IDLE: begin
                    if (E_mem_en && !translation_ok) begin
                        dtlb_status <= TLB_REFILL;
                        dtlb_vpn2 <= E_mem_va[31:13];
                    end
                end
                TLB_REFILL: begin
                    if (dtlb_found) begin
                        if ( (E_mem_va[12] & dtlb_entry.V1) | (!E_mem_va[12] & dtlb_entry.V0)) begin
                            dtlb[refill_index].vpn <= E_mem_va[31:12];
                            dtlb[refill_index].ppn <= E_mem_va[12] ? dtlb_entry.PFN1 : dtlb_entry.PFN0;
                            dtlb[refill_index].uncached <= E_mem_va[12] ? !dtlb_entry.C1 : !dtlb_entry.C0;
                            dtlb[refill_index].dirty <= E_mem_va[12] ? dtlb_entry.D1 : dtlb_entry.D0;
                            dtlb_valid[refill_index] <= 1'b1;
                            refill_index <= refill_index + 1;
                            dtlb_status <= IDLE;
                        end
                        else begin
                            dtlb_status <= TLB_EXCEPTION;
                            E_tlb_invalid <= 1'b1;
                        end
                    end
                    else begin
                        dtlb_status <= TLB_EXCEPTION;
                        E_tlb_refill <= 1'b1;
                    end
                end
                TLB_EXCEPTION: begin
                    if (E_ready_go) begin
                        dtlb_status <= IDLE;
                        E_tlb_refill <= 0;
                        E_tlb_invalid <= 0;
                    end
                end
            endcase
        end
    end
end
else begin
    // refill fsm
    always_ff @(posedge clk) begin
        if (rst) begin
            dtlb <= '{default: '0};
            dtlb_valid <= 0;
            dtlb_status <= IDLE;
            E_tlb_refill <= 0;
            E_tlb_invalid <= 0;
        end
        else begin
            if (fence_tlb & E_ready_go) dtlb_valid <= 0;
            case (dtlb_status)
                IDLE: begin
                    if (E_mem_en && !translation_ok) begin
                        dtlb_status <= TLB_REFILL;
                        dtlb_vpn2 <= E_mem_va[31:13];
                    end
                end
                TLB_REFILL: begin
                    if (dtlb_found) begin
                        if ( (E_mem_va[12] & dtlb_entry.V1) | (!E_mem_va[12] & dtlb_entry.V0)) begin
                            dtlb[0].vpn <= E_mem_va[31:12];
                            dtlb[0].ppn <= E_mem_va[12] ? dtlb_entry.PFN1 : dtlb_entry.PFN0;
                            dtlb[0].uncached <= E_mem_va[12] ? !dtlb_entry.C1 : !dtlb_entry.C0;
                            dtlb[0].dirty <= E_mem_va[12] ? dtlb_entry.D1 : dtlb_entry.D0;
                            dtlb_valid[0] <= 1'b1;
                            dtlb_status <= IDLE;
                        end
                        else begin
                            dtlb_status <= TLB_EXCEPTION;
                            E_tlb_invalid <= 1'b1;
                        end
                    end
                    else begin
                        dtlb_status <= TLB_EXCEPTION;
                        E_tlb_refill <= 1'b1;
                    end
                end
                TLB_EXCEPTION: begin
                    if (E_ready_go) begin
                        dtlb_status <= IDLE;
                        E_tlb_refill <= 0;
                        E_tlb_invalid <= 0;
                    end
                end
            endcase
        end
    end
end

endgenerate



endmodule