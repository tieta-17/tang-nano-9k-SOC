`timescale 1ns/1ps

module uart_rx_tb;

    // Testbench uses a 27 MHz clock (Tang Nano 9K)
    // 115200 baud UART --> CLKS_PER_BIT = 234
    parameter c_CLOCK_PERIOD_NS = 37;
    parameter c_CLKS_PER_BIT    = 234;
    parameter c_BIT_PERIOD      = 234 * 37; // 8658

    reg r_Clock = 0;
    reg r_Rx_Serial = 1'b1;
    wire  o_Rx_DV; 
    wire [7:0] o_Rx_Byte;

    uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UUR (
        .i_Clock(r_Clock),
        .i_Rx_Serial(r_Rx_Serial),
        .o_Rx_DV(o_Rx_DV),
        .o_Rx_Byte(o_Rx_Byte)
    );

    task UART_WRITE_BYTE;
        input [7:0] i_byte;
        integer k;
        begin
            
            // send start bit, wait for 1 bit period
            r_Rx_Serial <= 1'b0;
            #(c_BIT_PERIOD);

            // send data bits
            for (k = 0; k < 8; k = k + 1)
                begin
                    r_Rx_Serial <= i_byte[k];
                    #(c_BIT_PERIOD);
                end

            // send stop bit
            r_Rx_Serial <= 1'b1;
            #(c_BIT_PERIOD);    
        end
    endtask

    always begin
        #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    end
    /*
    always @(posedge r_Clock) begin
        $display("Time=%0t | state=%0d, r_Rx_Serial=%b, Rx_Data_R=%b, Rx_Data=%b, r_Rx_Byte=%b, o_Rx_Byte=%b",
        $time, UUR.r_SM_Main, r_Rx_Serial, UUR.r_Rx_Data_R, UUR.r_Rx_Data, UUR.r_Rx_Byte, o_Rx_Byte);
    end
    */

    always @(posedge r_Clock)begin
        $display("Time=%0t | state=%0d, internal_r_Rx_DV=%b, port_o_Rx_DV=%b",
          $time, UUR.r_SM_Main, UUR.r_Rx_DV, o_Rx_DV);
    end
    
    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end

    initial begin

        // wait two clock cycles
        @(posedge r_Clock);
        @(posedge r_Clock);
        
        // race condition
        fork
            UART_WRITE_BYTE(8'hFF);
            $display("Time=%0t | task finished, about to wait for DV", $time);
            @(posedge o_Rx_DV);
        join

        if (o_Rx_Byte == 8'hFF)
            $display("Success");
        else
            $display("Failed");
        $finish;
    end

endmodule