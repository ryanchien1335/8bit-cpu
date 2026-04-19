module main_cpu (
    input  wire        clk,
    input  wire        reset,
    input              INT,

    // Optional external bus/debug input for now.
    // This is mainly useful while bringing the CPU up in simulation.
    input  wire [7:0]  external_bus_in,
    input  wire       prom_tb_clk,
    input  wire       prom_tb_we,
    input  wire [7:0] prom_tb_addr,
    input  wire [7:0] prom_tb_data,


    // Useful top-level observable outputs for debugging in ModelSim.
    output wire [8:0]  upc_out,
    output wire [63:0] micro_out,

    output wire [7:0]  A_out,
    output wire [7:0]  B_out,
    output wire [7:0]  IR_out,
    output wire [7:0]  OPR_out,
    output wire [7:0]  MAR_out,
    output wire [7:0]  OUT_out,
    output wire [7:0]  TEMP_out,
    output wire [7:0]  DIGIT_out,
    output wire [7:0]  TEMP1_out,
    output wire [7:0]  TEMP2_out,
    output wire [7:0]  TEMP3_out,
    output wire [7:0]  flags_out,
    output wire [7:0]  alu_out,
    output wire [7:0]  pc_out,
    output wire [7:0]  sp_out,
    output wire [7:0]  ram_out,
    output wire [7:0]  bus,
    output wire        alu_zero,
    output wire        alu_carry
);

//
// Microcode decode wires
//
// These are local aliases for fixed bit positions inside the 64-bit
// microinstruction word. The goal here is readability: the ROM stores
// raw bits, while this wrapper gives each control bit a clear name.
//

wire        mc_pc_enable;
wire        mc_pc_out;
wire        mc_alu_out;

// This currently means "IR drives the datapath bus".
// It does NOT mean "operand nibble goes to the bus".
// In this HDL version, the full 8-bit IR register is the actual bus source.
wire        mc_ir_out;

wire        mc_a_out;
wire        mc_ir_load;
wire        mc_a_load;
wire [1:0]  mc_pc_op;
wire        mc_ram_we;

// Preserved as a separate microcode concept from the original design.
// Architecturally, this is the "update/capture RAM read value" idea.
// The current mini_cpu datapath does not yet explicitly model a separate
// RAM output register, but this control name is kept for clarity/future use.
wire        mc_ram_read_load;

wire        mc_out_load;
wire [1:0]  mc_alu_op;
wire        mc_b_load;
wire        mc_alu_load;
wire [8:0]  mc_branch_target;
wire [1:0]  mc_mux_in;
wire [2:0]  mc_branch_op;
wire        mc_temp_load;
wire        mc_temp_out;
wire        mc_digit_load;
wire        mc_digit_out;
wire        mc_temp1_load;
wire        mc_temp1_out;
wire        mc_temp2_load;
wire        mc_temp2_out;
wire        mc_temp3_load;
wire        mc_temp3_out;
wire        mc_kbd_out;
wire        mc_kbd_reset;
wire        mc_a_op;
wire        mc_b_op;
wire        mc_a_clear;
wire [2:0]  mc_a_shift_amt;
wire        mc_sp_load;
wire        mc_sp_out;
wire        mc_sp_inc;
wire [1:0]  mc_sp_s;
wire [1:0]  mc_mux_addr;
wire        mc_mar_load;
wire        mc_opr_load;

// This is the control that currently matters for the HDL datapath bus.
// If asserted, the RAM value is selected as the bus source.
wire        mc_ram_bus_out;

wire        mc_int_enable_load;
wire        mc_int_enable_data;
wire        mc_int_pending_clr;
wire        mc_flags_load;
wire        mc_flags_out;
wire        mc_flags_op;

assign mc_pc_enable       = micro_out[0];
assign mc_pc_out          = micro_out[1];
assign mc_alu_out         = micro_out[2];
assign mc_ir_out          = micro_out[3];
assign mc_a_out           = micro_out[4];
assign mc_ir_load         = micro_out[5];
assign mc_a_load          = micro_out[6];
assign mc_pc_op           = micro_out[8:7];
assign mc_ram_we          = micro_out[9];
assign mc_ram_read_load   = micro_out[10];
assign mc_out_load        = micro_out[11];
assign mc_alu_op          = micro_out[13:12];
assign mc_b_load          = micro_out[14];
assign mc_alu_load        = micro_out[15];
assign mc_branch_target   = micro_out[24:16];
assign mc_mux_in          = micro_out[26:25];
assign mc_branch_op       = micro_out[29:27];
assign mc_temp_load       = micro_out[30];
assign mc_temp_out        = micro_out[31];
assign mc_digit_load      = micro_out[32];
assign mc_digit_out       = micro_out[33];
assign mc_temp1_load      = micro_out[34];
assign mc_temp1_out       = micro_out[35];
assign mc_temp2_load      = micro_out[36];
assign mc_temp2_out       = micro_out[37];
assign mc_temp3_load      = micro_out[38];
assign mc_temp3_out       = micro_out[39];
assign mc_kbd_out         = micro_out[40];
assign mc_kbd_reset       = micro_out[41];
assign mc_a_op            = micro_out[42];
assign mc_b_op            = micro_out[43];
assign mc_a_clear         = micro_out[44];
assign mc_a_shift_amt     = micro_out[47:45];
assign mc_sp_load         = micro_out[48];
assign mc_sp_out          = micro_out[49];
assign mc_sp_inc          = micro_out[50];
assign mc_sp_s            = micro_out[52:51];
assign mc_mux_addr        = micro_out[54:53];
assign mc_mar_load        = micro_out[55];
assign mc_opr_load        = micro_out[56];
assign mc_ram_bus_out     = micro_out[57];
assign mc_int_enable_load = micro_out[58];
assign mc_int_enable_data = micro_out[59];
assign mc_int_pending_clr = micro_out[60];
assign mc_flags_load      = micro_out[61];
assign mc_flags_out       = micro_out[62];
assign mc_flags_op        = micro_out[63];

//
// Local control signals that feed mini_cpu
//

reg [3:0] bus_sel_ctrl;

//
// Decoded condition wires for uPC branch logic
//
// Some branch conditions already have a natural source in the datapath
// (for example the stored zero/carry flags).
// Others are higher-level decode conditions and are derived here.
//

wire ldk_flag;
wire digit_invalid;
wire int_request;
wire out_flag;
wire lda_char_flag;

//
// Interrupt state registers.
// These are 1-bit control-state registers, not normal datapath registers.
//

reg int_enable_reg;
reg int_pending_reg = 1'b0;

//
// Current instruction decode flags.
//
// The IR register should hold the first fetched instruction byte.
// In the current architecture:
//
//   IR_out[7:4] = primary opcode
//   IR_out[3:0] = sub-op / instruction variant selector
//
// The actual 8-bit operand for two-byte instructions belongs in OPR_out,
// not in the low nibble of IR.
//
// These flag decodes are safe as long as fetch discipline is maintained:
// the instruction byte goes to IR, and the second fetched operand byte
// goes to OPR.
//

assign ldk_flag      = (IR_out == 8'h1E);
assign lda_char_flag = (IR_out == 8'h1D);
assign out_flag      = (IR_out == 8'h2F);

//
// Placeholder conditions for logic that is not yet built.
//
// digit_invalid will eventually come from keyboard / ASCII validation logic.
//

assign digit_invalid = 1'b0;

//
// Interrupt request logic.
//
// int_request is high only when interrupts are enabled and a pending
// interrupt has been latched.
//

assign int_request = int_enable_reg & int_pending_reg;

//
// Interrupt state logic
//
// int_pending_reg:
//   - starts at 0
//   - latches to 1 when INT is observed on a clock edge
//   - stays 1 until cleared by microcode
//
// int_enable_reg:
//   - becomes 1 on reset
//   - updates only when microcode explicitly loads a new value
//

always @(posedge clk) begin
    if (mc_int_pending_clr)
        int_pending_reg <= 1'b0;
    else if (INT)
        int_pending_reg <= 1'b1;
end

always @(posedge clk or posedge reset) begin
    if (reset)
        int_enable_reg <= 1'b1;
    else if (mc_int_enable_load)
        int_enable_reg <= mc_int_enable_data;
end

//
// Translate microcode "out" controls into mini_cpu bus_sel encoding.
//
// Current mini_cpu bus mapping:
// 0000 -> external_bus_in
// 0001 -> A_out
// 0010 -> alu_out
// 0011 -> pc_out
// 0100 -> sp_out
// 0101 -> IR_out
// 0110 -> ram_out
// 0111 -> TEMP_out
// 1000 -> DIGIT_out
// 1001 -> TEMP1_out
// 1010 -> TEMP2_out
// 1011 -> TEMP3_out
// 1100 -> flags_out
// 1111 -> zero/default
//
// IMPORTANT DESIGN RULE:
// Only ONE mc_*_out signal should ever be asserted per microinstruction.
// This is a core bus-discipline invariant of the CPU.
//
// This translator prioritizes the first match if multiple mc_*_out signals
// are high, but that should be treated as unintended behavior and a
// microcode bug rather than valid operation.
//

always @(*) begin
    if (mc_a_out)
        bus_sel_ctrl = 4'b0001;
    else if (mc_alu_out)
        bus_sel_ctrl = 4'b0010;
    else if (mc_pc_out)
        bus_sel_ctrl = 4'b0011;
    else if (mc_sp_out)
        bus_sel_ctrl = 4'b0100;
    else if (mc_ir_out)
        bus_sel_ctrl = 4'b0101;
    else if (mc_ram_bus_out)
        bus_sel_ctrl = 4'b0110;
    else if (mc_temp_out)
        bus_sel_ctrl = 4'b0111;
    else if (mc_digit_out)
        bus_sel_ctrl = 4'b1000;
    else if (mc_temp1_out)
        bus_sel_ctrl = 4'b1001;
    else if (mc_temp2_out)
        bus_sel_ctrl = 4'b1010;
    else if (mc_temp3_out)
        bus_sel_ctrl = 4'b1011;
    else if (mc_flags_out)
        bus_sel_ctrl = 4'b1100;
    else
        bus_sel_ctrl = 4'b1111;
end

//
// Program ROM
//

wire [7:0] prom_out;

program_rom program_rom_unit (
    .addr(pc_out),
    .data_out(prom_out),
    .tb_we(prom_tb_we),
    .tb_clk(prom_tb_clk),
    .tb_addr(prom_tb_addr),
    .tb_data(prom_tb_data)
);

//
// Microcode ROM
//

microcode_rom microcode_rom_unit (
    .addr(upc_out),
    .micro_out(micro_out)
);

//
// Microprogram counter / sequencer
//
// Important note:
// Branch decisions should use the STORED architectural flags register,
// not the live combinational ALU outputs.
// That is why zero_flag/carry_flag are taken from flags_out[0]/flags_out[1]
// instead of directly from alu_zero/alu_carry.
//

upc upc_unit (
    .clk(clk),
    .reset(reset),
    .micro_out(micro_out),
    .opcode(IR_out[7:4]),
    .zero_flag(flags_out[0]),
    .carry_flag(flags_out[1]),
    .ldk_flag(ldk_flag),
    .digit_invalid(digit_invalid),
    .int_request(int_request),
    .out_flag(out_flag),
    .lda_char_flag(lda_char_flag),
    .upc_out(upc_out)
);

//
// Datapath
//
// Direct mappings:
// mc_a_load      -> A_load
// mc_b_load      -> B_load
// mc_ir_load     -> IR_load
// mc_opr_load    -> OPR_load
// mc_mar_load    -> MAR_load
// mc_mux_addr    -> MAR_sel
// mc_temp_load   -> TEMP_load
// mc_digit_load  -> DIGIT_load
// mc_temp1_load  -> TEMP1_load
// mc_temp2_load  -> TEMP2_load
// mc_temp3_load  -> TEMP3_load
// mc_flags_load  -> flags_load
// mc_flags_op    -> flags_sel
// mc_out_load    -> OUT_load
// mc_pc_enable   -> pc_load
// mc_sp_load     -> sp_load
// mc_sp_inc      -> sp_inc
// mc_ram_we      -> ram_we
// mc_alu_op      -> alu_op
// mc_pc_op       -> pc_op
// mc_sp_s        -> sp_op
//
// RAM note:
// mc_ram_read_load is intentionally preserved as a separate named control
// concept from the original design. The current mini_cpu does not yet model
// a separate RAM output register stage, so mc_ram_read_load is not connected
// into the datapath yet.
// mc_ram_bus_out is the RAM-related control that currently affects bus
// driving in this HDL version.
//

mini_cpu datapath_unit (
    .clk(clk),

    .A_load(mc_a_load),
    .B_load(mc_b_load),
    .IR_load(mc_ir_load),
    .OPR_load(mc_opr_load),
    .MAR_load(mc_mar_load),
    .MAR_sel(mc_mux_addr),
    .TEMP_load(mc_temp_load),
    .DIGIT_load(mc_digit_load),
    .TEMP1_load(mc_temp1_load),
    .TEMP2_load(mc_temp2_load),
    .TEMP3_load(mc_temp3_load),
    .flags_load(mc_flags_load),
    .flags_sel(mc_flags_op),

    .OUT_load(mc_out_load),
    .pc_load(mc_pc_enable),
    .pc_reset(reset),
    .sp_load(mc_sp_load),
    .sp_reset(reset),
    .sp_inc(mc_sp_inc),
    .ram_we(mc_ram_we),

    .alu_op(mc_alu_op),
    .pc_op(mc_pc_op),
    .sp_op(mc_sp_s),
    .bus_sel(bus_sel_ctrl),

    .external_bus_in(external_bus_in),
    .prom_in(prom_out),

    .A_out(A_out),
    .B_out(B_out),
    .IR_out(IR_out),
    .OPR_out(OPR_out),
    .MAR_out(MAR_out),
    .OUT_out(OUT_out),
    .TEMP_out(TEMP_out),
    .DIGIT_out(DIGIT_out),
    .TEMP1_out(TEMP1_out),
    .TEMP2_out(TEMP2_out),
    .TEMP3_out(TEMP3_out),
    .flags_out(flags_out),
    .alu_out(alu_out),
    .pc_out(pc_out),
    .sp_out(sp_out),
    .ram_out(ram_out),
    .bus(bus),
    .alu_zero(alu_zero),
    .alu_carry(alu_carry)
);

endmodule
