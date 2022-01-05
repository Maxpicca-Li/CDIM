`include "defines.vh"
module mem_access (
        input [ 5:0] opM,

        input               mem_en,
        input        [31:0] mem_wdata, // writedata_4B
        input        [31:0] mem_addr,
        output logic [31:0] mem_rdata,

        input        [31:0] data_sram_rdata,
        output logic        data_sram_en,
        output logic [ 3:0] data_sram_wen,
        output logic [31:0] data_sram_addr,
        output logic [31:0] data_sram_wdata,

        output logic ades, adel,
        output logic [31:0] bad_addr
    );

    assign data_sram_en    = mem_en;
    assign data_sram_addr = (mem_addr[31:28] == 4'hB) ? {4'h1, mem_addr[27:0]} :
                             (mem_addr[31:28] == 4'h8) ? {4'h0, mem_addr[27:0]} :
                              mem_addr;
                
    always_comb begin:mem_access_transform
        bad_addr = 32'b0; // 出错的内存地址
        ades = 1'b0; // 写指令地址错例外
        adel = 1'b0; // 读指令地址错例外
        case(opM)
            `OP_LW: begin
                data_sram_wen = 4'b0000;
                if(mem_addr[1:0] != 2'b00) begin
                    adel = 1'b1;
                    bad_addr = mem_addr;
                end
                else begin
                    mem_rdata = data_sram_rdata;
                end
            end
            `OP_LB: begin
                data_sram_wen = 4'b0000;
                case(mem_addr[1:0])
                    2'b11:
                        mem_rdata = {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]};
                    2'b10:
                        mem_rdata = {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]};
                    2'b01:
                        mem_rdata = {{24{data_sram_rdata[15]}},data_sram_rdata[15:8]};
                    2'b00:
                        mem_rdata = {{24{data_sram_rdata[7]}},data_sram_rdata[7:0]};
                endcase
            end
            `OP_LBU: begin
                data_sram_wen = 4'b0000;
                case(mem_addr[1:0])
                    2'b11:
                        mem_rdata = {{24{1'b0}},data_sram_rdata[31:24]};
                    2'b10:
                        mem_rdata = {{24{1'b0}},data_sram_rdata[23:16]};
                    2'b01:
                        mem_rdata = {{24{1'b0}},data_sram_rdata[15:8]};
                    2'b00:
                        mem_rdata = {{24{1'b0}},data_sram_rdata[7:0]};
                endcase
            end
            `OP_LH: begin
                data_sram_wen = 4'b0000;
                if(mem_addr[0] != 1'b0) begin
                    adel = 1'b1;
                    bad_addr = mem_addr;
                end
                else begin
                    case(mem_addr[1])
                        2'b1:
                            mem_rdata = {{24{data_sram_rdata[31]}},data_sram_rdata[31:16]};
                        2'b0:
                            mem_rdata = {{24{data_sram_rdata[15]}},data_sram_rdata[15:0]};
                    endcase
                end
            end
            `OP_LHU: begin
                data_sram_wen = 4'b0000;
                if(mem_addr[0] != 1'b0) begin
                    adel = 1'b1;
                    bad_addr = mem_addr;
                end
                else begin
                    case(mem_addr[1])
                        2'b1:
                            mem_rdata = {{24{1'b0}},data_sram_rdata[31:16]};
                        2'b0:
                            mem_rdata = {{24{1'b0}},data_sram_rdata[15:0]};
                    endcase
                end
            end
            `OP_SW: begin
                if(mem_addr[1:0] != 2'b00) begin
                    ades = 1'b1;
                    bad_addr = mem_addr;
                    data_sram_wen = 4'b0000;
                end
                else begin
                    data_sram_wdata = mem_wdata;
                    data_sram_wen =4'b1111;
                end
            end
            `OP_SH: begin
                if(mem_addr[0] != 1'b0) begin
                    ades = 1'b1;
                    bad_addr = mem_addr;
                    data_sram_wen = 4'b0000;
                end
                else begin
                    data_sram_wdata = {mem_wdata[15:0],mem_wdata[15:0]};
                    case(mem_addr[1:0])
                        2'b10:
                            data_sram_wen = 4'b1100;
                        2'b00:
                            data_sram_wen = 4'b0011;
                        default:
                            ;
                    endcase
                end
            end
            `OP_SB: begin
                data_sram_wdata = {mem_wdata[7:0],mem_wdata[7:0],mem_wdata[7:0],mem_wdata[7:0]};
                case(mem_addr[1:0])
                    2'b11:
                        data_sram_wen = 4'b1000;
                    2'b10:
                        data_sram_wen = 4'b0100;
                    2'b01:
                        data_sram_wen = 4'b0010;
                    2'b00:
                        data_sram_wen = 4'b0001;
                    default:
                        ;
                endcase
            end
            default :
                data_sram_wen = 4'b0000;
        endcase
    end

endmodule

