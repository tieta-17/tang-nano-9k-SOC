module instr_mem(
    input [31:0] i_pc,
    output [31:0]  o_instr
); 
    reg  [31:0] instr_mem [0:255];

    // byte indexed --> pc increments by 4 (since instr = 32 bits)
    // pc: 0x0 0x4 0x8 0xC 0x10
    // slicing from 31:2 is equal to >> 2; (divide by 4)
    // 0x0 >> 2 = 0, 0x4 >> 2 = 1, 0x8 >> 2 = 2, ..
    // aligned w/mem[0], mem[1], mem[2], mem[...]

    initial begin
        instr_mem[0] = {16'd1036, 4'h0, 4'h1, 2'b00, 6'b01_1111}; // LW x1,0x40C(x0)
        instr_mem[1] = {16'd2,    4'h1, 4'h2, 2'b00, 6'b01_0100}; // ANDI x2,x1,2
        instr_mem[2] = {12'hFFF, 4'h0, 4'h2, 4'hE, 2'b00, 6'b10_0000}; // BEQ x2,x0,-2
        instr_mem[3] = {16'd1032, 4'h0, 4'h3, 2'b00, 6'b01_1111}; // LW x3,0x408(x0)
        instr_mem[4] = {12'h040, 4'h3, 4'h0, 4'h4, 2'b00, 6'b11_0000}; // SW x3,0x404(x0)
        instr_mem[5] = {12'hFFF, 4'h0, 4'h0, 4'hB, 2'b00, 6'b10_0000}; // BEQ x0,x0,-5
    end
    
    assign o_instr = instr_mem[i_pc[31:2]];

endmodule