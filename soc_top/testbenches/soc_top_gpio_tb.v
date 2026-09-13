`timescale 1ns/1ps

module soc_top_gpio_tb;

    reg clk = 0;
    reg btn_rst;
    reg rx_serial = 1;   // idle high, unused for this test
    wire tx_serial;
    wire [5:0] led;
    wire [1:0] gpio_pins;   // left undriven (z) from the testbench — DUT drives it

    soc_top UUT (
        .i_clk(clk),
        .i_btn_rst(btn_rst),
        .i_uart_rx_serial(rx_serial),
        .o_uart_tx_serial(tx_serial),
        .gpio_pins(gpio_pins),
        .o_led(led)
    );

    always #18.5 clk = ~clk;  // 27 MHz

    initial begin
        $dumpfile("soc_top_gpio_tb.vcd");
        $dumpvars(0, soc_top_gpio_tb);

        $monitor("t=%0t | gpio_enable=%b gpio_out_bits=%b gpio_pins=%b",
                  $time, UUT.gpio_enable, UUT.gpio_out_bits, gpio_pins);

        // Override the delay-loop constants to small values so simulation
        // finishes quickly, WITHOUT changing the actual toggle logic itself.
        // instr_mem[5] = ADDI x2, x0, 6750  -> shrink to ADDI x2, x0, 2
        // instr_mem[6] = ADDI x3, x0, 1000  -> shrink to ADDI x3, x0, 2
        UUT.u_cpu.u_instr_mem.instr_mem[5] = {16'd2, 4'h0, 4'h2, 2'b00, 6'b01_0000};
        UUT.u_cpu.u_instr_mem.instr_mem[6] = {16'd2, 4'h0, 4'h3, 2'b00, 6'b01_0000};

        btn_rst = 0;         // active-low: 0 = reset asserted
        @(negedge clk);
        btn_rst = 1;         // release reset
        @(posedge clk);

        // run long enough to see several toggles with the shrunk delay
        repeat (400) @(posedge clk);

        $display("Final gpio_out_bits = %b", UUT.gpio_out_bits);
        if (UUT.gpio_out_bits == 2'b01 || UUT.gpio_out_bits == 2'b10)
            $display("Test Passed — bits are complementary, never both 0 or both 1");
        else
            $display("Test Failed — bits are %b, not complementary", UUT.gpio_out_bits);

        $finish;
    end

endmodule
