module riscv_cache_tag (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	phys_adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	invalidate_i,
	clean_i,
	pagefault_i,
	invalidate_all_blocks_i,
	req_o,
	wreq_o,
	adr_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	be_o,
	q_o,
	invalidate_o,
	clean_o,
	pagefault_o,
	core_tag_o
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
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
	function automatic integer riscv_cache_pkg_no_of_tag_bits;
		input integer plen;
		input integer no_of_index_bits;
		input integer no_of_block_offset_bits;
		riscv_cache_pkg_no_of_tag_bits = (plen - no_of_index_bits) - no_of_block_offset_bits;
	endfunction
	localparam TAG_BITS = riscv_cache_pkg_no_of_tag_bits(PLEN, IDX_BITS, BLK_OFFS_BITS);
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [PLEN - 1:0] phys_adr_i;
	input wire [2:0] size_i;
	input lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire invalidate_i;
	input wire clean_i;
	input wire pagefault_i;
	input wire invalidate_all_blocks_i;
	output reg req_o;
	output reg wreq_o;
	output reg [PLEN - 1:0] adr_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg [2:0] prot_o;
	output reg we_o;
	output reg [(XLEN / 8) - 1:0] be_o;
	output reg [XLEN - 1:0] q_o;
	output reg invalidate_o;
	output reg clean_o;
	output reg pagefault_o;
	output wire [TAG_BITS - 1:0] core_tag_o;
	function automatic [(XLEN / 8) - 1:0] size2be;
		input [2:0] size;
		input [XLEN - 1:0] adr;
		reg [$clog2(XLEN / 8) - 1:0] adr_lsbs;
		begin
			adr_lsbs = adr[$clog2(XLEN / 8) - 1:0];
			(* full_case, parallel_case *)
			case (size)
				3'b000: size2be = 'h1 << adr_lsbs;
				3'b001: size2be = 'h3 << adr_lsbs;
				3'b010: size2be = 'hf << adr_lsbs;
				3'b011: size2be = 'hff << adr_lsbs;
			endcase
		end
	endfunction
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wreq_o <= 1'b0;
		else if (flush_i)
			wreq_o <= 1'b0;
		else if (!stall_i)
			wreq_o <= req_i & we_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			adr_o <= phys_adr_i;
			size_o <= size_i;
			lock_o <= lock_i;
			prot_o <= prot_i;
			we_o <= we_i;
			be_o <= size2be(size_i, phys_adr_i);
			q_o <= d_i;
			pagefault_o <= pagefault_i;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			clean_o <= 1'b0;
		else if (!stall_i)
			clean_o <= clean_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_o <= 1'b0;
		else if (invalidate_all_blocks_i)
			invalidate_o <= 1'b0;
		else if (!stall_i)
			invalidate_o <= invalidate_i;
	assign core_tag_o = phys_adr_i[PLEN - 1-:TAG_BITS];
endmodule
