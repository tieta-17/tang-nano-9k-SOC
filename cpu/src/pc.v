`default_nettype none
module pc(
    input i_clk,
    input i_rst,
    input [31:0] i_pc_next,
    output reg [31:0] o_pc_out
); 
    always @(posedge i_clk) begin
        if (i_rst) 
            o_pc_out <= 32'b0;
        else
            o_pc_out <= i_pc_next;
    end
endmodule