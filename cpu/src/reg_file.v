module reg_file(
    input i_clk,
    input i_we,
    input i_rst,
    input [3:0] i_rd_addr,  // write destination
    input [31:0] i_rd_data, // write data
    input [3:0] i_rs1_addr, // port 1
    input [3:0] i_rs2_addr, // port 2
    output [31:0] o_rs1_data,
    output [31:0] o_rs2_data
);
    reg [31:0] regs[15:0]; // 16 - 32 bit general purpose registers
    // synchronous write
    always @(posedge i_clk) begin
        if (i_we && (i_rd_addr != 4'b0)) 
            regs[i_rd_addr] <= i_rd_data; 
    end

    // combinational read
    assign o_rs1_data = (i_rs1_addr == 4'b0) ? 32'b0 : regs[i_rs1_addr];
    assign o_rs2_data = (i_rs2_addr == 4'b0) ? 32'b0 : regs[i_rs2_addr];
endmodule