`timescale 1ns/1ps

module alu_path_cpu_tb;

    reg clk = 0;
    reg rst;

    wire [31:0] mem_addr, mem_write_data;
    wire        mem_read, mem_write;
    reg  [31:0] mem_read_data = 32'b0; // no real data_mem for this ALU-only test

    cpu UUT (
        .clk           (clk),
        .rst           (rst),
        .mem_read_data (mem_read_data),
        .mem_addr      (mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read      (mem_read),
        .mem_write     (mem_write)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("alu_path_cpu_tb.vcd");
        $dumpvars(0, alu_path_cpu_tb);
        $monitor("t=%0t | pc=%0d instr=%h | rd_in=%0d rs1=%0d rs2=%0d imm=%0d | alu_a=%0d alu_b=%0d alu_op=%b alu_out=%0d zero=%b | reg_write=%b mem_to_reg=%b branch=%b branch_taken=%b",
                  $time,
                  UUT.pc_current, UUT.instr,
                  UUT.rd_in, UUT.rs1_out, UUT.rs2_out, UUT.imm_out,
                  UUT.alu_a, UUT.alu_b, UUT.alu_op, UUT.alu_out, UUT.zero_flag,
                  UUT.reg_write, UUT.mem_to_reg, UUT.branch, UUT.branch_taken);
        
        // Preload a tiny test program directly into instruction memory.
        // Field layout: {imm/top16[31:16], rs1[15:12], rd[11:8], funct2[7:6], opcode[5:0]}
        // opcode[5:0] = {type[1:0], alu_op[3:0]}

        // ADDI x1, x0, 5      -> I_TYPE(01), ADD(0000), rd=1, rs1=0, imm=5
        UUT.u_instr_mem.instr_mem[0] = {16'd5,  4'h0, 4'h1, 2'b00, 6'b01_0000};

        // ADDI x2, x0, 10     -> I_TYPE(01), ADD(0000), rd=2, rs1=0, imm=10
        UUT.u_instr_mem.instr_mem[1] = {16'd10, 4'h0, 4'h2, 2'b00, 6'b01_0000};

        // ADD x3, x1, x2      -> R_TYPE(00), ADD(0000), rd=3, rs1=1, rs2=2
        UUT.u_instr_mem.instr_mem[2] = {12'b0, 4'h2, 4'h1, 4'h3, 2'b00, 6'b00_0000};

        rst = 1;
        @(negedge clk);
        rst = 0;

        // let the three instructions execute
        repeat (6) @(posedge clk);

        $display("x1 = %0d (expect 5)",  UUT.u_reg_file.regs[1]);
        $display("x2 = %0d (expect 10)", UUT.u_reg_file.regs[2]);
        $display("x3 = %0d (expect 15)", UUT.u_reg_file.regs[3]);

        if (UUT.u_reg_file.regs[3] == 32'd15)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end

endmodule

/*
`timescale 1ns/1ps

module cpu_tb;

    reg clk = 0;
    reg rst;

    wire [31:0] mem_addr, mem_write_data;
    wire        mem_read, mem_write;
    reg  [31:0] mem_read_data = 32'b0; // no real data_mem for this ALU-only test

    cpu UUT (
        .clk           (clk),
        .rst           (rst),
        .mem_read_data (mem_read_data),
        .mem_addr      (mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read      (mem_read),
        .mem_write     (mem_write)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        $monitor("t=%0t | pc=%0d instr=%h | rd_in=%0d rs1=%0d rs2=%0d imm=%0d | alu_a=%0d alu_b=%0d alu_op=%b alu_out=%0d zero=%b | reg_write=%b mem_to_reg=%b branch=%b branch_taken=%b",
                  $time,
                  UUT.pc_current, UUT.instr,
                  UUT.rd_in, UUT.rs1_out, UUT.rs2_out, UUT.imm_out,
                  UUT.alu_a, UUT.alu_b, UUT.alu_op, UUT.alu_out, UUT.zero_flag,
                  UUT.reg_write, UUT.mem_to_reg, UUT.branch, UUT.branch_taken);

        // Preload a tiny test program directly into instruction memory.
        // Field layout: {imm/top16[31:16], rs1[15:12], rd[11:8], funct2[7:6], opcode[5:0]}
        // opcode[5:0] = {type[1:0], alu_op[3:0]}

        // ADDI x1, x0, 5      -> I_TYPE(01), ADD(0000), rd=1, rs1=0, imm=5
        UUT.u_instr_mem.instr_mem[0] = {16'd5,  4'h0, 4'h1, 2'b00, 6'b01_0000};

        // ADDI x2, x0, 10     -> I_TYPE(01), ADD(0000), rd=2, rs1=0, imm=10
        UUT.u_instr_mem.instr_mem[1] = {16'd10, 4'h0, 4'h2, 2'b00, 6'b01_0000};

        // ADD x3, x1, x2      -> R_TYPE(00), ADD(0000), rd=3, rs1=1, rs2=2
        UUT.u_instr_mem.instr_mem[2] = {12'b0, 4'h2, 4'h1, 4'h3, 2'b00, 6'b00_0000};

        // Drive rst on negedge, not immediately after posedge, to avoid
        // racing pc.v's own posedge-triggered reset logic at the same instant.
        rst = 1;
        @(negedge clk);
        rst = 0;
        @(posedge clk);

        // let the three instructions execute
        repeat (6) @(posedge clk);

        $display("x1 = %0d (expect 5)",  UUT.u_reg_file.regs[1]);
        $display("x2 = %0d (expect 10)", UUT.u_reg_file.regs[2]);
        $display("x3 = %0d (expect 15)", UUT.u_reg_file.regs[3]);

        if (UUT.u_reg_file.regs[3] == 32'd15)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end

endmodule
*/