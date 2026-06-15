module riscv_memmisaligned (
	instruction_i,
	adr_i,
	size_i,
	misaligned_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter HAS_RVC = 0;
	input wire instruction_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	output reg misaligned_o;
	always @(*) begin
		if (_sv2v_0)
			;
		if (instruction_i)
			misaligned_o = (HAS_RVC != 0 ? adr_i[0] : |adr_i[1:0]);
		else
			(* full_case, parallel_case *)
			case (size_i)
				3'b000: misaligned_o = 1'b0;
				3'b001: misaligned_o = adr_i[0];
				3'b010: misaligned_o = |adr_i[1:0];
				3'b011: misaligned_o = |adr_i[2:0];
				default: misaligned_o = 1'b1;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
