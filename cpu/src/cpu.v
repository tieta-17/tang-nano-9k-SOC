module cpu(
    input clk;
    input rst;
); 
    pc 
    alu_control_unit u_alu_control_unit();
    alu u_alu();
    control_unit u_control_unit();
    data_mem u_data_mem();
    imm_gen u_imm_gen();
    instr_mem u_instr_mem();
endmodule