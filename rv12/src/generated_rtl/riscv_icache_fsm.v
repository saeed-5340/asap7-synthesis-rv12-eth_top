module riscv_icache_fsm (
	rst_ni,
	clk_i,
	stall_o,
	flush_i,
	invalidate_i,
	dc_clean_rdy_i,
	armed_o,
	invalidate_all_blocks_o,
	filling_o,
	fill_way_i,
	fill_way_o,
	req_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	cacheable_i,
	misaligned_i,
	pma_exception_i,
	pmp_exception_i,
	pagefault_i,
	cache_hit_i,
	cache_line_i,
	idx_o,
	core_tag_o,
	biucmd_o,
	biucmd_ack_i,
	biucmd_noncacheable_req_o,
	biucmd_noncacheable_ack_i,
	biucmd_adri_o,
	biucmd_tagi_o,
	inflight_cnt_i,
	biu_q_i,
	biu_stb_ack_i,
	biu_ack_i,
	biu_err_i,
	biu_adro_i,
	biu_tago_i,
	in_biubuffer_i,
	biubuffer_i,
	parcel_o,
	parcel_valid_o,
	parcel_error_o,
	parcel_misaligned_o,
	parcel_pagefault_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	parameter PARCEL_SIZE = XLEN;
	parameter HAS_RVC = 0;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter INFLIGHT_DEPTH = 2;
	parameter BIUTAG_SIZE = $clog2(XLEN / PARCEL_SIZE);
	function automatic integer riscv_cache_pkg_no_of_block_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_bits = 8 * block_size;
	endfunction
	localparam BLK_BITS = riscv_cache_pkg_no_of_block_bits(BLOCK_SIZE);
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
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	input wire rst_ni;
	input wire clk_i;
	output reg stall_o;
	input wire flush_i;
	input wire invalidate_i;
	input wire dc_clean_rdy_i;
	output reg armed_o;
	output reg invalidate_all_blocks_o;
	output reg filling_o;
	input wire [WAYS - 1:0] fill_way_i;
	output reg [WAYS - 1:0] fill_way_o;
	input wire req_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire cacheable_i;
	input wire misaligned_i;
	input wire pma_exception_i;
	input wire pmp_exception_i;
	input wire pagefault_i;
	input wire cache_hit_i;
	input wire [BLK_BITS - 1:0] cache_line_i;
	output wire [IDX_BITS - 1:0] idx_o;
	output wire [TAG_BITS - 1:0] core_tag_o;
	output reg [1:0] biucmd_o;
	input wire biucmd_ack_i;
	output reg biucmd_noncacheable_req_o;
	input wire biucmd_noncacheable_ack_i;
	output wire [PLEN - 1:0] biucmd_adri_o;
	output wire [BIUTAG_SIZE - 1:0] biucmd_tagi_o;
	input wire [INFLIGHT_BITS - 1:0] inflight_cnt_i;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_stb_ack_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	input wire [PLEN - 1:0] biu_adro_i;
	input wire [BIUTAG_SIZE - 1:0] biu_tago_i;
	input wire in_biubuffer_i;
	input wire [BLK_BITS - 1:0] biubuffer_i;
	output reg [XLEN - 1:0] parcel_o;
	output reg [(XLEN / PARCEL_SIZE) - 1:0] parcel_valid_o;
	output wire parcel_error_o;
	output wire parcel_misaligned_o;
	output wire parcel_pagefault_o;
	function automatic integer riscv_cache_pkg_no_of_data_offset_bits;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_no_of_data_offset_bits = $clog2(no_of_block_bits / xlen);
	endfunction
	localparam DAT_OFFS_BITS = riscv_cache_pkg_no_of_data_offset_bits(XLEN, BLK_BITS);
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
	function automatic [XLEN - 1:0] be_mux;
		input [(XLEN / 8) - 1:0] be;
		input [XLEN - 1:0] o;
		input [XLEN - 1:0] n;
		integer i;
		for (i = 0; i < (XLEN / 8); i = i + 1)
			be_mux[i * 8+:8] = (be[i] ? n[i * 8+:8] : o[i * 8+:8]);
	endfunction
	wire [XLEN - 1:0] cache_q;
	wire cache_ack;
	wire biu_cacheable_ack;
	reg invalidate_hold;
	wire pma_pmp_exception;
	wire valid_req;
	reg [2:0] memfsm_state;
	wire [PLEN - 1:0] biu_adro;
	wire biu_adro_eq_cache_adr_dly;
	wire [DAT_OFFS_BITS - 1:0] dat_offset;
	assign pma_pmp_exception = pma_exception_i | pmp_exception_i;
	assign valid_req = (((req_i & ~pma_pmp_exception) & ~misaligned_i) & ~pagefault_i) & ~flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_hold <= 1'b0;
		else
			invalidate_hold <= invalidate_i | (invalidate_hold & ~invalidate_all_blocks_o);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			memfsm_state <= 3'd0;
			armed_o <= 1'b1;
			invalidate_all_blocks_o <= 1'b0;
			filling_o <= 1'b0;
			fill_way_o <= 'hx;
			biucmd_o <= 2'h0;
		end
		else
			(* full_case, parallel_case *)
			case (memfsm_state)
				3'd0:
					if (invalidate_i | invalidate_hold) begin
						memfsm_state <= 3'd1;
						armed_o <= 1'b0;
						invalidate_all_blocks_o <= 1'b1;
					end
					else if (valid_req && !cacheable_i) begin
						memfsm_state <= 3'd2;
						armed_o <= 1'b0;
					end
					else if ((valid_req && cacheable_i) && !cache_hit_i) begin
						memfsm_state <= 3'd3;
						biucmd_o <= 2'h1;
						armed_o <= 1'b0;
						filling_o <= 1'b1;
						fill_way_o <= fill_way_i;
					end
					else
						biucmd_o <= 2'h0;
				3'd1:
					if (dc_clean_rdy_i) begin
						memfsm_state <= 3'd4;
						invalidate_all_blocks_o <= 1'b0;
					end
				3'd2:
					if ((flush_i || ((!valid_req && (inflight_cnt_i == 1)) && biu_ack_i)) || ((valid_req && cacheable_i) && biu_ack_i)) begin
						memfsm_state <= 3'd0;
						armed_o <= 1'b1;
					end
				3'd3: begin
					biucmd_o <= 2'h0;
					if (biucmd_ack_i || biu_err_i) begin
						memfsm_state <= 3'd4;
						filling_o <= 1'b0;
					end
				end
				3'd4: begin
					memfsm_state <= 3'd5;
					biucmd_o <= 2'h0;
				end
				3'd5: begin
					memfsm_state <= 3'd0;
					biucmd_o <= 2'h0;
					armed_o <= 1'b1;
				end
			endcase
	assign idx_o = adr_i[BLK_OFFS_BITS+:IDX_BITS];
	assign core_tag_o = adr_i[PLEN - 1-:TAG_BITS];
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			3'd1: biucmd_noncacheable_req_o = 1'b0;
			3'd3: biucmd_noncacheable_req_o = 1'b0;
			3'd4: biucmd_noncacheable_req_o = 1'b0;
			3'd5: biucmd_noncacheable_req_o = 1'b0;
			default: biucmd_noncacheable_req_o = (valid_req & ~cacheable_i) & ~(invalidate_i | invalidate_hold);
		endcase
	end
	assign biucmd_adri_o = (~cacheable_i ? adr_i & (XLEN == 64 ? ~'h7 : ~'h3) : adr_i);
	assign biucmd_tagi_o = adr_i[1+:BIUTAG_SIZE];
	assign biu_adro = {biu_adro_i[PLEN - 1:BIUTAG_SIZE + 1], biu_tago_i, 1'b0};
	assign biu_adro_eq_cache_adr_dly = biu_adro[PLEN - 1:BURST_LSB] == adr_i[PLEN - 1:BURST_LSB];
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			3'd0: stall_o = (invalidate_i | invalidate_hold) | (valid_req & (cacheable_i ? ~cache_hit_i : ~biu_stb_ack_i));
			3'd2: stall_o = (~valid_req ? |inflight_cnt_i : (cacheable_i ? ~biu_ack_i : ~biu_stb_ack_i));
			3'd3: stall_o = ~(((valid_req & biu_ack_i) & biu_adro_eq_cache_adr_dly) | (valid_req & cache_hit_i));
			3'd4: stall_o = 1'b1;
			3'd5: stall_o = 1'b1;
			3'd1: stall_o = 1'b1;
			default: stall_o = 1'b0;
		endcase
	end
	assign dat_offset = adr_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS];
	assign cache_q = (in_biubuffer_i ? biubuffer_i : cache_line_i) >> (dat_offset * XLEN);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			3'd3: parcel_o = (cache_hit_i ? cache_q : biu_q_i);
			default: parcel_o = (cacheable_i ? cache_q : biu_q_i);
		endcase
	end
	assign cache_ack = ((valid_req & cacheable_i) & cache_hit_i) & ~(invalidate_i | invalidate_hold);
	assign biu_cacheable_ack = ((valid_req & biu_ack_i) & biu_adro_eq_cache_adr_dly) | cache_ack;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (memfsm_state)
			3'd0: parcel_valid_o = {XLEN / PARCEL_SIZE {cache_ack}} << adr_i[1+:$clog2(XLEN / PARCEL_SIZE)];
			3'd2: parcel_valid_o = {XLEN / PARCEL_SIZE {biucmd_noncacheable_ack_i}} << biu_adro[1+:$clog2(XLEN / PARCEL_SIZE)];
			3'd3: parcel_valid_o = {XLEN / PARCEL_SIZE {biu_cacheable_ack}} << adr_i[1+:$clog2(XLEN / PARCEL_SIZE)];
			default: parcel_valid_o = {XLEN / PARCEL_SIZE {1'b0}};
		endcase
	end
	assign parcel_error_o = biu_err_i | (req_i & pma_pmp_exception);
	assign parcel_misaligned_o = req_i & misaligned_i;
	assign parcel_pagefault_o = req_i & pagefault_i;
	initial _sv2v_0 = 0;
endmodule
