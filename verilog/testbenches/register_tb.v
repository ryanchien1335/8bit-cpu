`timescale 1ns/1ps

module register_tb;

reg clk;
reg load;
reg [7:0] data_in;
wire [7:0] data_out;

register uut (
    .clk(clk),
    .load(load),
    .data_in(data_in),
    .data_out(data_out)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    load = 0;
    data_in = 8'd0;

    #10;
    data_in = 8'd42;
    load = 1;

    #10;
    load = 0;

    #10;
    data_in = 8'd99;

    #10;
    load = 1;

    #10;
    load = 0;

    #10;
    $stop;
end

endmodule