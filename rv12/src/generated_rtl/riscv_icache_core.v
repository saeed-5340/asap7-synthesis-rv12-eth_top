module riscv_icache_core (
	rst_ni,
	clk_i,
	phys_adr_i,
	pagefault_i,
	pma_cacheable_i,
	pma_misaligned_i,
	pma_exception_i,
	pmp_exception_i,
	mem_flush_i,
	mem_req_i,
	mem_stall_o,
	mem_adr_i,
	mem_size_i,
	mem_lock_i,
	mem_prot_i,
	parcel_o,
	parcel_valid_o,
	parcel_error_o,
	parcel_misaligned_o,
	parcel_pagefault_o,
	invalidate_i,
	dc_clean_rdy_i,
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
	parameter signed [31:0] XLEN = 32;
	parameter signed [31:0] PLEN = XLEN;
	parameter signed [31:0] PARCEL_SIZE = XLEN;
	parameter signed [31:0] HAS_RVC = 0;
	parameter signed [31:0] SIZE = 64;
	parameter signed [31:0] BLOCK_SIZE = XLEN;
	parameter signed [31:0] WAYS = 2;
	parameter signed [31:0] REPLACE_ALG = 0;
	parameter TECHNOLOGY = "GENERIC";
	parameter signed [31:0] DEPTH = 2;
	parameter signed [31:0] BIUTAG_SIZE = $clog2(XLEN / PARCEL_SIZE);
	input wire rst_ni;
	input wire clk_i;
	input wire [PLEN - 1:0] phys_adr_i;
	input wire pagefault_i;
	input wire pma_cacheable_i;
	input wire pma_misaligned_i;
	input wire pma_exception_i;
	input wire pmp_exception_i;
	input wire mem_flush_i;
	input wire mem_req_i;
	output wire mem_stall_o;
	input wire [XLEN - 1:0] mem_adr_i;
	input wire [2:0] mem_size_i;
	input mem_lock_i;
	input wire [2:0] mem_prot_i;
	output wire [XLEN - 1:0] parcel_o;
	output wire [(XLEN / PARCEL_SIZE) - 1:0] parcel_valid_o;
	output wire parcel_error_o;
	output wire parcel_misaligned_o;
	output wire parcel_pagefault_o;
	input wire invalidate_i;
	input wire dc_clean_rdy_i;
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
	localparam PARCEL_OFFS_BITS = $clog2(XLEN / PARCEL_SIZE);
	localparam INFLIGHT_DEPTH = BURST_SIZE;
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	reg [6:0] way_random;
	wire [WAYS - 1:0] fill_way_select;
	wire [WAYS - 1:0] mem_fill_way;
	wire [WAYS - 1:0] hit_fill_way;
	wire setup_req;
	wire tag_req;
	wire [PLEN - 1:0] tag_adr;
	wire [2:0] setup_size;
	wire [2:0] tag_size;
	wire setup_lock;
	wire tag_lock;
	wire [2:0] setup_prot;
	wire [2:0] tag_prot;
	wire setup_invalidate;
	wire tag_invalidate;
	wire tag_pagefault;
	wire [TAG_BITS - 1:0] tag_core_tag;
	wire [TAG_BITS - 1:0] hit_core_tag;
	wire [IDX_BITS - 1:0] setup_idx;
	wire [IDX_BITS - 1:0] hit_idx;
	wire cache_hit;
	wire [BLK_BITS - 1:0] cache_line;
	wire [INFLIGHT_BITS - 1:0] inflight_cnt;
	wire [1:0] biucmd;
	wire biucmd_ack;
	wire biucmd_noncacheable_req;
	wire biucmd_noncacheable_ack;
	wire [PLEN - 1:0] biucmd_adr;
	wire [BIUTAG_SIZE - 1:0] biucmd_tag;
	wire [BLK_BITS - 1:0] biubuffer;
	wire in_biubuffer;
	wire [BLK_BITS - 1:0] biu_line;
	wire armed;
	wire filling;
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
		.stall_i(mem_stall_o),
		.flush_i(mem_flush_i),
		.req_i(mem_req_i),
		.adr_i(mem_adr_i),
		.size_i(mem_size_i),
		.lock_i(mem_lock_i),
		.prot_i(mem_prot_i),
		.we_i(1'b0),
		.d_i({XLEN {1'b0}}),
		.invalidate_i(invalidate_i),
		.clean_i(1'b0),
		.req_o(setup_req),
		.rreq_o(),
		.size_o(setup_size),
		.lock_o(setup_lock),
		.prot_o(setup_prot),
		.we_o(),
		.q_o(),
		.invalidate_o(setup_invalidate),
		.clean_o(),
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
		.stall_i(mem_stall_o),
		.flush_i(mem_flush_i),
		.pagefault_i(pagefault_i),
		.req_i(setup_req),
		.phys_adr_i(phys_adr_i),
		.size_i(setup_size),
		.lock_i(setup_lock),
		.prot_i(setup_prot),
		.we_i(1'b0),
		.d_i({XLEN {1'b0}}),
		.invalidate_i(setup_invalidate),
		.clean_i(),
		.invalidate_all_blocks_i(invalidate_all_blocks),
		.req_o(tag_req),
		.wreq_o(),
		.adr_o(tag_adr),
		.size_o(tag_size),
		.lock_o(tag_lock),
		.prot_o(tag_prot),
		.we_o(),
		.be_o(),
		.q_o(),
		.invalidate_o(tag_invalidate),
		.clean_o(),
		.pagefault_o(tag_pagefault),
		.core_tag_o(tag_core_tag)
	);
	riscv_icache_fsm #(
		.XLEN(XLEN),
		.PLEN(PLEN),
		.PARCEL_SIZE(PARCEL_SIZE),
		.HAS_RVC(HAS_RVC),
		.SIZE(SIZE),
		.BLOCK_SIZE(BLOCK_SIZE),
		.WAYS(WAYS),
		.INFLIGHT_DEPTH(INFLIGHT_DEPTH),
		.BIUTAG_SIZE(BIUTAG_SIZE)
	) cache_fsm_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.stall_o(mem_stall_o),
		.flush_i(mem_flush_i),
		.invalidate_i(tag_invalidate),
		.dc_clean_rdy_i(dc_clean_rdy_i),
		.armed_o(armed),
		.invalidate_all_blocks_o(invalidate_all_blocks),
		.filling_o(filling),
		.fill_way_i(mem_fill_way),
		.fill_way_o(hit_fill_way),
		.req_i(tag_req),
		.adr_i(tag_adr),
		.size_i(tag_size),
		.lock_i(tag_lock),
		.prot_i(tag_prot),
		.cacheable_i(pma_cacheable_i),
		.misaligned_i(pma_misaligned_i),
		.pma_exception_i(pma_exception_i),
		.pmp_exception_i(pmp_exception_i),
		.pagefault_i(tag_pagefault),
		.idx_o(hit_idx),
		.core_tag_o(hit_core_tag),
		.biucmd_o(biucmd),
		.biucmd_ack_i(biucmd_ack),
		.biucmd_noncacheable_req_o(biucmd_noncacheable_req),
		.biucmd_noncacheable_ack_i(biucmd_noncacheable_ack),
		.biucmd_adri_o(biucmd_adr),
		.biucmd_tagi_o(biucmd_tag),
		.inflight_cnt_i(inflight_cnt),
		.cache_hit_i(cache_hit),
		.cache_line_i(cache_line),
		.biu_stb_ack_i(biu_stb_ack_i),
		.biu_ack_i(biu_ack_i),
		.biu_err_i(biu_err_i),
		.biu_adro_i(biu_adro_i),
		.biu_tago_i(biu_tago_i),
		.biu_q_i(biu_q_i),
		.in_biubuffer_i(in_biubuffer),
		.biubuffer_i(biubuffer),
		.parcel_o(parcel_o),
		.parcel_valid_o(parcel_valid_o),
		.parcel_error_o(parcel_error_o),
		.parcel_misaligned_o(parcel_misaligned_o),
		.parcel_pagefault_o(parcel_pagefault_o)
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
		.stall_i(mem_stall_o),
		.armed_i(armed),
		.cleaning_i(1'b0),
		.clean_way_int_o(),
		.clean_idx_o(),
		.clean_way_i({WAYS {1'b0}}),
		.clean_idx_i({IDX_BITS {1'b0}}),
		.invalidate_block_i(1'b0),
		.invalidate_all_blocks_i(invalidate_all_blocks),
		.filling_i(filling),
		.fill_way_select_i(fill_way_select),
		.fill_way_i(hit_fill_way),
		.fill_way_o(mem_fill_way),
		.rd_core_tag_i(tag_core_tag),
		.wr_core_tag_i(hit_core_tag),
		.rd_idx_i(setup_idx),
		.wr_idx_i(hit_idx),
		.rreq_i(1'b0),
		.writebuffer_we_i(1'b0),
		.writebuffer_be_i({BLK_BITS / 8 {1'b0}}),
		.writebuffer_idx_i({IDX_BITS {1'b0}}),
		.writebuffer_offs_i({DAT_OFFS_BITS {1'b0}}),
		.writebuffer_data_i({XLEN {1'b0}}),
		.writebuffer_ways_hit_i({WAYS {1'b0}}),
		.writebuffer_cleaning_i(1'b0),
		.evict_read_i(1'b0),
		.evict_adr_o(),
		.evict_line_o(),
		.biu_line_i(biu_line),
		.biu_line_dirty_i(1'b0),
		.biucmd_ack_i(biucmd_ack),
		.latchmem_i(~mem_stall_o),
		.hit_o(cache_hit),
		.ways_hit_o(),
		.cache_dirty_o(),
		.way_dirty_o(),
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
		.biucmd_busy_o(),
		.biucmd_noncacheable_req_i(biucmd_noncacheable_req),
		.biucmd_noncacheable_ack_o(biucmd_noncacheable_ack),
		.biucmd_tag_i(biucmd_tag),
		.inflight_cnt_o(inflight_cnt),
		.req_i(tag_req),
		.adr_i(biucmd_adr),
		.size_i(tag_size),
		.prot_i(tag_prot),
		.lock_i(1'b0),
		.we_i(1'b0),
		.be_i({XLEN / 8 {1'b0}}),
		.d_i({XLEN {1'b0}}),
		.evictbuffer_adr_i({PLEN {1'b0}}),
		.evictbuffer_d_i({BLK_BITS {1'b0}}),
		.biubuffer_o(biubuffer),
		.in_biubuffer_o(in_biubuffer),
		.biu_line_o(biu_line),
		.biu_line_dirty_o(),
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
