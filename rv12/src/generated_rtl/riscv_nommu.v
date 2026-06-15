module riscv_nommu (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	we_i,
	misaligned_i,
	cm_clean_i,
	cm_invalidate_i,
	req_o,
	adr_o,
	size_o,
	lock_o,
	we_o,
	misaligned_o,
	cm_clean_o,
	cm_invalidate_o,
	pagefault_o
);
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input lock_i;
	input wire we_i;
	input wire misaligned_i;
	input wire cm_clean_i;
	input wire cm_invalidate_i;
	output reg req_o;
	output reg [PLEN - 1:0] adr_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg we_o;
	output reg misaligned_o;
	output reg cm_clean_o;
	output reg cm_invalidate_o;
	output wire pagefault_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			if (XLEN == 32)
				adr_o <= {{PLEN - XLEN {1'b0}}, adr_i};
			else
				adr_o <= adr_i[PLEN - 1:0];
			size_o <= size_i;
			lock_o <= lock_i;
			we_o <= we_i;
			misaligned_o <= misaligned_i;
			cm_clean_o <= cm_clean_i;
			cm_invalidate_o <= cm_invalidate_i;
		end
	assign pagefault_o = 1'b0;
endmodule
