`timescale 1ns / 1ps

module pc_tb;

    reg clk;
    reg reset;
    reg load;
    reg [1:0] op;
    reg [7:0] data_in;
    wire [7:0] data_out;

    pc uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .op(op),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initial values
        reset = 1;
        load = 0;
        op = 2'b11;
        data_in = 8'd10;

        #10;
        reset = 0;

        // ----------------------------
        // 1) Increment for 2 cycles
        // ----------------------------
        load = 1;
        op = 2'b00;
        #20;

        // Turn load off and try increment again
        load = 0;
        #10;

        // ----------------------------
        // 2) Reset PC using op = 10
        // ----------------------------
        load = 1;
        op = 2'b10;
        #10;

        // Turn load off and try reset again
        load = 0;
        #10;

        // ----------------------------
        // 3) Increment for 2 more cycles
        // ----------------------------
        load = 1;
        op = 2'b00;
        #20;

        // Turn load off and try increment again
        load = 0;
        #10;

        // ----------------------------
        // 4) Load 8'd10 into PC
        // ----------------------------
        load = 1;
        op = 2'b01;
        data_in = 8'd10;
        #10;

        // Turn load off and try load again
        data_in = 8'd25;
        load = 0;
        #10;

        // ----------------------------
        // 5) Increment for 2 more cycles
        // ----------------------------
        load = 1;
        op = 2'b00;
        data_in = 8'd10;
        #20;

        // Turn load off and try increment again
        load = 0;
        #10;

        // ----------------------------
        // 6) Hold operation (11)
        // ----------------------------
        load = 1;
        op = 2'b11;
        #20;

        // Turn load off during hold just to show no change
        load = 0;
        #10;

        $stop;
    end

endmodule