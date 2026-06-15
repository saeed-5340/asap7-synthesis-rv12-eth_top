module riscv_cache_setup (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	invalidate_i,
	clean_i,
	req_o,
	rreq_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	q_o,
	invalidate_o,
	clean_o,
	idx_o
);
	parameter XLEN = 32;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	function automatic integer riscv_cache_pkg_no_of_sets;
		input integer cache_size;
		input integer block_size;
		input integer ways;
		riscv_cache_pkg_no_of_sets = ((cache_size * 1024) / block_size) / ways;
	endfunction
	localparam SETS = riscv_cache_pkg_no_of_sets(SIZE, BLOCK_SIZE, WAYS);
	function automatic integer riscv_cache_pkg_no_of_block_offset_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_offset_bits = $clog2(block_size);
	endfunction
	localparam BLK_OFFS_BITS = riscv_cache_pkg_no_of_block_offset_bits(BLOCK_SIZE);
	function automatic integer riscv_cache_pkg_no_of_index_bits;
		input integer no_of_sets;
		riscv_cache_pkg_no_of_index_bits = $clog2(no_of_sets);
	endfunction
	localparam IDX_BITS = riscv_cache_pkg_no_of_index_bits(SETS);
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire invalidate_i;
	input wire clean_i;
	output reg req_o;
	output wire rreq_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg [2:0] prot_o;
	output reg we_o;
	output reg [XLEN - 1:0] q_o;
	output reg invalidate_o;
	output reg clean_o;
	output wire [IDX_BITS - 1:0] idx_o;
	reg flush_dly;
	wire [IDX_BITS - 1:0] adr_idx;
	reg [IDX_BITS - 1:0] adr_idx_dly;
	reg invalidate_hold;
	reg clean_hold;
	always @(posedge clk_i) flush_dly <= flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_hold <= 1'b0;
		else if (!stall_i)
			invalidate_hold <= 1'b0;
		else
			invalidate_hold <= invalidate_i | invalidate_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			clean_hold <= 1'b0;
		else if (!stall_i)
			clean_hold <= 1'b0;
		else
			clean_hold <= clean_i | clean_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			size_o <= size_i;
			lock_o <= lock_i;
			prot_o <= prot_i;
			we_o <= we_i;
			q_o <= d_i;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			invalidate_o <= 1'b0;
			clean_o <= 1'b0;
		end
		else if (!stall_i) begin
			invalidate_o <= invalidate_i | invalidate_hold;
			clean_o <= clean_i | clean_hold;
		end
	assign rreq_o = req_i & ~we_i;
	assign adr_idx = adr_i[BLK_OFFS_BITS+:IDX_BITS];
	always @(posedge clk_i)
		if (!stall_i || flush_dly)
			adr_idx_dly <= adr_idx;
	assign idx_o = (stall_i ? adr_idx_dly : adr_idx);
endmodule
