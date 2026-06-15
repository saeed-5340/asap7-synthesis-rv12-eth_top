module riscv_bu (
	rst_ni,
	clk_i,
	ex_stall_i,
	st_flush_i,
	bu_bubble_o,
	id_pc_i,
	id_rsb_pc_i,
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
	id_exceptions_i,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i,
	bu_exceptions_o,
	opA_i,
	opB_i
);
	reg _sv2v_0;
	parameter signed [31:0] MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter signed [31:0] BP_GLOBAL_BITS = 2;
	parameter signed [31:0] RSB_DEPTH = 0;
	parameter [0:0] HAS_RVC = 0;
	input rst_ni;
	input clk_i;
	input ex_stall_i;
	input st_flush_i;
	output reg bu_bubble_o;
	input [MXLEN - 1:0] id_pc_i;
	input [MXLEN - 1:0] id_rsb_pc_i;
	output reg [MXLEN - 1:0] bu_nxt_pc_o;
	output reg bu_flush_o;
	output reg cm_ic_invalidate_o;
	output reg cm_dc_invalidate_o;
	output reg cm_dc_clean_o;
	input [1:0] id_bp_predict_i;
	output reg [1:0] bu_bp_predict_o;
	input [BP_GLOBAL_BITS - 1:0] id_bp_history_i;
	output reg [BP_GLOBAL_BITS - 1:0] bu_bp_history_update_o;
	output reg [BP_GLOBAL_BITS - 1:0] bu_bp_history_o;
	output reg bu_bp_btaken_o;
	output reg bu_bp_update_o;
	input wire [34:0] id_insn_i;
	input wire [27:0] id_exceptions_i;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	output reg [27:0] bu_exceptions_o;
	input [MXLEN - 1:0] opA_i;
	input [MXLEN - 1:0] opB_i;
	localparam SBITS = $clog2(MXLEN);
	wire has_rvc;
	wire has_rsb;
	wire is_16bit_instruction;
	wire [14:0] opcR;
	wire [4:0] rs1;
	wire is_ret;
	reg misaligned_instruction;
	wire [20:0] immUJ;
	wire [12:0] immSB;
	wire [MXLEN - 1:0] ext_immUJ;
	wire [MXLEN - 1:0] ext_immSB;
	reg bu_bubble;
	reg pipeflush;
	reg ic_invalidate;
	reg dc_invalidate;
	reg dc_clean;
	reg cacheflush;
	reg btaken;
	reg bp_update;
	reg [BP_GLOBAL_BITS:0] bp_history;
	reg [MXLEN - 1:0] nxt_pc;
	assign has_rvc = HAS_RVC != 0;
	assign has_rsb = RSB_DEPTH > 0;
	assign is_16bit_instruction = ~&id_insn_i[1:0];
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(id_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rs1;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rs1 = instr[19-:5];
	endfunction
	assign rs1 = riscv_opcodes_pkg_decode_rs1(id_insn_i[31-:32]);
	assign is_ret = (rs1 == 1) | (rs1 == 5);
	localparam [6:2] riscv_opcodes_pkg_OPC_BRANCH = 5'b11000;
	localparam [6:2] riscv_opcodes_pkg_OPC_JALR = 5'b11001;
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({id_insn_i[33], id_insn_i[6-:5]})
			{1'b0, riscv_opcodes_pkg_OPC_JALR}: misaligned_instruction = (id_exceptions_i[0] | has_rvc ? nxt_pc[0] : |nxt_pc[1:0]);
			{1'b0, riscv_opcodes_pkg_OPC_BRANCH}: misaligned_instruction = (id_exceptions_i[0] | has_rvc ? nxt_pc[0] : |nxt_pc[1:0]);
			default: misaligned_instruction = id_exceptions_i[0];
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			bu_exceptions_o <= 'h0;
		else if (!ex_stall_i) begin
			if ((((bu_flush_o || st_flush_i) || ex_exceptions_i[27]) || mem_exceptions_i[27]) || wb_exceptions_i[27])
				bu_exceptions_o <= 'h0;
			else begin
				bu_exceptions_o <= id_exceptions_i;
				bu_exceptions_o[0] <= misaligned_instruction;
				bu_exceptions_o[27] <= id_exceptions_i[27] | misaligned_instruction;
			end
		end
	function [20:0] riscv_opcodes_pkg_decode_immUJ;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immUJ = {instr[31], instr[19-:8], instr[20], instr[30-:10], 1'b0};
	endfunction
	assign immUJ = riscv_opcodes_pkg_decode_immUJ(id_insn_i[31-:32]);
	function [12:0] riscv_opcodes_pkg_decode_immSB;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immSB = {instr[31], instr[7], instr[30-:6], instr[11-:4], 1'b0};
	endfunction
	assign immSB = riscv_opcodes_pkg_decode_immSB(id_insn_i[31-:32]);
	assign ext_immUJ = {{MXLEN - 21 {immUJ[20]}}, immUJ};
	assign ext_immSB = {{MXLEN - 13 {immSB[12]}}, immSB};
	localparam [14:0] riscv_opcodes_pkg_BEQ = 15'bzzzzzzz00011000;
	localparam [14:0] riscv_opcodes_pkg_BGE = 15'bzzzzzzz10111000;
	localparam [14:0] riscv_opcodes_pkg_BGEU = 15'bzzzzzzz11111000;
	localparam [14:0] riscv_opcodes_pkg_BLT = 15'bzzzzzzz10011000;
	localparam [14:0] riscv_opcodes_pkg_BLTU = 15'bzzzzzzz11011000;
	localparam [14:0] riscv_opcodes_pkg_BNE = 15'bzzzzzzz00111000;
	localparam [31:0] riscv_opcodes_pkg_FENCE = 32'b0000zzzzzzzz00000000000000001101;
	localparam [31:0] riscv_opcodes_pkg_FENCE_I = 32'b00000000000000000001000000001101;
	localparam [14:0] riscv_opcodes_pkg_JAL = 15'bzzzzzzzzzz11011;
	localparam [14:0] riscv_opcodes_pkg_JALR = 15'bzzzzzzz00011001;
	localparam [14:0] riscv_opcodes_pkg_MISCMEM = 15'bzzzzzzzzzz00011;
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({id_insn_i[33], opcR})
			{1'b0, riscv_opcodes_pkg_JAL}: begin
				bu_bubble = 1'b0;
				btaken = 1'b1;
				bp_update = 1'b0;
				pipeflush = ~id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = id_pc_i + ext_immUJ;
			end
			{1'b0, riscv_opcodes_pkg_JALR}:
				if (has_rsb) begin
					bu_bubble = 1'b0;
					btaken = 1'b1;
					bp_update = 1'b0;
					cacheflush = 1'b0;
					ic_invalidate = 1'b0;
					dc_invalidate = 1'b0;
					dc_clean = 1'b0;
					nxt_pc = (opA_i + opB_i) & {{MXLEN - 1 {1'b1}}, 1'b0};
					pipeflush = (is_ret ? nxt_pc[MXLEN - 1:1] != id_rsb_pc_i[MXLEN - 1:1] : 1'b1);
				end
				else begin
					bu_bubble = 1'b0;
					btaken = 1'b1;
					bp_update = 1'b0;
					pipeflush = 1'b1;
					cacheflush = 1'b0;
					ic_invalidate = 1'b0;
					dc_invalidate = 1'b0;
					dc_clean = 1'b0;
					nxt_pc = (opA_i + opB_i) & {{MXLEN - 1 {1'b1}}, 1'b0};
				end
			{1'b0, riscv_opcodes_pkg_BEQ}: begin
				bu_bubble = 1'b0;
				btaken = opA_i == opB_i;
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_BNE}: begin
				bu_bubble = 1'b0;
				btaken = opA_i != opB_i;
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_BLTU}: begin
				bu_bubble = 1'b0;
				btaken = opA_i < opB_i;
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_BGEU}: begin
				bu_bubble = 1'b0;
				btaken = opA_i >= opB_i;
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_BLT}: begin
				bu_bubble = 1'b0;
				btaken = $signed(opA_i) < $signed(opB_i);
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_BGE}: begin
				bu_bubble = 1'b0;
				btaken = $signed(opA_i) >= $signed(opB_i);
				bp_update = 1'b1;
				pipeflush = btaken ^ id_bp_predict_i[1];
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = (btaken ? id_pc_i + ext_immSB : id_pc_i + ('h2 << id_insn_i[1-:2]));
			end
			{1'b0, riscv_opcodes_pkg_MISCMEM}:
				case (id_insn_i[31-:32])
					riscv_opcodes_pkg_FENCE_I: begin
						bu_bubble = 1'b0;
						btaken = 1'b0;
						bp_update = 1'b0;
						pipeflush = 1'b1;
						cacheflush = 1'b1;
						ic_invalidate = 1'b1;
						dc_invalidate = 1'b0;
						dc_clean = 1'b1;
						nxt_pc = id_pc_i + ('h2 << id_insn_i[1-:2]);
					end
					riscv_opcodes_pkg_FENCE: begin
						bu_bubble = 1'b0;
						btaken = 1'b0;
						bp_update = 1'b0;
						pipeflush = 1'b0;
						cacheflush = 1'b0;
						ic_invalidate = 1'b0;
						dc_invalidate = 1'b0;
						dc_clean = 1'b0;
						nxt_pc = id_pc_i + ('h2 << id_insn_i[1-:2]);
					end
					default: begin
						bu_bubble = 1'b1;
						btaken = 1'b0;
						bp_update = 1'b0;
						pipeflush = 1'b0;
						cacheflush = 1'b0;
						ic_invalidate = 1'b0;
						dc_invalidate = 1'b0;
						dc_clean = 1'b0;
						nxt_pc = id_pc_i + ('h2 << id_insn_i[1-:2]);
					end
				endcase
			default: begin
				bu_bubble = 1'b1;
				btaken = 1'b0;
				bp_update = 1'b0;
				pipeflush = 1'b0;
				cacheflush = 1'b0;
				ic_invalidate = 1'b0;
				dc_invalidate = 1'b0;
				dc_clean = 1'b0;
				nxt_pc = id_pc_i + ('h2 << id_insn_i[1-:2]);
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			bu_bubble_o <= 1'b1;
		else if ((ex_exceptions_i[27] || mem_exceptions_i[27]) || wb_exceptions_i[27])
			bu_bubble_o <= 1'b1;
		else if (!ex_stall_i)
			bu_bubble_o <= bu_bubble;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			bu_flush_o <= 1'b1;
			cm_ic_invalidate_o <= 1'b0;
			cm_dc_invalidate_o <= 1'b0;
			cm_dc_clean_o <= 1'b0;
			bu_bp_predict_o <= 2'b00;
			bu_bp_btaken_o <= 1'b0;
			bu_bp_update_o <= 1'b0;
			bu_bp_history_update_o <= 'h0;
			bp_history <= 'h0;
		end
		else begin
			bu_flush_o <= pipeflush === 1'b1;
			cm_ic_invalidate_o <= ic_invalidate;
			cm_dc_invalidate_o <= dc_invalidate;
			cm_dc_clean_o <= dc_clean;
			bu_bp_predict_o <= id_bp_predict_i;
			bu_bp_btaken_o <= btaken;
			bu_bp_update_o <= bp_update;
			bu_bp_history_update_o <= id_bp_history_i;
			if (bp_update)
				bp_history <= {bp_history[BP_GLOBAL_BITS - 1:0], btaken};
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			bu_nxt_pc_o <= PC_INIT;
		else if (!ex_stall_i)
			bu_nxt_pc_o <= nxt_pc;
	wire [BP_GLOBAL_BITS:1] sv2v_tmp_6D9FC;
	assign sv2v_tmp_6D9FC = bp_history[BP_GLOBAL_BITS:1];
	always @(*) bu_bp_history_o = sv2v_tmp_6D9FC;
	initial _sv2v_0 = 0;
endmodule
