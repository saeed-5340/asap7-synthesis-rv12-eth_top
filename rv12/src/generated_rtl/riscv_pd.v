module riscv_pd (
	rst_ni,
	clk_i,
	id_stall_i,
	pd_stall_o,
	du_mode_i,
	bu_flush_i,
	st_flush_i,
	pd_flush_o,
	pd_rs1_o,
	pd_rs2_o,
	pd_csr_reg_o,
	bu_nxt_pc_i,
	st_nxt_pc_i,
	pd_nxt_pc_o,
	pd_latch_nxt_pc_o,
	if_bp_history_i,
	pd_bp_history_o,
	bp_bp_predict_i,
	pd_bp_predict_o,
	if_pc_i,
	pd_pc_o,
	pd_rsb_pc_o,
	if_insn_i,
	pd_insn_o,
	id_insn_i,
	if_exceptions_i,
	pd_exceptions_o,
	id_exceptions_i,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter HAS_RVC = 0;
	parameter HAS_BPU = 0;
	parameter BP_GLOBAL_BITS = 2;
	parameter RSB_DEPTH = 4;
	input rst_ni;
	input clk_i;
	input id_stall_i;
	output wire pd_stall_o;
	input du_mode_i;
	input bu_flush_i;
	input st_flush_i;
	output wire pd_flush_o;
	output wire [4:0] pd_rs1_o;
	output wire [4:0] pd_rs2_o;
	output wire [11:0] pd_csr_reg_o;
	input [MXLEN - 1:0] bu_nxt_pc_i;
	input [MXLEN - 1:0] st_nxt_pc_i;
	output reg [MXLEN - 1:0] pd_nxt_pc_o;
	output reg pd_latch_nxt_pc_o;
	input [BP_GLOBAL_BITS - 1:0] if_bp_history_i;
	output reg [BP_GLOBAL_BITS - 1:0] pd_bp_history_o;
	input [1:0] bp_bp_predict_i;
	output reg [1:0] pd_bp_predict_o;
	input [MXLEN - 1:0] if_pc_i;
	output reg [MXLEN - 1:0] pd_pc_o;
	output reg [MXLEN - 1:0] pd_rsb_pc_o;
	input wire [34:0] if_insn_i;
	output reg [34:0] pd_insn_o;
	input wire [34:0] id_insn_i;
	input wire [27:0] if_exceptions_i;
	output reg [27:0] pd_exceptions_o;
	input wire [27:0] id_exceptions_i;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	localparam ADR_MASK = (HAS_RVC != 0 ? {MXLEN {1'b1}} << 1 : {MXLEN {1'b1}} << 2);
	wire is_16bit_instruction;
	wire has_rsb;
	wire [MXLEN - 1:0] rsb_nxt_pc;
	wire [MXLEN - 1:0] rsb_predict_pc;
	reg rsb_push;
	reg rsb_pop;
	wire rsb_empty;
	wire [4:0] rs1;
	wire [4:0] rd;
	wire link_rs1;
	wire link_rd;
	reg decode_rsb_push;
	reg decode_rsb_pop;
	wire [20:0] immUJ;
	wire [12:0] immSB;
	wire [MXLEN - 1:0] ext_immUJ;
	wire [MXLEN - 1:0] ext_immSB;
	reg [1:0] branch_predicted;
	reg branch_taken;
	reg stalled_branch;
	reg assert_local_stall;
	reg [1:0] local_stall;
	assign is_16bit_instruction = ~&if_insn_i[1:0];
	assign rsb_nxt_pc = if_pc_i + ('h2 << if_insn_i[1-:2]);
	assign has_rsb = RSB_DEPTH > 0;
	function [4:0] riscv_opcodes_pkg_decode_rs1;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rs1 = instr[19-:5];
	endfunction
	assign rs1 = riscv_opcodes_pkg_decode_rs1(if_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rd;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rd = instr[11-:5];
	endfunction
	assign rd = riscv_opcodes_pkg_decode_rd(if_insn_i[31-:32]);
	assign link_rs1 = (rs1 == 1) | (rs1 == 5);
	assign link_rd = (rd == 1) | (rd == 5);
	assign pd_flush_o = bu_flush_i | st_flush_i;
	localparam [14:0] riscv_opcodes_pkg_CSRRC = 15'bzzzzzzz01111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRCI = 15'bzzzzzzz11111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRS = 15'bzzzzzzz01011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRSI = 15'bzzzzzzz11011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRW = 15'bzzzzzzz00111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRWI = 15'bzzzzzzz10111100;
	function [11:0] riscv_opcodes_pkg_decode_immI;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immI = instr[31-:12];
	endfunction
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		casex (riscv_opcodes_pkg_decode_opcR(if_insn_i[31-:32]))
			riscv_opcodes_pkg_CSRRW: assert_local_stall <= ~if_insn_i[33];
			riscv_opcodes_pkg_CSRRWI: assert_local_stall <= ~if_insn_i[33];
			riscv_opcodes_pkg_CSRRS: assert_local_stall <= ~if_insn_i[33] & |riscv_opcodes_pkg_decode_rs1(if_insn_i[31-:32]);
			riscv_opcodes_pkg_CSRRSI: assert_local_stall <= ~if_insn_i[33] & |riscv_opcodes_pkg_decode_immI(if_insn_i[31-:32]);
			riscv_opcodes_pkg_CSRRC: assert_local_stall <= ~if_insn_i[33] & |riscv_opcodes_pkg_decode_rs1(if_insn_i[31-:32]);
			riscv_opcodes_pkg_CSRRCI: assert_local_stall <= ~if_insn_i[33] & |riscv_opcodes_pkg_decode_immI(if_insn_i[31-:32]);
			default: assert_local_stall <= 1'b0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			local_stall <= 2'h0;
		else if (local_stall[1])
			local_stall <= 2'h0;
		else if (!id_stall_i) begin
			local_stall[0] <= assert_local_stall | local_stall[0];
			local_stall[1] <= local_stall[0];
		end
	assign pd_stall_o = id_stall_i | local_stall[0];
	assign pd_rs1_o = riscv_opcodes_pkg_decode_rs1(if_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rs2;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rs2 = instr[24-:5];
	endfunction
	assign pd_rs2_o = riscv_opcodes_pkg_decode_rs2(if_insn_i[31-:32]);
	assign pd_csr_reg_o = if_insn_i[31-:12];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_pc_o <= PC_INIT & ADR_MASK;
		else if (st_flush_i)
			pd_pc_o <= st_nxt_pc_i & ADR_MASK;
		else if (bu_flush_i)
			pd_pc_o <= bu_nxt_pc_i & ADR_MASK;
		else if (!pd_stall_o)
			pd_pc_o <= if_pc_i & ADR_MASK;
	wire [1:1] sv2v_tmp_F9198;
	assign sv2v_tmp_F9198 = 1'b0;
	always @(*) pd_insn_o[32] = sv2v_tmp_F9198;
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_insn_o[31-:32] <= riscv_opcodes_pkg_NOP;
		else if (!id_stall_i)
			pd_insn_o[31-:32] <= if_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_insn_o[34] <= 1'b0;
		else if (!id_stall_i)
			pd_insn_o[34] <= if_insn_i[34];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_insn_o[33] <= 1'b1;
		else if (pd_flush_o)
			pd_insn_o[33] <= 1'b1;
		else if (((id_exceptions_i[27] || ex_exceptions_i[27]) || mem_exceptions_i[27]) || wb_exceptions_i[27])
			pd_insn_o[33] <= 1'b1;
		else if (!id_stall_i) begin
			if (local_stall)
				pd_insn_o[33] <= 1'b1;
			else
				pd_insn_o[33] <= if_insn_i[33];
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_exceptions_o <= 'h0;
		else if (pd_flush_o)
			pd_exceptions_o <= 'h0;
		else if (pd_stall_o)
			pd_exceptions_o <= 'h0;
		else
			pd_exceptions_o <= if_exceptions_i;
	always @(posedge clk_i)
		if (!pd_stall_o)
			pd_bp_history_o <= if_bp_history_i;
	generate
		if (RSB_DEPTH > 0) begin : gen_rsb
			riscv_rsb #(
				.MXLEN(MXLEN),
				.DEPTH(RSB_DEPTH)
			) rsb_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.ena_i(!pd_stall_o),
				.d_i(rsb_nxt_pc),
				.q_o(rsb_predict_pc),
				.push_i(rsb_push),
				.pop_i(rsb_pop),
				.empty_o(rsb_empty)
			);
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex ({link_rd, link_rs1, rs1 == rd})
			3'b00z: {decode_rsb_push, decode_rsb_pop} = 2'b00;
			3'b01z: {decode_rsb_push, decode_rsb_pop} = 2'b01;
			3'b10z: {decode_rsb_push, decode_rsb_pop} = 2'b10;
			3'b110: {decode_rsb_push, decode_rsb_pop} = 2'b11;
			3'b111: {decode_rsb_push, decode_rsb_pop} = 2'b10;
		endcase
	end
	function [20:0] riscv_opcodes_pkg_decode_immUJ;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immUJ = {instr[31], instr[19-:8], instr[20], instr[30-:10], 1'b0};
	endfunction
	assign immUJ = riscv_opcodes_pkg_decode_immUJ(if_insn_i[31-:32]);
	function [12:0] riscv_opcodes_pkg_decode_immSB;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immSB = {instr[31], instr[7], instr[30-:6], instr[11-:4], 1'b0};
	endfunction
	assign immSB = riscv_opcodes_pkg_decode_immSB(if_insn_i[31-:32]);
	assign ext_immUJ = {{MXLEN - 21 {immUJ[20]}}, immUJ};
	assign ext_immSB = {{MXLEN - 13 {immSB[12]}}, immSB};
	localparam [6:2] riscv_opcodes_pkg_OPC_BRANCH = 5'b11000;
	localparam [6:2] riscv_opcodes_pkg_OPC_JAL = 5'b11011;
	localparam [6:2] riscv_opcodes_pkg_OPC_JALR = 5'b11001;
	function [4:0] riscv_opcodes_pkg_decode_opcode;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcode = instr[6-:5];
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({du_mode_i, if_insn_i[33], riscv_opcodes_pkg_decode_opcode(if_insn_i[31-:32])})
			{2'b00, riscv_opcodes_pkg_OPC_JAL}: begin
				branch_taken = 1'b1;
				branch_predicted = 2'b10;
				rsb_push = decode_rsb_push;
				rsb_pop = decode_rsb_pop;
				pd_nxt_pc_o = if_pc_i + ext_immUJ;
			end
			{2'b00, riscv_opcodes_pkg_OPC_JALR}: begin
				branch_taken = (has_rsb ? decode_rsb_pop : 1'b0);
				branch_predicted = 2'b00;
				rsb_push = decode_rsb_push;
				rsb_pop = decode_rsb_pop;
				pd_nxt_pc_o = rsb_predict_pc;
			end
			{2'b00, riscv_opcodes_pkg_OPC_BRANCH}: begin
				branch_taken = (HAS_BPU != 0 ? bp_bp_predict_i[1] : ext_immSB[31]);
				branch_predicted = (HAS_BPU != 0 ? bp_bp_predict_i : {ext_immSB[31], 1'b0});
				rsb_push = 1'b0;
				rsb_pop = 1'b0;
				pd_nxt_pc_o = if_pc_i + ext_immSB;
			end
			default: begin
				branch_taken = 1'b0;
				branch_predicted = 2'b00;
				rsb_push = 1'b0;
				rsb_pop = 1'b0;
				pd_nxt_pc_o = 'hx;
			end
		endcase
	end
	always @(posedge clk_i)
		if (!pd_stall_o)
			pd_rsb_pc_o <= (has_rsb ? rsb_predict_pc : {MXLEN {1'b0}});
	always @(posedge clk_i) stalled_branch <= branch_taken & id_stall_i;
	wire [1:1] sv2v_tmp_439CA;
	assign sv2v_tmp_439CA = branch_taken & ~stalled_branch;
	always @(*) pd_latch_nxt_pc_o = sv2v_tmp_439CA;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pd_bp_predict_o <= 2'b00;
		else if (!pd_stall_o)
			pd_bp_predict_o <= branch_predicted;
	initial _sv2v_0 = 0;
endmodule
