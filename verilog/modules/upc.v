
module upc (
    input  wire       clk,
    input  wire       reset,

    input  wire [63:0] micro_out,
    input  wire [3:0]  opcode,

    input  wire       zero_flag,
    input  wire       carry_flag,

    // Placeholder inputs for branch conditions not fully implemented yet
    input  wire       ldk_flag,
    input  wire       digit_invalid,
    input  wire       int_request,
    input  wire       out_flag,
    input  wire       lda_char_flag,

    output reg  [8:0] upc_out
);

wire [8:0] branch_target;
wire [1:0] mux_in;
wire [2:0] branch_op;

reg        branch_taken;
reg [8:0]  next_addr;

assign branch_target = micro_out[24:16];
assign mux_in        = micro_out[26:25];
assign branch_op     = micro_out[29:27];

always @(*) begin
    case (branch_op)
        3'b000: branch_taken = 1'b1;
        3'b001: branch_taken = zero_flag;
        3'b010: branch_taken = carry_flag;
        3'b011: branch_taken = ldk_flag;
        3'b100: branch_taken = digit_invalid;
        3'b101: branch_taken = int_request;
        3'b110: branch_taken = out_flag;
        3'b111: branch_taken = lda_char_flag;
        default: branch_taken = 1'b0;
    endcase
end

always @(*) begin
    case (mux_in)
        2'b00: next_addr = upc_out + 9'b000000001;
        2'b01: next_addr = {opcode, 5'b00000};
        2'b10: next_addr = 9'b000000000;
        2'b11: begin
            if (branch_taken)
                next_addr = branch_target;
            else
                next_addr = upc_out + 9'b000000001;
        end
        default: next_addr = upc_out + 9'b000000001;
    endcase
end

always @(posedge clk) begin
    if (reset)
        upc_out <= 9'b000000000;
    else
        upc_out <= next_addr;
end

endmodule