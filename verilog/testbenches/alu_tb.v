`timescale 1ns/1ps

module alu_tb;

reg [7:0] A;
reg [7:0] B;
reg [1:0] op;

wire [7:0] result;
wire zero;
wire carry;

alu uut (
    .A(A),
    .B(B),
    .op(op),
    .result(result),
    .zero(zero),
    .carry(carry)
);

initial begin
    A = 0;
    B = 0;
    op = 2'b00;
    #5;

    A = 8'd5;
    B = 8'd3;
    op = 2'b00;
    #10;

    A = 8'd200;
    B = 8'd100;
    op = 2'b00;
    #10;

    A = 8'd7;
    B = 8'd3;
    op = 2'b01;
    #10;

    A = 8'd3;
    B = 8'd7;
    op = 2'b01;
    #10;

    A = 8'd15;
    B = 8'd10;
    op = 2'b10;
    #10;

    $stop;
end

endmodule