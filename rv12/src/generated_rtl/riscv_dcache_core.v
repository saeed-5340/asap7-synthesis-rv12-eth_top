module riscv_dcache_core (
	rst_ni,
	clk_i,
	stall_o,
	phys_adr_i,
	pagefault_i,
	pma_misaligned_i,
	pma_cacheable_i,
	pma_exception_i,
	pmp_exception_i,
	mem_flush_i,
	mem_req_i,
	mem_ack_o,
	mem_err_o,
	mem_misaligned_o,
	mem_pagefault_o,
	mem_adr_i,
	mem_size_i,
	mem_lock_i,
	mem_prot_i,
	mem_we_i,
	mem_d_i,
	mem_q_o,
	invalidate_i,
	clean_i,
	clean_rdy_clr_i,
	clean_rdy_o,
	biu_stb_o,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_prot_o,
	biu_we_o,
	biu_d_o,
	biu_q_i,
	biu_ack_i,
	biu_err_i,
	biu_tagi_o,
	biu_tago_i
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter REPLACE_ALG = 0;
	parameter TECHNOLOGY = "GENERIC";
	parameter DEPTH = 2;
	parameter BIUTAG_SIZE = 2;
	input wire rst_ni;
	input wire clk_i;
	output wire stall_o;
	input wire [PLEN - 1:0] phys_adr_i;
	input wire pagefault_i;
	input wire pma_misaligned_i;
	input wire pma_cacheable_i;
	input wire pma_exception_i;
	input wire pmp_exception_i;
	input wire mem_flush_i;
	input wire mem_req_i;
	output wire mem_ack_o;
	output wire mem_err_o;
	output wire mem_misaligned_o;
	output wire mem_pagefault_o;
	input wire [XLEN - 1:0] mem_adr_i;
	input wire [2:0] mem_size_i;
	input wire mem_lock_i;
	input wire [2:0] mem_prot_i;
	input wire mem_we_i;
	input wire [XLEN - 1:0] mem_d_i;
	output wire [XLEN - 1:0] mem_q_o;
	input wire invalidate_i;
	input wire clean_i;
	input wire clean_rdy_clr_i;
	output wire clean_rdy_o;
	output wire biu_stb_o;
	input wire biu_stb_ack_i;
	input wire biu_d_ack_i;
	output wire [PLEN - 1:0] biu_adri_o;
	input wire [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire [2:0] biu_prot_o;
	output wire biu_we_o;
	output wire [XLEN - 1:0] biu_d_o;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input wire [BIUTAG_SIZE - 1:0] biu_tago_i;
	localparam PAGE_SIZE = 4096;
	localparam MAX_IDX_BITS = 12 - $clog2(BLOCK_SIZE);
	localparam SETS = ((SIZE * 1024) / BLOCK_SIZE) / WAYS;
	localparam BLK_OFFS_BITS = $clog2(BLOCK_SIZE);
	localparam IDX_BITS = $clog2(SETS);
	localparam TAG_BITS = (PLEN - IDX_BITS) - BLK_OFFS_BITS;
	localparam BLK_BITS = 8 * BLOCK_SIZE;
	localparam BURST_SIZE = BLK_BITS / XLEN;
	localparam BURST_BITS = $clog2(BURST_SIZE);
	localparam BURST_OFFS = XLEN / 8;
	localparam BURST_LSB = $clog2(BURST_OFFS);
	localparam DAT_OFFS_BITS = $clog2(BLK_BITS / XLEN);
	localparam INFLIGHT_DEPTH = BURST_SIZE;
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	reg [6:0] way_random;
	wire [WAYS - 1:0] fill_way_select;
	wire [WAYS - 1:0] mem_fill_way;
	wire [WAYS - 1:0] hit_fill_way;
	wire setup_req;
	wire tag_req;
	wire setup_rreq;
	wire tag_wreq;
	wire [PLEN - 1:0] tag_adr;
	wire [2:0] setup_size;
	wire [2:0] tag_size;
	wire setup_lock;
	wire tag_lock;
	wire [2:0] setup_prot;
	wire [2:0] tag_prot;
	wire setup_we;
	wire tag_we;
	wire [XLEN - 1:0] setup_q;
	wire [XLEN - 1:0] tag_q;
	wire setup_invalidate;
	wire tag_invalidate;
	wire setup_clean;
	wire tag_clean;
	wire tag_pagefault;
	wire [(XLEN / 8) - 1:0] tag_be;
	wire writebuffer_we;
	wire [IDX_BITS - 1:0] writebuffer_idx;
	wire [DAT_OFFS_BITS - 1:0] writebuffer_offs;
	wire [XLEN - 1:0] writebuffer_data;
	wire [(BLK_BITS / 8) - 1:0] writebuffer_be;
	wire [WAYS - 1:0] writebuffer_ways_hit;
	wire writebuffer_cleaning;
	wire [TAG_BITS - 1:0] tag_core_tag;
	wire [TAG_BITS - 1:0] hit_core_tag;
	wire [IDX_BITS - 1:0] setup_idx;
	wire [IDX_BITS - 1:0] hit_idx;
	wire [(BLK_BITS / 8) - 1:0] dat_be;
	wire cache_hit;
	wire cache_dirty;
	wire way_dirty;
	wire [WAYS - 1:0] ways_hit;
	wire [WAYS - 1:0] ways_dirty;
	wire [BLK_BITS - 1:0] cache_line;
	wire evict_read;
	wire [PLEN - 1:0] evict_adr;
	wire [BLK_BITS - 1:0] evict_line;
	wire [$clog2(WAYS) - 1:0] mem_clean_way_int;
	wire [IDX_BITS - 1:0] mem_clean_idx;
	wire [WAYS - 1:0] hit_clean_way;
	wire [IDX_BITS - 1:0] hit_clean_idx;
	wire [INFLIGHT_BITS - 1:0] inflight_cnt;
	wire [1:0] biucmd;
	wire biucmd_ack;
	wire biucmd_busy;
	wire biucmd_noncacheable_req;
	wire biucmd_noncacheable_ack;
	wire [BLK_BITS - 1:0] biubuffer;
	wire in_biubuffer;
	wire [BLK_BITS - 1:0] biu_line;
	wire biu_line_dirty;
	wire hit_latchmem;
	wire armed;
	wire filling;
	wire cleaning;
	wire invalidate_block;
	wire invalidate_all_blocks;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			way_random <= 'h0;
		else if (!filling)
			way_random <= {way_random, way_random[6] ~^ way_random[5]};
	generate
		if (WAYS == 1) begin : genblk1
			assign fill_way_select = 1;
		end
		else begin : genblk1
			assign fill_way_select = 1 << way_random[$clog2(WAYS) - 1:0];
		end
	endgenerate
	riscv_cache_setup #(
		.XLEN(XLEN),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS)
	) cache_setup_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.stall_i(stall_o),
		.flush_i(mem_flush_i),
		.req_i(mem_req_i),
		.adr_i(mem_adr_i),
		.size_i(mem_size_i),
		.lock_i(mem_lock_i),
		.prot_i(mem_prot_i),
		.we_i(mem_we_i),
		.d_i(mem_d_i),
		.invalidate_i(invalidate_i),
		.clean_i(clean_i),
		.req_o(setup_req),
		.rreq_o(setup_rreq),
		.size_o(setup_size),
		.lock_o(setup_lock),
		.prot_o(setup_prot),
		.we_o(setup_we),
		.q_o(setup_q),
		.invalidate_o(setup_invalidate),
		.clean_o(setup_clean),
		.idx_o(setup_idx)
	);
	riscv_cache_tag #(
		.XLEN(XLEN),
		.PLEN(PLEN),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS)
	) cache_tag_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.stall_i(stall_o),
		.flush_i(mem_flush_i),
		.req_i(setup_req),
		.phys_adr_i(phys_adr_i),
		.size_i(setup_size),
		.lock_i(setup_lock),
		.prot_i(setup_prot),
		.we_i(setup_we),
		.d_i(setup_q),
		.invalidate_i(setup_invalidate),
		.clean_i(setup_clean),
		.pagefault_i(pagefault_i),
		.invalidate_all_blocks_i(invalidate_all_blocks),
		.req_o(tag_req),
		.wreq_o(tag_wreq),
		.adr_o(tag_adr),
		.size_o(tag_size),
		.lock_o(tag_lock),
		.prot_o(tag_prot),
		.we_o(tag_we),
		.be_o(tag_be),
		.q_o(tag_q),
		.invalidate_o(tag_invalidate),
		.clean_o(tag_clean),
		.pagefault_o(tag_pagefault),
		.core_tag_o(tag_core_tag)
	);
	riscv_dcache_fsm #(
		.XLEN(XLEN),
		.PLEN(PLEN),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS),
		.INFLIGHT_DEPTH(INFLIGHT_DEPTH)
	) cache_fsm_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.stall_o(stall_o),
		.flush_i(mem_flush_i),
		.invalidate_i(tag_invalidate),
		.clean_i(tag_clean),
		.clean_rdy_clr_i(clean_rdy_clr_i),
		.clean_rdy_o(clean_rdy_o),
		.armed_o(armed),
		.cleaning_o(cleaning),
		.invalidate_block_o(invalidate_block),
		.invalidate_all_blocks_o(invalidate_all_blocks),
		.filling_o(filling),
		.fill_way_i(mem_fill_way),
		.fill_way_o(hit_fill_way),
		.clean_way_int_i(mem_clean_way_int),
		.clean_idx_i(mem_clean_idx),
		.clean_way_o(hit_clean_way),
		.clean_idx_o(hit_clean_idx),
		.cacheable_i(pma_cacheable_i),
		.misaligned_i(pma_misaligned_i),
		.pma_exception_i(pma_exception_i),
		.pmp_exception_i(pmp_exception_i),
		.pagefault_i(tag_pagefault),
		.req_i(tag_req),
		.wreq_i(tag_wreq),
		.adr_i(tag_adr),
		.size_i(tag_size),
		.lock_i(tag_lock),
		.prot_i(tag_prot),
		.we_i(tag_we),
		.be_i(tag_be),
		.d_i(tag_q),
		.q_o(mem_q_o),
		.ack_o(mem_ack_o),
		.err_o(mem_err_o),
		.misaligned_o(mem_misaligned_o),
		.pagefault_o(mem_pagefault_o),
		.latchmem_o(hit_latchmem),
		.idx_o(hit_idx),
		.core_tag_o(hit_core_tag),
		.cache_hit_i(cache_hit),
		.ways_hit_i(ways_hit),
		.cache_line_i(cache_line),
		.cache_dirty_i(cache_dirty),
		.way_dirty_i(way_dirty),
		.writebuffer_we_o(writebuffer_we),
		.writebuffer_ack_i(~setup_rreq),
		.writebuffer_idx_o(writebuffer_idx),
		.writebuffer_offs_o(writebuffer_offs),
		.writebuffer_data_o(writebuffer_data),
		.writebuffer_be_o(writebuffer_be),
		.writebuffer_ways_hit_o(writebuffer_ways_hit),
		.writebuffer_cleaning_o(writebuffer_cleaning),
		.evict_read_o(evict_read),
		.biucmd_o(biucmd),
		.biucmd_ack_i(biucmd_ack),
		.biucmd_busy_i(biucmd_busy),
		.biucmd_noncacheable_req_o(biucmd_noncacheable_req),
		.biucmd_noncacheable_ack_i(biucmd_noncacheable_ack),
		.inflight_cnt_i(inflight_cnt),
		.biu_stb_ack_i(biu_stb_ack_i),
		.biu_ack_i(biu_ack_i),
		.biu_err_i(biu_err_i),
		.biu_adro_i(biu_adro_i),
		.biu_q_i(biu_q_i),
		.in_biubuffer_i(in_biubuffer),
		.biubuffer_i(biubuffer)
	);
	riscv_cache_memory #(
		.XLEN(XLEN),
		.PLEN(PLEN),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS),
		.TECHNOLOGY(TECHNOLOGY)
	) cache_memory_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.stall_i(stall_o),
		.armed_i(armed),
		.cleaning_i(cleaning),
		.invalidate_block_i(1'b0),
		.invalidate_all_blocks_i(invalidate_all_blocks),
		.filling_i(filling),
		.fill_way_select_i(fill_way_select),
		.fill_way_i(hit_fill_way),
		.fill_way_o(mem_fill_way),
		.clean_way_int_o(mem_clean_way_int),
		.clean_idx_o(mem_clean_idx),
		.clean_way_i(hit_clean_way),
		.clean_idx_i(hit_clean_idx),
		.rd_core_tag_i(tag_core_tag),
		.wr_core_tag_i(hit_core_tag),
		.rd_idx_i(setup_idx),
		.wr_idx_i(hit_idx),
		.rreq_i(setup_rreq),
		.writebuffer_we_i(writebuffer_we),
		.writebuffer_be_i(writebuffer_be),
		.writebuffer_idx_i(writebuffer_idx),
		.writebuffer_offs_i(writebuffer_offs),
		.writebuffer_data_i(writebuffer_data),
		.writebuffer_ways_hit_i(writebuffer_ways_hit),
		.writebuffer_cleaning_i(writebuffer_cleaning),
		.evict_read_i(evict_read),
		.evict_adr_o(evict_adr),
		.evict_line_o(evict_line),
		.biu_line_i(biu_line),
		.biu_line_dirty_i(biu_line_dirty),
		.biucmd_ack_i(biucmd_ack),
		.latchmem_i(hit_latchmem),
		.hit_o(cache_hit),
		.ways_hit_o(ways_hit),
		.cache_dirty_o(cache_dirty),
		.way_dirty_o(way_dirty),
		.ways_dirty_o(),
		.cache_line_o(cache_line)
	);
	riscv_cache_biu_ctrl #(
		.XLEN(XLEN),
		.PLEN(PLEN),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS),
		.INFLIGHT_DEPTH(INFLIGHT_DEPTH),
		.BIUTAG_SIZE(BIUTAG_SIZE)
	) biu_ctrl_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.flush_i(mem_flush_i),
		.biucmd_i(biucmd),
		.biucmd_ack_o(biucmd_ack),
		.biucmd_busy_o(biucmd_busy),
		.biucmd_noncacheable_req_i(biucmd_noncacheable_req),
		.biucmd_noncacheable_ack_o(biucmd_noncacheable_ack),
		.biucmd_tag_i({BIUTAG_SIZE {1'b0}}),
		.inflight_cnt_o(inflight_cnt),
		.req_i(tag_req),
		.adr_i(tag_adr),
		.size_i(tag_size),
		.prot_i(tag_prot),
		.lock_i(tag_lock),
		.we_i(tag_we),
		.be_i(tag_be),
		.d_i(tag_q),
		.biubuffer_o(biubuffer),
		.in_biubuffer_o(in_biubuffer),
		.biu_line_o(biu_line),
		.biu_line_dirty_o(biu_line_dirty),
		.evictbuffer_adr_i(evict_adr),
		.evictbuffer_d_i(evict_line),
		.biu_stb_o(biu_stb_o),
		.biu_stb_ack_i(biu_stb_ack_i),
		.biu_d_ack_i(biu_d_ack_i),
		.biu_adri_o(biu_adri_o),
		.biu_adro_i(biu_adro_i),
		.biu_size_o(biu_size_o),
		.biu_type_o(biu_type_o),
		.biu_lock_o(biu_lock_o),
		.biu_prot_o(biu_prot_o),
		.biu_we_o(biu_we_o),
		.biu_d_o(biu_d_o),
		.biu_q_i(biu_q_i),
		.biu_ack_i(biu_ack_i),
		.biu_err_i(biu_err_i),
		.biu_tagi_o(biu_tagi_o),
		.biu_tago_i(biu_tago_i)
	);
endmodule
