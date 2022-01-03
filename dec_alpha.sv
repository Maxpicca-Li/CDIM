`timescale 1ns/1ps
`include "defines.vh"

module  dec_alpha(
    input [31:0] instr,

    //per part
    output logic [5:0]          op,
    output logic [4:0]          rs,
    output logic [4:0]          rt,
    output logic [4:0]          rd,
    output logic [4:0]          shamt,
    output logic [5:0]          funct,
    output logic [15:0]         imm,
    output logic [25:0]         j_target,

    // output logic [2:0]          branch_type,    //only used in branch unit,maybe is not that necessary
    output logic                is_branch,
    output logic                is_branch_link,   //mem wb ��Ҫ��
    //why care about hilo?
    output logic                is_hilo_accessed   

);
    
    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shamt = instr[10:6];
    assign funct = instr[5:0];
    assign imm = instr[15:0];
    assign j_target = instr[25:0];

    //judge if the instr is branch/jump

    always_comb begin
    //BEQ,BGTZ,BLEZ,BNE
        if (op[5:2] == 4'b0001) begin
            is_branch = 1'b1;
            // branch_type = `B_EQNE;

        end
        // BLTZ, BGEZ, BLTZL, BGEZL
        else if(op == 6'b000001 && rt[3:1] == 3'b000) begin
            is_branch = 1'b1;
            // branch_type = `B_LTGE;
        // J, JAL
        end
        else if(op[5:1] == 5'b00001) begin
            is_branch = 1'b1;
            // branch_type = `B_JUMP;
        //  JR, JALR
        end
        else if(op == 6'b000000 && funct[5:1] == 5'b00100) begin
            is_branch = 1'b1;
            // branch_type = `B_JREG;
        end
        else begin
            is_branch = 1'b0;
            // branch_type = `B_INVA;
        end
    end

   
endmodule