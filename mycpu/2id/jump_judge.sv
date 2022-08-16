module jump_judge (
    input wire        enaD,
    input wire [31:0] instrD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] rs_valueD,
    input wire        reg_write_enE1, reg_write_enM1,
    input wire [4 :0] reg_waddrE1, reg_waddrM1,
    input wire        reg_write_enE2, reg_write_enM2,
    input wire [4 :0] reg_waddrE2, reg_waddrM2,

    output wire        is_jumpD,  // is j inst
    output wire        jump_takeD,
    output wire        jump_conflictD, 
    output wire [31:0] jump_targetD
);
    wire jr, j;
    wire [4:0] rsD;
    assign rsD = instrD[25:21];
    assign jr = ~(|instrD[31:26]) & ~(|(instrD[5:1] ^ 5'b00100)); // jr, jalr
    assign j = ~(|(instrD[31:27] ^ 5'b00001));                    // j, jal
    assign is_jumpD = jr | j;                                        // for getting his delayslot
    assign jump_takeD = enaD & (j | (jr&!jump_conflictD));

    assign jump_conflictD = jr &&                                    // 是否是寄存器依赖类型的jump指令
                            ((reg_write_enE1 && rsD == reg_waddrE1) || (reg_write_enM1 && rsD == reg_waddrM1) || 
                             (reg_write_enE2 && rsD == reg_waddrE2) || (reg_write_enM2 && rsD == reg_waddrM2));   // mem阶段依赖，wb阶段不会产生新数据，不需要考虑
    
    wire [31:0] pc_jump_immD;
    assign pc_jump_immD = {pc_plus4D[31:28], instrD[25:0], 2'b00};//普通jump指令的地址

    assign jump_targetD = j ?  pc_jump_immD : rs_valueD;
endmodule