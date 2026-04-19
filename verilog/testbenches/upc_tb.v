`timescale 1ns/1ps

module upc_tb;

reg clk;
reg reset;

reg [63:0] micro_out;
reg [3:0] opcode;

reg zero_flag;
reg carry_flag;
reg ldk_flag;
reg digit_invalid;
reg int_request;
reg out_flag;
reg lda_char_flag;

wire [8:0] upc_out;

upc uut (
    .clk(clk),
    .reset(reset),
    .micro_out(micro_out),
    .opcode(opcode),
    .zero_flag(zero_flag),
    .carry_flag(carry_flag),
    .ldk_flag(ldk_flag),
    .digit_invalid(digit_invalid),
    .int_request(int_request),
    .out_flag(out_flag),
    .lda_char_flag(lda_char_flag),
    .upc_out(upc_out)
);

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ------------------------------------------------------------
// Helper task:
// Put branch_target, mux_in, and branch_op into micro_out
//
// branch_target = bits [24:16]
// mux_in        = bits [26:25]
// branch_op     = bits [29:27]
// ------------------------------------------------------------
task set_microinstruction;
    input [8:0] branch_target_in;
    input [1:0] mux_in_in;
    input [2:0] branch_op_in;
    begin
        micro_out = 64'b0;
        micro_out[24:16] = branch_target_in;
        micro_out[26:25] = mux_in_in;
        micro_out[29:27] = branch_op_in;
    end
endtask

// ------------------------------------------------------------
// Helper task:
// Check expected uPC value
// ------------------------------------------------------------
task expect_upc;
    input [8:0] expected;
    input [255:0] test_name;
    begin
        if (upc_out !== expected) begin
            $display("FAIL: %s | expected = %h, got = %h at time %0t",
                     test_name, expected, upc_out, $time);
            $stop;
        end else begin
            $display("PASS: %s | upc_out = %h at time %0t",
                     test_name, upc_out, $time);
        end
    end
endtask

initial begin
    // --------------------------------------------------------
    // Default values
    // --------------------------------------------------------
    reset = 0;
    micro_out = 64'b0;
    opcode = 4'b0000;

    zero_flag = 0;
    carry_flag = 0;
    ldk_flag = 0;
    digit_invalid = 0;
    int_request = 0;
    out_flag = 0;
    lda_char_flag = 0;

    // --------------------------------------------------------
    // TEST 1: Reset
    // Expect uPC to go to 0
    // --------------------------------------------------------
    reset = 1;
    #12;   // cross a posedge
    expect_upc(9'h000, "reset drives uPC to 0");
    reset = 0;

    // --------------------------------------------------------
    // TEST 2: Increment
    // mux_in = 00 should increment every cycle
    // --------------------------------------------------------
    set_microinstruction(9'h000, 2'b00, 3'b000);
    #10;
    expect_upc(9'h001, "increment from 0 to 1");

    #10;
    expect_upc(9'h002, "increment from 1 to 2");

    #10;
    expect_upc(9'h003, "increment from 2 to 3");

    // --------------------------------------------------------
    // TEST 3: Opcode jump
    // mux_in = 01 should go to {opcode, 5'b00000}
    // Example opcode = 0011 => 0x060
    // That matches your opcode<<5 addressing style
    // --------------------------------------------------------
    opcode = 4'b0011;
    set_microinstruction(9'h000, 2'b01, 3'b000);
    #10;
    expect_upc(9'h060, "opcode jump to opcode<<5");

    // Another opcode example: 1110 => 0x1C0
    opcode = 4'b1110;
    #10;
    expect_upc(9'h1C0, "opcode jump with opcode 1110");

    // --------------------------------------------------------
    // TEST 4: Reset path through mux_in
    // mux_in = 10 should force uPC to 0
    // --------------------------------------------------------
    set_microinstruction(9'h000, 2'b10, 3'b000);
    #10;
    expect_upc(9'h000, "mux_in reset path");

    // --------------------------------------------------------
    // TEST 5: Unconditional branch
    // mux_in = 11, branch_op = 000 => always branch
    // --------------------------------------------------------
    set_microinstruction(9'h120, 2'b11, 3'b000);
    #10;
    expect_upc(9'h120, "unconditional branch to 0x120");

    // --------------------------------------------------------
    // TEST 6: Branch if zero - not taken
    // branch_op = 001
    // If zero_flag = 0, should increment instead
    // --------------------------------------------------------
    zero_flag = 0;
    set_microinstruction(9'h140, 2'b11, 3'b001);
    #10;
    expect_upc(9'h121, "branch if zero not taken -> increment");

    // --------------------------------------------------------
    // TEST 7: Branch if zero - taken
    // --------------------------------------------------------
    zero_flag = 1;
    set_microinstruction(9'h140, 2'b11, 3'b001);
    #10;
    expect_upc(9'h140, "branch if zero taken");

    zero_flag = 0;

    // --------------------------------------------------------
    // TEST 8: Branch if carry - not taken
    // branch_op = 010
    // --------------------------------------------------------
    carry_flag = 0;
    set_microinstruction(9'h160, 2'b11, 3'b010);
    #10;
    expect_upc(9'h141, "branch if carry not taken -> increment");

    // --------------------------------------------------------
    // TEST 9: Branch if carry - taken
    // --------------------------------------------------------
    carry_flag = 1;
    set_microinstruction(9'h160, 2'b11, 3'b010);
    #10;
    expect_upc(9'h160, "branch if carry taken");

    carry_flag = 0;

    // --------------------------------------------------------
    // TEST 10: Placeholder condition example - interrupt
    // branch_op = 101
    // This is one of the signals you're still mocking for now
    // --------------------------------------------------------
    int_request = 0;
    set_microinstruction(9'h070, 2'b11, 3'b101);
    #10;
    expect_upc(9'h161, "interrupt branch not taken -> increment");

    int_request = 1;
    set_microinstruction(9'h070, 2'b11, 3'b101);
    #10;
    expect_upc(9'h070, "interrupt branch taken");

    int_request = 0;

    // --------------------------------------------------------
    // TEST 11: Placeholder condition example - OUT
    // branch_op = 110
    // --------------------------------------------------------
    out_flag = 0;
    set_microinstruction(9'h1C0, 2'b11, 3'b110);
    #10;
    expect_upc(9'h071, "OUT branch not taken -> increment");

    out_flag = 1;
    set_microinstruction(9'h1C0, 2'b11, 3'b110);
    #10;
    expect_upc(9'h1C0, "OUT branch taken");

    out_flag = 0;

    // --------------------------------------------------------
    // TEST 12: Placeholder condition example - LDK
    // branch_op = 011
    // --------------------------------------------------------
    ldk_flag = 0;
    set_microinstruction(9'h1A0, 2'b11, 3'b011);
    #10;
    expect_upc(9'h1C1, "LDK branch not taken -> increment");

    ldk_flag = 1;
    set_microinstruction(9'h1A0, 2'b11, 3'b011);
    #10;
    expect_upc(9'h1A0, "LDK branch taken");

    ldk_flag = 0;

    $display("--------------------------------------------------");
    $display("All uPC tests passed.");
    $display("--------------------------------------------------");
    $stop;
end

endmodule
