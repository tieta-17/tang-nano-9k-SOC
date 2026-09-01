`default_nettype none
module cpu(
    input i_clk,
    input i_rst,

    // incoming memory response
    input  [31:0] i_mem_read_data,

    // outgoing memory request
    output [31:0] o_mem_addr,
    output [31:0] o_mem_write_data,
    output        o_mem_read,
    output        o_mem_write
    
);  
    
    wire [31:0] pc_current;
    wire [31:0] branch_target = pc_current + (imm_out << 1); //only shift 1, since B-Type has implicit 0;

    wire branch_condition_met = (instr[7:6] /*funct2*/ == 2'b00) ? zero_flag : ~zero_flag;
    wire branch_taken = branch & branch_condition_met;
    
    wire[31:0] pc_next = stall_read ? pc_current : (branch_taken ? branch_target : pc_current + 4);

    pc u_pc(.i_clk(i_clk), .i_rst(i_rst), .i_pc_next(pc_next), 
            .o_pc_out(pc_current));

    wire [31:0] instr;

    instr_mem u_instr_mem(.i_pc(pc_current), 
                          .o_instr(instr));

    wire reg_write, alu_src, mem_write_internal, mem_read_internal, mem_to_reg, branch; //mem write and read are internal signals fr CPU sent to data memory OUTSIDE

    control_unit u_control_unit(.i_opcode(instr[5:0]), 
                                .o_reg_write(reg_write), .o_alu_src(alu_src), .o_mem_write(mem_write_internal), 
                                .o_mem_read(mem_read_internal), .o_mem_to_reg(mem_to_reg), .o_branch(branch));

    wire [31:0] rs1_out, rs2_out;
    wire [31:0] rd_in  = mem_to_reg ? i_mem_read_data : alu_out;

    // stall ing for load_word from ram
    reg load_stage;
    always @(posedge i_clk) begin
        if (i_rst) 
            load_stage <= 1'b0;
        else
            load_stage <= mem_read_internal & ~load_stage;
    end
    
    wire stall_read = mem_read_internal & ~load_stage;
    wire reg_write_effective = mem_read_internal ? load_stage : reg_write;

    reg_file u_reg_file(.i_clk(i_clk), .i_we(reg_write_effective), .i_rst(i_rst), 
                        .i_rd_addr(instr[11:8]), .i_rd_data(rd_in), .i_rs1_addr(instr[15:12]), .i_rs2_addr(instr[19:16]), 
                        .o_rs1_data(rs1_out), .o_rs2_data(rs2_out));
    
    wire [3:0] alu_op;

    alu_control_unit u_alu_control_unit(.i_opcode(instr[5:0]), .i_funct2(instr[7:6]), 
                                        .o_alu_op(alu_op));

    wire [31:0] imm_out;

    imm_gen u_imm_gen(.i_instr(instr), .i_instr_type(instr[5:4]), 
                      .o_imm(imm_out));

    wire zero_flag;

    wire [31:0] alu_a = rs1_out;
    wire [31:0] alu_b = alu_src ? imm_out : rs2_out;
    wire [31:0] alu_out;

    alu u_alu(.i_alu_op(alu_op), .i_a(alu_a), .i_b(alu_b), 
              .o_result(alu_out), .o_zero(zero_flag));

    assign o_mem_addr = alu_out;
    assign o_mem_write_data = rs2_out;
    assign o_mem_read = mem_read_internal;
    assign o_mem_write = mem_write_internal;

endmodule