module sp (
    input wire clk,
    input wire reset,
    input wire load,
    input wire inc,
    input wire [1:0] op,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'hFF;
    end
    else if (load) begin
        case (op)
            2'b00: begin
                if (inc)
                    data_out <= data_out + 1;
                else
                    data_out <= data_out - 1;
            end

            2'b01: data_out <= data_in;

            2'b10: data_out <= 8'hFF;

            2'b11: data_out <= data_out; // hold (optional)
        endcase
    end
end

endmodule
