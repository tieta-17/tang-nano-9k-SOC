`default_nettype none
module alu_control_unit(
    input [5:0] i_opcode,
    input [1:0] i_funct2, // unused currently
    output reg [3:0] o_alu_op
);
    parameter R_TYPE = 2'b00;
    parameter I_TYPE = 2'b01; 
    parameter B_TYPE = 2'b10;
    parameter S_TYPE = 2'b11;
    parameter ADD_OP = 4'b0000;
    parameter SUB_OP = 4'b0001;     

    always @(*) begin
        case (i_opcode[5:4])                        // instruction type
            R_TYPE  :  o_alu_op = i_opcode[3:0]; // opcode already IS the ALU op
            I_TYPE  :  begin
                if (i_opcode[3:0] == 4'b1111)
                    o_alu_op = ADD_OP;  // LW: address = rs1 + imm
                else
                    o_alu_op = i_opcode[3:0];  // ordinary ALU-immediate op
                end
            S_TYPE  :  o_alu_op = ADD_OP;     // address calc, opcode bits aren't an ALU op here
            B_TYPE  :  o_alu_op = SUB_OP;     // if using ALU for comparison
            default :  o_alu_op = ADD_OP;
        endcase
    end 
endmodule