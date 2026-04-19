`timescale 1ns/1ps

module main_cpu_tb;

reg        clk;
reg        reset;
reg        INT;
reg [7:0]  external_bus_in;

wire [8:0]  upc_out;
wire [63:0] micro_out;

wire [7:0] A_out;
wire [7:0] B_out;
wire [7:0] IR_out;
wire [7:0] OPR_out;
wire [7:0] MAR_out;
wire [7:0] OUT_out;
wire [7:0] TEMP_out;
wire [7:0] DIGIT_out;
wire [7:0] TEMP1_out;
wire [7:0] TEMP2_out;
wire [7:0] TEMP3_out;
wire [7:0] flags_out;
wire [7:0] alu_out;
wire [7:0] pc_out;
wire [7:0] sp_out;
wire [7:0] ram_out;
wire [7:0] bus;
wire       alu_zero;
wire       alu_carry;

integer i;
reg [63:0] mi;
reg       prom_tb_we;
reg prom_tb_clk;
reg [7:0] prom_tb_addr;
reg [7:0] prom_tb_data;

main_cpu uut (
    .clk(clk),
    .reset(reset),
    .INT(INT),
    .external_bus_in(external_bus_in),

    .prom_tb_clk(prom_tb_clk),
    .prom_tb_we(prom_tb_we),
    .prom_tb_addr(prom_tb_addr),
    .prom_tb_data(prom_tb_data),

    .upc_out(upc_out),
    .micro_out(micro_out),

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

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task expect1;
    input actual;
    input expected;
    input [255:0] msg;
begin
    if (actual !== expected) begin
        $display("FAIL: %s | expected=%b actual=%b time=%0t", msg, expected, actual, $time);
        $stop;
    end else begin
        $display("PASS: %s | value=%b time=%0t", msg, actual, $time);
    end
end
endtask

task expect8;
    input [7:0] actual;
    input [7:0] expected;
    input [255:0] msg;
begin
    if (actual !== expected) begin
        $display("FAIL: %s | expected=%h actual=%h time=%0t", msg, expected, actual, $time);
        $stop;
    end else begin
        $display("PASS: %s | value=%h time=%0t", msg, actual, $time);
    end
end
endtask

task expect9;
    input [8:0] actual;
    input [8:0] expected;
    input [255:0] msg;
begin
    if (actual !== expected) begin
        $display("FAIL: %s | expected=%h actual=%h time=%0t", msg, expected, actual, $time);
        $stop;
    end else begin
        $display("PASS: %s | value=%h time=%0t", msg, actual, $time);
    end
end
endtask

task prom_write;
    input [7:0] addr;
    input [7:0] data;
begin
    prom_tb_addr = addr;
    prom_tb_data = data;
    prom_tb_we   = 1'b1;
    #1;
    prom_tb_clk  = 1'b1;
    #1;
    prom_tb_clk  = 1'b0;
    prom_tb_we   = 1'b0;
end
endtask

initial begin
    INT = 1'b0;
    external_bus_in = 8'h00;
    reset = 1'b1;
    mi = 64'd0;
    prom_tb_clk  = 1'b0;
    prom_tb_we   = 1'b0;
    prom_tb_addr = 8'h00;
    prom_tb_data = 8'h00;

    // Initialize ROM so uPC keeps returning to 0
    for (i = 0; i < 512; i = i + 1) begin
        uut.microcode_rom_unit.rom[i] = 64'd0;
        uut.microcode_rom_unit.rom[i][26:25] = 2'b10;
    end

    // Initialize program ROM to 00
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    #12;
    reset = 1'b0;

    // TEST 1: A <- external bus
    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h05;

    mi = 64'd0;
    mi[6] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(A_out, 8'h05, "A loads from external bus");

    // TEST 2: B <- external bus
    external_bus_in = 8'h03;

    mi = 64'd0;
    mi[14] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(B_out, 8'h03, "B loads from external bus");

    release uut.datapath_unit.bus_sel;

    // TEST 3: A <- A + B
    mi = 64'd0;
    mi[2] = 1'b1;
    mi[6] = 1'b1;
    mi[13:12] = 2'b00;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(A_out, 8'h08, "A loads ALU add result");

    // TEST 4: flags <- ALU flags
    mi = 64'd0;
    mi[61] = 1'b1;
    mi[63] = 1'b0;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(flags_out, 8'h00, "Flags loaded from ALU result");

    // TEST 5: PC increment
    mi = 64'd0;
    mi[0] = 1'b1;
    mi[8:7] = 2'b00;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(pc_out, 8'h01, "PC increments");

    // TEST 6: MAR <- PC
    mi = 64'd0;
    mi[54:53] = 2'b10;
    mi[55] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(MAR_out, 8'h01, "MAR loads from PC");

    // TEST 7: RAM[MAR] <- AA
    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'hAA;

    mi = 64'd0;
    mi[9] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    release uut.datapath_unit.bus_sel;

    // TEST 8: RAM -> bus
    mi = 64'd0;
    mi[57] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #2;
    expect8(ram_out, 8'hAA, "RAM raw output reflects stored memory");
    expect8(bus, 8'hAA, "RAM drives bus when selected");

    // TEST 9: A <- RAM bus value
    mi = 64'd0;
    mi[6] = 1'b1;
    mi[57] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(A_out, 8'hAA, "A loads from RAM bus");

    // --------------------------------------------------
    // DECODE TEST 10: LDA (0x10) -> opcode block 0001_00000
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);
    prom_write(8'h00, 8'h10);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;
    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;
    #10;
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[5] = 1'b1;
    mi[0] = 1'b1;
    mi[8:7] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h10, "IR loads LDA instruction byte from ROM");

    #10;
    expect9(upc_out, 9'b0001_00000, "uPC branches to LDA microcode block");

    // --------------------------------------------------
    // DECODE TEST 11: ADD (0x30) -> opcode block 0011_00000
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);
    prom_write(8'h00, 8'h30);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;
    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;
    #10;
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[5] = 1'b1;
    mi[0] = 1'b1;
    mi[8:7] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h30, "IR loads ADD instruction byte from ROM");

    #10;
    expect9(upc_out, 9'b0011_00000, "uPC branches to ADD microcode block");

    // --------------------------------------------------
    // DECODE TEST 12: JMP (0xE0) -> opcode block 1110_00000
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);
    prom_write(8'h00, 8'hE0);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;
    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;
    #30;
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[5] = 1'b1;
    mi[0] = 1'b1;
    mi[8:7] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'hE0, "IR loads JMP instruction byte from ROM");

    #10;
    expect9(upc_out, 9'b1110_00000, "uPC branches to JMP microcode block");

    // --------------------------------------------------
    // DECODE TEST 13: HLT (0xF0) -> opcode block 1111_00000
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);
    prom_write(8'h00, 8'hF0);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;
    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;
    #10;
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[5] = 1'b1;
    mi[0] = 1'b1;
    mi[8:7] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'hF0, "IR loads HLT instruction byte from ROM");

    #10;
    expect9(upc_out, 9'b1111_00000, "uPC branches to HLT microcode block");

    // --------------------------------------------------
    // INTERRUPT TEST 14: int_enable comes up enabled after reset
    // --------------------------------------------------
    expect1(uut.int_enable_reg, 1'b1, "Interrupt enable is 1 after reset");

    // --------------------------------------------------
    // INTERRUPT TEST 15: INT pulse latches int_pending
    // --------------------------------------------------
    mi = 64'd0;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    INT = 1'b1;
    #10;
    expect1(uut.int_pending_reg, 1'b1, "INT pulse latches interrupt pending");

    // --------------------------------------------------
    // INTERRUPT TEST 16: int_pending stays high after INT goes low
    // --------------------------------------------------
    INT = 1'b0;
    #10;
    expect1(uut.int_pending_reg, 1'b1, "Interrupt pending stays latched after INT goes low");

    // --------------------------------------------------
    // INTERRUPT TEST 17: microcode clear resets int_pending
    // --------------------------------------------------
    mi = 64'd0;
    mi[60] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect1(uut.int_pending_reg, 1'b0, "Microcode clears interrupt pending");

    // --------------------------------------------------
    // INTERRUPT TEST 18: microcode disables interrupt enable
    // --------------------------------------------------
    mi = 64'd0;
    mi[58] = 1'b1;
    mi[59] = 1'b0;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect1(uut.int_enable_reg, 1'b0, "Microcode disables interrupt enable");

    // --------------------------------------------------
    // INTERRUPT TEST 19: microcode re-enables interrupt enable
    // --------------------------------------------------
    mi = 64'd0;
    mi[58] = 1'b1;
    mi[59] = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect1(uut.int_enable_reg, 1'b1, "Microcode re-enables interrupt enable");

    // ==================================================
    // DAY 20-21 PLACEHOLDERS: FULL INSTRUCTION EXECUTION
    // ==================================================

    // --------------------------------------------------
    // EXECUTION TEST 20: LDA addr
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h10);
    prom_write(8'h01, 8'h00);

    uut.datapath_unit.ram_unit.mem[8'h00] = 8'h3C;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(pc_out, 8'h00, "LDA setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[56]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h020] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b00;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h021] = mi;

    mi = 64'd0;
    mi[10]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h022] = mi;

    mi = 64'd0;
    mi[6]     = 1'b1;
    mi[57]    = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h023] = mi;

    #10;
    expect8(IR_out, 8'h10, "LDA fetch loads IR with opcode from ROM");

    #10;
    expect9(upc_out, 9'h020, "LDA decode branches to opcode block");

    #10;
    expect8(OPR_out, 8'h00, "LDA operand fetch loads OPR with address 00 from ROM");

    #10;
    expect8(MAR_out, 8'h00, "LDA loads MAR from OPR");

    #10;
    #10;
    expect8(A_out, 8'h3C, "LDA loads A from RAM[00]");

    // --------------------------------------------------
    // EXECUTION TEST 21: ADD addr
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h30);
    prom_write(8'h01, 8'h01);

    uut.datapath_unit.ram_unit.mem[8'h01] = 8'h03;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #30;
    expect8(pc_out, 8'h00, "ADD setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h05;

    mi = 64'd0;
    mi[6]     = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(A_out, 8'h05, "ADD setup loads A with 05");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[56]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h060] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b00;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h061] = mi;

    mi = 64'd0;
    mi[10]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h062] = mi;

    mi = 64'd0;
    mi[14]    = 1'b1;
    mi[57]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h063] = mi;

    mi = 64'd0;
    mi[61]    = 1'b1;
    mi[63]    = 1'b0;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h064] = mi;

    mi = 64'd0;
    mi[2]     = 1'b1;
    mi[6]     = 1'b1;
    mi[13:12] = 2'b00;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h065] = mi;

    #10;
    expect8(IR_out, 8'h30, "ADD fetch loads IR with opcode from ROM");

    #10;
    expect9(upc_out, 9'h060, "ADD decode branches to opcode block");

    #10;
    expect8(OPR_out, 8'h01, "ADD operand fetch loads OPR with address 01 from ROM");

    #10;
    expect8(MAR_out, 8'h01, "ADD loads MAR from OPR");

    #10;
    #10;
    expect8(B_out, 8'h03, "ADD loads B from RAM[01]");

    #10;
    #10;
    expect8(A_out, 8'h08, "ADD adds RAM[01] into A");

    // --------------------------------------------------
    // EXECUTION TEST 22: PUSH
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h50);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(pc_out, 8'h00, "PUSH setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h22;

    mi = 64'd0;
    mi[6]     = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(A_out, 8'h22, "PUSH setup loads A with 22");
    release uut.datapath_unit.bus_sel;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'hFF;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[52:51] = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(sp_out, 8'hFF, "PUSH setup loads SP with FF");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[50]    = 1'b0;
    mi[52:51] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0A0] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b01;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0A1] = mi;

    mi = 64'd0;
    mi[4]     = 1'b1;
    mi[9]     = 1'b1;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h0A2] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h50, "PUSH fetch loads IR with opcode from ROM");

    #10;
    expect9(upc_out, 9'h0A0, "PUSH decode branches to opcode block");

    #10;
    expect8(sp_out, 8'hFE, "PUSH decrements SP");

    #10;
    expect8(MAR_out, 8'hFE, "PUSH loads MAR from SP");

    #10;
    expect8(uut.datapath_unit.ram_unit.mem[8'hFE], 8'h22, "PUSH stores A onto stack");

    // --------------------------------------------------
    // EXECUTION TEST 23: RET
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h80);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #30;
    expect8(pc_out, 8'h00, "RET setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    uut.datapath_unit.ram_unit.mem[8'hFE] = 8'h44;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'hFE;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[52:51] = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(sp_out, 8'hFE, "RET setup loads SP with FE");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[54:53] = 2'b01;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h100] = mi;

    mi = 64'd0;
    mi[10]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h101] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[57]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h102] = mi;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[50]    = 1'b1;
    mi[52:51] = 2'b00;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h103] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h80, "RET fetch loads IR with opcode from ROM");

    #10;
    expect9(upc_out, 9'h100, "RET decode branches to opcode block");

    #10;
    expect8(MAR_out, 8'hFE, "RET loads MAR from SP");

    #10;
    expect8(ram_out, 8'h44, "RET sees return address at RAM[FE]");

    #10;
    expect8(pc_out, 8'h44, "RET restores PC from stack");

    #10;
    expect8(sp_out, 8'hFF, "RET increments SP");

    // --------------------------------------------------
    // EXECUTION TEST 24: CALL addr
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h70);
    prom_write(8'h01, 8'h20);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'hFF;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[52:51] = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(sp_out, 8'hFF, "CALL setup loads SP with FF");
    release uut.datapath_unit.bus_sel;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #30;
    expect8(pc_out, 8'h00, "CALL setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[50]    = 1'b0;
    mi[52:51] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E0] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b01;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E1] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E2] = mi;

    mi = 64'd0;
    mi[1]     = 1'b1;
    mi[9]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E3] = mi;

    mi = 64'd0;
    mi[24:16] = 9'h1C1;
    mi[26:25] = 2'b11;
    mi[29:27] = 3'b000;
    uut.microcode_rom_unit.rom[9'h0E4] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[3]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h1C1] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h70, "CALL fetch loads IR with opcode from ROM");

    #10;
    expect9(upc_out, 9'h0E0, "CALL decode branches to opcode block");

    #10;
    expect8(sp_out, 8'hFE, "CALL decrements SP");

    #10;
    expect8(MAR_out, 8'hFE, "CALL loads MAR from SP");

    #10;
    expect8(IR_out, 8'h20, "CALL second fetch loads target into IR from ROM");

    #10;
    expect8(uut.datapath_unit.ram_unit.mem[8'hFE], 8'h02, "CALL saves return address");

    #10;
    expect9(upc_out, 9'h1C1, "CALL branches to JMP tail");

    #10;
    expect8(pc_out, 8'h20, "CALL jumps to target");

    // --------------------------------------------------
    // EXECUTION TEST 25: CALL -> RET round trip
    // --------------------------------------------------
    for (i = 0; i < 256; i = i + 1)
        prom_write(i[7:0], 8'h00);

    prom_write(8'h00, 8'h70);
    prom_write(8'h01, 8'h20);
    prom_write(8'h20, 8'h80);

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'hFF;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[52:51] = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #10;
    expect8(sp_out, 8'hFF, "CALL/RET setup loads SP with FF");
    release uut.datapath_unit.bus_sel;

    force uut.datapath_unit.bus_sel = 4'b0000;
    external_bus_in = 8'h00;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[0] = mi;

    #30;
    expect8(pc_out, 8'h00, "CALL/RET setup loads PC with 00");
    release uut.datapath_unit.bus_sel;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[50]    = 1'b0;
    mi[52:51] = 2'b00;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E0] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b01;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E1] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E2] = mi;

    mi = 64'd0;
    mi[1]     = 1'b1;
    mi[9]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h0E3] = mi;

    mi = 64'd0;
    mi[24:16] = 9'h1C1;
    mi[26:25] = 2'b11;
    mi[29:27] = 3'b000;
    uut.microcode_rom_unit.rom[9'h0E4] = mi;

    mi = 64'd0;
    mi[3]     = 1'b1;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h1C1] = mi;

    mi = 64'd0;
    mi[54:53] = 2'b01;
    mi[55]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h100] = mi;

    mi = 64'd0;
    mi[10]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h101] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b01;
    mi[57]    = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[9'h102] = mi;

    mi = 64'd0;
    mi[48]    = 1'b1;
    mi[50]    = 1'b1;
    mi[52:51] = 2'b00;
    mi[26:25] = 2'b10;
    uut.microcode_rom_unit.rom[9'h103] = mi;

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h70, "CALL/RET fetch loads CALL opcode from ROM");

    #10;
    expect9(upc_out, 9'h0E0, "CALL/RET decode branches to CALL block");

    #10;
    expect8(sp_out, 8'hFE, "CALL/RET decrements SP on CALL");

    #10;
    expect8(MAR_out, 8'hFE, "CALL/RET loads MAR from SP during CALL");

    #10;
    expect8(IR_out, 8'h20, "CALL/RET second fetch loads target into IR from ROM");

    #10;
    expect8(uut.datapath_unit.ram_unit.mem[8'hFE], 8'h02, "CALL/RET saves return address");

    #10;
    expect9(upc_out, 9'h1C1, "CALL/RET branches to JMP tail");

    #10;
    expect8(pc_out, 8'h20, "CALL/RET jumps to target");

    mi = 64'd0;
    mi[0]     = 1'b1;
    mi[8:7]   = 2'b00;
    mi[5]     = 1'b1;
    mi[26:25] = 2'b00;
    uut.microcode_rom_unit.rom[0] = mi;

    mi = 64'd0;
    mi[26:25] = 2'b01;
    uut.microcode_rom_unit.rom[1] = mi;

    #10;
    expect8(IR_out, 8'h80, "CALL/RET fetch loads RET opcode from ROM");

    #10;
    expect9(upc_out, 9'h100, "CALL/RET decode branches to RET block");

    #10;
    expect8(MAR_out, 8'hFE, "CALL/RET loads MAR from SP during RET");

    #10;
    expect8(ram_out, 8'h02, "CALL/RET sees saved return address on stack");

    #10;
    expect8(pc_out, 8'h02, "CALL/RET returns to caller");

    #10;
    expect8(sp_out, 8'hFF, "CALL/RET restores SP");

    $display("--------------------------------------------------");
    $display("All current-state main_cpu integration tests passed");
    $display("Program ROM is now loaded through prom_write");
    $display("--------------------------------------------------");
    $stop;
end

endmodule