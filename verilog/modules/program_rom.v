module program_rom (
    input  wire [7:0] addr,
    output wire [7:0] data_out,

    // testbench/debug write port
    input  wire       tb_we,
    input  wire       tb_clk,
    input  wire [7:0] tb_addr,
    input  wire [7:0] tb_data
);

    reg [7:0] rom [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 8'h00;
	$readmemh("C:/Users/Ryan Chien/OneDrive/8bit_CPU/8bit-cpu/program.mem", rom);
    end

    assign data_out = rom[addr];

    always @(posedge tb_clk) begin
        if (tb_we)
            rom[tb_addr] <= tb_data;
    end

endmodule