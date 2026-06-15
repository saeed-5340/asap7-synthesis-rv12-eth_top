module riscv_membuf (
	rst_ni,
	clk_i,
	flush_i,
	stall_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	misaligned_i,
	cm_clean_i,
	cm_invalidate_i,
	req_o,
	ack_i,
	adr_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	q_o,
	misaligned_o,
	cm_clean_o,
	cm_invalidate_o,
	empty_o,
	full_o
);
	parameter DEPTH = 2;
	parameter XLEN = 32;
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire stall_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire misaligned_i;
	input wire cm_clean_i;
	input wire cm_invalidate_i;
	output wire req_o;
	input wire ack_i;
	output wire [XLEN - 1:0] adr_o;
	output wire [2:0] size_o;
	output wire lock_o;
	output wire [2:0] prot_o;
	output wire we_o;
	output wire [XLEN - 1:0] q_o;
	output wire misaligned_o;
	output wire cm_clean_o;
	output wire cm_invalidate_o;
	output wire empty_o;
	output wire full_o;
	wire [(((1 + XLEN) + 8) + XLEN) + 2:0] queue_d;
	wire [(((1 + XLEN) + 8) + XLEN) + 2:0] queue_q;
	wire queue_we;
	wire queue_re;
	reg [$clog2(DEPTH):0] access_pending;
	assign queue_d[1 + (XLEN + (8 + (XLEN + 2)))] = req_i;
	assign queue_d[XLEN + (8 + (XLEN + 2))-:((XLEN + (8 + (XLEN + 2))) >= (8 + (XLEN + 3)) ? ((XLEN + (8 + (XLEN + 2))) - (8 + (XLEN + 3))) + 1 : ((8 + (XLEN + 3)) - (XLEN + (8 + (XLEN + 2)))) + 1)] = adr_i;
	assign queue_d[8 + (XLEN + 2)-:((8 + (XLEN + 2)) >= (5 + (XLEN + 3)) ? ((8 + (XLEN + 2)) - (5 + (XLEN + 3))) + 1 : ((5 + (XLEN + 3)) - (8 + (XLEN + 2))) + 1)] = size_i;
	assign queue_d[5 + (XLEN + 2)] = lock_i;
	assign queue_d[4 + (XLEN + 2)-:((4 + (XLEN + 2)) >= (1 + (XLEN + 3)) ? ((4 + (XLEN + 2)) - (1 + (XLEN + 3))) + 1 : ((1 + (XLEN + 3)) - (4 + (XLEN + 2))) + 1)] = prot_i;
	assign queue_d[1 + (XLEN + 2)] = we_i;
	assign queue_d[XLEN + 2-:((XLEN + 2) >= 3 ? XLEN + 0 : 4 - (XLEN + 2))] = d_i;
	assign queue_d[2] = misaligned_i;
	assign queue_d[1] = cm_clean_i;
	assign queue_d[0] = cm_invalidate_i;
	rl_queue #(
		.DEPTH(DEPTH),
		.DBITS((((((1 + XLEN) + 8) + XLEN) + 2) >= 0 ? (((1 + XLEN) + 8) + XLEN) + 3 : 1 - ((((1 + XLEN) + 8) + XLEN) + 2)))
	) rl_queue_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.clr_i(flush_i),
		.ena_i(1'b1),
		.we_i(queue_we),
		.d_i(queue_d),
		.re_i(queue_re),
		.q_o(queue_q),
		.empty_o(empty_o),
		.full_o(full_o),
		.almost_empty_o(),
		.almost_full_o()
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			access_pending <= 'h0;
		else if (flush_i)
			access_pending <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({req_i, ~stall_i})
				2'b01: access_pending <= (|access_pending ? access_pending - 1 : 'h0);
				2'b10: access_pending <= access_pending + 1;
				default:
					;
			endcase
	assign queue_we = ((req_i & (stall_i | (|access_pending))) | cm_clean_i) | cm_invalidate_i;
	assign queue_re = ~empty_o & ~stall_i;
	assign req_o = (empty_o ? req_i : queue_q[1 + (XLEN + (8 + (XLEN + 2)))]);
	assign adr_o = (empty_o ? adr_i : queue_q[XLEN + (8 + (XLEN + 2))-:((XLEN + (8 + (XLEN + 2))) >= (8 + (XLEN + 3)) ? ((XLEN + (8 + (XLEN + 2))) - (8 + (XLEN + 3))) + 1 : ((8 + (XLEN + 3)) - (XLEN + (8 + (XLEN + 2)))) + 1)]);
	assign size_o = (empty_o ? size_i : queue_q[8 + (XLEN + 2)-:((8 + (XLEN + 2)) >= (5 + (XLEN + 3)) ? ((8 + (XLEN + 2)) - (5 + (XLEN + 3))) + 1 : ((5 + (XLEN + 3)) - (8 + (XLEN + 2))) + 1)]);
	assign lock_o = (empty_o ? lock_i : queue_q[5 + (XLEN + 2)]);
	assign prot_o = (empty_o ? prot_i : queue_q[4 + (XLEN + 2)-:((4 + (XLEN + 2)) >= (1 + (XLEN + 3)) ? ((4 + (XLEN + 2)) - (1 + (XLEN + 3))) + 1 : ((1 + (XLEN + 3)) - (4 + (XLEN + 2))) + 1)]);
	assign we_o = (empty_o ? we_i : queue_q[1 + (XLEN + 2)]);
	assign q_o = (empty_o ? d_i : queue_q[XLEN + 2-:((XLEN + 2) >= 3 ? XLEN + 0 : 4 - (XLEN + 2))]);
	assign misaligned_o = (empty_o ? misaligned_i : queue_q[2]);
	assign cm_clean_o = (empty_o ? cm_clean_i : queue_q[1]);
	assign cm_invalidate_o = (empty_o ? cm_invalidate_i : queue_q[0]);
endmodule
