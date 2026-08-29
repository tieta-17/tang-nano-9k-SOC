`timescale 1ns/10ps

module uart_echo_tb;
    // Testbench uses a 27 MHz clock (Tang Nano 9K)
    // 115200 baud UART --> CLKS_PER_BIT = 234
    parameter c_CLOCK_PERIOD_NS = 37;
    parameter c_CLKS_PER_BIT    = 234;
    parameter c_BIT_PERIOD      = 234 * 37; // 8658

    reg  r_Clock = 0;
    reg  r_Rx_Serial = 1; // initial state
    wire w_Tx_Serial;

    wire w_Checked_DV; 
    wire [7:0] w_Checked_Byte;

    reg [7:0] r_Sent_Byte;

    uart_top #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UUT
        (
            .i_Clock(r_Clock),
            .i_Rx_Serial(r_Rx_Serial),
            .o_Tx_Serial(w_Tx_Serial)
        );
    
    uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CHECKER
        (
            .i_Clock(r_Clock),
            .i_Rx_Serial(w_Tx_Serial),
            .o_Rx_DV(w_Checked_DV),
            .o_Rx_Byte(w_Checked_Byte)
        );

    always 
        #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    
    // Takes in input byte and serializes it
    task UART_WRITE_BYTE;
        input [7:0] i_Data;
        integer     ii;
        begin

        // Send Start Bit
        r_Rx_Serial <= 1'b0;
        #(c_BIT_PERIOD);

        // Send Data Byte
        for (ii=0; ii<8; ii=ii+1)
            begin
            r_Rx_Serial <= i_Data[ii];
            #(c_BIT_PERIOD);
            end

        // Send Stop Bit
        r_Rx_Serial <= 1'b1;
        #(c_BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE

    // Waveform dump for GTKWave
    initial begin
        $dumpfile("uart_echo_tb.vcd");
        $dumpvars(0, uart_echo_tb);
    end

    initial
        begin
        // wait for signal to settle
        @(posedge r_Clock);
        
        // save byte state for reference
        r_Sent_Byte <= 8'hFF;

        @(posedge r_Clock);
        UART_WRITE_BYTE(r_Sent_Byte);
        
        @(posedge w_Checked_DV);

        if (w_Checked_Byte == r_Sent_Byte)
            $display("Test Passed - Correct Byte Received");
        else
            $display("Test Failed - Incorrect Byte Received");

      $finish;
    end
endmodule