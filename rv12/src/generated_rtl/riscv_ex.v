module riscv_ex (
	rst_ni,
	clk_i,
	mem_stall_i,
	ex_stall_o,
	id_pc_i,
	id_rsb_pc_i,
	ex_pc_o,
	bu_nxt_pc_o,
	bu_flush_o,
	cm_ic_invalidate_o,
	cm_dc_invalidate_o,
	cm_dc_clean_o,
	id_bp_predict_i,
	bu_bp_predict_o,
	id_bp_history_i,
	bu_bp_history_update_o,
	bu_bp_history_o,
	bu_bp_btaken_o,
	bu_bp_update_o,
	id_insn_i,
	ex_insn_o,
	id_exceptions_i,
	ex_exceptions_o,
	mem_exceptions_i,
	wb_exceptions_i,
	id_userf_opA_i,
	id_userf_opB_i,
	id_bypex_opA_i,
	id_bypex_opB_i,
	id_opA_i,
	id_opB_i,
	rf_srcv1_i,
	rf_srcv2_i,
	ex_r_o,
	ex_csr_reg_o,
	ex_csr_wval_o,
	ex_csr_we_o,
	st_xlen_i,
	st_be_i,
	st_flush_i,
	st_csr_rval_i,
	dmem_req_o,
	dmem_lock_o,
	dmem_adr_o,
	dmem_size_o,
	dmem_we_o,
	dmem_d_o,
	dmem_q_i,
	dmem_ack_i,
	dmem_misaligned_i,
	dmem_page_fault_i
);
	reg _sv2v_0;
	parameter signed [31:0] MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter signed [31:0] BP_GLOBAL_BITS = 2;
	parameter [0:0] HAS_RVC = 0;
	parameter [0:0] HAS_RVA = 0;
	parameter [0:0] HAS_RVM = 0;
	parameter signed [31:0] MULT_LATENCY = 0;
	parameter signed [31:0] RSB_DEPTH = 0;
	input rst_ni;
	input clk_i;
	input mem_stall_i;
	output wire ex_stall_o;
	input [MXLEN - 1:0] id_pc_i;
	input [MXLEN - 1:0] id_rsb_pc_i;
	output reg [MXLEN - 1:0] ex_pc_o;
	output reg [MXLEN - 1:0] bu_nxt_pc_o;
	output wire bu_flush_o;
	output wire cm_ic_invalidate_o;
	output wire cm_dc_invalidate_o;
	output wire cm_dc_clean_o;
	input [1:0] id_bp_predict_i;
	output wire [1:0] bu_bp_predict_o;
	input [BP_GLOBAL_BITS - 1:0] id_bp_history_i;
	output wire [BP_GLOBAL_BITS - 1:0] bu_bp_history_update_o;
	output wire [BP_GLOBAL_BITS - 1:0] bu_bp_history_o;
	output wire bu_bp_btaken_o;
	output wire bu_bp_update_o;
	input wire [34:0] id_insn_i;
	output reg [34:0] ex_insn_o;
	input wire [27:0] id_exceptions_i;
	output wire [27:0] ex_exceptions_o;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	input id_userf_opA_i;
	input id_userf_opB_i;
	input id_bypex_opA_i;
	input id_bypex_opB_i;
	input [MXLEN - 1:0] id_opA_i;
	input [MXLEN - 1:0] id_opB_i;
	input [MXLEN - 1:0] rf_srcv1_i;
	input [MXLEN - 1:0] rf_srcv2_i;
	output reg [MXLEN - 1:0] ex_r_o;
	output wire [11:0] ex_csr_reg_o;
	output wire [MXLEN - 1:0] ex_csr_wval_o;
	output wire ex_csr_we_o;
	input [1:0] st_xlen_i;
	input st_be_i;
	input st_flush_i;
	input [MXLEN - 1:0] st_csr_rval_i;
	output wire dmem_req_o;
	output wire dmem_lock_o;
	output wire [MXLEN - 1:0] dmem_adr_o;
	output wire [2:0] dmem_size_o;
	output wire dmem_we_o;
	output wire [MXLEN - 1:0] dmem_d_o;
	input [MXLEN - 1:0] dmem_q_i;
	input dmem_ack_i;
	input dmem_misaligned_i;
	input dmem_page_fault_i;
	reg [MXLEN - 1:0] opA;
	reg [MXLEN - 1:0] opB;
	wire [MXLEN - 1:0] alu_r;
	wire [MXLEN - 1:0] lsu_r;
	wire [MXLEN - 1:0] mul_r;
	wire [MXLEN - 1:0] div_r;
	wire alu_bubble;
	wire lsu_bubble;
	wire bu_bubble;
	wire mul_bubble;
	wire div_bubble;
	wire lsu_stall;
	wire mul_stall;
	wire div_stall;
	localparam riscv_state_pkg_EXCEPTION_SIZE = 20;
	wire [19:0] bu_exception;
	wire [27:0] lsu_exceptions;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ex_pc_o <= PC_INIT;
		else if (!ex_stall_o)
			ex_pc_o <= id_pc_i;
	always @(posedge clk_i)
		if (!ex_stall_o)
			ex_insn_o[31-:32] <= id_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ex_insn_o[34] <= 1'b0;
		else if (!ex_stall_o)
			ex_insn_o[34] <= id_insn_i[34];
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({id_userf_opA_i, id_bypex_opA_i})
			2'bz1: opA = ex_r_o;
			2'b10: opA = rf_srcv1_i;
			default: opA = id_opA_i;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({id_userf_opB_i, id_bypex_opB_i})
			2'bz1: opB = ex_r_o;
			2'b10: opB = rf_srcv2_i;
			default: opB = id_opB_i;
		endcase
	end
	riscv_alu #(
		.MXLEN(MXLEN),
		.HAS_RVC(HAS_RVC)
	) alu(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.ex_stall_i(ex_stall_o),
		.id_pc_i(id_pc_i),
		.id_insn_i(id_insn_i),
		.opA_i(opA),
		.opB_i(opB),
		.ex_exceptions_i(ex_exceptions_o),
		.mem_exceptions_i(mem_exceptions_i),
		.wb_exceptions_i(wb_exceptions_i),
		.alu_bubble_o(alu_bubble),
		.alu_r_o(alu_r),
		.ex_csr_reg_o(ex_csr_reg_o),
		.ex_csr_wval_o(ex_csr_wval_o),
		.ex_csr_we_o(ex_csr_we_o),
		.st_csr_rval_i(st_csr_rval_i),
		.st_xlen_i(st_xlen_i)
	);
	riscv_lsu #(.MXLEN(MXLEN)) lsu(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.ex_stall_i(ex_stall_o),
		.lsu_stall_o(lsu_stall),
		.id_insn_i(id_insn_i),
		.lsu_bubble_o(lsu_bubble),
		.lsu_r_o(lsu_r),
		.id_exceptions_i(id_exceptions_i),
		.ex_exceptions_i(ex_exceptions_o),
		.mem_exceptions_i(mem_exceptions_i),
		.wb_exceptions_i(wb_exceptions_i),
		.lsu_exceptions_o(lsu_exceptions),
		.opA_i(opA),
		.opB_i(opB),
		.st_xlen_i(st_xlen_i),
		.st_be_i(st_be_i),
		.dmem_req_o(dmem_req_o),
		.dmem_lock_o(dmem_lock_o),
		.dmem_we_o(dmem_we_o),
		.dmem_size_o(dmem_size_o),
		.dmem_adr_o(dmem_adr_o),
		.dmem_d_o(dmem_d_o),
		.dmem_q_i(dmem_q_i),
		.dmem_ack_i(dmem_ack_i),
		.dmem_misaligned_i(dmem_misaligned_i),
		.dmem_page_fault_i(dmem_page_fault_i)
	);
	wire [MXLEN:1] sv2v_tmp_bu_bu_nxt_pc_o;
	always @(*) bu_nxt_pc_o = sv2v_tmp_bu_bu_nxt_pc_o;
	riscv_bu #(
		.MXLEN(MXLEN),
		.HAS_RVC(HAS_RVC),
		.PC_INIT(PC_INIT),
		.BP_GLOBAL_BITS(BP_GLOBAL_BITS),
		.RSB_DEPTH(RSB_DEPTH)
	) bu(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.ex_stall_i(ex_stall_o),
		.st_flush_i(st_flush_i),
		.bu_bubble_o(bu_bubble),
		.id_pc_i(id_pc_i),
		.id_insn_i(id_insn_i),
		.id_rsb_pc_i(id_rsb_pc_i),
		.bu_nxt_pc_o(sv2v_tmp_bu_bu_nxt_pc_o),
		.bu_flush_o(bu_flush_o),
		.cm_ic_invalidate_o(cm_ic_invalidate_o),
		.cm_dc_invalidate_o(cm_dc_invalidate_o),
		.cm_dc_clean_o(cm_dc_clean_o),
		.id_bp_predict_i(id_bp_predict_i),
		.bu_bp_predict_o(bu_bp_predict_o),
		.id_bp_history_i(id_bp_history_i),
		.bu_bp_history_update_o(bu_bp_history_update_o),
		.bu_bp_history_o(bu_bp_history_o),
		.bu_bp_btaken_o(bu_bp_btaken_o),
		.bu_bp_update_o(bu_bp_update_o),
		.id_exceptions_i(id_exceptions_i),
		.ex_exceptions_i(ex_exceptions_o),
		.mem_exceptions_i(mem_exceptions_i),
		.wb_exceptions_i(wb_exceptions_i),
		.bu_exceptions_o(ex_exceptions_o),
		.opA_i(opA),
		.opB_i(opB)
	);
	generate
		if (HAS_RVM != 0) begin : genblk1
			riscv_mul #(
				.MXLEN(MXLEN),
				.MULT_LATENCY(MULT_LATENCY)
			) mul(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.mem_stall_i(mem_stall_i),
				.ex_stall_i(ex_stall_o),
				.mul_stall_o(mul_stall),
				.id_insn_i(id_insn_i),
				.opA_i(opA),
				.opB_i(opB),
				.st_xlen_i(st_xlen_i),
				.mul_bubble_o(mul_bubble),
				.mul_r_o(mul_r)
			);
			riscv_div #(.MXLEN(MXLEN)) div(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.mem_stall_i(mem_stall_i),
				.ex_stall_i(ex_stall_o),
				.div_stall_o(div_stall),
				.id_insn_i(id_insn_i),
				.opA_i(opA),
				.opB_i(opB),
				.st_xlen_i(st_xlen_i),
				.div_bubble_o(div_bubble),
				.div_r_o(div_r)
			);
		end
		else begin : genblk1
			assign mul_bubble = 1'b1;
			assign mul_r = 'h0;
			assign mul_stall = 1'b0;
			assign div_bubble = 1'b1;
			assign div_r = 'h0;
			assign div_stall = 1'b0;
		end
	endgenerate
	wire [1:1] sv2v_tmp_E5E68;
	assign sv2v_tmp_E5E68 = ((alu_bubble & lsu_bubble) & mul_bubble) & div_bubble;
	always @(*) ex_insn_o[33] = sv2v_tmp_E5E68;
	wire [1:1] sv2v_tmp_A16AA;
	assign sv2v_tmp_A16AA = ~((((alu_bubble & lsu_bubble) & bu_bubble) & mul_bubble) & div_bubble);
	always @(*) ex_insn_o[32] = sv2v_tmp_A16AA;
	assign ex_stall_o = ((mem_stall_i | lsu_stall) | mul_stall) | div_stall;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex ({mul_bubble, div_bubble, lsu_bubble})
			3'b110: ex_r_o = lsu_r;
			3'b101: ex_r_o = div_r;
			3'b011: ex_r_o = mul_r;
			default: ex_r_o = alu_r;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
