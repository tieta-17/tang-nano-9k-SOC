module reg_file_tb;
    /*
    input i_clk,
    input i_we,
    input i_rst,
    input [3:0] i_rd_addr,  // write destination
    input [31:0] i_rd_data, // write data
    input [3:0] i_rs1_addr, // port 1
    input [3:0] i_rs2_addr, // port 2
    output [31:0] o_rs1_data,
    output [31:0] o_rs2_data
    */    
    reg clk = 0;
    reg we;
    reg [3:0] rd_addr, rs1_addr, rs2_addr;
    reg [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    always #1 clk = ~clk;
    
    reg_file UUT(clk, we, 1'b0, rd_addr, rd_data, rs1_addr, rs2_addr, rs1_data, rs2_data);

    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, reg_file_tb);
        $monitor("t=%0t we=%b rd_addr=%d rd_data=%d | rs1=%d->%d rs2=%d->%d",
                  $time, we, rd_addr, rd_data, rs1_addr, rs1_data, rs2_addr, rs2_data);
        
        // initialize initial state
        we = 0; rd_addr = 0; rd_data = 0; rs1_addr = 4'd15; rs2_addr = 4'd8;
        @(negedge clk);

        // write to register 15
        we = 1; rd_addr = 4'hF; rd_data = 32'd42;
        @(negedge clk);

        // write to register 8
        rd_addr = 4'h8; rd_data = 32'd67;
        @(negedge clk);

        // write to register 0
        rd_addr = 4'h0; rd_data = 32'd15;
        @(negedge clk);

        we = 0;
        @(negedge clk);

        // attempt to write into register 1, we = 0;
        rd_addr = 4'hF; rd_data = 32'd63;
        @(negedge clk);

        $finish;
    end
endmodule