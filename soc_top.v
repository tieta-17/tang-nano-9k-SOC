module soc_top(
    input  i_clk,
    input  i_rst,
    input  i_uart_rx_serial,
    output o_uart_tx_serial,
    output [31:0] o_gpio
);

    wire [31:0] mem_addr, mem_write_data, mem_read_data;
    wire        mem_read, mem_write;

    cpu u_cpu (
        .clk(i_clk), .rst(i_rst),
        .mem_read_data(mem_read_data),
        .mem_addr(mem_addr), .mem_write_data(mem_write_data),
        .mem_read(mem_read), .mem_write(mem_write)
    );

    // TODO 1: address decoder — pick your ranges, declare ram_sel/gpio_sel/
    //         uart_tx_sel/uart_rx_sel as wires comparing mem_addr

    // TODO 2: instantiate data_mem, gate its i_mem_write with (mem_write & ram_sel)

    // TODO 3: GPIO register — a plain reg, written when (mem_write & gpio_sel)

    // TODO 4: instantiate uart_tx — what should i_Tx_DV be wired to, given
    //         what you already know about single-cycle stores?

    // TODO 5: instantiate uart_rx, plus the holding register + ready flag
    //         (you designed this already, a while back — what clears the
    //         ready flag, and what signal should gate that?)

    // TODO 6: the read-data mux — which signal selects ram vs gpio vs
    //         uart data, and what feeds mem_read_data?

endmodule