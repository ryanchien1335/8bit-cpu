module microcode_rom (
    input  wire [8:0] addr,
    output reg  [63:0] micro_out
);

reg [63:0] rom [0:511];

wire        mc_pc_enable       = micro_out[0];
wire        mc_pc_out          = micro_out[1];
wire        mc_alu_out         = micro_out[2];
wire        mc_ir_operand_out  = micro_out[3];
wire        mc_a_out           = micro_out[4];
wire        mc_ir_load         = micro_out[5];
wire        mc_a_load          = micro_out[6];
wire [1:0]  mc_pc_op           = micro_out[8:7];
wire        mc_ram_we          = micro_out[9];
wire        mc_rm_output_en    = micro_out[10];
wire        mc_out_load        = micro_out[11];
wire [1:0]  mc_alu_op          = micro_out[13:12];
wire        mc_b_load          = micro_out[14];
wire        mc_alu_load        = micro_out[15];
wire [8:0]  mc_branch_target   = micro_out[24:16];
wire [1:0]  mc_mux_in          = micro_out[26:25];
wire [2:0]  mc_branch_op       = micro_out[29:27];
wire        mc_temp_load       = micro_out[30];
wire        mc_temp_out        = micro_out[31];
wire        mc_digit_load      = micro_out[32];
wire        mc_digit_out       = micro_out[33];
wire        mc_temp1_load      = micro_out[34];
wire        mc_temp1_out       = micro_out[35];
wire        mc_temp2_load      = micro_out[36];
wire        mc_temp2_out       = micro_out[37];
wire        mc_temp3_load      = micro_out[38];
wire        mc_temp3_out       = micro_out[39];
wire        mc_kbd_out         = micro_out[40];
wire        mc_kbd_reset       = micro_out[41];
wire        mc_a_op            = micro_out[42];
wire        mc_b_op            = micro_out[43];
wire        mc_a_clear         = micro_out[44];
wire [2:0]  mc_a_shift_amt     = micro_out[47:45];
wire        mc_sp_load         = micro_out[48];
wire        mc_sp_out          = micro_out[49];
wire        mc_sp_inc          = micro_out[50];
wire [1:0]  mc_sp_s            = micro_out[52:51];
wire [1:0]  mc_mux_addr        = micro_out[54:53];
wire        mc_mar_load        = micro_out[55];
wire        mc_opr_load        = micro_out[56];
wire        mc_ram_out         = micro_out[57];
wire        mc_int_enable_load = micro_out[58];
wire        mc_int_enable_data = micro_out[59];
wire        mc_int_pending_clr = micro_out[60];
wire        mc_flags_load      = micro_out[61];
wire        mc_flags_out       = micro_out[62];
wire        mc_flags_op        = micro_out[63];

integer i;

always @(*) begin
    micro_out = rom[addr];
end

initial begin
    for (i = 0; i < 512; i = i + 1)
        rom[i] = 64'b0;

    $readmemh("C:/Users/Ryan Chien/OneDrive/8bit_CPU/8bit-cpu/microcode.mem", rom);
end

endmodule