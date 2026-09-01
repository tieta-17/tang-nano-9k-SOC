`default_nettype none
module alu(
    input [3:0] i_alu_op,
    input [31:0] i_a,          // input a
    input [31:0] i_b,          // input b
    output reg [31:0] o_result,    //ouput result
    output o_zero
); 
    assign o_zero = (o_result == 32'b0);
    wire [4:0] shift_amt = i_b[0:4]; // only first 5 bits are meaningful for 32 bit integer (0-31 bit shift)
    always @(*) begin
        case(i_alu_op)
            4'b0000 : o_result = i_a + i_b;       // ADD
            4'b0001 : o_result = i_a - i_b;       // SUB
            4'b0010 : o_result = i_a ^ i_b;       // XOR
            4'b0011 : o_result = i_a | i_b;       // OR
            4'b0100 : o_result = i_a & i_b;       // AND
            4'b0101 : o_result = i_a << shift_amt;      // SLL
            4'b0110 : o_result = i_a >> shift_amt;      // SRL
            4'b0111 : o_result = i_a >>> shift_amt;     // SRA
            4'b1000 : o_result = {31'b0, ($signed(i_a) < $signed(i_b))};   // SLT
            4'b1001 : o_result = {31'b0, (i_a < i_b)};                      // SLTU
        default : o_result = 32'b0;
        endcase
    end
endmodule