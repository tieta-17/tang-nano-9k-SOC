module imm_gen_tb();
    reg [31:0] instr;
    reg [1:0] instr_type;
    wire [31:0] imm_out;

    task check;
        input [31:0] expected; 
        input [255:0] label;
        begin
            if (imm_out != expected)
                $display("FAIL [%0s]: Expected %h, got %h", label, expected, imm_out);
            else
                $display("PASS [%0s]: imm_out = %h", label, imm_out);
        end
    endtask

    imm_gen dut(
        .i_instr(instr),
        .i_instr_type(instr_type),
        .o_imm(imm_out)
    );

    initial begin
        // I-type negative
        instr = 32'hFFFF_0000;
        instr_type = 2'b01;
        #1;
        check(32'hFFFF_FFFF, "I-type: imm = -1");

        // I-type positive
        instr = 32'h000F_0000;
        instr_type = 2'b01;
        #1;
        check(32'h0000000F, "I-type: imm = 15");

        // B-type negative
        instr = 32'hFFF0_0F00;
        instr_type = 2'b10;
        #1;
        check(32'hFFFF_FFFE, "B-type: imm = -16");

        // B-type positive
        instr = 32'h0000_0F00;
        instr_type = 2'b10;
        #1;
        check(32'h0000_001E, "B-type: imm = 30");

        // S-type negative
        instr = 32'hFFF0_0F00;
        instr_type = 2'b11;
        #1;
        check(32'hFFFF_FFFF, "S-type: imm = -1");

        // S-type positive
        instr = 32'h0000_0F00;
        instr_type = 2'b11;
        #1;
        check(32'h0000_000F, "S-type: imm = 15");

        $finish;
    end
endmodule
