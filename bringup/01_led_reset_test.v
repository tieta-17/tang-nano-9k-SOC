`default_nettype none

// Bring-up test 1: verifies the 27 MHz clock, reset button, and onboard LEDs.
// The LEDs display the upper six bits of a free-running counter. Holding the
// active-low button resets the counter and turns all LEDs off.
module led_reset_test (
    input        i_clk,
    input        i_btn_rst,
    input        i_uart_rx_serial,
    output       o_uart_tx_serial,
    output [5:0] o_led
);
    wire i_rst = ~i_btn_rst;
    reg [25:0] counter = 26'd0;

    always @(posedge i_clk) begin
        if (i_rst)
            counter <= 26'd0;
        else
            counter <= counter + 1'b1;
    end

    // Tang Nano 9K LEDs are active-low.
    assign o_led = ~counter[25:20];

    // Keep the UART output in its normal idle-high state during this test.
    assign o_uart_tx_serial = 1'b1;

    // The RX input is intentionally unused in this test.
    wire _unused = i_uart_rx_serial;
endmodule

`default_nettype wire
