`timescale 1ns/1ps

module soc_top_tb;

    reg clk = 0;
    reg rst;
    reg rx_serial = 1;   // idle high, nothing incoming for this test

    wire tx_serial;
    wire [5:0] led;

    soc_top UUT (
        .i_clk(clk),
        .i_rst(rst),
        .i_uart_rx_serial(rx_serial),
        .o_uart_tx_serial(tx_serial),
        .o_led(led)
    );

    // Checker uart_rx — decodes whatever soc_top actually transmits,
    // so we can verify the byte, not just eyeball the waveform.
    wire        checked_dv;
    wire [7:0]  checked_byte;
    uart_rx #(.CLKS_PER_BIT(234)) u_checker (
        .i_Clock(clk),
        .i_Rx_Serial(tx_serial),
        .o_Rx_DV(checked_dv),
        .o_Rx_Byte(checked_byte)
    );

    always #18.5 clk = ~clk;  // 27 MHz

    initial begin
        $dumpfile("soc_top_tb.vcd");
        $dumpvars(0, soc_top_tb);

        // idx0: ADDI x1, x0, 21     -> x1 = 21 (0b010101), LED pattern
        UUT.u_cpu.u_instr_mem.instr_mem[0] = {16'd21, 4'h0, 4'h1, 2'b00, 6'b01_0000};

        // idx1: SW x1, 0x400(x0)   -> mem[0x400] = GPIO register <= x1
        UUT.u_cpu.u_instr_mem.instr_mem[1] = {12'h040, 4'h1, 4'h0, 4'h0, 2'b00, 6'b11_0000};

        // idx2: ADDI x2, x0, 72    -> x2 = 72 ('H')
        UUT.u_cpu.u_instr_mem.instr_mem[2] = {16'd72, 4'h0, 4'h2, 2'b00, 6'b01_0000};

        // idx3: SW x2, 0x404(x0)   -> triggers UART TX with x2's low byte
        UUT.u_cpu.u_instr_mem.instr_mem[3] = {12'h040, 4'h2, 4'h0, 4'h4, 2'b00, 6'b11_0000};

        rst = 1;
        @(negedge clk);
        rst = 0;
        @(posedge clk);

        // let the 4 instructions execute
        repeat (5) @(posedge clk);

        $display("gpio = %b (expect 010101)", gpio[5:0]);

        // wait for the checker to fully receive the transmitted byte
        @(posedge checked_dv);
        $display("uart tx byte = %0d / '%c' (expect 72 / 'H')", checked_byte, checked_byte);

        if (led[5:0] == 6'b010101 && checked_byte == 8'd72)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end

endmodule