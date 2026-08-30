`default_nettype none

// UART Reciever for Tang Nano 9k
// 27 MHz Clock --> 115200 baud rate ~ 234 CLKS_PER_BIT

module uart_rx 
    #(parameter CLKS_PER_BIT = 234)
    (
        input        i_Clock,
        input        i_Rx_Serial,
        output       o_Rx_DV,
        output [7:0] o_Rx_Byte
    );
    
    parameter s_IDLE         = 3'b000;
    parameter s_RX_START_BIT = 3'b001;
    parameter s_RX_DATA_BITS = 3'b010;
    parameter s_RX_STOP_BIT  = 3'b011;
    parameter s_CLEANUP      = 3'b100;
   
    reg           r_Rx_Data_R = 1'b1;
    reg           r_Rx_Data   = 1'b1;
    
    reg [7:0]     r_Clock_Count = 0;
    reg [2:0]     r_Bit_Index   = 0; //8 bits total
    reg [7:0]     r_Rx_Byte     = 0;
    reg           r_Rx_DV       = 0;
    reg [2:0]     r_SM_Main     = 0;

    // double register incoming data --> metastability protection   
    always @(posedge i_Clock) begin
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data <= r_Rx_Data_R;
    end

    always @(posedge i_Clock) begin
        case (r_SM_Main)
            s_IDLE : begin 
                r_Rx_DV <= 1'b0;
                r_Clock_Count <= 0;
                r_Bit_Index <= 0;

                if (r_Rx_Data == 1'b0) // start bit detected
                    r_SM_Main <= s_RX_START_BIT;
                else
                    r_SM_Main <= s_IDLE;
            end

            s_RX_START_BIT : begin 
                // wait to sample at the midpoint of the bit period
                // if remains low --> valid start bit; reset counter and begin sampling
                // if is high --> noise/glitch, return to idle
                if (r_Clock_Count == ((CLKS_PER_BIT - 1)/2)) begin
                    if (r_Rx_Data == 1'b0) begin
                        r_Clock_Count <= 0; // reset counter, the middle is valid
                        r_SM_Main <= s_RX_DATA_BITS; 
                    end else begin
                        r_SM_Main <= s_IDLE; // glitch? return to idle state
                    end
                end else begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main <= s_RX_START_BIT;
                end
            end

            s_RX_DATA_BITS : begin
                if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main <= s_RX_DATA_BITS;
                end else begin
                    r_Clock_Count <= 0;
                    r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;

                    // check if we have recieved all 8 bits, if we have, clear bit idx and go to STOP
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main <= s_RX_DATA_BITS;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main <= s_RX_STOP_BIT;
                    end
                end
            end

            s_RX_STOP_BIT : begin
                if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main <= s_RX_STOP_BIT;
                end else begin
                    r_Rx_DV <= 1'b1; // data transmission is possible
                    r_Clock_Count <= 0;
                    r_SM_Main <= s_CLEANUP;
                end
            end

            s_CLEANUP : begin
                // TODO: one-cycle pause back to IDLE
                r_SM_Main <= s_IDLE;
                r_Rx_DV <= 1'b0;
            end

            default : 
            r_SM_Main <= s_IDLE;
        endcase
    end

    assign o_Rx_DV = r_Rx_DV;
    assign o_Rx_Byte = r_Rx_Byte;
endmodule