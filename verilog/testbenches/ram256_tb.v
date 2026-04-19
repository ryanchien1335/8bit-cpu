`timescale 1ns/1ps

module ram256_tb;

reg clk;
reg we;
reg [7:0] addr;
reg [7:0] data_in;

wire [7:0] data_out;

ram256 uut (
    .clk(clk),
    .we(we),
    .addr(addr),
    .data_in(data_in),
    .data_out(data_out)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    we = 0;
    addr = 8'h00;
    data_in = 8'h00;

    #10;
    we = 1;
    addr = 8'h05;
    data_in = 8'h55;

    #10;
    we = 0;
    addr = 8'h05;
    data_in = 8'h99;

    #10;
    we = 1;
    addr = 8'h05;
    data_in = 8'h99;

    #10;
    we = 0;
    addr = 8'h06;

    #10;
    addr = 8'h05;

    #20;
    $stop;
end

endmodule
