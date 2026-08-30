`default_nettype none
module imm_gen(
    input [31:0] i_instr,
    input [1:0] i_instr_type,
    output reg [31:0] o_imm
); 
    parameter I_TYPE = 2'b01; 
    parameter B_TYPE = 2'b10;
    parameter S_TYPE = 2'b11;

    always @(*) begin
        case (i_instr_type)
            I_TYPE : o_imm = { {16{i_instr[31]}}, i_instr[31:16] };
            B_TYPE : o_imm = { {15{i_instr[31]}}, i_instr[31:20], i_instr[11:8], 1'b0 };
            S_TYPE : o_imm = { {16{i_instr[31]}}, i_instr[31:20], i_instr[11:8]};
            default : o_imm = 32'b0;
        endcase
    end
endmodule