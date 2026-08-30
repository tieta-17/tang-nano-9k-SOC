`default_nettype none
module soc_top(
    input  i_clk,
    input  i_btn_rst,
    input  i_uart_rx_serial,
    output o_uart_tx_serial,
    output [31:0] o_gpio,
    output [5:0]  o_led
);
    wire i_rst = ~i_btn_rst;

    wire [31:0] mem_addr, mem_write_data, mem_read_data;
    wire        mem_read, mem_write;

    cpu u_cpu (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_mem_read_data(mem_read_data),
        .o_mem_addr(mem_addr), .o_mem_write_data(mem_write_data),
        .o_mem_read(mem_read), .o_mem_write(mem_write)
    );

    // TODO 1: address decoder — pick your ranges, declare ram_sel/gpio_sel/
    //         uart_tx_sel/uart_rx_sel as wires comparing mem_addr

    parameter RAM_ADDR = 32'h3FF; //256 words
    parameter GPIO_ADDR = 32'h400;
    parameter UART_TX_ADDR = 32'h404;
    parameter UART_RX_ADDR = 32'h408;
    parameter UART_STATUS_ADDR = 32'h40C;

    wire ram_sel    = (mem_addr <  RAM_ADDR + 32'h4);
    wire gpio_sel   = (mem_addr == GPIO_ADDR);
    wire uart_tx_sel= (mem_addr == UART_TX_ADDR);
    wire uart_rx_sel= (mem_addr == UART_RX_ADDR);
    wire status_sel = (mem_addr == UART_STATUS_ADDR); // bit0 = tx busy, bit2 = rx ready

    // TODO 2: instantiate data_mem, gate its i_mem_write with (mem_write & ram_sel)
    // RAM
    wire [31:0] ram_read_data;
    data_mem u_ram (
        .i_clk(i_clk), 
        .i_rst(i_rst),
        .i_mem_write(mem_write & ram_sel), 
        .i_addr(mem_addr), 
        .i_data_in(mem_write_data),
        .o_data_out(ram_read_data)
    );

    // TODO 3: GPIO register — a plain reg, written when (mem_write & gpio_sel)
    reg [31:0] gpio_out;
    always  @(posedge i_clk) begin
        if (i_rst) 
            gpio_out <= 32'b0;
        else if (mem_write & gpio_sel)
            gpio_out <= mem_write_data;
    end
    assign o_gpio = gpio_out;

    // TODO 4: instantiate uart_tx — what should i_Tx_DV be wired to, given
    //         what you already know about single-cycle stores?

    wire tx_dv = mem_write & uart_tx_sel;
    wire tx_active, tx_done;

    uart_tx #(.CLKS_PER_BIT(234)) u_uart_tx (
        .i_Clock(i_clk),
        .i_Tx_DV(tx_dv),
        .i_Tx_Byte(mem_write_data[7:0]),
        .o_Tx_Active(tx_active),
        .o_Tx_Serial(o_uart_tx_serial),
        .o_Tx_Done(tx_done)
    );

    // TODO 5: instantiate uart_rx, plus the holding register + ready flag
    //         (you designed this already, a while back — what clears the
    //         ready flag, and what signal should gate that?)

    wire        rx_dv;
    wire [7:0]  rx_byte;
    reg  [7:0]  rx_byte_latched;
    reg         rx_ready;

    uart_rx #(.CLKS_PER_BIT(234)) u_uart_rx (
        .i_Clock    (i_clk),
        .i_Rx_Serial(i_uart_rx_serial),
        .o_Rx_DV    (rx_dv),
        .o_Rx_Byte  (rx_byte)

    );

    wire [31:0] status_data = {30'b0, rx_ready, tx_active};

    wire rx_consumed = mem_read & uart_rx_sel;
    always @(posedge i_clk) begin
        if (i_rst) begin
            rx_ready <= 1'b0;
            rx_byte_latched <= 8'b0;
        end else if (rx_dv) begin
            rx_byte_latched <= rx_byte;
            rx_ready <= 1'b1;
        end else if (rx_consumed) begin
            rx_ready <= 1'b0;
        end
    end

    // read-data mux — which signal selects ram vs gpio vs uart data
    assign mem_read_data = ram_sel ? ram_read_data :
                            gpio_sel ? gpio_out :
                            uart_rx_sel ? {24'b0, rx_byte_latched} :
                            status_sel ? status_data :
                            32'b0;


    // tang nano output
    
    assign o_led = ~o_gpio[5:0];
    

endmodule