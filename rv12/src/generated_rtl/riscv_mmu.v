module riscv_mmu (
	rst_ni,
	clk_i,
	clr_i,
	vreq_i,
	vadr_i,
	vsize_i,
	vlock_i,
	vprot_i,
	vwe_i,
	vd_i,
	preq_o,
	padr_o,
	psize_o,
	plock_o,
	pprot_o,
	pwe_o,
	pd_o,
	pq_i,
	pack_i,
	page_fault_o
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	input wire rst_ni;
	input wire clk_i;
	input wire clr_i;
	input wire vreq_i;
	input wire [XLEN - 1:0] vadr_i;
	input wire [2:0] vsize_i;
	input wire vlock_i;
	input wire [2:0] vprot_i;
	input wire vwe_i;
	input wire [XLEN - 1:0] vd_i;
	output reg preq_o;
	output reg [PLEN - 1:0] padr_o;
	output reg [2:0] psize_o;
	output reg plock_o;
	output reg [2:0] pprot_o;
	output reg pwe_o;
	output reg [XLEN - 1:0] pd_o;
	input wire [XLEN - 1:0] pq_i;
	input wire pack_i;
	output wire page_fault_o;
	always @(posedge clk_i)
		if (vreq_i)
			padr_o <= vadr_i;
	always @(posedge clk_i)
		if (clr_i)
			preq_o <= 1'b0;
		else
			preq_o <= vreq_i;
	always @(posedge clk_i) begin
		psize_o <= vsize_i;
		plock_o <= vlock_i;
		pprot_o <= vprot_i;
		pwe_o <= vwe_i;
	end
	always @(posedge clk_i) pd_o <= vd_i;
	assign page_fault_o = 1'b0;
endmodule
