module riscv_dcache_fsm (
	rst_ni,
	clk_i,
	stall_o,
	flush_i,
	invalidate_i,
	clean_i,
	clean_rdy_clr_i,
	clean_rdy_o,
	armed_o,
	cleaning_o,
	invalidate_block_o,
	invalidate_all_blocks_o,
	filling_o,
	fill_way_i,
	fill_way_o,
	clean_way_int_i,
	clean_idx_i,
	clean_way_o,
	clean_idx_o,
	cacheable_i,
	misaligned_i,
	pma_exception_i,
	pmp_exception_i,
	pagefault_i,
	req_i,
	wreq_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	be_i,
	d_i,
	q_o,
	ack_o,
	err_o,
	misaligned_o,
	pagefault_o,
	cache_hit_i,
	ways_hit_i,
	cache_line_i,
	cache_dirty_i,
	way_dirty_i,
	idx_o,
	core_tag_o,
	latchmem_o,
	writebuffer_we_o,
	writebuffer_ack_i,
	writebuffer_idx_o,
	writebuffer_offs_o,
	writebuffer_data_o,
	writebuffer_be_o,
	writebuffer_ways_hit_o,
	writebuffer_cleaning_o,
	evict_read_o,
	biucmd_o,
	biucmd_ack_i,
	biucmd_busy_i,
	biucmd_noncacheable_req_o,
	biucmd_noncacheable_ack_i,
	inflight_cnt_i,
	biu_q_i,
	biu_stb_ack_i,
	biu_ack_i,
	biu_err_i,
	biu_adro_i,
	in_biubuffer_i,
	biubuffer_i
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter INFLIGHT_DEPTH = 2;
	function automatic integer riscv_cache_pkg_no_of_sets;
		input integer cache_size;
		input integer block_size;
		input integer ways;
		riscv_cache_pkg_no_of_sets = ((cache_size * 1024) / block_size) / ways;
	endfunction
	localparam SETS = riscv_cache_pkg_no_of_sets(SIZE, BLOCK_SIZE, WAYS);
	function automatic integer riscv_cache_pkg_no_of_block_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_bits = 8 * block_size;
	endfunction
	localparam BLK_BITS = riscv_cache_pkg_no_of_block_bits(BLOCK_SIZE);
	function automatic integer riscv_cache_pkg_no_of_block_offset_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_offset_bits = $clog2(block_size);
	endfunction
	localparam BLK_OFFS_BITS = riscv_cache_pkg_no_of_block_offset_bits(BLOCK_SIZE);
	function automatic integer riscv_cache_pkg_no_of_data_offset_bits;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_no_of_data_offset_bits = $clog2(no_of_block_bits / xlen);
	endfunction
	localparam DAT_OFFS_BITS = riscv_cache_pkg_no_of_data_offset_bits(XLEN, BLK_BITS);
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
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	input wire rst_ni;
	input wire clk_i;
	output reg stall_o;
	input wire flush_i;
	input wire invalidate_i;
	input wire clean_i;
	input wire clean_rdy_clr_i;
	output reg clean_rdy_o;
	output reg armed_o;
	output reg cleaning_o;
	output reg invalidate_block_o;
	output reg invalidate_all_blocks_o;
	output reg filling_o;
	input wire [WAYS - 1:0] fill_way_i;
	output reg [WAYS - 1:0] fill_way_o;
	input wire [$clog2(WAYS) - 1:0] clean_way_int_i;
	input wire [IDX_BITS - 1:0] clean_idx_i;
	output reg [WAYS - 1:0] clean_way_o;
	output reg [IDX_BITS - 1:0] clean_idx_o;
	input wire cacheable_i;
	input wire misaligned_i;
	input wire pma_exception_i;
	input wire pmp_exception_i;
	input wire pagefault_i;
	input wire req_i;
	input wire wreq_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [(XLEN / 8) - 1:0] be_i;
	input wire [XLEN - 1:0] d_i;
	output reg [XLEN - 1:0] q_o;
	output reg ack_o;
	output reg err_o;
	output reg misaligned_o;
	output reg pagefault_o;
	input wire cache_hit_i;
	input wire [WAYS - 1:0] ways_hit_i;
	input wire [BLK_BITS - 1:0] cache_line_i;
	input wire cache_dirty_i;
	input wire way_dirty_i;
	output wire [IDX_BITS - 1:0] idx_o;
	output wire [TAG_BITS - 1:0] core_tag_o;
	output reg latchmem_o;
	output reg writebuffer_we_o;
	input wire writebuffer_ack_i;
	output reg [IDX_BITS - 1:0] writebuffer_idx_o;
	output reg [DAT_OFFS_BITS - 1:0] writebuffer_offs_o;
	output reg [XLEN - 1:0] writebuffer_data_o;
	output reg [(BLK_BITS / 8) - 1:0] writebuffer_be_o;
	output reg [WAYS - 1:0] writebuffer_ways_hit_o;
	output reg writebuffer_cleaning_o;
	output reg evict_read_o;
	output reg [1:0] biucmd_o;
	input wire biucmd_ack_i;
	input wire biucmd_busy_i;
	output reg biucmd_noncacheable_req_o;
	input wire biucmd_noncacheable_ack_i;
	input wire [INFLIGHT_BITS - 1:0] inflight_cnt_i;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_stb_ack_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	input wire [PLEN - 1:0] biu_adro_i;
	input wire in_biubuffer_i;
	input wire [BLK_BITS - 1:0] biubuffer_i;
	localparam BURST_OFF = XLEN / 8;
	localparam BURST_LSB = $clog2(BURST_OFF);
	function automatic integer onehot2int;
		input [WAYS - 1:0] a;
		integer i;
		begin
			onehot2int = 0;
			for (i = 0; i < WAYS; i = i + 1)
				if (a[i])
					onehot2int = i;
		end
	endfunction
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
	function automatic [BLK_BITS - 1:0] be_mux;
		input ena;
		input [(BLK_BITS / 8) - 1:0] be;
		input [BLK_BITS - 1:0] o;
		input [BLK_BITS - 1:0] n;
		integer i;
		for (i = 0; i < (BLK_BITS / 8); i = i + 1)
			be_mux[i * 8+:8] = (ena && be[i] ? n[i * 8+:8] : o[i * 8+:8]);
	endfunction
	wire [XLEN - 1:0] cache_q;
	wire cache_ack;
	wire biu_cacheable_ack;
	wire pma_pmp_exception;
	wire valid_req;
	wire valid_wreq;
	reg [3:0] nxt_memfsm_state;
	reg [3:0] memfsm_state;
	reg [1:0] nxt_biucmd;
	reg [WAYS - 1:0] fill_way;
	reg invalidate_hold;
	reg clean_hold;
	reg clean_hold_clr;
	reg clean_rdy;
	reg clean_block;
	reg invalidate_block;
	reg invalidate_all_blocks;
	reg writebuffer_cleaning;
	reg evict_read;
	wire biu_adro_eq_cache_adr;
	wire [DAT_OFFS_BITS - 1:0] dat_offset;
	wire bypass_writebuffer_we;
	wire [BLK_BITS - 1:0] cache_line;
	assign pma_pmp_exception = pma_exception_i | pmp_exception_i;
	assign valid_req = (((req_i & ~pma_pmp_exception) & ~misaligned_i) & ~pagefault_i) & ~flush_i;
	assign valid_wreq = (((wreq_i & ~pma_pmp_exception) & ~misaligned_i) & ~pagefault_i) & ~flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_hold <= 1'b0;
		else
			invalidate_hold <= invalidate_i | (invalidate_hold & ~invalidate_all_blocks_o);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			clean_hold <= 1'b0;
		else
			clean_hold <= clean_i | (clean_hold & ~(cleaning_o | clean_hold_clr));
	always @(*) begin
		if (_sv2v_0)
			;
		nxt_memfsm_state = memfsm_state;
		nxt_biucmd = biucmd_o;
		fill_way = fill_way_o;
		clean_rdy = 1'b0;
		invalidate_all_blocks = 1'b0;
		invalidate_block = 1'b0;
		clean_block = 1'b0;
		evict_read = 1'b0;
		writebuffer_cleaning = 1'b0;
		(* full_case, parallel_case *)
		case (memfsm_state)
			4'd0:
				if (clean_hold) begin
					if (writebuffer_we_o)
						writebuffer_cleaning = 1'b1;
					else if (cache_dirty_i) begin
						nxt_memfsm_state = 4'd1;
						nxt_biucmd = 2'h0;
						clean_rdy = 1'b0;
					end
					else if (invalidate_hold)
						invalidate_all_blocks = 1'b1;
				end
				else if (invalidate_hold) begin
					if (writebuffer_we_o)
						writebuffer_cleaning = 1'b1;
					else
						invalidate_all_blocks = 1'b1;
				end
				else if ((valid_req && !cacheable_i) && !biucmd_busy_i) begin
					nxt_memfsm_state = 4'd4;
					nxt_biucmd = 2'h0;
				end
				else if (((valid_req && cacheable_i) && !cache_hit_i) && !biucmd_busy_i) begin
					fill_way = fill_way_i;
					if (way_dirty_i || ((writebuffer_we_o && (idx_o == writebuffer_idx_o)) && (fill_way_i == writebuffer_ways_hit_o))) begin
						nxt_memfsm_state = 4'd5;
						nxt_biucmd = 2'h1;
						evict_read = 1'b1;
					end
					else begin
						nxt_memfsm_state = 4'd7;
						nxt_biucmd = 2'h1;
					end
				end
			4'd1: begin
				nxt_memfsm_state = 4'd2;
				nxt_biucmd = 2'h0;
				clean_rdy = 1'b0;
			end
			4'd2: begin
				nxt_memfsm_state = 4'd3;
				nxt_biucmd = 2'h0;
				clean_rdy = 1'b0;
			end
			4'd3: begin
				nxt_memfsm_state = 4'd6;
				nxt_biucmd = 2'h0;
				clean_rdy = 1'b0;
				clean_block = 1'b1;
			end
			4'd6: begin
				nxt_memfsm_state = memfsm_state;
				nxt_biucmd = 2'h2;
				clean_rdy = 1'b0;
				if (biucmd_ack_i) begin
					if (cache_dirty_i) begin
						nxt_memfsm_state = 4'd6;
						nxt_biucmd = 2'h2;
						clean_block = 1'b1;
					end
					else begin
						nxt_memfsm_state = 4'd8;
						nxt_biucmd = 2'h0;
						clean_rdy = 1'b1;
						invalidate_all_blocks = invalidate_hold;
					end
				end
			end
			4'd4:
				if ((flush_i || ((!valid_req && (inflight_cnt_i == 1)) && biu_ack_i)) || ((valid_req && cacheable_i) && biu_ack_i)) begin
					nxt_memfsm_state = 4'd0;
					nxt_biucmd = 2'h0;
				end
			4'd5:
				if (biucmd_ack_i || biu_err_i) begin
					nxt_memfsm_state = 4'd8;
					nxt_biucmd = 2'h2;
				end
				else
					nxt_biucmd = 2'h0;
			4'd7: begin
				nxt_biucmd = 2'h0;
				if (biucmd_ack_i || biu_err_i)
					nxt_memfsm_state = 4'd8;
			end
			4'd8: begin
				nxt_memfsm_state = 4'd9;
				nxt_biucmd = 2'h0;
			end
			4'd9: begin
				nxt_memfsm_state = 4'd0;
				nxt_biucmd = 2'h0;
			end
			default: begin
				nxt_memfsm_state = 4'd1;
				nxt_biucmd = 2'h0;
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			memfsm_state <= 4'd0;
			biucmd_o <= 2'h0;
			armed_o <= 1'b1;
			cleaning_o <= 1'b0;
			invalidate_all_blocks_o <= 1'b0;
			invalidate_block_o <= 1'b0;
			filling_o <= 1'b0;
			fill_way_o <= 'hx;
			clean_hold_clr <= 1'b0;
			clean_rdy_o <= 1'b1;
			evict_read_o <= 1'b0;
			writebuffer_cleaning_o <= 1'b1;
		end
		else begin
			memfsm_state <= nxt_memfsm_state;
			biucmd_o <= nxt_biucmd;
			fill_way_o <= fill_way;
			clean_hold_clr <= 1'b0;
			clean_rdy_o <= (clean_rdy | clean_rdy_o) & ~clean_rdy_clr_i;
			invalidate_all_blocks_o <= invalidate_all_blocks;
			invalidate_block_o <= invalidate_block;
			evict_read_o <= evict_read;
			writebuffer_cleaning_o <= writebuffer_cleaning;
			(* full_case, parallel_case *)
			case (nxt_memfsm_state)
				4'd0: begin
					armed_o <= 1'b1;
					cleaning_o <= 1'b0;
					filling_o <= 1'b0;
					if (clean_hold && !writebuffer_we_o) begin
						if (!cache_dirty_i)
							clean_hold_clr <= 1'b1;
					end
				end
				4'd1: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b1;
					filling_o <= 1'b0;
				end
				4'd2: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b1;
					filling_o <= 1'b0;
				end
				4'd3: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b1;
					filling_o <= 1'b0;
				end
				4'd6: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b1;
					filling_o <= 1'b0;
				end
				4'd4: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b0;
					filling_o <= 1'b0;
				end
				4'd5: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b0;
					filling_o <= 1'b1;
				end
				4'd7: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b0;
					filling_o <= 1'b1;
				end
				4'd8: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b0;
					filling_o <= 1'b0;
				end
				4'd9: begin
					armed_o <= 1'b0;
					cleaning_o <= 1'b0;
					filling_o <= 1'b0;
				end
			endcase
		end
	assign idx_o = adr_i[BLK_OFFS_BITS+:IDX_BITS];
	assign core_tag_o = adr_i[PLEN - 1-:TAG_BITS];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			writebuffer_we_o <= 1'b0;
		else if (flush_i)
			writebuffer_we_o <= 1'b0;
		else if (((valid_req && wreq_i) && cacheable_i) && cache_hit_i)
			writebuffer_we_o <= 1'b1;
		else if (writebuffer_ack_i)
			writebuffer_we_o <= 1'b0;
	always @(posedge clk_i)
		if (((valid_req && wreq_i) && cacheable_i) && cache_hit_i) begin
			writebuffer_idx_o <= adr_i[BLK_OFFS_BITS+:IDX_BITS];
			writebuffer_offs_o <= dat_offset;
			writebuffer_data_o <= d_i;
			writebuffer_be_o <= be_i << ((dat_offset * XLEN) / 8);
			writebuffer_ways_hit_o <= ways_hit_i;
		end
	always @(posedge clk_i) begin
		clean_way_o <= (1 << clean_way_int_i) & {WAYS {clean_block}};
		clean_idx_o <= clean_idx_i;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			4'd0: biucmd_noncacheable_req_o = valid_req & ~cacheable_i;
			4'd4: biucmd_noncacheable_req_o = (valid_req & ~cacheable_i) & biu_ack_i;
			default: biucmd_noncacheable_req_o = 1'b0;
		endcase
	end
	assign biu_adro_eq_cache_adr = biu_adro_i[PLEN - 1:BURST_LSB] == adr_i[PLEN - 1:BURST_LSB];
	assign cache_ack = ((valid_req & cacheable_i) & cache_hit_i) & ~flush_i;
	assign biu_cacheable_ack = (((valid_req & biu_ack_i) & biu_adro_eq_cache_adr) & ~flush_i) | cache_ack;
	reg biu_stb_ack_reg;
	always @(posedge clk_i) biu_stb_ack_reg <= (memfsm_state == 4'd0) && biu_stb_ack_i;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			4'd0: begin
				stall_o = ((clean_hold & ~clean_hold_clr) | (valid_req & ~cacheable_i)) | ((valid_req & cacheable_i) & ~cache_hit_i);
				latchmem_o = ~stall_o;
			end
			4'd4: begin
				stall_o = (~valid_req ? |inflight_cnt_i : cacheable_i | ((~cacheable_i & ~biu_ack_i) & ~biu_stb_ack_reg));
				latchmem_o = ~stall_o;
			end
			4'd7: begin
				stall_o = ~(biu_cacheable_ack | (valid_req & cache_hit_i));
				latchmem_o = ~stall_o;
			end
			4'd5: begin
				stall_o = ~(biu_cacheable_ack | (valid_req & cache_hit_i));
				latchmem_o = ~stall_o;
			end
			4'd8: begin
				stall_o = 1'b1;
				latchmem_o = 1'b0;
			end
			4'd9: begin
				stall_o = 1'b1;
				latchmem_o = 1'b1;
			end
			4'd6: begin
				stall_o = 1'b1;
				latchmem_o = 1'b1;
			end
			default: begin
				stall_o = 1'b1;
				latchmem_o = 1'b1;
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ack_o <= 1'b0;
		else
			(* full_case, parallel_case *)
			case (memfsm_state)
				4'd0: ack_o <= cache_ack;
				4'd4: ack_o <= biucmd_noncacheable_ack_i;
				4'd7: ack_o <= biu_cacheable_ack;
				4'd5: ack_o <= biu_cacheable_ack;
				default: ack_o <= 1'b0;
			endcase
	always @(posedge clk_i) err_o <= biu_err_i | (req_i & pma_pmp_exception);
	always @(posedge clk_i) misaligned_o <= req_i & misaligned_i;
	always @(posedge clk_i) pagefault_o <= req_i & pagefault_i;
	assign bypass_writebuffer_we = (writebuffer_we_o & (idx_o == writebuffer_idx_o)) & (writebuffer_ways_hit_o == ways_hit_i);
	assign dat_offset = adr_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS];
	assign cache_line = be_mux(bypass_writebuffer_we, writebuffer_be_o, (in_biubuffer_i ? biubuffer_i : cache_line_i), {BLK_BITS / XLEN {writebuffer_data_o}});
	assign cache_q = cache_line >> (dat_offset * XLEN);
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (memfsm_state)
			4'd5: q_o <= (cache_hit_i ? cache_q : biu_q_i);
			4'd7: q_o <= (cache_hit_i ? cache_q : biu_q_i);
			default: q_o <= (cacheable_i ? cache_q : biu_q_i);
		endcase
	initial _sv2v_0 = 0;
endmodule
