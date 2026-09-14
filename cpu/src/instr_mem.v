`default_nettype none
module instr_mem #(
    parameter PROGRAM_FILE = "/home/an-tiet/personal-projects/fpga/tang-nano-9k-SOC/assembler/program.hex"
)(
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
        $readmemh(PROGRAM_FILE, instr_mem);
    end
    
    assign o_instr = instr_mem[i_pc[31:2]];

endmodule