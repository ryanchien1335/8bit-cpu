module ram256 (
    input clk,
    input we,
    input [7:0] addr,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] mem [0:255];
integer i;

initial begin
    for (i = 0; i < 256; i = i + 1)
        mem[i] = 8'h00;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= data_in;
end

assign data_out = mem[addr];

endmodule