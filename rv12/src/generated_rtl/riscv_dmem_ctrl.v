module riscv_dmem_ctrl (
	rst_ni,
	clk_i,
	pma_cfg_i,
	pma_adr_i,
	st_pmpcfg_i,
	st_pmpaddr_i,
	st_prv_i,
	mem_req_i,
	mem_size_i,
	mem_lock_i,
	mem_adr_i,
	mem_we_i,
	mem_d_i,
	mem_q_o,
	mem_ack_o,
	mem_err_o,
	mem_misaligned_o,
	mem_pagefault_o,
	cm_invalidate_i,
	cm_clean_i,
	cm_clean_rdy_o,
	biu_stb_o,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_we_o,
	biu_lock_o,
	biu_prot_o,
	biu_d_o,
	biu_q_i,
	biu_ack_i,
	biu_err_i,
	biu_tagi_o,
	biu_tago_i
);
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	parameter HAS_RVC = 0;
	parameter HAS_MMU = 0;
	parameter PMA_CNT = 3;
	parameter PMP_CNT = 16;
	parameter CACHE_SIZE = 64;
	parameter CACHE_BLOCK_SIZE = 32;
	parameter CACHE_WAYS = 2;
	parameter TECHNOLOGY = "GENERIC";
	parameter BIUTAG_SIZE = 2;
	input wire rst_ni;
	input wire clk_i;
	input wire [(PMA_CNT * 14) - 1:0] pma_cfg_i;
	input [(PMA_CNT * XLEN) - 1:0] pma_adr_i;
	input wire [127:0] st_pmpcfg_i;
	input wire [(16 * XLEN) - 1:0] st_pmpaddr_i;
	input wire [1:0] st_prv_i;
	input wire mem_req_i;
	input wire [2:0] mem_size_i;
	input wire mem_lock_i;
	input wire [XLEN - 1:0] mem_adr_i;
	input wire mem_we_i;
	input wire [XLEN - 1:0] mem_d_i;
	output wire [XLEN - 1:0] mem_q_o;
	output wire mem_ack_o;
	output wire mem_err_o;
	output wire mem_misaligned_o;
	output wire mem_pagefault_o;
	input wire cm_invalidate_i;
	input wire cm_clean_i;
	output wire cm_clean_rdy_o;
	output wire biu_stb_o;
	input wire biu_stb_ack_i;
	input wire biu_d_ack_i;
	output wire [PLEN - 1:0] biu_adri_o;
	input wire [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_we_o;
	output wire biu_lock_o;
	output wire [2:0] biu_prot_o;
	output wire [XLEN - 1:0] biu_d_o;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input wire [BIUTAG_SIZE - 1:0] biu_tago_i;
	wire [2:0] prot;
	wire queue_req;
	wire [XLEN - 1:0] queue_adr;
	wire [2:0] queue_size;
	wire queue_lock;
	wire [2:0] queue_prot;
	wire queue_we;
	wire [XLEN - 1:0] queue_d;
	wire queue_misaligned;
	wire queue_cm_clean;
	wire queue_cm_invalidate;
	wire mmu_req;
	wire [PLEN - 1:0] mmu_adr;
	wire [2:0] mmu_size;
	wire mmu_lock;
	wire mmu_we;
	wire mmu_misaligned;
	wire mmu_pagefault;
	wire mmu_cm_clean;
	wire mmu_cm_invalidate;
	wire mem_misaligned;
	wire pma_exception;
	reg pma_misaligned;
	wire pma_cacheable;
	wire pmp_exception;
	wire stall;
	localparam [2:0] biu_constants_pkg_PROT_DATA = 3'b001;
	localparam [2:0] biu_constants_pkg_PROT_PRIVILEGED = 3'b010;
	localparam [2:0] biu_constants_pkg_PROT_USER = 3'b000;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	assign prot = biu_constants_pkg_PROT_DATA | (st_prv_i == riscv_state_pkg_PRV_U ? biu_constants_pkg_PROT_USER : biu_constants_pkg_PROT_PRIVILEGED);
	riscv_memmisaligned #(
		.XLEN(XLEN),
		.HAS_RVC(HAS_RVC)
	) misaligned_inst(
		.instruction_i(1'b0),
		.adr_i(mem_adr_i),
		.size_i(mem_size_i),
		.misaligned_o(mem_misaligned)
	);
	riscv_membuf #(
		.DEPTH(2),
		.XLEN(XLEN)
	) membuffer_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.flush_i(1'b0),
		.stall_i(stall),
		.req_i(mem_req_i),
		.adr_i(mem_adr_i),
		.size_i(mem_size_i),
		.lock_i(mem_lock_i),
		.prot_i(prot),
		.we_i(mem_we_i),
		.d_i(mem_d_i),
		.misaligned_i(mem_misaligned),
		.cm_clean_i(cm_clean_i),
		.cm_invalidate_i(cm_invalidate_i),
		.req_o(queue_req),
		.ack_i(((mem_ack_o | mem_err_o) | mem_misaligned_o) | mem_pagefault_o),
		.adr_o(queue_adr),
		.size_o(queue_size),
		.lock_o(queue_lock),
		.prot_o(queue_prot),
		.we_o(queue_we),
		.q_o(queue_d),
		.misaligned_o(queue_misaligned),
		.cm_clean_o(queue_cm_clean),
		.cm_invalidate_o(queue_cm_invalidate),
		.empty_o(),
		.full_o()
	);
	generate
		if (CACHE_SIZE > 0) begin : cache_blk
			if (HAS_MMU != 0) begin
				;
			end
			else begin : nommu_blk
				riscv_nommu #(
					.XLEN(XLEN),
					.PLEN(PLEN)
				) mmu_inst(
					.rst_ni(rst_ni),
					.clk_i(clk_i),
					.stall_i(stall),
					.flush_i(1'b0),
					.req_i(queue_req),
					.adr_i(queue_adr),
					.size_i(queue_size),
					.lock_i(queue_lock),
					.we_i(queue_we),
					.misaligned_i(queue_misaligned),
					.cm_clean_i(queue_cm_clean),
					.cm_invalidate_i(queue_cm_invalidate),
					.req_o(mmu_req),
					.adr_o(mmu_adr),
					.size_o(mmu_size),
					.lock_o(mmu_lock),
					.we_o(mmu_we),
					.misaligned_o(mmu_misaligned),
					.cm_clean_o(mmu_cm_clean),
					.cm_invalidate_o(mmu_cm_invalidate),
					.pagefault_o(mmu_pagefault)
				);
			end
			if (PMA_CNT > 0) begin : pma_blk
				wire [1:1] sv2v_tmp_pmachk_inst_misaligned_o;
				always @(*) pma_misaligned = sv2v_tmp_pmachk_inst_misaligned_o;
				riscv_pmachk #(
					.XLEN(XLEN),
					.PLEN(PLEN),
					.HAS_RVC(HAS_RVC),
					.PMA_CNT(PMA_CNT)
				) pmachk_inst(
					.clk_i(clk_i),
					.stall_i(stall),
					.pma_cfg_i(pma_cfg_i),
					.pma_adr_i(pma_adr_i),
					.instruction_i(1'b0),
					.adr_i(mmu_adr),
					.size_i(mmu_size),
					.lock_i(mmu_lock),
					.we_i(mmu_we),
					.misaligned_i(mmu_misaligned),
					.exception_o(pma_exception),
					.misaligned_o(sv2v_tmp_pmachk_inst_misaligned_o),
					.cacheable_o(pma_cacheable)
				);
			end
			else begin : genblk2
				assign pma_cacheable = 1'b1;
				assign pma_exception = 1'b0;
				always @(posedge clk_i)
					if (!stall)
						pma_misaligned <= mmu_misaligned;
			end
			if (PMP_CNT > 0) begin : pmp_blk
				riscv_pmpchk #(
					.XLEN(XLEN),
					.PLEN(PLEN),
					.PMP_CNT(PMP_CNT)
				) pmpchk_inst(
					.clk_i(clk_i),
					.stall_i(stall),
					.st_pmpcfg_i(st_pmpcfg_i),
					.st_pmpaddr_i(st_pmpaddr_i),
					.st_prv_i(st_prv_i),
					.instruction_i(1'b0),
					.adr_i(mmu_adr),
					.size_i(mmu_size),
					.we_i(mmu_we),
					.exception_o(pmp_exception)
				);
			end
			else begin : genblk3
				assign pmp_exception = 1'b0;
			end
			riscv_dcache_core #(
				.XLEN(XLEN),
				.PLEN(PLEN),
				.SIZE(CACHE_SIZE),
				.BLOCK_SIZE(CACHE_BLOCK_SIZE),
				.WAYS(CACHE_WAYS),
				.TECHNOLOGY(TECHNOLOGY),
				.BIUTAG_SIZE(BIUTAG_SIZE)
			) dcache_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.stall_o(stall),
				.phys_adr_i(mmu_adr),
				.pagefault_i(mmu_pagefault),
				.pma_cacheable_i(pma_cacheable),
				.pma_misaligned_i(pma_misaligned),
				.pma_exception_i(pma_exception),
				.pmp_exception_i(pmp_exception),
				.mem_req_i(queue_req),
				.mem_ack_o(mem_ack_o),
				.mem_adr_i(queue_adr),
				.mem_flush_i(1'b0),
				.mem_size_i(queue_size),
				.mem_lock_i(queue_lock),
				.mem_prot_i(queue_prot),
				.mem_we_i(queue_we),
				.mem_d_i(queue_d),
				.mem_q_o(mem_q_o),
				.mem_err_o(mem_err_o),
				.mem_misaligned_o(mem_misaligned_o),
				.mem_pagefault_o(mem_pagefault_o),
				.invalidate_i(mmu_cm_invalidate),
				.clean_i(mmu_cm_clean),
				.clean_rdy_clr_i(cm_clean_i),
				.clean_rdy_o(cm_clean_rdy_o),
				.biu_stb_o(biu_stb_o),
				.biu_stb_ack_i(biu_stb_ack_i),
				.biu_d_ack_i(biu_d_ack_i),
				.biu_adri_o(biu_adri_o),
				.biu_adro_i(biu_adro_i),
				.biu_size_o(biu_size_o),
				.biu_type_o(biu_type_o),
				.biu_we_o(biu_we_o),
				.biu_lock_o(biu_lock_o),
				.biu_prot_o(biu_prot_o),
				.biu_d_o(biu_d_o),
				.biu_q_i(biu_q_i),
				.biu_ack_i(biu_ack_i),
				.biu_err_i(biu_err_i),
				.biu_tagi_o(biu_tagi_o),
				.biu_tago_i(biu_tago_i)
			);
		end
		else begin : genblk1
			riscv_nodcache_core #(
				.XLEN(XLEN),
				.ALEN(PLEN),
				.DEPTH(2)
			) nodcache_core_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.mem_req_i(mem_req_i),
				.mem_size_i(mem_size_i),
				.mem_lock_i(mem_lock_i),
				.mem_misaligned_i(mem_misaligned),
				.mem_adr_i(mem_adr_i),
				.mem_we_i(mem_we_i),
				.mem_d_i(mem_d_i),
				.mem_q_o(mem_q_o),
				.mem_ack_o(mem_ack_o),
				.mem_err_o(mem_err_o),
				.mem_misaligned_o(mem_misaligned_o),
				.st_prv_i(st_prv_i),
				.biu_stb_o(biu_stb_o),
				.biu_stb_ack_i(biu_stb_ack_i),
				.biu_d_ack_i(biu_d_ack_i),
				.biu_adri_o(biu_adri_o),
				.biu_adro_i(biu_adro_i),
				.biu_size_o(biu_size_o),
				.biu_type_o(biu_type_o),
				.biu_we_o(biu_we_o),
				.biu_lock_o(biu_lock_o),
				.biu_prot_o(biu_prot_o),
				.biu_d_o(biu_d_o),
				.biu_q_i(biu_q_i),
				.biu_ack_i(biu_ack_i),
				.biu_err_i(biu_err_i)
			);
			assign stall = 1'b0;
			assign cm_clean_rdy_o = 1'b1;
			assign mem_pagefault_o = 1'b0;
		end
	endgenerate
endmodule
