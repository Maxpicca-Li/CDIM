module branch_predict #(
    parameter PHT_DEPTH = 6,
    parameter BHT_DEPTH = 4
) (
    input wire clk, rst,
    input wire [31:0] instrD,

    input wire enaD,
    input wire [31:0] pcD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] pcE,
    input wire branchE,
    input wire actual_takeE,

    output wire branchD,
    output wire pred_takeD,
    output wire [31:0] branch_targetD
);

    assign branchD = ( ~(|(instrD[31:26] ^ 6'b000001)) &  ~(|(instrD[19:17])) ) 
                    | ~(|(instrD[31:28] ^4'b0001)); //4'b0001 -> beq, bgtz, blez, bne    
    assign branch_targetD = pc_plus4D + {{14{instrD[15]}},instrD[15:0], 2'b00};  // branch为有符号扩展

    localparam Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

    assign BHT_index = pcD[1+BHT_DEPTH:2];
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    assign pred_takeD = enaD & branchD & PHT[PHT_index][1];    // 跳转状态最高位都为1

    // BHT初始化以及更新
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcE[1+BHT_DEPTH:2];
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_PHT_index = update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            // for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin // 对于深度超过256的，loop初始化会报错
            //     BHT[j] <= 6'b0;
            // end
            BHT = '{default:'0};
        end
        else if(branchE) begin
            BHT[update_BHT_index] <= {BHT[update_BHT_index][5:1], actual_takeE};
        end
    end

    // PHT初始化以及更新
    always @(posedge clk) begin
        if(rst) begin
            // for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
            //     PHT[i] <= Weakly_taken;
            // end
            PHT = '{default:'0};
        end
        else if(branchE) begin//此处应当判断branchE，即只有当MEM阶段执行的是branch指令时，才修正状态
            case(PHT[update_PHT_index])//不能在case里面引入actual_takeE & branchE判断，这是错误的，会让状态机认为一条指令是没有跳转的，向not_taken转化
                Strongly_not_taken  :   PHT[update_PHT_index] <= actual_takeE ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken    :   PHT[update_PHT_index] <= actual_takeE ? Weakly_taken : Strongly_not_taken;
                Weakly_taken        :   PHT[update_PHT_index] <= actual_takeE ? Strongly_taken : Weakly_not_taken;
                Strongly_taken      :   PHT[update_PHT_index] <= actual_takeE ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end


endmodule