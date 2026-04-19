
module alu (
    input [7:0] A,
    input [7:0] B,
    input [1:0] op,
    output reg [7:0] result,
    output reg zero,
    output reg carry
);

reg [8:0] temp;

always @(*) begin
    case (op)

        2'b00: begin
            temp = A + B;
            result = temp[7:0];
            carry = temp[8];
        end

        2'b01: begin
            temp = A - B;
            result = temp[7:0];
            carry = ~temp[8];
        end
	
	2'b10: begin
	    result = A & B;
	    carry = 0;
	end

	2'b11: begin
	    result = A | B;
	    carry = 0;
	end

        default: begin
            result = 8'b00000000;
            carry = 0;
        end

    endcase

    zero = (result == 0);
end

endmodule