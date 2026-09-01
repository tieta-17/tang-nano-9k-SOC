module data_mem(
    input i_clk,
    input i_rst,
    input i_mem_write, // write to memory this cycle? 1 = yes (SW0)
    input [31:0] i_addr,
    input [31:0] i_data_in,
    output reg [31:0] o_data_out
);
    reg [31:0] mem [0:255];

    always @(posedge i_clk) begin
        if (i_mem_write)
            mem[i_addr[31:2]] <= i_data_in; //byte addressed, i_addr will be in bytes; << 2
        o_data_out <= mem[i_addr[31:2]];
    end
    
endmodule