`default_nettype none

// Bring-up test 2: repeatedly transmits ASCII 'U' at 115200 8N1.
// Open the board's USB serial port at 115200 baud; a 'U' should appear every
// 500 ms. LED 0 illuminates while a UART frame is being transmitted.
module uart_tx_test (
    input        i_clk,
    input        i_btn_rst,
    input        i_uart_rx_serial,
    output       o_uart_tx_serial,
    output [5:0] o_led
);
    localparam integer SEND_INTERVAL = 13_500_000; // 0.5 s at 27 MHz

    wire i_rst = ~i_btn_rst;
    reg [23:0] interval_counter = 24'd0;
    reg        tx_dv = 1'b0;
    wire       tx_active;
    wire       tx_done;

    always @(posedge i_clk) begin
        tx_dv <= 1'b0;

        if (i_rst) begin
            interval_counter <= 24'd0;
        end else if (interval_counter == SEND_INTERVAL - 1) begin
            interval_counter <= 24'd0;
            if (!tx_active)
                tx_dv <= 1'b1;
        end else begin
            interval_counter <= interval_counter + 1'b1;
        end
    end

    uart_tx #(.CLKS_PER_BIT(234)) u_uart_tx (
        .i_Clock      (i_clk),
        .i_Tx_DV      (tx_dv),
        .i_Tx_Byte    (8'h55), // ASCII 'U' produces an alternating-bit pattern
        .o_Tx_Active  (tx_active),
        .o_Tx_Serial  (o_uart_tx_serial),
        .o_Tx_Done    (tx_done)
    );

    // Active-low LEDs: LED 0 is on while TX is active.
    assign o_led = {5'b11111, ~tx_active};

    wire _unused = i_uart_rx_serial ^ tx_done;
endmodule

`default_nettype wire
