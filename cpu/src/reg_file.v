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
    reg[511:0] regs_flat;

    // synchronous write
    always @(posedge i_clk) begin
        if (i_we && (i_rd_addr != 4'b0)) 
            regs_flat[i_rd_addr*32 +: 32] <= i_rd_data; 
    end

    // combinational read
    assign o_rs1_data = (i_rs1_addr == 4'b0) ? 32'b0 : regs[i_rs1_addr*32 +: 32];
    assign o_rs2_data = (i_rs2_addr == 4'b0) ? 32'b0 : regs[i_rs2_addr*32 +: 32];
endmodule