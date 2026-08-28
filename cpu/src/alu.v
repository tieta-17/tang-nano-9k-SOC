module alu(
    input [3:0] i_alu_op,
    input [31:0] i_a,          // input a
    input [31:0] i_b,          // input b
    output reg [31:0] o_result,    //ouput result
    output zero
); 
    assign zero = (o_result == 32'b0);
    
    always @(*) begin
        case(i_alu_op)
            4'b0000 : o_result <= i_a + i_b;       // ADD
            4'b0001 : o_result <= i_a - i_b;       // SUB
            4'b0010 : o_result <= i_a ^ i_b;       // XOR
            4'b0011 : o_result <= i_a | i_b;       // OR
            4'b0100 : o_result <= i_a & i_b;       // AND
            4'b0101 : o_result <= i_a << i_b;      // SLL
            4'b0110 : o_result <= i_a >> i_b;      // SRL
            4'b0111 : o_result <= i_a >>> i_b;     // SRA
            4'b1000 : o_result <= (31'b0 $signed(i_a) < $signed(i_b));       //SLT
            4'b1001 : o_result <= (31'b0, $unsigned(i_a) < $unsigned(i_b));   // SLTU
        default : o_result <= 32'b0;
        endcase
    end
endmodule;