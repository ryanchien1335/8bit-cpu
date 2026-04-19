module mini_cpu (
    input wire clk,

    input wire A_load,
    input wire B_load,
    input wire IR_load,
    input wire OPR_load,
    input wire MAR_load,
    input wire [1:0] MAR_sel,
    input wire TEMP_load,
    input wire DIGIT_load,
    input wire TEMP1_load,
    input wire TEMP2_load,
    input wire TEMP3_load,
    input wire flags_load,
    input wire flags_sel,

    input wire OUT_load,
    input wire pc_load,
    input wire pc_reset,
    input wire sp_load,
    input wire sp_reset,
    input wire sp_inc,
    input wire ram_we,

    input wire [1:0] alu_op,
    input wire [1:0] pc_op,
    input wire [1:0] sp_op,
    input wire [3:0] bus_sel,

    input wire [7:0] external_bus_in,
    input wire [7:0] prom_in,

    output wire [7:0] A_out,
    output wire [7:0] B_out,
    output wire [7:0] IR_out,
    output wire [7:0] OPR_out,
    output wire [7:0] MAR_out,
    output wire [7:0] OUT_out,
    output wire [7:0] TEMP_out,
    output wire [7:0] DIGIT_out,
    output wire [7:0] TEMP1_out,
    output wire [7:0] TEMP2_out,
    output wire [7:0] TEMP3_out,
    output wire [7:0] flags_out,
    output wire [7:0] alu_out,
    output wire [7:0] pc_out,
    output wire [7:0] sp_out,
    output wire [7:0] ram_out,
    output wire [7:0] bus,
    output wire alu_zero,
    output wire alu_carry
);

reg [7:0] bus_internal;
reg [7:0] MAR_in;
reg [7:0] flags_in;

wire [7:0] ram_addr;

assign bus = bus_internal;
assign ram_addr = MAR_out;

// Main bus mux
always @(*) begin
    case (bus_sel)
        4'b0000: bus_internal = external_bus_in;
        4'b0001: bus_internal = A_out;
        4'b0010: bus_internal = alu_out;
        4'b0011: bus_internal = pc_out;
        4'b0100: bus_internal = sp_out;
        4'b0101: bus_internal = IR_out;
        4'b0110: bus_internal = ram_out;
	4'b0111: bus_internal = TEMP_out;
        4'b1000: bus_internal = DIGIT_out;
        4'b1001: bus_internal = TEMP1_out;
        4'b1010: bus_internal = TEMP2_out;
        4'b1011: bus_internal = TEMP3_out;
        4'b1100: bus_internal = flags_out;

 // Reserved for future bus drivers
        4'b1101: bus_internal = 8'b00000000;
        4'b1110: bus_internal = 8'b00000000;
        4'b1111: bus_internal = 8'b00000000;

        default: bus_internal = 8'b00000000;
    endcase
end

// MAR input mux (matches Logisim structure: external mux feeding MAR)
always @(*) begin
    case (MAR_sel)
        2'b00: MAR_in = OPR_out;
        2'b01: MAR_in = sp_out;
        2'b10: MAR_in = pc_out;
        default: MAR_in = 8'b00000000;
    endcase
end

always @(*) begin
    case (flags_sel)
        1'b0: flags_in = {6'b000000, alu_carry, alu_zero};
        1'b1: flags_in = bus_internal;
        default: flags_in = 8'b00000000;
    endcase
end

register A_reg (
    .clk(clk),
    .load(A_load),
    .data_in(bus_internal),
    .data_out(A_out)
);

register B_reg (
    .clk(clk),
    .load(B_load),
    .data_in(bus_internal),
    .data_out(B_out)
);

// IR is currently bus-fed as a placeholder.
// In the full CPU, this should be fed from program ROM fetch output.
register IR_reg (
    .clk(clk),
    .load(IR_load),
    .data_in(prom_in),
    .data_out(IR_out)
);

// OPR is currently bus-fed as a placeholder.
// In the full CPU, this should be fed from the operand byte fetched from program ROM.
register OPR_reg (
    .clk(clk),
    .load(OPR_load),
    .data_in(prom_in),
    .data_out(OPR_out)
);

// MAR now matches the real CPU structure:
// External mux (OPR/SP/PC) -> MAR register.
// MAR_out drives the RAM address input.
register MAR_reg (
    .clk(clk),
    .load(MAR_load),
    .data_in(MAR_in),
    .data_out(MAR_out)
);

// OUT is a sink/output register.
// Loads from the bus and does not need to drive the bus back.
register OUT_reg (
    .clk(clk),
    .load(OUT_load),
    .data_in(bus_internal),
    .data_out(OUT_out)
);

alu alu_unit (
    .A(A_out),
    .B(B_out),
    .op(alu_op),
    .result(alu_out),
    .zero(alu_zero),
    .carry(alu_carry)
);

pc pc_unit (
    .clk(clk),
    .reset(pc_reset),
    .load(pc_load),
    .op(pc_op),
    .data_in(bus_internal),
    .data_out(pc_out)
);

sp sp_unit (
    .clk(clk),
    .reset(sp_reset),
    .load(sp_load),
    .inc(sp_inc),
    .op(sp_op),
    .data_in(bus_internal),
    .data_out(sp_out)
);

ram256 ram_unit (
    .clk(clk),
    .we(ram_we),
    .addr(ram_addr),
    .data_in(bus_internal),
    .data_out(ram_out)
);

register TEMP_reg (
    .clk(clk),
    .load(TEMP_load),
    .data_in(bus_internal),
    .data_out(TEMP_out)
);

register DIGIT_reg (
    .clk(clk),
    .load(DIGIT_load),
    .data_in(bus_internal),
    .data_out(DIGIT_out)
);

register TEMP1_reg (
    .clk(clk),
    .load(TEMP1_load),
    .data_in(bus_internal),
    .data_out(TEMP1_out)
);

register TEMP2_reg (
    .clk(clk),
    .load(TEMP2_load),
    .data_in(bus_internal),
    .data_out(TEMP2_out)
);

register TEMP3_reg (
    .clk(clk),
    .load(TEMP3_load),
    .data_in(bus_internal),
    .data_out(TEMP3_out)
);

register flags_reg (
    .clk(clk),
    .load(flags_load),
    .data_in(flags_in),
    .data_out(flags_out)
);

endmodule