module riscv_mem (
	rst_ni,
	clk_i,
	mem_stall_i,
	mem_stall_o,
	mem_pc_i,
	mem_pc_o,
	mem_insn_i,
	mem_insn_o,
	mem_exceptions_dn_i,
	mem_exceptions_dn_o,
	mem_exceptions_up_i,
	mem_exceptions_up_o,
	mem_r_i,
	mem_memadr_i,
	mem_r_o,
	mem_memadr_o
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	input rst_ni;
	input clk_i;
	input mem_stall_i;
	output wire mem_stall_o;
	input [MXLEN - 1:0] mem_pc_i;
	output reg [MXLEN - 1:0] mem_pc_o;
	input wire [34:0] mem_insn_i;
	output reg [34:0] mem_insn_o;
	input wire [27:0] mem_exceptions_dn_i;
	output reg [27:0] mem_exceptions_dn_o;
	input wire [27:0] mem_exceptions_up_i;
	output wire [27:0] mem_exceptions_up_o;
	input [MXLEN - 1:0] mem_r_i;
	input [MXLEN - 1:0] mem_memadr_i;
	output reg [MXLEN - 1:0] mem_r_o;
	output reg [MXLEN - 1:0] mem_memadr_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_pc_o <= PC_INIT;
		else if (!mem_stall_i)
			mem_pc_o <= mem_pc_i;
	assign mem_stall_o = mem_stall_i;
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_insn_o[31-:32] <= mem_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[34] <= 1'b0;
		else if (!mem_stall_i)
			mem_insn_o[34] <= mem_insn_i[34];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[33] <= 1'b1;
		else if (mem_exceptions_up_i[27])
			mem_insn_o[33] <= 1'b1;
		else if (!mem_stall_i)
			mem_insn_o[33] <= mem_insn_i[33];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[32] <= 'h0;
		else if (mem_exceptions_up_i[27])
			mem_insn_o[32] <= 'h0;
		else if (!mem_stall_i)
			mem_insn_o[32] <= mem_insn_i[32];
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_r_o <= mem_r_i;
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_memadr_o <= mem_memadr_i;
	assign mem_exceptions_up_o = mem_exceptions_dn_o | mem_exceptions_up_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_exceptions_dn_o <= 'h0;
		else if (mem_exceptions_up_o[27])
			mem_exceptions_dn_o <= 'h0;
		else if (!mem_stall_i)
			mem_exceptions_dn_o <= mem_exceptions_dn_i;
endmodule
