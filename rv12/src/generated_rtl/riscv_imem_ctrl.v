module riscv_imem_ctrl (
	rst_ni,
	clk_i,
	pma_cfg_i,
	pma_adr_i,
	st_pmpcfg_i,
	st_pmpaddr_i,
	st_prv_i,
	mem_req_i,
	mem_ack_o,
	mem_flush_i,
	mem_adr_i,
	parcel_o,
	parcel_valid_o,
	mem_error_o,
	mem_misaligned_o,
	mem_pagefault_o,
	cm_invalidate_i,
	cm_dc_clean_rdy_i,
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
	parameter signed [31:0] XLEN = 32;
	parameter signed [31:0] PLEN = (XLEN == 32 ? 34 : 56);
	parameter signed [31:0] PARCEL_SIZE = 32;
	parameter signed [31:0] HAS_RVC = 0;
	parameter signed [31:0] HAS_MMU = 0;
	parameter signed [31:0] PMA_CNT = 3;
	parameter signed [31:0] PMP_CNT = 16;
	parameter signed [31:0] CACHE_SIZE = 64;
	parameter signed [31:0] CACHE_BLOCK_SIZE = 32;
	parameter signed [31:0] CACHE_WAYS = 2;
	parameter TECHNOLOGY = "GENERIC";
	parameter signed [31:0] BIUTAG_SIZE = $clog2(XLEN / PARCEL_SIZE);
	input wire rst_ni;
	input wire clk_i;
	input wire [(PMA_CNT * 14) - 1:0] pma_cfg_i;
	input [(PMA_CNT * XLEN) - 1:0] pma_adr_i;
	input wire [127:0] st_pmpcfg_i;
	input wire [(16 * XLEN) - 1:0] st_pmpaddr_i;
	input wire [1:0] st_prv_i;
	input wire mem_req_i;
	output wire mem_ack_o;
	input wire mem_flush_i;
	input wire [XLEN - 1:0] mem_adr_i;
	output wire [XLEN - 1:0] parcel_o;
	output wire [(XLEN / PARCEL_SIZE) - 1:0] parcel_valid_o;
	output wire mem_error_o;
	output wire mem_misaligned_o;
	output wire mem_pagefault_o;
	input wire cm_invalidate_i;
	input wire cm_dc_clean_rdy_i;
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
	wire stall;
	wire [2:0] size;
	wire [2:0] prot;
	wire lock;
	wire mmu_req;
	wire [PLEN - 1:0] mmu_adr;
	wire [2:0] mmu_size;
	wire mmu_lock;
	wire mmu_we;
	wire mmu_misaligned;
	wire mmu_pagefault;
	wire mmu_cm_invalidate;
	wire mem_misaligned;
	wire pma_exception;
	reg pma_misaligned;
	wire pma_cacheable;
	wire pmp_exception;
	assign size = (XLEN == 64 ? 3'b011 : 3'b010);
	localparam [2:0] biu_constants_pkg_PROT_INSTRUCTION = 3'b000;
	localparam [2:0] biu_constants_pkg_PROT_PRIVILEGED = 3'b010;
	localparam [2:0] biu_constants_pkg_PROT_USER = 3'b000;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	assign prot = biu_constants_pkg_PROT_INSTRUCTION | (st_prv_i == riscv_state_pkg_PRV_U ? biu_constants_pkg_PROT_USER : biu_constants_pkg_PROT_PRIVILEGED);
	assign lock = 1'b0;
	riscv_memmisaligned #(
		.XLEN(XLEN),
		.HAS_RVC(HAS_RVC)
	) misaligned_inst(
		.instruction_i(1'b1),
		.adr_i(mem_adr_i),
		.size_i(size),
		.misaligned_o(mem_misaligned)
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
					.flush_i(mem_flush_i),
					.req_i(mem_req_i),
					.adr_i(mem_adr_i),
					.size_i(size),
					.lock_i(lock),
					.we_i(1'b0),
					.misaligned_i(mem_misaligned),
					.cm_clean_i(1'b0),
					.cm_invalidate_i(cm_invalidate_i),
					.req_o(mmu_req),
					.adr_o(mmu_adr),
					.size_o(mmu_size),
					.lock_o(mmu_lock),
					.we_o(),
					.misaligned_o(mmu_misaligned),
					.cm_clean_o(),
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
					.misaligned_i(mmu_misaligned),
					.instruction_i(1'b1),
					.adr_i(mmu_adr),
					.size_i(size),
					.lock_i(lock),
					.we_i(1'b0),
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
					.instruction_i(1'b1),
					.adr_i(mmu_adr),
					.size_i(size),
					.we_i(1'b0),
					.exception_o(pmp_exception)
				);
			end
			else begin : genblk3
				assign pmp_exception = 1'b0;
			end
			riscv_icache_core #(
				.XLEN(XLEN),
				.PLEN(PLEN),
				.HAS_RVC(HAS_RVC),
				.PARCEL_SIZE(PARCEL_SIZE),
				.SIZE(CACHE_SIZE),
				.BLOCK_SIZE(CACHE_BLOCK_SIZE),
				.WAYS(CACHE_WAYS),
				.TECHNOLOGY(TECHNOLOGY),
				.BIUTAG_SIZE(BIUTAG_SIZE)
			) icache_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.phys_adr_i(mmu_adr),
				.pagefault_i(mmu_pagefault),
				.pma_cacheable_i(pma_cacheable),
				.pma_misaligned_i(pma_misaligned),
				.pma_exception_i(pma_exception),
				.pmp_exception_i(pmp_exception),
				.mem_req_i(mem_req_i),
				.mem_stall_o(stall),
				.mem_adr_i(mem_adr_i),
				.mem_flush_i(mem_flush_i),
				.mem_size_i(size),
				.mem_lock_i(lock),
				.mem_prot_i(prot),
				.parcel_o(parcel_o),
				.parcel_valid_o(parcel_valid_o),
				.parcel_misaligned_o(mem_misaligned_o),
				.parcel_error_o(mem_error_o),
				.parcel_pagefault_o(mem_pagefault_o),
				.invalidate_i(cm_invalidate_i),
				.dc_clean_rdy_i(cm_dc_clean_rdy_i),
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
			assign mem_ack_o = ~stall;
		end
		else begin : genblk1
			riscv_noicache_core #(
				.XLEN(XLEN),
				.PLEN(PLEN),
				.HAS_RVC(HAS_RVC),
				.PARCEL_SIZE(PARCEL_SIZE),
				.BIUTAG_SIZE(BIUTAG_SIZE)
			) noicache_core_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.if_req_i(mem_req_i),
				.if_ack_o(mem_ack_o),
				.if_prot_i(prot),
				.if_flush_i(mem_flush_i),
				.if_nxt_pc_i(mem_adr_i),
				.if_parcel_pc_o(),
				.if_parcel_o(parcel_o),
				.if_parcel_valid_o(parcel_valid_o),
				.if_parcel_misaligned_o(mem_misaligned_o),
				.if_parcel_error_o(mem_error_o),
				.cm_dc_clean_rdy_i(cm_dc_clean_rdy_i),
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
				.biu_err_i(biu_err_i),
				.biu_tagi_o(biu_tagi_o),
				.biu_tago_i(biu_tago_i)
			);
			assign mem_pagefault_o = 1'b0;
		end
	endgenerate
endmodule
