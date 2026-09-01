`default_nettype none

// Bring-up test 3: hardware-only UART echo, with no CPU or memory map.
// Every received byte is latched and sent back when the transmitter is idle.
// LED 0 indicates TX activity; LED 1 indicates a byte waiting to be sent.
module uart_echo_test (
    input        i_clk,
    input        i_btn_rst,
    input        i_uart_rx_serial,
    output       o_uart_tx_serial,
    output [5:0] o_led
);
    wire i_rst = ~i_btn_rst;

    wire       rx_dv;
    wire [7:0] rx_byte;
    reg  [7:0] tx_byte = 8'd0;
    reg        pending = 1'b0;
    reg        tx_dv = 1'b0;
    wire       tx_active;
    wire       tx_done;

    uart_rx #(.CLKS_PER_BIT(234)) u_uart_rx (
        .i_Clock      (i_clk),
        .i_Rx_Serial  (i_uart_rx_serial),
        .o_Rx_DV      (rx_dv),
        .o_Rx_Byte    (rx_byte)
    );

    always @(posedge i_clk) begin
        tx_dv <= 1'b0;

        if (i_rst) begin
            tx_byte <= 8'd0;
            pending <= 1'b0;
        end else if (rx_dv) begin
            tx_byte <= rx_byte;
            pending <= 1'b1;
        end else if (pending && !tx_active) begin
            tx_dv <= 1'b1;
            pending <= 1'b0;
        end
    end

    uart_tx #(.CLKS_PER_BIT(234)) u_uart_tx (
        .i_Clock      (i_clk),
        .i_Tx_DV      (tx_dv),
        .i_Tx_Byte    (tx_byte),
        .o_Tx_Active  (tx_active),
        .o_Tx_Serial  (o_uart_tx_serial),
        .o_Tx_Done    (tx_done)
    );

    assign o_led = {4'b1111, ~pending, ~tx_active};

    wire _unused = tx_done;
endmodule

`default_nettype wire
