`timescale 1ns/1ps

module soc_echo_tb;

    reg clk = 0;
    reg rst;
    reg rx_serial = 1;

    wire tx_serial;
    wire [31:0] gpio;

    soc_top UUT (
        .i_clk(clk),
        .i_btn_rst_n(~rst),   // module expects active-low; invert our active-high testbench signal
        .i_uart_rx_serial(rx_serial),
        .o_uart_tx_serial(tx_serial),
        .o_gpio(gpio)
    );

    // Checker uart_rx — decodes whatever the FPGA echoes back
    wire        checked_dv;
    wire [7:0]  checked_byte;
    uart_rx #(.CLKS_PER_BIT(234)) u_checker (
        .i_Clock(clk),
        .i_Rx_Serial(tx_serial),
        .o_Rx_DV(checked_dv),
        .o_Rx_Byte(checked_byte)
    );

    always #18.5 clk = ~clk;  // 27 MHz

    localparam CLKS_PER_BIT = 234;
    localparam BIT_PERIOD   = CLKS_PER_BIT * 37;

    task UART_WRITE_BYTE;
        input [7:0] i_byte;
        integer k;
        begin
            rx_serial = 1'b0;
            #(BIT_PERIOD);
            for (k = 0; k < 8; k = k + 1) begin
                rx_serial = i_byte[k];
                #(BIT_PERIOD);
            end
            rx_serial = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    initial begin
        $dumpfile("soc_echo_tb.vcd");
        $dumpvars(0, soc_echo_tb);

        // Echo loop:
        //   idx0: LW  x1, 0x40C(x0)      ; x1 = status register
        //   idx1: ANDI x2, x1, 2          ; x2 = rx_ready bit
        //   idx2: BEQ x2, x0, -2           ; not ready -> loop back to idx0
        //   idx3: LW  x3, 0x408(x0)       ; read received byte (clears ready)
        //   idx4: SW  x3, 0x404(x0)       ; echo it back out over UART TX
        //   idx5: BEQ x0, x0, -5           ; unconditional jump back to idx0

        UUT.u_cpu.u_instr_mem.instr_mem[0] = {16'd1036, 4'h0, 4'h1, 2'b00, 6'b01_1111}; // LW x1,0x40C(x0)
        UUT.u_cpu.u_instr_mem.instr_mem[1] = {16'd2,    4'h1, 4'h2, 2'b00, 6'b01_0100}; // ANDI x2,x1,2
        UUT.u_cpu.u_instr_mem.instr_mem[2] = {12'hFFF, 4'h0, 4'h2, 4'hE, 2'b00, 6'b10_0000}; // BEQ x2,x0,-2
        UUT.u_cpu.u_instr_mem.instr_mem[3] = {16'd1032, 4'h0, 4'h3, 2'b00, 6'b01_1111}; // LW x3,0x408(x0)
        UUT.u_cpu.u_instr_mem.instr_mem[4] = {12'h040, 4'h3, 4'h0, 4'h4, 2'b00, 6'b11_0000}; // SW x3,0x404(x0)
        UUT.u_cpu.u_instr_mem.instr_mem[5] = {12'hFFF, 4'h0, 4'h0, 4'hB, 2'b00, 6'b10_0000}; // BEQ x0,x0,-5

        rst = 1;
        @(negedge clk);
        rst = 0;
        @(posedge clk);

        // let a few loop iterations of polling happen first (nothing to receive yet)
        repeat (20) @(posedge clk);

        // now send a byte in, as if typed into a terminal
        UART_WRITE_BYTE(8'h41); // 'A'

        // wait for the echoed byte to come back out
        @(posedge checked_dv);
        $display("echoed byte = %0d / '%c' (expect 65 / 'A')", checked_byte, checked_byte);

        if (checked_byte == 8'h41)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end

endmodule