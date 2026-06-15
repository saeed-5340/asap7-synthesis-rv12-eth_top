module riscv_cache_memory (
	rst_ni,
	clk_i,
	stall_i,
	armed_i,
	cleaning_i,
	invalidate_block_i,
	invalidate_all_blocks_i,
	filling_i,
	fill_way_select_i,
	fill_way_i,
	fill_way_o,
	clean_way_int_o,
	clean_idx_o,
	clean_way_i,
	clean_idx_i,
	rd_core_tag_i,
	wr_core_tag_i,
	rd_idx_i,
	wr_idx_i,
	rreq_i,
	writebuffer_we_i,
	writebuffer_be_i,
	writebuffer_idx_i,
	writebuffer_offs_i,
	writebuffer_data_i,
	writebuffer_ways_hit_i,
	writebuffer_cleaning_i,
	biu_line_i,
	biu_line_dirty_i,
	biucmd_ack_i,
	evict_read_i,
	evict_adr_o,
	evict_line_o,
	latchmem_i,
	hit_o,
	ways_hit_o,
	cache_dirty_o,
	ways_dirty_o,
	way_dirty_o,
	cache_line_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	parameter SIZE = 4;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter TECHNOLOGY = "GENERIC";
	function automatic integer riscv_cache_pkg_no_of_sets;
		input integer cache_size;
		input integer block_size;
		input integer ways;
		riscv_cache_pkg_no_of_sets = ((cache_size * 1024) / block_size) / ways;
	endfunction
	localparam SETS = riscv_cache_pkg_no_of_sets(SIZE, BLOCK_SIZE, WAYS);
	function automatic integer riscv_cache_pkg_no_of_index_bits;
		input integer no_of_sets;
		riscv_cache_pkg_no_of_index_bits = $clog2(no_of_sets);
	endfunction
	localparam IDX_BITS = riscv_cache_pkg_no_of_index_bits(SETS);
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
	input wire armed_i;
	input wire cleaning_i;
	input wire invalidate_block_i;
	input wire invalidate_all_blocks_i;
	input wire filling_i;
	input wire [WAYS - 1:0] fill_way_select_i;
	input wire [WAYS - 1:0] fill_way_i;
	output reg [WAYS - 1:0] fill_way_o;
	output reg [$clog2(WAYS) - 1:0] clean_way_int_o;
	output reg [IDX_BITS - 1:0] clean_idx_o;
	input wire [WAYS - 1:0] clean_way_i;
	input wire [IDX_BITS - 1:0] clean_idx_i;
	input wire [TAG_BITS - 1:0] rd_core_tag_i;
	input wire [TAG_BITS - 1:0] wr_core_tag_i;
	input wire [IDX_BITS - 1:0] rd_idx_i;
	input wire [IDX_BITS - 1:0] wr_idx_i;
	input wire rreq_i;
	input wire writebuffer_we_i;
	input wire [(BLK_BITS / 8) - 1:0] writebuffer_be_i;
	input wire [IDX_BITS - 1:0] writebuffer_idx_i;
	input wire [DAT_OFFS_BITS - 1:0] writebuffer_offs_i;
	input wire [XLEN - 1:0] writebuffer_data_i;
	input wire [WAYS - 1:0] writebuffer_ways_hit_i;
	input wire writebuffer_cleaning_i;
	input wire [BLK_BITS - 1:0] biu_line_i;
	input wire biu_line_dirty_i;
	input wire biucmd_ack_i;
	input wire evict_read_i;
	output wire [PLEN - 1:0] evict_adr_o;
	output reg [BLK_BITS - 1:0] evict_line_o;
	input wire latchmem_i;
	output reg hit_o;
	output reg [WAYS - 1:0] ways_hit_o;
	output reg cache_dirty_o;
	output reg [WAYS - 1:0] ways_dirty_o;
	output reg way_dirty_o;
	output reg [BLK_BITS - 1:0] cache_line_o;
	function automatic signed [31:0] onehot2int;
		input [WAYS - 1:0] a;
		integer i;
		begin
			onehot2int = 0;
			for (i = 0; i < WAYS; i = i + 1)
				if (a[i])
					onehot2int = i;
		end
	endfunction
	function automatic [BLK_BITS - 1:0] be_mux;
		input ena;
		input [(BLK_BITS / 8) - 1:0] be;
		input [BLK_BITS - 1:0] data_old;
		input [BLK_BITS - 1:0] data_new;
		reg signed [31:0] i;
		for (i = 0; i < (BLK_BITS / 8); i = i + 1)
			be_mux[i * 8+:8] = (ena && be[i] ? data_new[i * 8+:8] : data_old[i * 8+:8]);
	endfunction
	function automatic signed [31:0] first_dirty_way;
		input [(WAYS * SETS) - 1:0] valid;
		input [(WAYS * SETS) - 1:0] dirty;
		reg [(WAYS * SETS) - 1:0] valid_vect;
		reg [(WAYS * SETS) - 1:0] dirty_vect;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			valid_vect = valid;
			dirty_vect = dirty;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				begin : sv2v_autoblock_2
					reg signed [31:0] _sv2v_value_on_break;
					for (n = 0; n < (WAYS * SETS); n = n + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (valid_vect[n] && dirty_vect[n]) begin
								first_dirty_way = n;
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = n;
						end
					if (!(_sv2v_jump < 2'b10))
						n = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
		end
	endfunction
	genvar _gv_way_2;
	wire biumem_we;
	wire writebuffer_we;
	reg we_dly;
	reg [WAYS - 1:0] fill_way_select_dly;
	reg [$clog2(WAYS) - 1:0] fill_way_select_int_dly;
	reg [$clog2(WAYS) - 1:0] clean_way_int_dly;
	reg [$clog2(WAYS) - 1:0] evict_way_select_int;
	reg [IDX_BITS - 1:0] rd_idx_dly;
	reg [IDX_BITS - 1:0] filling_idx;
	wire [IDX_BITS - 1:0] clean_idx;
	reg [IDX_BITS - 1:0] clean_idx_dly;
	reg [TAG_BITS - 1:0] rd_core_tag_dly;
	reg [TAG_BITS - 1:0] filling_tag;
	wire bypass_biumem_we;
	reg [WAYS - 1:0] bypass_writebuffer_we;
	reg [IDX_BITS - 1:0] tag_idx;
	wire [(2 + TAG_BITS) - 1:0] tag_in [0:WAYS - 1];
	wire [(2 + TAG_BITS) - 1:0] tag_out [0:WAYS - 1];
	wire [WAYS - 1:0] tag_we;
	wire [WAYS - 1:0] tag_we_dirty;
	reg [TAG_BITS - 1:0] tag_byp_tag;
	reg [(WAYS * SETS) - 1:0] tag_valid;
	reg [(WAYS * SETS) - 1:0] tag_dirty;
	wire [WAYS - 1:0] way_hit;
	wire [WAYS - 1:0] way_dirty;
	reg [IDX_BITS - 1:0] dat_idx;
	wire [BLK_BITS - 1:0] dat_in;
	wire [WAYS - 1:0] dat_we;
	wire [(BLK_BITS / 8) - 1:0] dat_be;
	wire [BLK_BITS - 1:0] dat_out [0:WAYS - 1];
	wire [BLK_BITS - 1:0] dat_out_bypassed [0:WAYS - 1];
	wire [BLK_BITS - 1:0] way_q_mux [0:WAYS - 1];
	reg evict_latch;
	reg [TAG_BITS - 1:0] evict_tag;
	reg [IDX_BITS - 1:0] evict_idx;
	assign biumem_we = filling_i & biucmd_ack_i;
	assign writebuffer_we = (~rreq_i | writebuffer_cleaning_i) & writebuffer_we_i;
	always @(posedge clk_i) we_dly <= biumem_we;
	always @(posedge clk_i) begin
		rd_idx_dly <= rd_idx_i;
		rd_core_tag_dly <= rd_core_tag_i;
	end
	always @(posedge clk_i)
		if (!filling_i) begin
			filling_idx <= wr_idx_i;
			filling_tag <= wr_core_tag_i;
		end
	always @(posedge clk_i) begin
		evict_latch <= evict_read_i;
		evict_way_select_int <= onehot2int(fill_way_i);
	end
	always @(posedge clk_i) begin
		clean_idx_o <= first_dirty_way(tag_valid, tag_dirty) % SETS;
		clean_way_int_o <= first_dirty_way(tag_valid, tag_dirty) / SETS;
		clean_idx_dly <= clean_idx_i;
		clean_way_int_dly <= onehot2int(clean_way_i);
	end
	always @(posedge clk_i) begin
		fill_way_select_dly <= fill_way_select_i;
		fill_way_select_int_dly <= onehot2int(fill_way_select_i);
	end
	assign bypass_biumem_we = (biumem_we & (rd_idx_dly == filling_idx)) & (rd_core_tag_dly == filling_tag);
	always @(*) begin : sv2v_autoblock_3
		reg signed [31:0] n;
		if (_sv2v_0)
			;
		for (n = 0; n < WAYS; n = n + 1)
			bypass_writebuffer_we[n] = (writebuffer_we_i & (rd_idx_dly == writebuffer_idx_i)) & writebuffer_ways_hit_i[n];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex ({cleaning_i, evict_read_i, biumem_we})
			3'b1zz: tag_idx = clean_idx_i;
			3'bz1z: tag_idx = filling_idx;
			3'bzz1: tag_idx = filling_idx;
			default: tag_idx = rd_idx_i;
		endcase
	end
	always @(posedge clk_i)
		if (biumem_we)
			tag_byp_tag <= wr_core_tag_i;
	generate
		for (_gv_way_2 = 0; _gv_way_2 < WAYS; _gv_way_2 = _gv_way_2 + 1) begin : gen_ways_tag
			localparam way = _gv_way_2;
			rl_ram_1rw #(
				.ABITS(IDX_BITS),
				.DBITS(TAG_BITS),
				.TECHNOLOGY(TECHNOLOGY)
			) tag_ram(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.addr_i(tag_idx),
				.we_i(tag_we[way]),
				.be_i({(TAG_BITS + 7) / 8 {1'b1}}),
				.din_i(tag_in[way][TAG_BITS - 1-:TAG_BITS]),
				.dout_o(tag_out[way][TAG_BITS - 1-:TAG_BITS])
			);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					tag_valid[way * SETS+:SETS] <= 'h0;
				else if (invalidate_all_blocks_i)
					tag_valid[way * SETS+:SETS] <= 'h0;
				else if (invalidate_block_i)
					tag_valid[(way * SETS) + tag_idx] <= 1'b0;
				else if (tag_we[way])
					tag_valid[(way * SETS) + tag_idx] <= tag_in[way][TAG_BITS + 1];
			assign tag_out[way][TAG_BITS + 1] = tag_valid[(way * SETS) + rd_idx_dly];
			assign way_hit[way] = (tag_out[way][TAG_BITS + 1] & (rd_core_tag_i == tag_out[way][TAG_BITS - 1-:TAG_BITS])) & ~((filling_i & fill_way_i[way]) & ~rreq_i);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					tag_dirty[way * SETS+:SETS] <= 'h0;
				else if (clean_way_i[way])
					tag_dirty[(way * SETS) + clean_idx_i] <= 1'b0;
				else if (tag_we_dirty[way])
					tag_dirty[(way * SETS) + dat_idx] <= tag_in[way][TAG_BITS + 0];
			assign tag_out[way][TAG_BITS + 0] = tag_dirty[(way * SETS) + rd_idx_dly];
			assign way_dirty[way] = (tag_out[way][TAG_BITS + 1] & tag_out[way][TAG_BITS + 0]) | (bypass_writebuffer_we[way] & writebuffer_ways_hit_i[way]);
			assign tag_we[way] = biumem_we & fill_way_i[way];
			assign tag_we_dirty[way] = (biumem_we & fill_way_i[way]) | (writebuffer_we & writebuffer_ways_hit_i[way]);
			assign tag_in[way][TAG_BITS + 1] = 1'b1;
			assign tag_in[way][TAG_BITS + 0] = (biumem_we ? biu_line_dirty_i : writebuffer_we_i);
			assign tag_in[way][TAG_BITS - 1-:TAG_BITS] = filling_tag;
		end
	endgenerate
	always @(posedge clk_i)
		if (invalidate_all_blocks_i)
			hit_o <= 1'b0;
		else if (bypass_biumem_we)
			hit_o <= 1'b1;
		else if (latchmem_i)
			hit_o <= |way_hit & ~we_dly;
	always @(posedge clk_i)
		if (bypass_biumem_we)
			ways_hit_o <= fill_way_i;
		else if (latchmem_i)
			ways_hit_o <= way_hit;
	always @(posedge clk_i)
		if (bypass_biumem_we)
			cache_dirty_o <= biu_line_dirty_i;
		else if (latchmem_i)
			cache_dirty_o <= |(tag_valid & tag_dirty);
	always @(posedge clk_i)
		if (bypass_biumem_we)
			ways_dirty_o <= {WAYS {biu_line_dirty_i}} & fill_way_i;
		else if (latchmem_i)
			ways_dirty_o <= way_dirty;
	always @(posedge clk_i)
		if (bypass_biumem_we)
			way_dirty_o <= biu_line_dirty_i;
		else if (latchmem_i)
			way_dirty_o <= way_dirty[fill_way_select_int_dly];
	always @(posedge clk_i)
		if (latchmem_i)
			fill_way_o <= fill_way_select_dly;
	always @(posedge clk_i)
		if (cleaning_i)
			evict_tag <= tag_out[clean_way_int_o][TAG_BITS - 1-:TAG_BITS];
		else if (evict_latch)
			evict_tag <= tag_out[evict_way_select_int][TAG_BITS - 1-:TAG_BITS];
	always @(posedge clk_i)
		if (cleaning_i)
			evict_idx <= clean_idx_dly;
		else if (evict_latch)
			evict_idx <= filling_idx;
	assign evict_adr_o = {evict_tag, evict_idx, {BLK_OFFS_BITS {1'b0}}};
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex ({cleaning_i, evict_read_i, biumem_we, writebuffer_we})
			4'b1zzz: dat_idx = clean_idx_i;
			4'bz1zz: dat_idx = filling_idx;
			4'bzz1z: dat_idx = filling_idx;
			4'bzzz1: dat_idx = writebuffer_idx_i;
			default: dat_idx = rd_idx_i;
		endcase
	end
	assign dat_in = (writebuffer_we ? {BLK_BITS / XLEN {writebuffer_data_i}} : biu_line_i);
	assign dat_be = (writebuffer_we ? writebuffer_be_i : {BLK_BITS / 8 {1'b1}});
	generate
		for (_gv_way_2 = 0; _gv_way_2 < WAYS; _gv_way_2 = _gv_way_2 + 1) begin : gen_ways_dat
			localparam way = _gv_way_2;
			rl_ram_1rw #(
				.ABITS(IDX_BITS),
				.DBITS(BLK_BITS),
				.TECHNOLOGY(TECHNOLOGY)
			) data_ram(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.addr_i(dat_idx),
				.we_i(dat_we[way]),
				.be_i(dat_be),
				.din_i(dat_in),
				.dout_o(dat_out[way])
			);
			assign dat_we[way] = (biumem_we & fill_way_i[way]) | (writebuffer_we & writebuffer_ways_hit_i[way]);
			assign dat_out_bypassed[way] = be_mux(bypass_writebuffer_we[way], writebuffer_be_i, dat_out[way], {BLK_BITS / XLEN {writebuffer_data_i}});
			if (way == 0) begin : genblk1
				assign way_q_mux[way] = dat_out_bypassed[way] & {BLK_BITS {way_hit[way]}};
			end
			else begin : genblk1
				assign way_q_mux[way] = (dat_out_bypassed[way] & {BLK_BITS {way_hit[way]}}) | way_q_mux[way - 1];
			end
		end
	endgenerate
	always @(posedge clk_i)
		if (bypass_biumem_we)
			cache_line_o <= biu_line_i;
		else if (latchmem_i)
			cache_line_o <= way_q_mux[WAYS - 1];
	always @(posedge clk_i)
		if (cleaning_i)
			evict_line_o <= dat_out_bypassed[clean_way_int_o];
		else if (evict_latch)
			evict_line_o <= dat_out_bypassed[evict_way_select_int];
	initial _sv2v_0 = 0;
endmodule
