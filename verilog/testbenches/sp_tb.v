`timescale 1ns / 1ps

module sp_tb;

    reg clk;
    reg reset;
    reg load;
    reg inc;
    reg [1:0] op;
    reg [7:0] data_in;
    wire [7:0] data_out;

    sp uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .inc(inc),
        .op(op),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // ------------------------
        // INITIAL STATE + RESET
        // ------------------------
        reset = 1;
        load = 0;
        inc = 0;
        op = 2'b00;
        data_in = 8'h00;

        #10;
        reset = 0;

        // ------------------------
        // CASE 1: HOLD (load = 0)
        // ------------------------
        load = 0;
        op = 2'b00;
        inc = 0;
        #10;

        inc = 1;
        #10;

        op = 2'b01;
        data_in = 8'h3A;
        #10;

        op = 2'b10;
        #10;

        op = 2'b11;
        #10;

        // ------------------------
        // CASE 2: DEC (op = 00, inc = 0)
        // ------------------------
        load = 1;
        op = 2'b00;
        inc = 0;
        #10;

        // ------------------------
        // CASE 3: INC (op = 00, inc = 1)
        // ------------------------
        inc = 1;
        #10;

        // ------------------------
        // CASE 4: LOAD FROM BUS (op = 01)
        // ------------------------
        op = 2'b01;
        data_in = 8'h3A;
        #10;

	op = 2'b00;
	inc = 0;
	#10;
	#10;
	inc = 1;
	#10;
	#10;
	#10;

        // ------------------------
        // CASE 5: RESET VIA OP (op = 10)
        // ------------------------
        op = 2'b10;
        #10;

        // ------------------------
        // CASE 6: UNUSED (op = 11)
        // ------------------------
        op = 2'b11;
        #10;

        $stop;
    end

endmodule