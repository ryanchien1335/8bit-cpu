module pc (
    input wire clk,
    input wire reset,
    input wire load,
    input wire [1:0] op,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'd0;
    end
    else if (load) begin
        case (op)
            2'b00: data_out <= data_out + 1;  // increment
            2'b01: data_out <= data_in;       // load value
            2'b10: data_out <= 8'd0;          // clear
            default: ;                        // hold
        endcase
    end
end

endmodule