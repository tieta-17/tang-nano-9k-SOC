module control_unit (
    input [5:0] i_opcode,
    output reg o_reg_write,   // write result into rd? 1 for R-type, I-type, Loads, 0 for S-Type, B-Type
    output reg o_alu_src,     // 1 for I-Type, S-Type (any immediates), 0 for R-Type, B-Type
    output reg o_mem_write,   // write to data memory? 1 for S-Type ONLY opcode[5:4] = 2'b11
    output reg o_mem_read,    // read from data memory? 1 for Loads ONLY (opcode[3:0] = 4'b1111)
    output reg o_mem_to_reg,  // write to rd from memory or from registers? 1 = memory (LW), 0 = everything else
    output reg o_branch       // is this a conditional branch? 1 for B-Type only
); 
    parameter R_TYPE = 2'b00;
    parameter I_TYPE = 2'b01; 
    parameter B_TYPE = 2'b10;
    parameter S_TYPE = 2'b11;

    always @(*) begin
        case (i_opcode[5:4])
            R_TYPE : begin
                o_reg_write = 1'b1; o_alu_src = 1'b0;
                o_mem_write = 1'b0; o_mem_read = 1'b0;
                o_mem_to_reg = 1'b0; o_branch = 1'b0;
            end

            I_TYPE : begin
                o_reg_write = 1'b1; o_alu_src = 1'b1; o_mem_write = 1'b0; o_branch = 1'b0;  
                if (i_opcode[3:0] == 4'b1111) begin // LW instruction
                    o_mem_to_reg = 1'b1; o_mem_read = 1'b1;
                end else begin 
                    o_mem_to_reg = 1'b0; o_mem_read = 1'b0;
                end
            end

            B_TYPE : begin
                o_reg_write = 1'b0; o_alu_src = 1'b0;
                o_mem_write = 1'b0; o_mem_read = 1'b0;
                o_mem_to_reg = 1'b0; o_branch = 1'b1;
            end

            S_TYPE : begin
                o_reg_write = 1'b0; o_alu_src = 1'b1;
                o_mem_write = 1'b1; o_mem_read = 1'b0;
                o_mem_to_reg = 1'b0; o_branch = 1'b0;
            end

            default : begin
                o_reg_write = 1'b0; o_alu_src = 1'b0;
                o_mem_write = 1'b0; o_mem_read = 1'b0;
                o_mem_to_reg = 1'b0; o_branch = 1'b0;
            end
        endcase     
    end
endmodule 