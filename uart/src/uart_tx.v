`default_nettype none
// UART Transmitter for Tang Nano 9k
// 27 MHz Clock --> 115200 baud rate; ~234 CLKS_PER_BIT
module uart_tx
    #(parameter CLKS_PER_BIT = 234)

    (
      input i_Clock,
      input i_Tx_DV, // data valid (answer from driving line high)
      input [7:0] i_Tx_Byte,
      output o_Tx_Active,
      output reg o_Tx_Serial,
      output o_Tx_Done
    );

    parameter s_IDLE            = 3'b000;
    parameter s_TX_START_BIT    = 3'b001;
    parameter s_TX_DATA_BITS    = 3'b010;
    parameter s_TX_STOP_BIT     = 3'b011;
    parameter s_CLEANUP         = 3'b100;

    reg [2:0] r_SM_Main     = 0; // holds current state of UART transmiotter
    reg [7:0] r_Clock_Count = 0; // holds clock cycles within the current bit period
    reg [2:0] r_Bit_Index   = 0; // which one of the 8 data bits is being transmitted
    reg [7:0] r_Tx_Data     = 0; // copy of i_Tx_Byte --> prevents corruption of i_Tx_byte
    reg r_Tx_Done           = 0; // flag --> finished sending byte
    reg r_Tx_Active         = 0; // flag --> high during transmission, low du ring idle

    always @(posedge i_Clock) begin
    case (r_SM_Main)
      s_IDLE: begin
        // TODO: what should the line do while idle?
        o_Tx_Serial <= 1'b1; // drive the line high while idle
        r_Tx_Done   <= 1'b0; // reset; byte transmission ready to begin
        r_Clock_Count <= 0; // reset the clock count
        r_Bit_Index <= 0; // reset the bit index

        // TODO: what should happen when i_Tx_DV pulses?
        if (i_Tx_DV == 1'b1) begin
            r_Tx_Active <= 1'b1; // show line is active
            r_Tx_Data <= i_Tx_Byte; // data to send is i_Tx_Byte;
            r_SM_Main <= s_TX_START_BIT; // set state to (START_BIT)
        end
      end

      s_TX_START_BIT: begin
        // TODO: drive the line low, count one bit period
        o_Tx_Serial <= 1'b0; //drive the line low

        // wait for one bit period before sending data 
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main <= s_TX_START_BIT; // remain in s_TX_START_BIT
        end else begin
            r_Clock_Count <= 0;
            r_SM_Main <= s_TX_DATA_BITS;
        end
      end

      s_TX_DATA_BITS: begin
        // TODO: shift r_Tx_Data out one bit at a time
        o_Tx_Serial <= r_Tx_Data[r_Bit_Index];

        if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main <= s_TX_DATA_BITS;
        end else begin
            r_Clock_Count <= 0;

            // Check if we have sent all bits in a data packet
            if (r_Bit_Index < 7) begin
                r_Bit_Index <= r_Bit_Index + 1;
                r_SM_Main <= s_TX_DATA_BITS;
            end else begin 
                // all data bits sent out; reset r_BIT, and transition to next state
                r_Bit_Index <= 0;
                r_SM_Main <= s_TX_STOP_BIT;
            end
        end
      end

      s_TX_STOP_BIT: begin
        // TODO: drive line high, count one bit period, signal done
        o_Tx_Serial <= 1;
        
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main <= s_TX_STOP_BIT;
        end else begin 
            r_Tx_Done <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main <= s_CLEANUP;
            r_Tx_Active <= 1'b0;
        end
      end

      s_CLEANUP: begin
        // TODO: one-cycle pause back to IDLE
        r_Tx_Done <= 1'b1;
        r_SM_Main <= s_IDLE;
      end

      default: r_SM_Main <= s_IDLE;
    endcase
  end

  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;

endmodule