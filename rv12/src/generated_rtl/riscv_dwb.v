module riscv_dwb (
	rst_ni,
	clk_i,
	wb_insn_i,
	wb_we_i,
	wb_r_i,
	dwb_insn_o,
	dwb_r_o
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	input rst_ni;
	input clk_i;
	input wire [34:0] wb_insn_i;
	input wb_we_i;
	input [MXLEN - 1:0] wb_r_i;
	output reg [34:0] dwb_insn_o;
	output reg [MXLEN - 1:0] dwb_r_o;
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[31-:32] <= riscv_opcodes_pkg_NOP;
		else
			dwb_insn_o[31-:32] <= wb_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[33] <= 1'b1;
		else
			dwb_insn_o[33] <= ~wb_we_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[34] <= 1'b0;
		else
			dwb_insn_o[34] <= wb_insn_i[34];
	always @(posedge clk_i)
		if (wb_we_i)
			dwb_r_o <= wb_r_i;
endmodule
