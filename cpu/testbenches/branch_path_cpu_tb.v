`timescale 1ns/1ps

module branch_path_cpu_tb;

    reg clk = 0;
    reg rst;

    wire [31:0] mem_addr, mem_write_data, mem_read_data;
    wire        mem_read, mem_write;

    cpu UUT (
        .clk           (clk),
        .rst           (rst),
        .mem_read_data (mem_read_data),
        .mem_addr      (mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read      (mem_read),
        .mem_write     (mem_write)
    );

    data_mem u_data_mem (
        .i_clk      (clk),
        .i_rst      (rst),
        .i_mem_write(mem_write),
        .i_addr     (mem_addr),
        .i_data_in  (mem_write_data),
        .o_data_out (mem_read_data)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            UUT.u_reg_file.regs[i] = 32'b0;
    end

    initial begin
        $dumpfile("branch_path_cpu_tb.vcd");
        $dumpvars(0, branch_path_cpu_tb);

        $monitor("t=%0t | pc=%0d instr=%h | rd_in=%0d rs1=%0d rs2=%0d imm=%0d | alu_a=%0d alu_b=%0d alu_op=%b alu_out=%0d zero=%b | mem_addr=%0d mem_write=%b mem_write_data=%0d mem_read_data=%0d | branch=%b branch_taken=%b",
                  $time,
                  UUT.pc_current, UUT.instr,
                  UUT.rd_in, UUT.rs1_out, UUT.rs2_out, UUT.imm_out,
                  UUT.alu_a, UUT.alu_b, UUT.alu_op, UUT.alu_out, UUT.zero_flag,
                  mem_addr, mem_write, mem_write_data, mem_read_data,
                  UUT.branch, UUT.branch_taken);

        // Field layout: opcode[5:0]={type[1:0],op[3:0]}, funct2[7:6], rd[11:8],
        // rs1[15:12], rs2[19:16], top bits [31:20] (R-type funct / B,S-type imm-high)
        //
        // idx0 (addr 0 ): ADDI x1, x0, 5      -> x1 = 5
        // idx1 (addr 4 ): ADDI x2, x0, 5      -> x2 = 5  (equal to x1)
        // idx2 (addr 8 ): BEQ  x1, x2, +2     -> taken (x1==x2), target = 8 + (2<<2) = 16 (idx4)
        // idx3 (addr 12): ADDI x9, x0, 99     -> POISON, must be skipped
        // idx4 (addr 16): ADDI x3, x0, 7      -> x3 = 7  (branch lands here)
        // idx5 (addr 20): SW   x3, 20(x0)     -> mem[20] = 7
        // idx6 (addr 24): LW   x4, 20(x0)     -> x4 = mem[20] = 7
        // idx7 (addr 28): BNE  x1, x3, +2     -> taken (5 != 7), target = 28 + (2<<2) = 36 (idx9)
        // idx8 (addr 32): ADDI x8, x0, 99     -> POISON, must be skipped
        // idx9 (addr 36): ADDI x7, x0, 42     -> x7 = 42 (branch lands here)

        UUT.u_instr_mem.instr_mem[0] = {16'd5,  4'h0, 4'h1, 2'b00, 6'b01_0000}; // ADDI x1,x0,5
        UUT.u_instr_mem.instr_mem[1] = {16'd5,  4'h0, 4'h2, 2'b00, 6'b01_0000}; // ADDI x2,x0,5
        UUT.u_instr_mem.instr_mem[2] = {12'h000, 4'h2, 4'h1, 4'h2, 2'b00, 6'b10_0000}; // BEQ x1,x2,+2
        UUT.u_instr_mem.instr_mem[3] = {16'd99, 4'h0, 4'h9, 2'b00, 6'b01_0000}; // ADDI x9,x0,99 (poison)
        UUT.u_instr_mem.instr_mem[4] = {16'd7,  4'h0, 4'h3, 2'b00, 6'b01_0000}; // ADDI x3,x0,7
        UUT.u_instr_mem.instr_mem[5] = {12'h001, 4'h3, 4'h0, 4'h4, 2'b00, 6'b11_0000}; // SW x3,20(x0)
        UUT.u_instr_mem.instr_mem[6] = {16'd20, 4'h0, 4'h4, 2'b00, 6'b01_1111}; // LW x4,20(x0)
        UUT.u_instr_mem.instr_mem[7] = {12'h000, 4'h3, 4'h1, 4'h2, 2'b01, 6'b10_0000}; // BNE x1,x3,+2
        UUT.u_instr_mem.instr_mem[8] = {16'd99, 4'h0, 4'h8, 2'b00, 6'b01_0000}; // ADDI x8,x0,99 (poison)
        UUT.u_instr_mem.instr_mem[9] = {16'd42, 4'h0, 4'h7, 2'b00, 6'b01_0000}; // ADDI x7,x0,42

        rst = 1;
        @(negedge clk);
        rst = 0;
        @(posedge clk);

        repeat (12) @(posedge clk);

        $display("x1 = %0d (expect 5)",  UUT.u_reg_file.regs[1]);
        $display("x2 = %0d (expect 5)",  UUT.u_reg_file.regs[2]);
        $display("x3 = %0d (expect 7)",  UUT.u_reg_file.regs[3]);
        $display("x4 = %0d (expect 7, from LW)", UUT.u_reg_file.regs[4]);
        $display("x7 = %0d (expect 42)", UUT.u_reg_file.regs[7]);
        $display("x8 = %0d (expect 0, poison must be skipped)", UUT.u_reg_file.regs[8]);
        $display("x9 = %0d (expect 0, poison must be skipped)", UUT.u_reg_file.regs[9]);

        if (UUT.u_reg_file.regs[3] == 32'd7 &&
            UUT.u_reg_file.regs[4] == 32'd7 &&
            UUT.u_reg_file.regs[7] == 32'd42 &&
            UUT.u_reg_file.regs[8] == 32'd0 &&
            UUT.u_reg_file.regs[9] == 32'd0)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end

endmodule