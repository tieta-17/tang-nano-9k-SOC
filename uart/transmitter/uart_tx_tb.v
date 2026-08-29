`timescale 1ns/1ps

module uart_tx_tb;

    // Testbench signals
    reg        r_Clock = 0;
    reg        r_Tx_DV = 0;
    reg  [7:0] r_Tx_Byte = 0;
    wire       w_Tx_Active;
    wire       w_Tx_Serial;
    wire       w_Tx_Done;

    // Instantiate the UART transmitter
    uart_tx #(.CLKS_PER_BIT(234)) UUT (
        .i_Clock     (r_Clock),
        .i_Tx_DV     (r_Tx_DV),
        .i_Tx_Byte   (r_Tx_Byte),
        .o_Tx_Active (w_Tx_Active),
        .o_Tx_Serial (w_Tx_Serial),
        .o_Tx_Done   (w_Tx_Done)
    );

    // Clock generation — 27 MHz means a period of ~37.037 ns.
    // TODO: toggle r_Clock every half-period to build that clock.
    always begin
        // #(half_period) r_Clock = ~r_Clock;
        #(18.5) r_Clock = ~r_Clock;
    end

    always @(posedge r_Clock) begin
        if (UUT.r_SM_Main == UUT.s_TX_STOP_BIT)
            $display("Time=%0t | STOP_BIT, count=%0d", $time, UUT.r_Clock_Count);
    end

    // Waveform dump so you can view this in GTKWave
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    // Stimulus
    initial begin
        // TODO 1: wait a few clock edges to let things settle
        @(posedge r_Clock);
        @(posedge r_Clock);

        // TODO 2: pick a byte with mixed 1s and 0s, e.g. 8'b10110101,
        //         and load it onto r_Tx_Byte
        r_Tx_Byte <= 8'b10110101;

        // TODO 3: pulse r_Tx_DV high for exactly one clock cycle
        //         (remember: it needs to go back low after — this isn't
        //         a level signal, it's a one-cycle trigger)
        @(posedge r_Clock);
        r_Tx_DV <= 1'b1;
        @(posedge r_Clock);
        r_Tx_DV <=1'b0;

        // TODO 4: wait long enough for a full frame to transmit
        //         (~10 * CLKS_PER_BIT clocks: start + 8 data + stop),
        //         or better — wait until w_Tx_Done goes high
        @(posedge w_Tx_Done);
        #20;
        // TODO 5: end simulation
        $finish;
    end

endmodule