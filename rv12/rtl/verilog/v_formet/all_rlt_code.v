module riscv_alu (
	rst_ni,
	clk_i,
	ex_stall_i,
	id_pc_i,
	id_insn_i,
	opA_i,
	opB_i,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i,
	alu_bubble_o,
	alu_r_o,
	ex_csr_reg_o,
	ex_csr_wval_o,
	ex_csr_we_o,
	st_csr_rval_i,
	st_xlen_i
);
	parameter signed [31:0] MXLEN = 32;
	parameter [0:0] HAS_RVC = 0;
	input rst_ni;
	input clk_i;
	input ex_stall_i;
	input [MXLEN - 1:0] id_pc_i;
	input wire [34:0] id_insn_i;
	input [MXLEN - 1:0] opA_i;
	input [MXLEN - 1:0] opB_i;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	output reg alu_bubble_o;
	output reg [MXLEN - 1:0] alu_r_o;
	output reg [11:0] ex_csr_reg_o;
	output reg [MXLEN - 1:0] ex_csr_wval_o;
	output reg ex_csr_we_o;
	input [MXLEN - 1:0] st_csr_rval_i;
	input [1:0] st_xlen_i;
	function [MXLEN - 1:0] sext32;
		input [31:0] operand;
		reg sign;
		begin
			sign = operand[31];
			sext32 = {{MXLEN - 31 {sign}}, operand[30:0]};
		end
	endfunction
	localparam SBITS = $clog2(MXLEN);
	wire [14:0] opcR;
	wire xlen32;
	wire has_rvc;
	wire [31:0] opA32;
	wire [31:0] opB32;
	wire [SBITS - 1:0] shamt;
	wire [4:0] shamt32;
	wire [MXLEN - 1:0] csri;
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(id_insn_i[31-:32]);
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	assign has_rvc = HAS_RVC != 0;
	assign opA32 = opA_i[31:0];
	assign opB32 = opB_i[31:0];
	assign shamt = opB_i[SBITS - 1:0];
	assign shamt32 = opB_i[4:0];
	localparam [14:0] riscv_opcodes_pkg_ADD = 15'b000000000001100;
	localparam [14:0] riscv_opcodes_pkg_ADDI = 15'bzzzzzzz00000100;
	localparam [14:0] riscv_opcodes_pkg_ADDIW = 15'bzzzzzzz00000110;
	localparam [14:0] riscv_opcodes_pkg_ADDW = 15'b000000000001110;
	localparam [14:0] riscv_opcodes_pkg_AND = 15'b000000011101100;
	localparam [14:0] riscv_opcodes_pkg_ANDI = 15'bzzzzzzz11100100;
	localparam [14:0] riscv_opcodes_pkg_AUIPC = 15'bzzzzzzzzzz00101;
	localparam [14:0] riscv_opcodes_pkg_CSRRC = 15'bzzzzzzz01111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRCI = 15'bzzzzzzz11111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRS = 15'bzzzzzzz01011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRSI = 15'bzzzzzzz11011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRW = 15'bzzzzzzz00111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRWI = 15'bzzzzzzz10111100;
	localparam [14:0] riscv_opcodes_pkg_JAL = 15'bzzzzzzzzzz11011;
	localparam [14:0] riscv_opcodes_pkg_JALR = 15'bzzzzzzz00011001;
	localparam [14:0] riscv_opcodes_pkg_LUI = 15'bzzzzzzzzzz01101;
	localparam [14:0] riscv_opcodes_pkg_OR = 15'b000000011001100;
	localparam [14:0] riscv_opcodes_pkg_ORI = 15'bzzzzzzz11000100;
	localparam [14:0] riscv_opcodes_pkg_SLL = 15'b000000000101100;
	localparam [14:0] riscv_opcodes_pkg_SLLI = 15'b000000z00100100;
	localparam [14:0] riscv_opcodes_pkg_SLLIW = 15'b000000000100110;
	localparam [14:0] riscv_opcodes_pkg_SLLW = 15'b000000000101110;
	localparam [14:0] riscv_opcodes_pkg_SLT = 15'b000000001001100;
	localparam [14:0] riscv_opcodes_pkg_SLTI = 15'bzzzzzzz01000100;
	localparam [14:0] riscv_opcodes_pkg_SLTIU = 15'bzzzzzzz01100100;
	localparam [14:0] riscv_opcodes_pkg_SLTU = 15'b000000001101100;
	localparam [14:0] riscv_opcodes_pkg_SRA = 15'b010000010101100;
	localparam [14:0] riscv_opcodes_pkg_SRAI = 15'b010000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SRAIW = 15'b010000010100110;
	localparam [14:0] riscv_opcodes_pkg_SRAW = 15'b010000010101110;
	localparam [14:0] riscv_opcodes_pkg_SRL = 15'b000000010101100;
	localparam [14:0] riscv_opcodes_pkg_SRLI = 15'b000000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SRLIW = 15'b000000010100110;
	localparam [14:0] riscv_opcodes_pkg_SRLW = 15'b000000010101110;
	localparam [14:0] riscv_opcodes_pkg_SUB = 15'b010000000001100;
	localparam [14:0] riscv_opcodes_pkg_SUBW = 15'b010000000001110;
	localparam [14:0] riscv_opcodes_pkg_XOR = 15'b000000010001100;
	localparam [14:0] riscv_opcodes_pkg_XORI = 15'bzzzzzzz10000100;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			alu_r_o <= 'h0;
		else if (!ex_stall_i)
			casex ({xlen32, opcR})
				{1'bz, riscv_opcodes_pkg_LUI}: alu_r_o <= opA_i + opB_i;
				{1'bz, riscv_opcodes_pkg_AUIPC}: alu_r_o <= opA_i + opB_i;
				{1'bz, riscv_opcodes_pkg_JAL}: alu_r_o <= id_pc_i + ('h2 << id_insn_i[1:0]);
				{1'bz, riscv_opcodes_pkg_JALR}: alu_r_o <= id_pc_i + ('h2 << id_insn_i[1:0]);
				{1'bz, riscv_opcodes_pkg_ADDI}: alu_r_o <= opA_i + opB_i;
				{1'bz, riscv_opcodes_pkg_ADD}: alu_r_o <= opA_i + opB_i;
				{1'b0, riscv_opcodes_pkg_ADDIW}: alu_r_o <= sext32(opA32 + opB32);
				{1'b0, riscv_opcodes_pkg_ADDW}: alu_r_o <= sext32(opA32 + opB32);
				{1'bz, riscv_opcodes_pkg_SUB}: alu_r_o <= opA_i - opB_i;
				{1'b0, riscv_opcodes_pkg_SUBW}: alu_r_o <= sext32(opA32 - opB32);
				{1'bz, riscv_opcodes_pkg_XORI}: alu_r_o <= opA_i ^ opB_i;
				{1'bz, riscv_opcodes_pkg_XOR}: alu_r_o <= opA_i ^ opB_i;
				{1'bz, riscv_opcodes_pkg_ORI}: alu_r_o <= opA_i | opB_i;
				{1'bz, riscv_opcodes_pkg_OR}: alu_r_o <= opA_i | opB_i;
				{1'bz, riscv_opcodes_pkg_ANDI}: alu_r_o <= opA_i & opB_i;
				{1'bz, riscv_opcodes_pkg_AND}: alu_r_o <= opA_i & opB_i;
				{1'bz, riscv_opcodes_pkg_SLLI}: alu_r_o <= opA_i << shamt;
				{1'bz, riscv_opcodes_pkg_SLL}: alu_r_o <= opA_i << shamt;
				{1'b0, riscv_opcodes_pkg_SLLIW}: alu_r_o <= sext32(opA32 << shamt32);
				{1'b0, riscv_opcodes_pkg_SLLW}: alu_r_o <= sext32(opA32 << shamt32);
				{1'bz, riscv_opcodes_pkg_SLTI}: alu_r_o <= ({~opA_i[MXLEN - 1], opA_i[MXLEN - 2:0]} < {~opB_i[MXLEN - 1], opB_i[MXLEN - 2:0]} ? 'h1 : 'h0);
				{1'bz, riscv_opcodes_pkg_SLT}: alu_r_o <= ({~opA_i[MXLEN - 1], opA_i[MXLEN - 2:0]} < {~opB_i[MXLEN - 1], opB_i[MXLEN - 2:0]} ? 'h1 : 'h0);
				{1'bz, riscv_opcodes_pkg_SLTIU}: alu_r_o <= (opA_i < opB_i ? 'h1 : 'h0);
				{1'bz, riscv_opcodes_pkg_SLTU}: alu_r_o <= (opA_i < opB_i ? 'h1 : 'h0);
				{1'bz, riscv_opcodes_pkg_SRLI}: alu_r_o <= opA_i >> shamt;
				{1'bz, riscv_opcodes_pkg_SRL}: alu_r_o <= opA_i >> shamt;
				{1'b0, riscv_opcodes_pkg_SRLIW}: alu_r_o <= sext32(opA32 >> shamt32);
				{1'b0, riscv_opcodes_pkg_SRLW}: alu_r_o <= sext32(opA32 >> shamt32);
				{1'bz, riscv_opcodes_pkg_SRAI}: alu_r_o <= $signed(opA_i) >>> shamt;
				{1'bz, riscv_opcodes_pkg_SRA}: alu_r_o <= $signed(opA_i) >>> shamt;
				{1'b0, riscv_opcodes_pkg_SRAIW}: alu_r_o <= sext32($signed(opA32) >>> shamt32);
				{1'bz, riscv_opcodes_pkg_SRAW}: alu_r_o <= sext32($signed(opA32) >>> shamt32);
				{1'bz, riscv_opcodes_pkg_CSRRW}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				{1'bz, riscv_opcodes_pkg_CSRRWI}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				{1'bz, riscv_opcodes_pkg_CSRRS}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				{1'bz, riscv_opcodes_pkg_CSRRSI}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				{1'bz, riscv_opcodes_pkg_CSRRC}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				{1'bz, riscv_opcodes_pkg_CSRRCI}: alu_r_o <= {MXLEN {1'b0}} | st_csr_rval_i;
				default: alu_r_o <= 'hx;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			alu_bubble_o <= 1'b1;
		else if ((ex_exceptions_i[27] || mem_exceptions_i[27]) || wb_exceptions_i[27])
			alu_bubble_o <= 1'b1;
		else if (!ex_stall_i)
			casex ({xlen32, opcR})
				{1'bz, riscv_opcodes_pkg_LUI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_AUIPC}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_JAL}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_JALR}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_ADDI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_ADD}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_ADDIW}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_ADDW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SUB}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SUBW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_XORI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_XOR}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_ORI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_OR}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_ANDI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_AND}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLLI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLL}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SLLIW}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SLLW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLTI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLT}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLTIU}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SLTU}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SRLI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SRL}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SRLIW}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SRLW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SRAI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SRA}: alu_bubble_o <= id_insn_i[33];
				{1'b0, riscv_opcodes_pkg_SRAIW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_SRAW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRW}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRWI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRS}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRSI}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRC}: alu_bubble_o <= id_insn_i[33];
				{1'bz, riscv_opcodes_pkg_CSRRCI}: alu_bubble_o <= id_insn_i[33];
				default: alu_bubble_o <= 1'b1;
			endcase
	assign csri = {{MXLEN - 5 {1'b0}}, opB_i[4:0]};
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ex_csr_reg_o <= 'hx;
			ex_csr_wval_o <= 'hx;
			ex_csr_we_o <= 1'b0;
		end
		else begin
			ex_csr_reg_o <= id_insn_i[31-:12];
			casex ({id_insn_i[33], opcR})
				{1'b0, riscv_opcodes_pkg_CSRRW}: begin
					ex_csr_we_o <= 'b1;
					ex_csr_wval_o <= opA_i;
				end
				{1'b0, riscv_opcodes_pkg_CSRRWI}: begin
					ex_csr_we_o <= |csri;
					ex_csr_wval_o <= csri;
				end
				{1'b0, riscv_opcodes_pkg_CSRRS}: begin
					ex_csr_we_o <= |opA_i;
					ex_csr_wval_o <= st_csr_rval_i | opA_i;
				end
				{1'b0, riscv_opcodes_pkg_CSRRSI}: begin
					ex_csr_we_o <= |csri;
					ex_csr_wval_o <= st_csr_rval_i | csri;
				end
				{1'b0, riscv_opcodes_pkg_CSRRC}: begin
					ex_csr_we_o <= |opA_i;
					ex_csr_wval_o <= st_csr_rval_i & ~opA_i;
				end
				{1'b0, riscv_opcodes_pkg_CSRRCI}: begin
					ex_csr_we_o <= |csri;
					ex_csr_wval_o <= st_csr_rval_i & ~csri;
				end
				default: begin
					ex_csr_we_o <= 'b0;
					ex_csr_wval_o <= 'hx;
				end
			endcase
		end
endmodule
module riscv_bp (
	rst_ni,
	clk_i,
	id_stall_i,
	if_parcel_pc_i,
	if_parcel_bp_history_i,
	bp_bp_predict_o,
	ex_pc_i,
	bu_bp_history_i,
	bu_bp_predict_i,
	bu_bp_btaken_i,
	bu_bp_update_i
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter HAS_BPU = 0;
	parameter HAS_RVC = 0;
	parameter BP_GLOBAL_BITS = 2;
	parameter BP_LOCAL_BITS = 10;
	parameter BP_LOCAL_BITS_LSB = (HAS_RVC != 0 ? 1 : 2);
	parameter TECHNOLOGY = "GENERIC";
	parameter AVOID_X = 0;
	input rst_ni;
	input clk_i;
	input id_stall_i;
	input [MXLEN - 1:0] if_parcel_pc_i;
	input [BP_GLOBAL_BITS - 1:0] if_parcel_bp_history_i;
	output reg [1:0] bp_bp_predict_o;
	input [MXLEN - 1:0] ex_pc_i;
	input [BP_GLOBAL_BITS - 1:0] bu_bp_history_i;
	input [1:0] bu_bp_predict_i;
	input bu_bp_btaken_i;
	input bu_bp_update_i;
	localparam ADR_BITS = BP_GLOBAL_BITS + BP_LOCAL_BITS;
	localparam MEMORY_DEPTH = 1 << ADR_BITS;
	wire [ADR_BITS - 1:0] radr;
	wire [ADR_BITS - 1:0] wadr;
	reg [MXLEN - 1:0] if_parcel_pc_dly;
	wire [1:0] new_prediction;
	wire [1:0] current_prediction;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_parcel_pc_dly <= PC_INIT;
		else if (!id_stall_i)
			if_parcel_pc_dly <= if_parcel_pc_i;
	assign radr = (id_stall_i ? {if_parcel_bp_history_i, if_parcel_pc_dly[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]} : {if_parcel_bp_history_i, if_parcel_pc_i[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]});
	assign wadr = {bu_bp_history_i, ex_pc_i[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]};
	assign new_prediction[0] = bu_bp_predict_i[1] ^ bu_bp_btaken_i;
	assign new_prediction[1] = (bu_bp_predict_i[1] & ~bu_bp_predict_i[0]) | (bu_bp_btaken_i & bu_bp_predict_i[0]);
	rl_ram_1r1w #(
		.ABITS(ADR_BITS),
		.DBITS(2),
		.TECHNOLOGY(TECHNOLOGY),
		.RW_CONTENTION("DONT_CARE")
	) bp_ram_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.waddr_i(wadr),
		.din_i(new_prediction),
		.we_i(bu_bp_update_i),
		.be_i(1'b1),
		.raddr_i(radr),
		.re_i(1'b1),
		.dout_o(current_prediction)
	);
	generate
		if (AVOID_X) begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					bp_bp_predict_o <= (current_prediction == 2'bxx ? $random : current_prediction);
		end
		else begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					bp_bp_predict_o <= current_prediction;
		end
	endgenerate
endmodule
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
module riscv_cache_biu_ctrl (
	rst_ni,
	clk_i,
	flush_i,
	biucmd_i,
	biucmd_ack_o,
	biucmd_busy_o,
	biucmd_noncacheable_req_i,
	biucmd_noncacheable_ack_o,
	biucmd_tag_i,
	inflight_cnt_o,
	req_i,
	adr_i,
	size_i,
	prot_i,
	lock_i,
	we_i,
	be_i,
	d_i,
	evictbuffer_adr_i,
	evictbuffer_d_i,
	in_biubuffer_o,
	biubuffer_o,
	biu_line_o,
	biu_line_dirty_o,
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
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter INFLIGHT_DEPTH = 2;
	parameter BIUTAG_SIZE = 2;
	function automatic integer riscv_cache_pkg_no_of_block_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_bits = 8 * block_size;
	endfunction
	localparam BLK_BITS = riscv_cache_pkg_no_of_block_bits(BLOCK_SIZE);
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire [1:0] biucmd_i;
	output reg biucmd_ack_o;
	output reg biucmd_busy_o;
	input wire biucmd_noncacheable_req_i;
	output wire biucmd_noncacheable_ack_o;
	input wire [BIUTAG_SIZE - 1:0] biucmd_tag_i;
	output reg [INFLIGHT_BITS - 1:0] inflight_cnt_o;
	input wire req_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire [2:0] prot_i;
	input wire lock_i;
	input wire we_i;
	input wire [(XLEN / 8) - 1:0] be_i;
	input wire [XLEN - 1:0] d_i;
	input wire [PLEN - 1:0] evictbuffer_adr_i;
	input wire [BLK_BITS - 1:0] evictbuffer_d_i;
	output wire in_biubuffer_o;
	output reg [BLK_BITS - 1:0] biubuffer_o;
	output reg [BLK_BITS - 1:0] biu_line_o;
	output wire biu_line_dirty_o;
	output reg biu_stb_o;
	input wire biu_stb_ack_i;
	input wire biu_d_ack_i;
	output reg [PLEN - 1:0] biu_adri_o;
	input wire [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output reg [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire [2:0] biu_prot_o;
	output reg biu_we_o;
	output reg [XLEN - 1:0] biu_d_o;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input wire [BIUTAG_SIZE - 1:0] biu_tago_i;
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
	function automatic integer riscv_cache_pkg_no_of_data_offset_bits;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_no_of_data_offset_bits = $clog2(no_of_block_bits / xlen);
	endfunction
	localparam DAT_OFFS_BITS = riscv_cache_pkg_no_of_data_offset_bits(XLEN, BLK_BITS);
	function automatic integer riscv_cache_pkg_burst_size;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_burst_size = no_of_block_bits / xlen;
	endfunction
	localparam BURST_SIZE = riscv_cache_pkg_burst_size(XLEN, BLK_BITS);
	localparam BURST_BITS = $clog2(BURST_SIZE);
	localparam BURST_OFFS = XLEN / 8;
	localparam BURST_LSB = $clog2(BURST_OFFS);
	function automatic [3:0] biu_type2cnt;
		input reg [2:0] biu_type;
		case (biu_type)
			3'b000: biu_type2cnt = 0;
			3'b001: biu_type2cnt = 0;
			3'b010: biu_type2cnt = 3;
			3'b011: biu_type2cnt = 3;
			3'b100: biu_type2cnt = 7;
			3'b101: biu_type2cnt = 7;
			3'b110: biu_type2cnt = 15;
			3'b111: biu_type2cnt = 15;
			default: biu_type2cnt = 4'hx;
		endcase
	endfunction
	function automatic [XLEN - 1:0] be_mux;
		input [(XLEN / 8) - 1:0] be;
		input [XLEN - 1:0] data_old;
		input [XLEN - 1:0] data_new;
		reg signed [31:0] i;
		for (i = 0; i < (XLEN / 8); i = i + 1)
			be_mux[i * 8+:8] = (be[i] ? data_new[i * 8+:8] : data_old[i * 8+:8]);
	endfunction
	genvar _gv_way_1;
	integer n;
	reg [1:0] biufsm_state;
	reg [BURST_SIZE - 1:0] biubuffer_valid;
	reg biubuffer_dirty;
	wire [DAT_OFFS_BITS - 1:0] dat_offset;
	wire biu_adro_eq_cache_adr;
	wire [XLEN - 1:0] biu_q;
	reg [PLEN - 1:0] biu_adri_hold;
	reg [XLEN - 1:0] biu_d_hold;
	reg biu_we_hold;
	reg [BURST_BITS - 1:0] burst_cnt;
	reg [INFLIGHT_BITS - 1:0] discard;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			biufsm_state <= 2'd0;
			biucmd_busy_o <= 1'b0;
		end
		else
			(* full_case, parallel_case *)
			case (biufsm_state)
				2'd0:
					(* full_case, parallel_case *)
					case (biucmd_i)
						2'h0:
							;
						2'h1: begin
							biucmd_busy_o <= 1'b1;
							if (biu_stb_ack_i)
								biufsm_state <= 2'd2;
							else
								biufsm_state <= 2'd1;
						end
						2'h2: begin
							biucmd_busy_o <= 1'b1;
							if (biu_stb_ack_i)
								biufsm_state <= 2'd2;
							else
								biufsm_state <= 2'd1;
						end
					endcase
				2'd1:
					if (biu_stb_ack_i)
						biufsm_state <= 2'd2;
				2'd2:
					if (biu_err_i || (~|burst_cnt && biu_ack_i)) begin
						biufsm_state <= 2'd0;
						biucmd_busy_o <= 1'b0;
					end
			endcase
	assign biu_adro_eq_cache_adr = biu_adro_i[PLEN - 1:BURST_LSB] == adr_i[PLEN - 1:BURST_LSB];
	assign biu_q = (we_i && biu_adro_eq_cache_adr ? be_mux(be_i, biu_q_i, d_i) : biu_q_i);
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0: begin
				if (biucmd_i == 2'h2)
					biubuffer_o <= evictbuffer_d_i >> XLEN;
				biubuffer_valid <= 'h0;
				biubuffer_dirty <= 1'b0;
			end
			2'd2:
				if (!biu_we_hold) begin
					if (biu_ack_i) begin
						biubuffer_o[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS] * XLEN+:XLEN] <= biu_q;
						biubuffer_valid[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS]] <= 1'b1;
						biubuffer_dirty <= biubuffer_dirty | we_i;
					end
				end
				else if (biu_d_ack_i) begin
					biubuffer_o <= biubuffer_o >> XLEN;
					biubuffer_valid <= 'h0;
					biubuffer_dirty <= 1'b0;
				end
			default:
				;
		endcase
	assign dat_offset = adr_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS];
	assign in_biubuffer_o = (req_i & (biu_adri_hold[PLEN - 1:BLK_OFFS_BITS] == adr_i[PLEN - 1:BLK_OFFS_BITS])) & (biubuffer_valid >> dat_offset);
	always @(*) begin
		if (_sv2v_0)
			;
		biu_line_o = biubuffer_o;
		biu_line_o[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS] * XLEN+:XLEN] = biu_q;
	end
	assign biu_line_dirty_o = biubuffer_dirty | we_i;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd2: biucmd_ack_o = (~|burst_cnt & biu_ack_i) | biu_err_i;
			default: biucmd_ack_o = 1'b0;
		endcase
	end
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0: burst_cnt <= {BURST_BITS {1'b1}};
			2'd2:
				if (biu_ack_i)
					burst_cnt <= burst_cnt - 1;
		endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inflight_cnt_o <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({biu_stb_ack_i, biu_ack_i | biu_err_i})
				2'b01: inflight_cnt_o <= inflight_cnt_o - 1;
				2'b10: inflight_cnt_o <= (inflight_cnt_o + 1) + biu_type2cnt(biu_type_o);
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			discard <= 'h0;
		else if (flush_i) begin
			if (|inflight_cnt_o && (biu_ack_i | biu_err_i))
				discard <= inflight_cnt_o - 1;
			else
				discard <= inflight_cnt_o;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	assign biucmd_noncacheable_ack_o = (biu_ack_i & ~flush_i) & ~|discard;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0:
				(* full_case, parallel_case *)
				case (biucmd_i)
					2'h0: begin
						biu_stb_o = biucmd_noncacheable_req_i;
						biu_adri_o = adr_i[0+:PLEN];
						biu_we_o = we_i;
						biu_d_o = d_i;
					end
					2'h1: begin
						biu_stb_o = 1'b1;
						biu_adri_o = {adr_i[PLEN - 1:BURST_LSB], {BURST_LSB {1'b0}}};
						biu_we_o = 1'b0;
						biu_d_o = 'hx;
					end
					2'h2: begin
						biu_stb_o = 1'b1;
						biu_adri_o = evictbuffer_adr_i;
						biu_we_o = 1'b1;
						biu_d_o = evictbuffer_d_i[0+:XLEN];
					end
				endcase
			2'd1: begin
				biu_stb_o = 1'b1;
				biu_adri_o = biu_adri_hold;
				biu_we_o = biu_we_hold;
				biu_d_o = biu_d_hold;
			end
			2'd2: begin
				biu_stb_o = 1'b0;
				biu_adri_o = 'hx;
				biu_we_o = 1'bx;
				biu_d_o = biubuffer_o[0+:XLEN];
			end
			default: begin
				biu_stb_o = 1'b0;
				biu_adri_o = 'hx;
				biu_we_o = 1'bx;
				biu_d_o = 'hx;
			end
		endcase
	end
	always @(posedge clk_i)
		if (biufsm_state == 2'd0) begin
			biu_adri_hold <= biu_adri_o;
			biu_we_hold <= biu_we_o;
			biu_d_hold <= biu_d_o;
		end
	assign biu_tagi_o = biucmd_tag_i;
	assign biu_size_o = (biucmd_noncacheable_req_i ? size_i : (XLEN == 64 ? 3'b011 : 3'b010));
	localparam [2:0] biu_constants_pkg_PROT_CACHEABLE = 3'b100;
	localparam [2:0] biu_constants_pkg_PROT_NONCACHEABLE = 3'b000;
	assign biu_prot_o = prot_i | (biucmd_noncacheable_req_i ? biu_constants_pkg_PROT_NONCACHEABLE : biu_constants_pkg_PROT_CACHEABLE);
	assign biu_lock_o = lock_i;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((biufsm_state == 2'd0) && (biucmd_i == 2'h0))
			biu_type_o = 3'b001;
		else
			(* full_case, parallel_case *)
			case (BURST_SIZE)
				16: biu_type_o = 3'b110;
				8: biu_type_o = 3'b100;
				default: biu_type_o = 3'b010;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
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
module riscv_cache_setup (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	invalidate_i,
	clean_i,
	req_o,
	rreq_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	q_o,
	invalidate_o,
	clean_o,
	idx_o
);
	parameter XLEN = 32;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
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
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire invalidate_i;
	input wire clean_i;
	output reg req_o;
	output wire rreq_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg [2:0] prot_o;
	output reg we_o;
	output reg [XLEN - 1:0] q_o;
	output reg invalidate_o;
	output reg clean_o;
	output wire [IDX_BITS - 1:0] idx_o;
	reg flush_dly;
	wire [IDX_BITS - 1:0] adr_idx;
	reg [IDX_BITS - 1:0] adr_idx_dly;
	reg invalidate_hold;
	reg clean_hold;
	always @(posedge clk_i) flush_dly <= flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_hold <= 1'b0;
		else if (!stall_i)
			invalidate_hold <= 1'b0;
		else
			invalidate_hold <= invalidate_i | invalidate_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			clean_hold <= 1'b0;
		else if (!stall_i)
			clean_hold <= 1'b0;
		else
			clean_hold <= clean_i | clean_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			size_o <= size_i;
			lock_o <= lock_i;
			prot_o <= prot_i;
			we_o <= we_i;
			q_o <= d_i;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			invalidate_o <= 1'b0;
			clean_o <= 1'b0;
		end
		else if (!stall_i) begin
			invalidate_o <= invalidate_i | invalidate_hold;
			clean_o <= clean_i | clean_hold;
		end
	assign rreq_o = req_i & ~we_i;
	assign adr_idx = adr_i[BLK_OFFS_BITS+:IDX_BITS];
	always @(posedge clk_i)
		if (!stall_i || flush_dly)
			adr_idx_dly <= adr_idx;
	assign idx_o = (stall_i ? adr_idx_dly : adr_idx);
endmodule
module riscv_cache_tag (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	phys_adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	invalidate_i,
	clean_i,
	pagefault_i,
	invalidate_all_blocks_i,
	req_o,
	wreq_o,
	adr_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	be_o,
	q_o,
	invalidate_o,
	clean_o,
	pagefault_o,
	core_tag_o
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
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
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [PLEN - 1:0] phys_adr_i;
	input wire [2:0] size_i;
	input lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire invalidate_i;
	input wire clean_i;
	input wire pagefault_i;
	input wire invalidate_all_blocks_i;
	output reg req_o;
	output reg wreq_o;
	output reg [PLEN - 1:0] adr_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg [2:0] prot_o;
	output reg we_o;
	output reg [(XLEN / 8) - 1:0] be_o;
	output reg [XLEN - 1:0] q_o;
	output reg invalidate_o;
	output reg clean_o;
	output reg pagefault_o;
	output wire [TAG_BITS - 1:0] core_tag_o;
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
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wreq_o <= 1'b0;
		else if (flush_i)
			wreq_o <= 1'b0;
		else if (!stall_i)
			wreq_o <= req_i & we_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			adr_o <= phys_adr_i;
			size_o <= size_i;
			lock_o <= lock_i;
			prot_o <= prot_i;
			we_o <= we_i;
			be_o <= size2be(size_i, phys_adr_i);
			q_o <= d_i;
			pagefault_o <= pagefault_i;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			clean_o <= 1'b0;
		else if (!stall_i)
			clean_o <= clean_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			invalidate_o <= 1'b0;
		else if (invalidate_all_blocks_i)
			invalidate_o <= 1'b0;
		else if (!stall_i)
			invalidate_o <= invalidate_i;
	assign core_tag_o = phys_adr_i[PLEN - 1-:TAG_BITS];
endmodule
module riscv_core (
	rst_ni,
	clk_i,
	imem_adr_o,
	imem_req_o,
	imem_ack_i,
	imem_flush_o,
	imem_parcel_i,
	imem_parcel_valid_i,
	imem_parcel_misaligned_i,
	imem_parcel_page_fault_i,
	imem_parcel_error_i,
	dmem_adr_o,
	dmem_d_o,
	dmem_q_i,
	dmem_we_o,
	dmem_size_o,
	dmem_lock_o,
	dmem_req_o,
	dmem_ack_i,
	dmem_err_i,
	dmem_misaligned_i,
	dmem_page_fault_i,
	st_prv_o,
	st_pmpcfg_o,
	st_pmpaddr_o,
	cm_ic_invalidate_o,
	cm_dc_invalidate_o,
	cm_dc_clean_o,
	int_nmi_i,
	int_timer_i,
	int_software_i,
	int_external_i,
	dbg_stall_i,
	dbg_strb_i,
	dbg_we_i,
	dbg_addr_i,
	dbg_dati_i,
	dbg_dato_o,
	dbg_ack_o,
	dbg_bp_o
);
	parameter signed [31:0] MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter [0:0] HAS_USER = 0;
	parameter [0:0] HAS_SUPER = 0;
	parameter [0:0] HAS_HYPER = 0;
	parameter [0:0] HAS_BPU = 1;
	parameter [0:0] HAS_FPU = 0;
	parameter [0:0] HAS_MMU = 0;
	parameter [0:0] HAS_RVA = 0;
	parameter [0:0] HAS_RVB = 0;
	parameter [0:0] HAS_RVC = 0;
	parameter [0:0] HAS_RVM = 0;
	parameter [0:0] HAS_RVN = 0;
	parameter [0:0] HAS_RVP = 0;
	parameter [0:0] HAS_RVT = 0;
	parameter [0:0] IS_RV32E = 0;
	parameter signed [31:0] RF_REGOUT = 1;
	parameter signed [31:0] MULT_LATENCY = 1;
	parameter signed [31:0] BREAKPOINTS = 3;
	parameter signed [31:0] PMP_CNT = 16;
	parameter signed [31:0] BP_GLOBAL_BITS = 2;
	parameter signed [31:0] BP_LOCAL_BITS = 10;
	parameter signed [31:0] RSB_DEPTH = 0;
	parameter TECHNOLOGY = "GENERIC";
	parameter [MXLEN - 1:0] MNMIVEC_DEFAULT = PC_INIT - 'h4;
	parameter [MXLEN - 1:0] MTVEC_DEFAULT = PC_INIT - 'h40;
	parameter [MXLEN - 1:0] HTVEC_DEFAULT = PC_INIT - 'h80;
	parameter [MXLEN - 1:0] STVEC_DEFAULT = PC_INIT - 'hc0;
	parameter [7:0] JEDEC_BANK = 10;
	parameter [6:0] JEDEC_MANUFACTURER_ID = 'h6e;
	parameter [MXLEN - 1:0] HARTID = 0;
	parameter signed [31:0] PARCEL_SIZE = 16;
	parameter signed [31:0] MEM_STAGES = 1;
	input wire rst_ni;
	input wire clk_i;
	output wire [MXLEN - 1:0] imem_adr_o;
	output wire imem_req_o;
	input wire imem_ack_i;
	output wire imem_flush_o;
	input wire [MXLEN - 1:0] imem_parcel_i;
	input wire [(MXLEN / PARCEL_SIZE) - 1:0] imem_parcel_valid_i;
	input wire imem_parcel_misaligned_i;
	input wire imem_parcel_page_fault_i;
	input wire imem_parcel_error_i;
	output wire [MXLEN - 1:0] dmem_adr_o;
	output wire [MXLEN - 1:0] dmem_d_o;
	input wire [MXLEN - 1:0] dmem_q_i;
	output wire dmem_we_o;
	output wire [2:0] dmem_size_o;
	output wire dmem_lock_o;
	output wire dmem_req_o;
	input wire dmem_ack_i;
	input wire dmem_err_i;
	input wire dmem_misaligned_i;
	input wire dmem_page_fault_i;
	output wire [1:0] st_prv_o;
	output wire [127:0] st_pmpcfg_o;
	output wire [(16 * MXLEN) - 1:0] st_pmpaddr_o;
	output wire cm_ic_invalidate_o;
	output wire cm_dc_invalidate_o;
	output wire cm_dc_clean_o;
	input wire int_nmi_i;
	input wire int_timer_i;
	input wire int_software_i;
	input wire [3:0] int_external_i;
	input wire dbg_stall_i;
	input wire dbg_strb_i;
	input wire dbg_we_i;
	localparam riscv_du_pkg_DBG_ADDR_SIZE = 16;
	input wire [15:0] dbg_addr_i;
	input wire [MXLEN - 1:0] dbg_dati_i;
	output wire [MXLEN - 1:0] dbg_dato_o;
	output wire dbg_ack_o;
	output wire dbg_bp_o;
	wire [MXLEN - 1:0] pd_nxt_pc;
	wire [MXLEN - 1:0] bu_nxt_pc;
	wire [MXLEN - 1:0] st_nxt_pc;
	wire [MXLEN - 1:0] if_predict_pc;
	wire [MXLEN - 1:0] if_nxt_pc;
	wire [MXLEN - 1:0] if_pc;
	wire [MXLEN - 1:0] pd_pc;
	wire [MXLEN - 1:0] pd_rsb_pc;
	wire [MXLEN - 1:0] id_pc;
	wire [MXLEN - 1:0] id_rsb_pc;
	wire [MXLEN - 1:0] ex_pc;
	wire [MXLEN - 1:0] mem_pc [0:MEM_STAGES - 1];
	wire [MXLEN - 1:0] wb_pc;
	wire [34:0] if_nxt_insn;
	wire [34:0] if_insn;
	wire [34:0] pd_insn;
	wire [34:0] id_insn;
	wire [34:0] ex_insn;
	wire [(MEM_STAGES * 35) - 1:0] mem_insn;
	wire [34:0] wb_insn;
	wire [34:0] dwb_insn;
	wire pd_flush;
	wire bu_flush;
	wire st_flush;
	wire du_flush;
	wire bu_cacheflush;
	wire cm_ic_invalidate;
	wire cm_dc_invalidate;
	wire cm_dc_clean;
	wire du_flush_cache;
	wire id_stall;
	wire pd_stall;
	wire ex_stall;
	wire mem_stall [0:MEM_STAGES + 0];
	wire wb_stall;
	wire du_stall;
	wire du_stall_if;
	wire [1:0] bp_bp_predict;
	wire [1:0] pd_bp_predict;
	wire [1:0] id_bp_predict;
	wire [1:0] bu_bp_predict;
	wire pd_latch_nxt_pc;
	wire [BP_GLOBAL_BITS - 1:0] bu_bp_history;
	wire [BP_GLOBAL_BITS - 1:0] if_predict_history;
	wire [BP_GLOBAL_BITS - 1:0] if_bp_history;
	wire [BP_GLOBAL_BITS - 1:0] pd_bp_history;
	wire [BP_GLOBAL_BITS - 1:0] id_bp_history;
	wire [BP_GLOBAL_BITS - 1:0] bu_bp_history_update;
	wire bu_bp_btaken;
	wire bu_bp_update;
	wire [5:0] st_interrupts;
	wire [27:0] if_exceptions;
	wire [27:0] pd_exceptions;
	wire [27:0] id_exceptions;
	wire [27:0] ex_exceptions;
	wire [27:0] mem_exceptions_dn [0:MEM_STAGES - 1];
	wire [27:0] mem_exceptions_up [0:MEM_STAGES + 0];
	wire [27:0] wb_exceptions;
	wire [4:0] pd_rs1;
	wire [4:0] pd_rs2;
	wire [4:0] id_rs1;
	wire [4:0] id_rs2;
	wire [4:0] rf_src1;
	wire [4:0] rf_src2;
	wire [MXLEN - 1:0] rf_srcv1;
	wire [MXLEN - 1:0] rf_srcv2;
	wire [MXLEN - 1:0] id_opA;
	wire [MXLEN - 1:0] id_opB;
	wire [MXLEN - 1:0] ex_r;
	wire [(MEM_STAGES * MXLEN) - 1:0] mem_r;
	wire [MXLEN - 1:0] mem_memadr [0:MEM_STAGES - 1];
	wire [MXLEN - 1:0] wb_r;
	wire [MXLEN - 1:0] wb_memq;
	wire [MXLEN - 1:0] dwb_r;
	wire id_userf_opA;
	wire id_userf_opB;
	wire id_bypex_opA;
	wire id_bypex_opB;
	wire [1:0] st_xlen;
	wire st_be;
	wire st_tvm;
	wire st_tw;
	wire st_tsr;
	wire [MXLEN - 1:0] st_mcounteren;
	wire [MXLEN - 1:0] st_scounteren;
	wire [11:0] pd_csr_reg;
	wire [11:0] ex_csr_reg;
	wire [MXLEN - 1:0] ex_csr_wval;
	wire [MXLEN - 1:0] st_csr_rval;
	wire [MXLEN - 1:0] du_csr_rval;
	wire ex_csr_we;
	wire [4:0] wb_dst;
	wire [0:0] wb_we;
	wire [MXLEN - 1:0] wb_badaddr;
	wire du_latch_nxt_pc;
	wire du_re_rf;
	wire du_we_rf;
	wire du_we_frf;
	wire du_re_csr;
	wire du_we_csr;
	wire du_we_pc;
	localparam riscv_du_pkg_DU_ADDR_SIZE = 12;
	wire [11:0] du_addr;
	wire [MXLEN - 1:0] du_dato;
	wire [MXLEN - 1:0] du_dati_rf;
	wire [MXLEN - 1:0] du_dati_frf;
	wire [MXLEN - 1:0] du_interrupts;
	wire [MXLEN - 1:0] du_ie;
	wire [63:0] du_exceptions;
	wire [63:0] du_ee;
	assign cm_ic_invalidate_o = cm_ic_invalidate | du_flush_cache;
	assign cm_dc_invalidate_o = cm_dc_invalidate | du_flush_cache;
	assign cm_dc_clean_o = cm_dc_clean | du_flush_cache;
	riscv_if #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT),
		.HAS_RVC(HAS_RVC),
		.BP_GLOBAL_BITS(BP_GLOBAL_BITS)
	) if_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.imem_adr_o(imem_adr_o),
		.imem_req_o(imem_req_o),
		.imem_ack_i(imem_ack_i),
		.imem_flush_o(imem_flush_o),
		.imem_parcel_i(imem_parcel_i),
		.imem_parcel_valid_i(imem_parcel_valid_i),
		.imem_parcel_misaligned_i(imem_parcel_misaligned_i),
		.imem_parcel_page_fault_i(imem_parcel_page_fault_i),
		.imem_parcel_error_i(imem_parcel_error_i),
		.bu_bp_history_i(bu_bp_history),
		.if_predict_history_o(if_predict_history),
		.if_bp_history_o(if_bp_history),
		.if_predict_pc_o(if_predict_pc),
		.if_nxt_pc_o(if_nxt_pc),
		.if_nxt_insn_o(if_nxt_insn),
		.if_pc_o(if_pc),
		.if_insn_o(if_insn),
		.if_exceptions_o(if_exceptions),
		.pd_exceptions_i(pd_exceptions),
		.id_exceptions_i(id_exceptions),
		.ex_exceptions_i(ex_exceptions),
		.mem_exceptions_i(mem_exceptions_up[0]),
		.wb_exceptions_i(wb_exceptions),
		.pd_pc_i(pd_pc),
		.pd_stall_i(pd_stall),
		.pd_flush_i(pd_flush),
		.bu_flush_i(bu_flush),
		.st_flush_i(st_flush),
		.du_stall_i(du_stall_if),
		.du_flush_i(du_flush),
		.du_we_pc_i(du_we_pc),
		.du_dato_i(du_dato),
		.du_latch_nxt_pc_i(du_latch_nxt_pc),
		.pd_latch_nxt_pc_i(pd_latch_nxt_pc),
		.pd_nxt_pc_i(pd_nxt_pc),
		.bu_nxt_pc_i(bu_nxt_pc),
		.st_nxt_pc_i(st_nxt_pc),
		.st_xlen_i(st_xlen)
	);
	riscv_pd #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT),
		.HAS_RVC(HAS_RVC),
		.HAS_BPU(HAS_BPU),
		.BP_GLOBAL_BITS(BP_GLOBAL_BITS),
		.RSB_DEPTH(RSB_DEPTH)
	) pd_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.id_stall_i(id_stall),
		.pd_stall_o(pd_stall),
		.du_mode_i(du_stall_if),
		.bu_flush_i(bu_flush),
		.st_flush_i(st_flush),
		.pd_flush_o(pd_flush),
		.pd_rs1_o(pd_rs1),
		.pd_rs2_o(pd_rs2),
		.pd_csr_reg_o(pd_csr_reg),
		.if_bp_history_i(if_bp_history),
		.pd_bp_history_o(pd_bp_history),
		.bp_bp_predict_i(bp_bp_predict),
		.pd_bp_predict_o(pd_bp_predict),
		.pd_latch_nxt_pc_o(pd_latch_nxt_pc),
		.bu_nxt_pc_i(bu_nxt_pc),
		.st_nxt_pc_i(st_nxt_pc),
		.pd_nxt_pc_o(pd_nxt_pc),
		.pd_rsb_pc_o(pd_rsb_pc),
		.if_pc_i(if_pc),
		.if_insn_i(if_insn),
		.id_insn_i(id_insn),
		.pd_pc_o(pd_pc),
		.pd_insn_o(pd_insn),
		.if_exceptions_i(if_exceptions),
		.pd_exceptions_o(pd_exceptions),
		.id_exceptions_i(id_exceptions),
		.ex_exceptions_i(ex_exceptions),
		.mem_exceptions_i(mem_exceptions_up[0]),
		.wb_exceptions_i(wb_exceptions)
	);
	riscv_id #(
		.XLEN(MXLEN),
		.PC_INIT(PC_INIT),
		.HAS_USER(HAS_USER),
		.HAS_SUPER(HAS_SUPER),
		.HAS_HYPER(HAS_HYPER),
		.HAS_RVA(HAS_RVA),
		.HAS_RVM(HAS_RVM),
		.HAS_RVC(HAS_RVC),
		.MULT_LATENCY(MULT_LATENCY),
		.RF_REGOUT(RF_REGOUT),
		.BP_GLOBAL_BITS(BP_GLOBAL_BITS),
		.RSB_DEPTH(RSB_DEPTH),
		.MEM_STAGES(MEM_STAGES),
		.PMP_CNT(PMP_CNT)
	) id_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.id_stall_o(id_stall),
		.ex_stall_i(ex_stall),
		.du_stall_i(du_stall),
		.bu_flush_i(bu_flush),
		.st_flush_i(st_flush),
		.du_flush_i(du_flush),
		.bu_nxt_pc_i(bu_nxt_pc),
		.if_nxt_pc_i(if_nxt_pc),
		.st_nxt_pc_i(st_nxt_pc),
		.pd_pc_i(pd_pc),
		.id_pc_o(id_pc),
		.pd_rsb_pc_i(pd_rsb_pc),
		.id_rsb_pc_o(id_rsb_pc),
		.pd_bp_history_i(pd_bp_history),
		.id_bp_history_o(id_bp_history),
		.pd_bp_predict_i(pd_bp_predict),
		.id_bp_predict_o(id_bp_predict),
		.pd_insn_i(pd_insn),
		.id_insn_o(id_insn),
		.ex_insn_i(ex_insn),
		.mem_insn_i(mem_insn),
		.wb_insn_i(wb_insn),
		.dwb_insn_i(dwb_insn),
		.st_interrupts_i(st_interrupts),
		.int_nmi_i(int_nmi_i),
		.pd_exceptions_i(pd_exceptions),
		.id_exceptions_o(id_exceptions),
		.ex_exceptions_i(ex_exceptions),
		.mem_exceptions_i(mem_exceptions_up[0]),
		.wb_exceptions_i(wb_exceptions),
		.st_prv_i(st_prv_o),
		.st_xlen_i(st_xlen),
		.st_tvm_i(st_tvm),
		.st_tw_i(st_tw),
		.st_tsr_i(st_tsr),
		.st_mcounteren_i(st_mcounteren),
		.st_scounteren_i(st_scounteren),
		.id_rs1_o(id_rs1),
		.id_rs2_o(id_rs2),
		.id_opA_o(id_opA),
		.id_opB_o(id_opB),
		.id_userf_opA_o(id_userf_opA),
		.id_userf_opB_o(id_userf_opB),
		.id_bypex_opA_o(id_bypex_opA),
		.id_bypex_opB_o(id_bypex_opB),
		.ex_r_i(ex_r),
		.mem_r_i(mem_r),
		.wb_r_i(wb_r),
		.wb_memq_i(wb_memq),
		.dwb_r_i(dwb_r)
	);
	riscv_ex #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT),
		.HAS_RVC(HAS_RVC),
		.HAS_RVA(HAS_RVA),
		.HAS_RVM(HAS_RVM),
		.MULT_LATENCY(MULT_LATENCY),
		.BP_GLOBAL_BITS(BP_GLOBAL_BITS),
		.RSB_DEPTH(RSB_DEPTH)
	) ex_units(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.mem_stall_i(mem_stall[0]),
		.ex_stall_o(ex_stall),
		.id_pc_i(id_pc),
		.ex_pc_o(ex_pc),
		.bu_nxt_pc_o(bu_nxt_pc),
		.bu_flush_o(bu_flush),
		.id_rsb_pc_i(id_rsb_pc),
		.cm_ic_invalidate_o(cm_ic_invalidate),
		.cm_dc_invalidate_o(cm_dc_invalidate),
		.cm_dc_clean_o(cm_dc_clean),
		.id_bp_predict_i(id_bp_predict),
		.bu_bp_predict_o(bu_bp_predict),
		.id_bp_history_i(id_bp_history),
		.bu_bp_history_update_o(bu_bp_history_update),
		.bu_bp_history_o(bu_bp_history),
		.bu_bp_btaken_o(bu_bp_btaken),
		.bu_bp_update_o(bu_bp_update),
		.id_insn_i(id_insn),
		.ex_insn_o(ex_insn),
		.id_exceptions_i(id_exceptions),
		.ex_exceptions_o(ex_exceptions),
		.mem_exceptions_i(mem_exceptions_up[0]),
		.wb_exceptions_i(wb_exceptions),
		.id_userf_opA_i(id_userf_opA),
		.id_userf_opB_i(id_userf_opB),
		.id_bypex_opA_i(id_bypex_opA),
		.id_bypex_opB_i(id_bypex_opB),
		.id_opA_i(id_opA),
		.id_opB_i(id_opB),
		.rf_srcv1_i(rf_srcv1),
		.rf_srcv2_i(rf_srcv2),
		.ex_r_o(ex_r),
		.ex_csr_reg_o(ex_csr_reg),
		.ex_csr_wval_o(ex_csr_wval),
		.ex_csr_we_o(ex_csr_we),
		.st_xlen_i(st_xlen),
		.st_be_i(st_be),
		.st_flush_i(st_flush),
		.st_csr_rval_i(st_csr_rval),
		.dmem_req_o(dmem_req_o),
		.dmem_lock_o(dmem_lock_o),
		.dmem_adr_o(dmem_adr_o),
		.dmem_size_o(dmem_size_o),
		.dmem_we_o(dmem_we_o),
		.dmem_d_o(dmem_d_o),
		.dmem_q_i(dmem_q_i),
		.dmem_ack_i(dmem_ack_i),
		.dmem_misaligned_i(dmem_misaligned_i),
		.dmem_page_fault_i(dmem_page_fault_i)
	);
	genvar _gv_n_1;
	assign mem_stall[MEM_STAGES] = wb_stall;
	assign mem_exceptions_up[MEM_STAGES] = wb_exceptions;
	generate
		for (_gv_n_1 = 0; _gv_n_1 < MEM_STAGES; _gv_n_1 = _gv_n_1 + 1) begin : genblk1
			localparam n = _gv_n_1;
			if (n == 0) begin : genblk1
				riscv_mem #(
					.MXLEN(MXLEN),
					.PC_INIT(PC_INIT)
				) mem_unit(
					.rst_ni(rst_ni),
					.clk_i(clk_i),
					.mem_stall_i(mem_stall[n + 1]),
					.mem_stall_o(mem_stall[n]),
					.mem_pc_i(ex_pc),
					.mem_pc_o(mem_pc[n]),
					.mem_insn_i(ex_insn),
					.mem_insn_o(mem_insn[((MEM_STAGES - 1) - n) * 35+:35]),
					.mem_exceptions_dn_i(ex_exceptions),
					.mem_exceptions_dn_o(mem_exceptions_dn[n]),
					.mem_exceptions_up_i(mem_exceptions_up[n + 1]),
					.mem_exceptions_up_o(mem_exceptions_up[n]),
					.mem_r_i(ex_r),
					.mem_r_o(mem_r[((MEM_STAGES - 1) - n) * MXLEN+:MXLEN]),
					.mem_memadr_i(dmem_adr_o),
					.mem_memadr_o(mem_memadr[n])
				);
			end
			else begin : genblk1
				riscv_mem #(
					.MXLEN(MXLEN),
					.PC_INIT(PC_INIT)
				) mem_unit(
					.rst_ni(rst_ni),
					.clk_i(clk_i),
					.mem_stall_i(mem_stall[n + 1]),
					.mem_stall_o(mem_stall[n]),
					.mem_pc_i(mem_pc[n - 1]),
					.mem_pc_o(mem_pc[n]),
					.mem_insn_i(mem_insn[((MEM_STAGES - 1) - (n - 1)) * 35+:35]),
					.mem_insn_o(mem_insn[((MEM_STAGES - 1) - n) * 35+:35]),
					.mem_exceptions_dn_i(mem_exceptions_dn[n - 1]),
					.mem_exceptions_dn_o(mem_exceptions_dn[n]),
					.mem_exceptions_up_i(mem_exceptions_up[n + 1]),
					.mem_exceptions_up_o(mem_exceptions_up[n]),
					.mem_r_i(mem_r[((MEM_STAGES - 1) - (n - 1)) * MXLEN+:MXLEN]),
					.mem_r_o(mem_r[((MEM_STAGES - 1) - n) * MXLEN+:MXLEN]),
					.mem_memadr_i(mem_memadr[n - 1]),
					.mem_memadr_o(mem_memadr[n])
				);
			end
		end
	endgenerate
	riscv_wb #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT)
	) wb_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.mem_pc_i(mem_pc[MEM_STAGES - 1]),
		.mem_insn_i(mem_insn[((MEM_STAGES - 1) - (MEM_STAGES - 1)) * 35+:35]),
		.mem_r_i(mem_r[((MEM_STAGES - 1) - (MEM_STAGES - 1)) * MXLEN+:MXLEN]),
		.mem_exceptions_i(mem_exceptions_dn[MEM_STAGES - 1]),
		.mem_memadr_i(mem_memadr[MEM_STAGES - 1]),
		.wb_pc_o(wb_pc),
		.wb_stall_o(wb_stall),
		.wb_insn_o(wb_insn),
		.wb_exceptions_o(wb_exceptions),
		.wb_badaddr_o(wb_badaddr),
		.dmem_ack_i(dmem_ack_i),
		.dmem_q_i(dmem_q_i),
		.dmem_misaligned_i(dmem_misaligned_i),
		.dmem_page_fault_i(dmem_page_fault_i),
		.dmem_err_i(dmem_err_i),
		.wb_dst_o(wb_dst),
		.wb_r_o(wb_r),
		.wb_memq_o(wb_memq),
		.wb_we_o(wb_we)
	);
	riscv_dwb #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT)
	) dwb_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.wb_insn_i(wb_insn),
		.wb_we_i(wb_we),
		.wb_r_i(wb_r),
		.dwb_insn_o(dwb_insn),
		.dwb_r_o(dwb_r)
	);
	riscv_state1_10 #(
		.MXLEN(MXLEN),
		.PC_INIT(PC_INIT),
		.IS_RV32E(IS_RV32E),
		.HAS_RVA(HAS_RVA),
		.HAS_RVB(HAS_RVB),
		.HAS_RVC(HAS_RVC),
		.HAS_FPU(HAS_FPU),
		.HAS_MMU(HAS_MMU),
		.HAS_RVN(HAS_RVN),
		.HAS_RVP(HAS_RVP),
		.HAS_RVT(HAS_RVT),
		.HAS_USER(HAS_USER),
		.HAS_SUPER(HAS_SUPER),
		.HAS_HYPER(HAS_HYPER),
		.MNMIVEC_DEFAULT(MNMIVEC_DEFAULT),
		.MTVEC_DEFAULT(MTVEC_DEFAULT),
		.HTVEC_DEFAULT(HTVEC_DEFAULT),
		.STVEC_DEFAULT(STVEC_DEFAULT),
		.JEDEC_BANK(JEDEC_BANK),
		.JEDEC_MANUFACTURER_ID(JEDEC_MANUFACTURER_ID),
		.PMP_CNT(PMP_CNT),
		.HARTID(HARTID)
	) cpu_state(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.id_pc_i(id_pc),
		.id_insn_i(id_insn),
		.bu_flush_i(bu_flush),
		.bu_nxt_pc_i(bu_nxt_pc),
		.st_flush_o(st_flush),
		.st_nxt_pc_o(st_nxt_pc),
		.wb_pc_i(wb_pc),
		.wb_insn_i(wb_insn),
		.wb_exceptions_i(wb_exceptions),
		.wb_badaddr_i(wb_badaddr),
		.st_prv_o(st_prv_o),
		.st_xlen_o(st_xlen),
		.st_be_o(st_be),
		.st_tvm_o(st_tvm),
		.st_tw_o(st_tw),
		.st_tsr_o(st_tsr),
		.st_mcounteren_o(st_mcounteren),
		.st_scounteren_o(st_scounteren),
		.st_pmpcfg_o(st_pmpcfg_o),
		.st_pmpaddr_o(st_pmpaddr_o),
		.int_external_i(int_external_i),
		.int_timer_i(int_timer_i),
		.int_software_i(int_software_i),
		.st_int_o(st_interrupts),
		.pd_stall_i(pd_stall),
		.id_stall_i(id_stall),
		.pd_csr_reg_i(pd_csr_reg),
		.ex_csr_reg_i(ex_csr_reg),
		.ex_csr_we_i(ex_csr_we),
		.ex_csr_wval_i(ex_csr_wval),
		.st_csr_rval_o(st_csr_rval),
		.du_stall_i(du_stall),
		.du_flush_i(du_flush),
		.du_re_csr_i(du_re_csr),
		.du_we_csr_i(du_we_csr),
		.du_csr_rval_o(du_csr_rval),
		.du_dato_i(du_dato),
		.du_addr_i(du_addr),
		.du_ie_i(du_ie),
		.du_ee_i(du_ee),
		.du_interrupts_o(du_interrupts),
		.du_exceptions_o(du_exceptions)
	);
	assign rf_src1 = (RF_REGOUT > 0 ? pd_rs1 : id_rs1);
	assign rf_src2 = (RF_REGOUT > 0 ? pd_rs2 : id_rs2);
	riscv_rf #(
		.MXLEN(MXLEN),
		.REGOUT(RF_REGOUT)
	) int_rf(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.rf_src1_i(rf_src1),
		.rf_src2_i(rf_src2),
		.rf_src1_q_o(rf_srcv1),
		.rf_src2_q_o(rf_srcv2),
		.rf_dst_i(wb_dst),
		.rf_dst_d_i(wb_r),
		.rf_we_i(wb_we),
		.pd_stall_i(pd_stall),
		.id_stall_i(id_stall),
		.du_re_rf_i(du_re_rf),
		.du_we_rf_i(du_we_rf),
		.du_d_i(du_dato),
		.du_rf_q_o(du_dati_rf),
		.du_addr_i(du_addr)
	);
	generate
		if (HAS_BPU == 0) begin : genblk2
			assign bp_bp_predict = 2'b00;
		end
		else begin : genblk2
			riscv_bp #(
				.MXLEN(MXLEN),
				.PC_INIT(PC_INIT),
				.HAS_RVC(HAS_RVC),
				.BP_GLOBAL_BITS(BP_GLOBAL_BITS),
				.BP_LOCAL_BITS(BP_LOCAL_BITS),
				.BP_LOCAL_BITS_LSB(2),
				.TECHNOLOGY(TECHNOLOGY)
			) bp_unit(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.id_stall_i(id_stall),
				.if_parcel_bp_history_i(if_predict_history),
				.if_parcel_pc_i(if_predict_pc),
				.bp_bp_predict_o(bp_bp_predict),
				.ex_pc_i(ex_pc),
				.bu_bp_history_i(bu_bp_history_update),
				.bu_bp_predict_i(bu_bp_predict),
				.bu_bp_btaken_i(bu_bp_btaken),
				.bu_bp_update_i(bu_bp_update)
			);
		end
	endgenerate
	riscv_du #(
		.MXLEN(MXLEN),
		.BREAKPOINTS(BREAKPOINTS)
	) du_unit(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.dbg_stall_i(dbg_stall_i),
		.dbg_strb_i(dbg_strb_i),
		.dbg_we_i(dbg_we_i),
		.dbg_addr_i(dbg_addr_i),
		.dbg_d_i(dbg_dati_i),
		.dbg_q_o(dbg_dato_o),
		.dbg_ack_o(dbg_ack_o),
		.dbg_bp_o(dbg_bp_o),
		.du_dbg_mode_o(),
		.du_stall_o(du_stall),
		.du_stall_if_o(du_stall_if),
		.du_latch_nxt_pc_o(du_latch_nxt_pc),
		.du_flush_o(du_flush),
		.du_flush_cache_o(du_flush_cache),
		.du_re_rf_o(du_re_rf),
		.du_we_rf_o(du_we_rf),
		.du_we_frf_o(du_we_frf),
		.du_re_csr_o(du_re_csr),
		.du_we_csr_o(du_we_csr),
		.du_we_pc_o(du_we_pc),
		.du_addr_o(du_addr),
		.du_d_o(du_dato),
		.du_ee_o(du_ee),
		.du_ie_o(du_ie),
		.du_rf_q_i(du_dati_rf),
		.du_frf_q_i({MXLEN {1'b0}}),
		.st_csr_q_i(du_csr_rval),
		.if_nxt_pc_i(if_nxt_pc),
		.bu_nxt_pc_i(bu_nxt_pc),
		.if_pc_i(if_pc),
		.pd_pc_i(pd_pc),
		.id_pc_i(id_pc),
		.ex_pc_i(ex_pc),
		.wb_pc_i(wb_pc),
		.bu_flush_i(bu_flush),
		.st_flush_i(st_flush),
		.if_nxt_insn_i(if_nxt_insn),
		.if_insn_i(if_insn),
		.pd_insn_i(pd_insn),
		.mem_insn_i(mem_insn[((MEM_STAGES - 1) - (MEM_STAGES - 1)) * 35+:35]),
		.mem_exceptions_i(mem_exceptions_dn[MEM_STAGES - 1]),
		.mem_memadr_i(mem_memadr[MEM_STAGES - 1]),
		.wb_insn_i(wb_insn),
		.dmem_ack_i(dmem_ack_i),
		.ex_stall_i(ex_stall),
		.du_interrupts_i(du_interrupts),
		.du_exceptions_i(du_exceptions)
	);
endmodule
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
module riscv_div (
	rst_ni,
	clk_i,
	mem_stall_i,
	ex_stall_i,
	div_stall_o,
	id_insn_i,
	opA_i,
	opB_i,
	st_xlen_i,
	div_bubble_o,
	div_r_o
);
	parameter signed [31:0] MXLEN = 32;
	input rst_ni;
	input clk_i;
	input mem_stall_i;
	input ex_stall_i;
	output reg div_stall_o;
	input wire [34:0] id_insn_i;
	input [MXLEN - 1:0] opA_i;
	input [MXLEN - 1:0] opB_i;
	input [1:0] st_xlen_i;
	output reg div_bubble_o;
	output reg [MXLEN - 1:0] div_r_o;
	function [MXLEN - 1:0] sext32;
		input [31:0] operand;
		reg sign;
		begin
			sign = operand[31];
			sext32 = {{MXLEN - 32 {sign}}, operand};
		end
	endfunction
	function [MXLEN - 1:0] twos;
		input [MXLEN - 1:0] a;
		twos = ~a + 'h1;
	endfunction
	function [MXLEN - 1:0] abs;
		input [MXLEN - 1:0] a;
		abs = (a[MXLEN - 1] ? twos(a) : a);
	endfunction
	wire xlen32;
	reg [31:0] div_instr;
	wire [14:0] opcR;
	wire [14:0] opcR_div;
	wire [31:0] opA_i32;
	wire [31:0] opB_i32;
	reg [$clog2(MXLEN) - 1:0] cnt;
	reg neg_q;
	reg neg_s;
	reg [(MXLEN + MXLEN) - 1:0] pa;
	wire [(MXLEN + MXLEN) - 1:0] pa_shifted;
	wire [MXLEN:0] p_minus_b;
	reg [MXLEN - 1:0] b;
	reg [1:0] state;
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(id_insn_i[31-:32]);
	assign opcR_div = riscv_opcodes_pkg_decode_opcR(div_instr);
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	always @(posedge clk_i)
		if (!ex_stall_i)
			div_instr <= id_insn_i[31-:32];
	assign opA_i32 = opA_i[31:0];
	assign opB_i32 = opB_i[31:0];
	assign pa_shifted = pa << 1;
	assign p_minus_b = pa_shifted[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] - b;
	localparam [14:0] riscv_opcodes_pkg_DIV = 15'b000000110001100;
	localparam [14:0] riscv_opcodes_pkg_DIVU = 15'b000000110101100;
	localparam [14:0] riscv_opcodes_pkg_DIVUW = 15'b000000110101110;
	localparam [14:0] riscv_opcodes_pkg_DIVW = 15'b000000110001110;
	localparam [14:0] riscv_opcodes_pkg_REM = 15'b000000111001100;
	localparam [14:0] riscv_opcodes_pkg_REMU = 15'b000000111101100;
	localparam [14:0] riscv_opcodes_pkg_REMUW = 15'b000000111101110;
	localparam [14:0] riscv_opcodes_pkg_REMW = 15'b000000111001110;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			cnt <= {$clog2(MXLEN) {1'bx}};
			state <= 2'b00;
			div_bubble_o <= 1'b1;
			div_stall_o <= 1'b0;
			div_r_o <= {MXLEN {1'bx}};
			pa <= {MXLEN + MXLEN {1'bx}};
			b <= {MXLEN {1'bx}};
			neg_q <= 1'bx;
			neg_s <= 1'bx;
		end
		else begin
			div_bubble_o <= 1'b1;
			case (state)
				2'b00:
					if (!ex_stall_i && !id_insn_i[33])
						(* full_case, parallel_case *)
						casex ({xlen32, opcR})
							{1'bz, riscv_opcodes_pkg_DIV}:
								if (~|opB_i) begin
									div_r_o <= {MXLEN {1'b1}};
									div_bubble_o <= 1'b0;
								end
								else if ((opA_i == {1'b1, {MXLEN - 1 {1'b0}}}) && &opB_i) begin
									div_r_o <= {1'b1, {MXLEN - 1 {1'b0}}};
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {$clog2(MXLEN) {1'b1}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= opA_i[MXLEN - 1] ^ opB_i[MXLEN - 1];
									neg_s <= opA_i[MXLEN - 1];
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= abs(opA_i);
									b <= abs(opB_i);
								end
							{1'b0, riscv_opcodes_pkg_DIVW}:
								if (~|opB_i32) begin
									div_r_o <= {MXLEN {1'b1}};
									div_bubble_o <= 1'b0;
								end
								else if ((opA_i32 == {1'b1, {31 {1'b0}}}) && &opB_i32) begin
									div_r_o <= sext32({1'b1, {31 {1'b0}}});
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {1'b0, {$clog2(MXLEN) - 1 {1'b1}}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= opA_i32[31] ^ opB_i32[31];
									neg_s <= opA_i32[31];
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= {abs(sext32(opA_i32)), {MXLEN - 32 {1'b0}}};
									b <= abs(sext32(opB_i32));
								end
							{1'bz, riscv_opcodes_pkg_DIVU}:
								if (~|opB_i) begin
									div_r_o <= {MXLEN {1'b1}};
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {$clog2(MXLEN) {1'b1}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= 1'b0;
									neg_s <= 1'b0;
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= opA_i;
									b <= opB_i;
								end
							{1'b0, riscv_opcodes_pkg_DIVUW}:
								if (~|opB_i32) begin
									div_r_o <= {MXLEN {1'b1}};
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {1'b0, {$clog2(MXLEN) - 1 {1'b1}}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= 1'b0;
									neg_s <= 1'b0;
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= {opA_i32, {MXLEN - 32 {1'b0}}};
									b <= {{MXLEN - 32 {1'b0}}, opB_i32};
								end
							{1'bz, riscv_opcodes_pkg_REM}:
								if (~|opB_i) begin
									div_r_o <= opA_i;
									div_bubble_o <= 1'b0;
								end
								else if ((opA_i == {1'b1, {MXLEN - 1 {1'b0}}}) && &opB_i) begin
									div_r_o <= 'h0;
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {$clog2(MXLEN) {1'b1}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= opA_i[MXLEN - 1] ^ opB_i[MXLEN - 1];
									neg_s <= opA_i[MXLEN - 1];
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= abs(opA_i);
									b <= abs(opB_i);
								end
							{1'b0, riscv_opcodes_pkg_REMW}:
								if (~|opB_i32) begin
									div_r_o <= sext32(opA_i32);
									div_bubble_o <= 1'b0;
								end
								else if ((opA_i32 == {1'b1, {31 {1'b0}}}) && &opB_i32) begin
									div_r_o <= 'h0;
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {1'b0, {$clog2(MXLEN) - 1 {1'b1}}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= opA_i32[31] ^ opB_i32[31];
									neg_s <= opA_i32[31];
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= {abs(sext32(opA_i32)), {MXLEN - 32 {1'b0}}};
									b <= abs(sext32(opB_i32));
								end
							{1'bz, riscv_opcodes_pkg_REMU}:
								if (~|opB_i) begin
									div_r_o <= opA_i;
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {$clog2(MXLEN) {1'b1}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= 1'b0;
									neg_s <= 1'b0;
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= opA_i;
									b <= opB_i;
								end
							{1'b0, riscv_opcodes_pkg_REMUW}:
								if (~|opB_i32) begin
									div_r_o <= sext32(opA_i32);
									div_bubble_o <= 1'b0;
								end
								else begin
									cnt <= {1'b0, {$clog2(MXLEN) - 1 {1'b1}}};
									state <= 2'b01;
									div_stall_o <= 1'b1;
									neg_q <= 1'b0;
									neg_s <= 1'b0;
									pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= 'h0;
									pa[MXLEN - 1-:MXLEN] <= {opA_i32, {MXLEN - 32 {1'b0}}};
									b <= {{MXLEN - 32 {1'b0}}, opB_i32};
								end
							default:
								;
						endcase
				2'b01: begin
					cnt <= cnt - 1;
					if (~|cnt)
						state <= 2'b10;
					if (p_minus_b[MXLEN]) begin
						pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= pa_shifted[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)];
						pa[MXLEN - 1-:MXLEN] <= {pa_shifted[(MXLEN - 1) - ((MXLEN - 1) - (MXLEN - 1)):(MXLEN - 1) - (MXLEN - 2)], 1'b0};
					end
					else begin
						pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)] <= p_minus_b[MXLEN - 1:0];
						pa[MXLEN - 1-:MXLEN] <= {pa_shifted[(MXLEN - 1) - ((MXLEN - 1) - (MXLEN - 1)):(MXLEN - 1) - (MXLEN - 2)], 1'b1};
					end
				end
				2'b10:
					if (!mem_stall_i) begin
						state <= 2'b00;
						div_bubble_o <= 1'b0;
						div_stall_o <= 1'b0;
						(* full_case, parallel_case *)
						casex (opcR_div)
							riscv_opcodes_pkg_DIV: div_r_o <= (neg_q ? twos(pa[MXLEN - 1-:MXLEN]) : pa[MXLEN - 1-:MXLEN]);
							riscv_opcodes_pkg_DIVW: div_r_o <= sext32((neg_q ? twos(pa[MXLEN - 1-:MXLEN]) : pa[MXLEN - 1-:MXLEN]));
							riscv_opcodes_pkg_DIVU: div_r_o <= pa[MXLEN - 1-:MXLEN];
							riscv_opcodes_pkg_DIVUW: div_r_o <= sext32(pa[MXLEN - 1-:MXLEN]);
							riscv_opcodes_pkg_REM: div_r_o <= (neg_s ? twos(pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)]) : pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)]);
							riscv_opcodes_pkg_REMW: div_r_o <= sext32((neg_s ? twos(pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)]) : pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)]));
							riscv_opcodes_pkg_REMU: div_r_o <= pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)];
							riscv_opcodes_pkg_REMUW: div_r_o <= sext32(pa[MXLEN + (MXLEN - 1)-:((MXLEN + (MXLEN - 1)) >= (MXLEN + 0) ? ((MXLEN + (MXLEN - 1)) - (MXLEN + 0)) + 1 : ((MXLEN + 0) - (MXLEN + (MXLEN - 1))) + 1)]);
							default: div_r_o <= 'hx;
						endcase
					end
			endcase
		end
endmodule
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
module riscv_du (
	rst_ni,
	clk_i,
	dbg_stall_i,
	dbg_strb_i,
	dbg_we_i,
	dbg_addr_i,
	dbg_d_i,
	dbg_q_o,
	dbg_ack_o,
	dbg_bp_o,
	du_dbg_mode_o,
	du_stall_o,
	du_stall_if_o,
	du_latch_nxt_pc_o,
	du_flush_o,
	du_flush_cache_o,
	du_we_rf_o,
	du_re_rf_o,
	du_we_frf_o,
	du_we_csr_o,
	du_re_csr_o,
	du_we_pc_o,
	du_addr_o,
	du_d_o,
	du_ie_o,
	du_ee_o,
	du_rf_q_i,
	du_frf_q_i,
	st_csr_q_i,
	if_nxt_pc_i,
	bu_nxt_pc_i,
	if_pc_i,
	pd_pc_i,
	id_pc_i,
	ex_pc_i,
	wb_pc_i,
	bu_flush_i,
	st_flush_i,
	if_nxt_insn_i,
	if_insn_i,
	pd_insn_i,
	mem_insn_i,
	wb_insn_i,
	mem_exceptions_i,
	mem_memadr_i,
	dmem_ack_i,
	ex_stall_i,
	du_exceptions_i,
	du_interrupts_i
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter BREAKPOINTS = 3;
	input rst_ni;
	input clk_i;
	input dbg_stall_i;
	input dbg_strb_i;
	input dbg_we_i;
	localparam riscv_du_pkg_DBG_ADDR_SIZE = 16;
	input [15:0] dbg_addr_i;
	input [MXLEN - 1:0] dbg_d_i;
	output reg [MXLEN - 1:0] dbg_q_o;
	output reg dbg_ack_o;
	output reg dbg_bp_o;
	output wire du_dbg_mode_o;
	output wire du_stall_o;
	output wire du_stall_if_o;
	output wire du_latch_nxt_pc_o;
	output wire du_flush_o;
	output wire du_flush_cache_o;
	output reg du_we_rf_o;
	output reg du_re_rf_o;
	output reg du_we_frf_o;
	output reg du_we_csr_o;
	output reg du_re_csr_o;
	output reg du_we_pc_o;
	localparam riscv_du_pkg_DU_ADDR_SIZE = 12;
	output reg [11:0] du_addr_o;
	output reg [MXLEN - 1:0] du_d_o;
	output wire [MXLEN - 1:0] du_ie_o;
	output reg [63:0] du_ee_o;
	input [MXLEN - 1:0] du_rf_q_i;
	input [MXLEN - 1:0] du_frf_q_i;
	input [MXLEN - 1:0] st_csr_q_i;
	input [MXLEN - 1:0] if_nxt_pc_i;
	input [MXLEN - 1:0] bu_nxt_pc_i;
	input [MXLEN - 1:0] if_pc_i;
	input [MXLEN - 1:0] pd_pc_i;
	input [MXLEN - 1:0] id_pc_i;
	input [MXLEN - 1:0] ex_pc_i;
	input [MXLEN - 1:0] wb_pc_i;
	input bu_flush_i;
	input st_flush_i;
	input wire [34:0] if_nxt_insn_i;
	input wire [34:0] if_insn_i;
	input wire [34:0] pd_insn_i;
	input wire [34:0] mem_insn_i;
	input wire [34:0] wb_insn_i;
	input wire [27:0] mem_exceptions_i;
	input [MXLEN - 1:0] mem_memadr_i;
	input dmem_ack_i;
	input ex_stall_i;
	input [63:0] du_exceptions_i;
	input [MXLEN - 1:0] du_interrupts_i;
	localparam riscv_du_pkg_MAX_BREAKPOINTS = 8;
	reg dbg_strb_i_dly;
	reg du_stall_dly;
	reg wb_dbg_dly;
	wire [15:riscv_du_pkg_DU_ADDR_SIZE] du_bank_addr;
	wire du_sel_internal;
	wire du_sel_gprs;
	wire du_sel_csrs;
	wire [4:0] du_re_csrs;
	wire du_access;
	wire du_we;
	reg [2:0] du_ack;
	reg du_we_internal;
	reg [MXLEN - 1:0] du_internal_regs;
	reg [((((66 + MXLEN) + MXLEN) + 10) + (8 * (5 + MXLEN))) - 1:0] dbg;
	wire bp_instr_hit;
	wire bp_branch_hit;
	reg [7:0] bp_hit;
	wire mem_read;
	wire mem_write;
	reg [MXLEN - 1:0] dpc;
	genvar _gv_n_2;
	function automatic [MXLEN - 1:0] find_first_one;
		input [MXLEN - 1:0] a;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			find_first_one = 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				begin : sv2v_autoblock_2
					reg signed [31:0] _sv2v_value_on_break;
					for (n = 0; n < MXLEN; n = n + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (a[n]) begin
								find_first_one = n;
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
	assign du_bank_addr = dbg_addr_i[15:riscv_du_pkg_DU_ADDR_SIZE];
	localparam [15:12] riscv_du_pkg_DBG_INTERNAL = 4'h0;
	assign du_sel_internal = du_bank_addr == riscv_du_pkg_DBG_INTERNAL;
	localparam [15:12] riscv_du_pkg_DBG_GPRS = 4'h1;
	assign du_sel_gprs = du_bank_addr == riscv_du_pkg_DBG_GPRS;
	localparam [15:12] riscv_du_pkg_DBG_CSRS = 4'h2;
	assign du_sel_csrs = du_bank_addr == riscv_du_pkg_DBG_CSRS;
	always @(posedge clk_i) dbg_strb_i_dly <= dbg_strb_i;
	assign du_access = (dbg_strb_i & dbg_stall_i) | (dbg_strb_i & du_sel_internal);
	assign du_we = (du_access & ~dbg_strb_i_dly) & dbg_we_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			du_ack <= 'h0;
		else if (!ex_stall_i)
			du_ack <= {3 {du_access & ~dbg_ack_o}} & {1'b1, du_ack[2:1]};
	wire [1:1] sv2v_tmp_4F4FB;
	assign sv2v_tmp_4F4FB = du_ack[0];
	always @(*) dbg_ack_o = sv2v_tmp_4F4FB;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dbg_bp_o <= 'b0;
		else
			dbg_bp_o <= ((~ex_stall_i & ~du_flush_o) & ~st_flush_i) & ((|du_exceptions_i | (|du_interrupts_i)) | (|dbg[(8 * (5 + MXLEN)) + 9-:(((8 * (5 + MXLEN)) + 9) >= ((8 * (5 + MXLEN)) + 0) ? (((8 * (5 + MXLEN)) + 9) - ((8 * (5 + MXLEN)) + 0)) + 1 : (((8 * (5 + MXLEN)) + 0) - ((8 * (5 + MXLEN)) + 9)) + 1)]));
	assign du_stall_o = dbg_stall_i;
	assign du_stall_if_o = dbg_stall_i | (|dbg[(8 * (5 + MXLEN)) + 9-:(((8 * (5 + MXLEN)) + 9) >= ((8 * (5 + MXLEN)) + 0) ? (((8 * (5 + MXLEN)) + 9) - ((8 * (5 + MXLEN)) + 0)) + 1 : (((8 * (5 + MXLEN)) + 0) - ((8 * (5 + MXLEN)) + 9)) + 1)]);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			du_stall_dly <= 1'b0;
		else
			du_stall_dly <= dbg_stall_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_dbg_dly <= 1'b0;
		else
			wb_dbg_dly <= wb_insn_i[34];
	assign du_latch_nxt_pc_o = dbg_stall_i & ~du_stall_dly;
	assign du_flush_cache_o = wb_insn_i[34] & ~wb_dbg_dly;
	assign du_flush_o = ~dbg_stall_i & du_stall_dly;
	localparam [11:0] riscv_du_pkg_DBG_NPC = 12'h200;
	always @(posedge clk_i) begin
		du_addr_o <= dbg_addr_i[11:0];
		du_d_o <= dbg_d_i;
		du_we_rf_o <= (du_we & du_sel_gprs) & (dbg_addr_i[11:8] == 4'h0);
		du_we_frf_o <= (du_we & du_sel_gprs) & (dbg_addr_i[11:8] == 4'h1);
		du_we_internal <= du_we & du_sel_internal;
		du_we_csr_o <= du_we & du_sel_csrs;
		du_we_pc_o <= (du_we & du_sel_gprs) & (dbg_addr_i[11:0] == riscv_du_pkg_DBG_NPC);
	end
	wire [1:1] sv2v_tmp_A4B9D;
	assign sv2v_tmp_A4B9D = dbg_strb_i & du_sel_csrs;
	always @(*) du_re_csr_o = sv2v_tmp_A4B9D;
	wire [1:1] sv2v_tmp_EBD90;
	assign sv2v_tmp_EBD90 = (dbg_strb_i & du_sel_gprs) & (dbg_addr_i[11:8] == 4'h0);
	always @(*) du_re_rf_o = sv2v_tmp_EBD90;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL0 = 'h10;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL1 = 'h12;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL2 = 'h14;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL3 = 'h16;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL4 = 'h18;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL5 = 'h1a;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL6 = 'h1c;
	localparam [4:0] riscv_du_pkg_DBG_BPCTRL7 = 'h1e;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA0 = 'h11;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA1 = 'h13;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA2 = 'h15;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA3 = 'h17;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA4 = 'h19;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA5 = 'h1b;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA6 = 'h1d;
	localparam [4:0] riscv_du_pkg_DBG_BPDATA7 = 'h1f;
	localparam [4:0] riscv_du_pkg_DBG_CAUSE = 'h3;
	localparam [4:0] riscv_du_pkg_DBG_CTRL = 'h0;
	localparam [4:0] riscv_du_pkg_DBG_EE = 'h2;
	localparam [4:0] riscv_du_pkg_DBG_EEH = 'h4;
	localparam [4:0] riscv_du_pkg_DBG_HIT = 'h1;
	localparam [4:0] riscv_du_pkg_DBG_IE = 'h5;
	always @(*) begin
		if (_sv2v_0)
			;
		case (du_addr_o)
			riscv_du_pkg_DBG_CTRL: du_internal_regs = {{MXLEN - 2 {1'b0}}, dbg[66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))-:((66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) >= (64 + (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))))) ? ((66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - (64 + (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))))) + 1 : ((64 + (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))))) - (66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))))) + 1)]};
			riscv_du_pkg_DBG_HIT: du_internal_regs = {{MXLEN - 16 {1'b0}}, dbg[(8 * (5 + MXLEN)) + 9-:8], 6'h00, dbg[(8 * (5 + MXLEN)) + 1], dbg[(8 * (5 + MXLEN)) + 0]};
			riscv_du_pkg_DBG_IE: du_internal_regs = dbg[MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))-:((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) >= (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) ? ((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) - (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) + 1 : ((MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) - (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) + 1)];
			riscv_du_pkg_DBG_EE: du_internal_regs = dbg[(64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - (64 - MXLEN):(64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - 63];
			riscv_du_pkg_DBG_EEH: du_internal_regs = (MXLEN == 32 ? dbg[64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))):(64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - 31] : {MXLEN {1'b0}});
			riscv_du_pkg_DBG_CAUSE: du_internal_regs = {{MXLEN - 32 {1'b0}}, dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)]};
			riscv_du_pkg_DBG_BPCTRL0: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - (0 + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - (0 + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - (0 + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA0: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - (MXLEN - 1))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL1: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 + MXLEN) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 + MXLEN) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 + MXLEN) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA1: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 + MXLEN) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL2: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((2 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((2 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((2 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA2: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((2 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL3: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((3 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((3 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((3 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA3: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((3 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL4: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((4 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((4 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((4 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA4: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((4 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL5: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA5: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((5 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL6: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((6 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((6 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((6 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA6: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((6 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			riscv_du_pkg_DBG_BPCTRL7: du_internal_regs = {{MXLEN - 7 {1'b0}}, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((7 * (5 + MXLEN)) + (MXLEN + 4)))-:3], 2'h0, dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((7 * (5 + MXLEN)) + (MXLEN + 1)))], dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((7 * (5 + MXLEN)) + (MXLEN + 0)))]};
			riscv_du_pkg_DBG_BPDATA7: du_internal_regs = dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((7 * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN];
			default: du_internal_regs = 'h0;
		endcase
	end
	localparam [11:0] riscv_du_pkg_DBG_FPR = 12'b0001000zzzzz;
	localparam [11:0] riscv_du_pkg_DBG_GPR = 12'b0000000zzzzz;
	localparam [11:0] riscv_du_pkg_DBG_PPC = 12'h201;
	always @(posedge clk_i)
		casex (dbg_addr_i)
			{riscv_du_pkg_DBG_INTERNAL, 12'hzzz}: dbg_q_o <= du_internal_regs;
			{riscv_du_pkg_DBG_GPRS, riscv_du_pkg_DBG_GPR}: dbg_q_o <= du_rf_q_i;
			{riscv_du_pkg_DBG_GPRS, riscv_du_pkg_DBG_FPR}: dbg_q_o <= du_frf_q_i;
			{riscv_du_pkg_DBG_GPRS, riscv_du_pkg_DBG_NPC}: dbg_q_o <= if_nxt_pc_i;
			{riscv_du_pkg_DBG_GPRS, riscv_du_pkg_DBG_PPC}: dbg_q_o <= dpc;
			{riscv_du_pkg_DBG_CSRS, 12'hzzz}: dbg_q_o <= st_csr_q_i;
			default: dbg_q_o <= 'h0;
		endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			dbg[(66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - 1] <= 1'b0;
			dbg[66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))] <= 1'b0;
		end
		else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_CTRL)) begin
			dbg[(66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - 1] <= du_d_o[0];
			dbg[66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))] <= du_d_o[1];
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			dbg[(8 * (5 + MXLEN)) + 0] <= 1'b0;
			dbg[(8 * (5 + MXLEN)) + 1] <= 1'b0;
		end
		else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_HIT)) begin
			dbg[(8 * (5 + MXLEN)) + 0] <= du_d_o[0];
			dbg[(8 * (5 + MXLEN)) + 1] <= du_d_o[1];
		end
		else begin
			if (bp_instr_hit)
				dbg[(8 * (5 + MXLEN)) + 0] <= 1'b1;
			if (bp_branch_hit)
				dbg[(8 * (5 + MXLEN)) + 1] <= 1'b1;
		end
	generate
		for (_gv_n_2 = 0; _gv_n_2 < riscv_du_pkg_MAX_BREAKPOINTS; _gv_n_2 = _gv_n_2 + 1) begin : gen_bp_hits
			localparam n = _gv_n_2;
			if (n < BREAKPOINTS) begin : genblk1
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						dbg[((8 * (5 + MXLEN)) + 9) - (9 - (2 + n))] <= 1'b0;
					else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_HIT))
						dbg[((8 * (5 + MXLEN)) + 9) - (9 - (2 + n))] <= du_d_o[n + 4];
					else if (bp_hit[n])
						dbg[((8 * (5 + MXLEN)) + 9) - (9 - (2 + n))] <= 1'b1;
			end
			else begin : genblk1
				wire [1:1] sv2v_tmp_35F82;
				assign sv2v_tmp_35F82 = 1'b0;
				always @(*) dbg[((8 * (5 + MXLEN)) + 9) - (9 - (2 + n))] = sv2v_tmp_35F82;
			end
		end
	endgenerate
	always @(posedge clk_i)
		if (|du_exceptions_i || |du_interrupts_i)
			dpc <= wb_pc_i;
		else if (bu_flush_i)
			dpc <= bu_nxt_pc_i;
		else if (bp_instr_hit)
			dpc <= if_nxt_pc_i;
		else if (|bp_hit)
			dpc <= id_pc_i;
		else if (bp_branch_hit)
			dpc <= id_pc_i;
		else if (du_latch_nxt_pc_o && ~|dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)])
			dpc <= id_pc_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dbg[MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))-:((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) >= (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) ? ((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) - (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) + 1 : ((MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) - (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) + 1)] <= 'h0;
		else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_IE))
			dbg[MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))-:((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) >= (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) ? ((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) - (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) + 1 : ((MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) - (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) + 1)] <= du_d_o[31:0];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dbg[64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))-:((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) >= (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) ? ((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))))) + 1 : ((MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) - (64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))))) + 1)] <= 'h0;
		else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_EE))
			dbg[64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))-:((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) >= (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) ? ((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))))) + 1 : ((MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) - (64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))))) + 1)] <= du_d_o[31:0];
	assign du_ie_o = dbg[MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))-:((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) >= (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) ? ((MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))) - (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) + 1 : ((MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))) - (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) + 1)];
	wire [64:1] sv2v_tmp_42136;
	assign sv2v_tmp_42136 = dbg[64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))-:((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) >= (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) ? ((64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - (MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0))))) + 1 : ((MXLEN + (MXLEN + (10 + ((8 * (5 + MXLEN)) + 0)))) - (64 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9))))) + 1)];
	always @(*) du_ee_o = sv2v_tmp_42136;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)] <= 'h0;
		else if (du_we_internal && (du_addr_o == riscv_du_pkg_DBG_CAUSE))
			dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)] <= du_d_o;
		else if ((du_flush_o && ~|du_exceptions_i) && ~|du_interrupts_i)
			dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)] <= 'h0;
		else if (|du_exceptions_i)
			dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)] <= find_first_one(du_exceptions_i);
		else if (|du_interrupts_i)
			dbg[MXLEN + ((8 * (5 + MXLEN)) + 9)-:((MXLEN + ((8 * (5 + MXLEN)) + 9)) >= (10 + ((8 * (5 + MXLEN)) + 0)) ? ((MXLEN + ((8 * (5 + MXLEN)) + 9)) - (10 + ((8 * (5 + MXLEN)) + 0))) + 1 : ((10 + ((8 * (5 + MXLEN)) + 0)) - (MXLEN + ((8 * (5 + MXLEN)) + 9))) + 1)] <= (1'h1 << (MXLEN - 1)) | find_first_one(du_interrupts_i);
	generate
		for (_gv_n_2 = 0; _gv_n_2 < riscv_du_pkg_MAX_BREAKPOINTS; _gv_n_2 = _gv_n_2 + 1) begin : gen_bp
			localparam n = _gv_n_2;
			if (n < BREAKPOINTS) begin : genblk1
				wire [1:1] sv2v_tmp_206C1;
				assign sv2v_tmp_206C1 = 1'b1;
				always @(*) dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 0)))] = sv2v_tmp_206C1;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 1)))] <= 'b0;
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 4)))-:3] <= 'h0;
					end
					else if (du_we_internal && (du_addr_o == (riscv_du_pkg_DBG_BPCTRL0 + (2 * n)))) begin
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 1)))] <= du_d_o[1];
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 4)))-:3] <= du_d_o[6:4];
					end
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN] <= 'h0;
					else if (du_we_internal && (du_addr_o == (riscv_du_pkg_DBG_BPDATA0 + (2 * n))))
						dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN] <= du_d_o;
			end
			else begin : genblk1
				wire [(5 + MXLEN) * 1:1] sv2v_tmp_AA57C;
				assign sv2v_tmp_AA57C = 'h0;
				always @(*) dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - (n * (5 + MXLEN)))+:5 + MXLEN] = sv2v_tmp_AA57C;
			end
		end
	endgenerate
	assign bp_instr_hit = dbg[(66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))) - 1] & ~if_nxt_insn_i[33];
	localparam [6:2] riscv_opcodes_pkg_OPC_BRANCH = 5'b11000;
	assign bp_branch_hit = (dbg[66 + (MXLEN + (MXLEN + ((8 * (5 + MXLEN)) + 9)))] & ~if_insn_i[33]) & (if_insn_i[6-:5] == riscv_opcodes_pkg_OPC_BRANCH);
	localparam [6:2] riscv_opcodes_pkg_OPC_LOAD = 5'b00000;
	assign mem_read = (~mem_exceptions_i[27] & ~mem_insn_i[33]) & (mem_insn_i[6-:5] == riscv_opcodes_pkg_OPC_LOAD);
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE = 5'b01000;
	assign mem_write = (~mem_exceptions_i[27] & ~mem_insn_i[33]) & (mem_insn_i[6-:5] == riscv_opcodes_pkg_OPC_STORE);
	localparam riscv_du_pkg_BP_CTRL_CC_FETCH = 3'h0;
	localparam riscv_du_pkg_BP_CTRL_CC_LDST_ADR = 3'h3;
	localparam riscv_du_pkg_BP_CTRL_CC_LD_ADR = 3'h1;
	localparam riscv_du_pkg_BP_CTRL_CC_ST_ADR = 3'h2;
	generate
		for (_gv_n_2 = 0; _gv_n_2 < riscv_du_pkg_MAX_BREAKPOINTS; _gv_n_2 = _gv_n_2 + 1) begin : gen_bp_hit
			localparam n = _gv_n_2;
			if (n < BREAKPOINTS) begin : gen_hit_logic
				always @(*) begin
					if (_sv2v_0)
						;
					if (!dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 1)))] || !dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 0)))])
						bp_hit[n] = 1'b0;
					else
						case (dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN + 4)))-:3])
							riscv_du_pkg_BP_CTRL_CC_FETCH: bp_hit[n] = ((pd_pc_i == dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN]) & ~bu_flush_i) & ~st_flush_i;
							riscv_du_pkg_BP_CTRL_CC_LD_ADR: bp_hit[n] = ((mem_memadr_i == dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN]) & dmem_ack_i) & mem_read;
							riscv_du_pkg_BP_CTRL_CC_ST_ADR: bp_hit[n] = ((mem_memadr_i == dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN]) & dmem_ack_i) & mem_write;
							riscv_du_pkg_BP_CTRL_CC_LDST_ADR: bp_hit[n] = ((mem_memadr_i == dbg[((8 * (5 + MXLEN)) - 1) - (((8 * (5 + MXLEN)) - 1) - ((n * (5 + MXLEN)) + (MXLEN - 1)))-:MXLEN]) & dmem_ack_i) & (mem_read | mem_write);
							default: bp_hit[n] = 1'b0;
						endcase
				end
			end
			else begin : genblk1
				wire [1:1] sv2v_tmp_94226;
				assign sv2v_tmp_94226 = 1'b0;
				always @(*) bp_hit[n] = sv2v_tmp_94226;
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module riscv_dwb (
	rst_ni,
	clk_i,
	wb_insn_i,
	wb_we_i,
	wb_r_i,
	dwb_insn_o,
	dwb_r_o
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	input rst_ni;
	input clk_i;
	input wire [34:0] wb_insn_i;
	input wb_we_i;
	input [MXLEN - 1:0] wb_r_i;
	output reg [34:0] dwb_insn_o;
	output reg [MXLEN - 1:0] dwb_r_o;
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[31-:32] <= riscv_opcodes_pkg_NOP;
		else
			dwb_insn_o[31-:32] <= wb_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[33] <= 1'b1;
		else
			dwb_insn_o[33] <= ~wb_we_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dwb_insn_o[34] <= 1'b0;
		else
			dwb_insn_o[34] <= wb_insn_i[34];
	always @(posedge clk_i)
		if (wb_we_i)
			dwb_r_o <= wb_r_i;
endmodule
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
module riscv_id (
	rst_ni,
	clk_i,
	id_stall_o,
	ex_stall_i,
	du_stall_i,
	bu_flush_i,
	st_flush_i,
	du_flush_i,
	bu_nxt_pc_i,
	st_nxt_pc_i,
	pd_pc_i,
	pd_rsb_pc_i,
	if_nxt_pc_i,
	id_pc_o,
	id_rsb_pc_o,
	pd_bp_history_i,
	id_bp_history_o,
	pd_bp_predict_i,
	id_bp_predict_o,
	pd_insn_i,
	id_insn_o,
	ex_insn_i,
	mem_insn_i,
	wb_insn_i,
	dwb_insn_i,
	st_interrupts_i,
	int_nmi_i,
	pd_exceptions_i,
	id_exceptions_o,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i,
	st_prv_i,
	st_xlen_i,
	st_tvm_i,
	st_tw_i,
	st_tsr_i,
	st_mcounteren_i,
	st_scounteren_i,
	id_rs1_o,
	id_rs2_o,
	id_opA_o,
	id_opB_o,
	id_userf_opA_o,
	id_userf_opB_o,
	id_bypex_opA_o,
	id_bypex_opB_o,
	ex_r_i,
	mem_r_i,
	wb_r_i,
	wb_memq_i,
	dwb_r_i
);
	reg _sv2v_0;
	parameter signed [31:0] XLEN = 32;
	parameter [XLEN - 1:0] PC_INIT = 'h200;
	parameter [0:0] HAS_HYPER = 0;
	parameter [0:0] HAS_SUPER = 0;
	parameter [0:0] HAS_USER = 0;
	parameter [0:0] HAS_FPU = 0;
	parameter [0:0] HAS_RVA = 0;
	parameter [0:0] HAS_RVM = 0;
	parameter [0:0] HAS_RVC = 0;
	parameter signed [31:0] MULT_LATENCY = 0;
	parameter signed [31:0] RF_REGOUT = 1;
	parameter signed [31:0] BP_GLOBAL_BITS = 2;
	parameter signed [31:0] RSB_DEPTH = 0;
	parameter signed [31:0] MEM_STAGES = 1;
	parameter signed [31:0] PMP_CNT = 16;
	input rst_ni;
	input clk_i;
	output reg id_stall_o;
	input ex_stall_i;
	input du_stall_i;
	input bu_flush_i;
	input st_flush_i;
	input du_flush_i;
	input [XLEN - 1:0] bu_nxt_pc_i;
	input [XLEN - 1:0] st_nxt_pc_i;
	input [XLEN - 1:0] pd_pc_i;
	input [XLEN - 1:0] pd_rsb_pc_i;
	input [XLEN - 1:0] if_nxt_pc_i;
	output reg [XLEN - 1:0] id_pc_o;
	output reg [XLEN - 1:0] id_rsb_pc_o;
	input [BP_GLOBAL_BITS - 1:0] pd_bp_history_i;
	output reg [BP_GLOBAL_BITS - 1:0] id_bp_history_o;
	input [1:0] pd_bp_predict_i;
	output reg [1:0] id_bp_predict_o;
	input wire [34:0] pd_insn_i;
	output reg [34:0] id_insn_o;
	input wire [34:0] ex_insn_i;
	input wire [(MEM_STAGES * 35) - 1:0] mem_insn_i;
	input wire [34:0] wb_insn_i;
	input wire [34:0] dwb_insn_i;
	input wire [5:0] st_interrupts_i;
	input int_nmi_i;
	input wire [27:0] pd_exceptions_i;
	output reg [27:0] id_exceptions_o;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	input [1:0] st_prv_i;
	input [1:0] st_xlen_i;
	input st_tvm_i;
	input st_tw_i;
	input st_tsr_i;
	input [XLEN - 1:0] st_mcounteren_i;
	input [XLEN - 1:0] st_scounteren_i;
	output wire [4:0] id_rs1_o;
	output wire [4:0] id_rs2_o;
	output reg [XLEN - 1:0] id_opA_o;
	output reg [XLEN - 1:0] id_opB_o;
	output reg id_userf_opA_o;
	output reg id_userf_opB_o;
	output reg id_bypex_opA_o;
	output reg id_bypex_opB_o;
	input [XLEN - 1:0] ex_r_i;
	input [(MEM_STAGES * XLEN) - 1:0] mem_r_i;
	input [XLEN - 1:0] wb_r_i;
	input [XLEN - 1:0] wb_memq_i;
	input [XLEN - 1:0] dwb_r_i;
	function use_result;
		input reg [4:0] rs;
		input reg [4:0] rd;
		input reg valid;
		use_result = ((rs == rd) & |rd) & valid;
	endfunction
	localparam [6:2] riscv_opcodes_pkg_OPC_LOAD = 5'b00000;
	function [XLEN - 1:0] nxt_operand;
		input reg use_exr;
		input reg [MEM_STAGES - 1:0] use_memr;
		input reg use_wbr;
		input reg [XLEN - 1:0] ex_r;
		input reg [(MEM_STAGES * XLEN) - 1:0] mem_r;
		input reg [XLEN - 1:0] wb_memq;
		input reg [XLEN - 1:0] wb_r;
		input reg [XLEN - 1:0] dwb_r;
		input reg [(MEM_STAGES * 5) - 1:0] mem_opcode;
		begin
			nxt_operand = dwb_r;
			if (use_wbr)
				nxt_operand = wb_r;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				for (n = MEM_STAGES - 1; n >= 0; n = n - 1)
					if (n == (MEM_STAGES - 1)) begin
						if (use_memr[MEM_STAGES - 1])
							nxt_operand = (mem_opcode[((MEM_STAGES - 1) - (MEM_STAGES - 1)) * 5+:5] == riscv_opcodes_pkg_OPC_LOAD ? wb_memq : mem_r[((MEM_STAGES - 1) - (MEM_STAGES - 1)) * XLEN+:XLEN]);
					end
					else if (use_memr[n])
						nxt_operand = mem_r[((MEM_STAGES - 1) - n) * XLEN+:XLEN];
			end
			if (use_exr)
				nxt_operand = ex_r;
		end
	endfunction
	genvar _gv_n_3;
	wire has_rvc;
	wire has_rsb;
	reg id_bubble_r;
	reg multi_cycle_instruction;
	wire stalls;
	wire flushes;
	wire exceptions;
	reg [27:0] my_exceptions;
	wire [11:0] immI;
	wire [31:0] immU;
	wire [XLEN - 1:0] ext_immI;
	wire [XLEN - 1:0] ext_immU;
	wire [14:0] pd_opcR;
	wire [4:0] id_opcode;
	wire [4:0] ex_opcode;
	wire [(MEM_STAGES * 5) - 1:0] mem_opcode;
	wire [4:0] wb_opcode;
	wire [4:0] dwb_opcode;
	wire is_32bit_instruction;
	wire xlen64;
	wire xlen32;
	wire has_fpu;
	wire has_muldiv;
	wire has_amo;
	wire has_u;
	wire has_s;
	wire has_h;
	wire [4:0] pd_rs1;
	wire [4:0] pd_rs2;
	wire [4:0] id_rd;
	wire [4:0] ex_rd;
	wire [4:0] mem_rd [0:MEM_STAGES - 1];
	wire [4:0] wb_rd;
	wire [4:0] dwb_rd;
	reg can_bypex;
	reg can_use_exr;
	reg can_use_memr [0:MEM_STAGES - 1];
	reg can_use_wbr;
	reg can_use_dwbr;
	wire use_rf_opA;
	wire use_rf_opB;
	reg use_exr_opA;
	reg use_exr_opB;
	reg [MEM_STAGES - 1:0] use_memr_opA;
	reg [MEM_STAGES - 1:0] use_memr_opB;
	reg use_wbr_opA;
	reg use_wbr_opB;
	reg use_dwbr_opA;
	reg use_dwbr_opB;
	reg stall_ld_id;
	reg stall_ld_ex;
	reg [MEM_STAGES - 1:0] stall_ld_mem;
	wire [XLEN - 1:0] nxt_opA;
	wire [XLEN - 1:0] nxt_opB;
	reg illegal_instr;
	reg illegal_alu_instr;
	reg illegal_lsu_instr;
	reg illegal_muldiv_instr;
	reg illegal_csr_rd;
	reg illegal_csr_wr;
	assign has_rvc = HAS_RVC != 0;
	assign has_rsb = RSB_DEPTH > 0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			id_pc_o <= PC_INIT;
		else if (st_flush_i)
			id_pc_o <= st_nxt_pc_i;
		else if (bu_flush_i)
			id_pc_o <= bu_nxt_pc_i;
		else if (du_flush_i)
			id_pc_o <= if_nxt_pc_i;
		else if (!stalls && !id_stall_o)
			id_pc_o <= pd_pc_i;
	always @(posedge clk_i)
		if (!stalls && !id_stall_o)
			id_rsb_pc_o <= (has_rsb ? pd_rsb_pc_i : {XLEN {1'b0}});
	wire [1:1] sv2v_tmp_D3728;
	assign sv2v_tmp_D3728 = 1'b0;
	always @(*) id_insn_o[32] = sv2v_tmp_D3728;
	always @(posedge clk_i)
		if (!stalls)
			id_insn_o[31-:32] <= pd_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			id_insn_o[34] <= 1'b0;
		else if (!stalls)
			id_insn_o[34] <= pd_insn_i[34];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			id_bubble_r <= 1'b1;
		else if (bu_flush_i || st_flush_i)
			id_bubble_r <= 1'b1;
		else if (!stalls)
			id_bubble_r <= (pd_insn_i[33] | id_stall_o) | my_exceptions[27];
	assign stalls = ex_stall_i;
	assign flushes = bu_flush_i | st_flush_i;
	assign exceptions = (ex_exceptions_i[27] | mem_exceptions_i[27]) | wb_exceptions_i[27];
	wire [1:1] sv2v_tmp_511E2;
	assign sv2v_tmp_511E2 = ((stalls | flushes) | exceptions) | id_bubble_r;
	always @(*) id_insn_o[33] = sv2v_tmp_511E2;
	assign is_32bit_instruction = ~&pd_insn_i[4:1] & pd_insn_i[0];
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign pd_opcR = riscv_opcodes_pkg_decode_opcR(pd_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_opcode;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcode = instr[6-:5];
	endfunction
	assign id_opcode = riscv_opcodes_pkg_decode_opcode(id_insn_o[31-:32]);
	assign ex_opcode = riscv_opcodes_pkg_decode_opcode(ex_insn_i[31-:32]);
	generate
		for (_gv_n_3 = 0; _gv_n_3 < MEM_STAGES; _gv_n_3 = _gv_n_3 + 1) begin : genblk1
			localparam n = _gv_n_3;
			assign mem_opcode[((MEM_STAGES - 1) - n) * 5+:5] = riscv_opcodes_pkg_decode_opcode(mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 31-:32]);
		end
	endgenerate
	assign wb_opcode = riscv_opcodes_pkg_decode_opcode(wb_insn_i[31-:32]);
	assign dwb_opcode = riscv_opcodes_pkg_decode_opcode(dwb_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rd;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rd = instr[11-:5];
	endfunction
	assign id_rd = riscv_opcodes_pkg_decode_rd(id_insn_o[31-:32]);
	assign ex_rd = riscv_opcodes_pkg_decode_rd(ex_insn_i[31-:32]);
	generate
		for (_gv_n_3 = 0; _gv_n_3 < MEM_STAGES; _gv_n_3 = _gv_n_3 + 1) begin : genblk2
			localparam n = _gv_n_3;
			assign mem_rd[n] = riscv_opcodes_pkg_decode_rd(mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 31-:32]);
		end
	endgenerate
	assign wb_rd = riscv_opcodes_pkg_decode_rd(wb_insn_i[31-:32]);
	assign dwb_rd = riscv_opcodes_pkg_decode_rd(dwb_insn_i[31-:32]);
	assign has_fpu = HAS_FPU != 0;
	assign has_muldiv = HAS_RVM != 0;
	assign has_amo = HAS_RVA != 0;
	assign has_u = HAS_USER != 0;
	assign has_s = HAS_SUPER != 0;
	assign has_h = HAS_HYPER != 0;
	localparam [1:0] riscv_state_pkg_RV64I = 2'b10;
	assign xlen64 = st_xlen_i == riscv_state_pkg_RV64I;
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	always @(posedge clk_i)
		if (!stalls && !id_stall_o)
			id_bp_predict_o <= pd_bp_predict_i;
	localparam [31:0] riscv_opcodes_pkg_EBREAK = 32'b00000000000100000000000001110001;
	localparam [31:0] riscv_opcodes_pkg_ECALL = 32'b00000000000000000000000001110001;
	localparam [1:0] riscv_state_pkg_PRV_M = 2'b11;
	localparam [1:0] riscv_state_pkg_PRV_S = 2'b01;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		my_exceptions = pd_exceptions_i;
		my_exceptions[25-:6] = {6 {~pd_insn_i[33]}} & st_interrupts_i;
		my_exceptions[26] = ~pd_insn_i[33] & int_nmi_i;
		my_exceptions[2] = ~pd_insn_i[33] & (illegal_instr | pd_exceptions_i[2]);
		my_exceptions[3] = ~pd_insn_i[33] & (pd_insn_i[31-:32] == riscv_opcodes_pkg_EBREAK);
		my_exceptions[8] = ((~pd_insn_i[33] & (pd_insn_i[31-:32] == riscv_opcodes_pkg_ECALL)) & (st_prv_i == riscv_state_pkg_PRV_U)) & has_u;
		my_exceptions[9] = ((~pd_insn_i[33] & (pd_insn_i[31-:32] == riscv_opcodes_pkg_ECALL)) & (st_prv_i == riscv_state_pkg_PRV_S)) & has_s;
		my_exceptions[11] = (~pd_insn_i[33] & (pd_insn_i[31-:32] == riscv_opcodes_pkg_ECALL)) & (st_prv_i == riscv_state_pkg_PRV_M);
		my_exceptions[27] = (|my_exceptions[19-:20] | (|my_exceptions[25-:6])) | int_nmi_i;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			id_exceptions_o <= 'h0;
		else if (bu_flush_i || st_flush_i)
			id_exceptions_o <= 'h0;
		else if (!stalls) begin
			if (id_stall_o)
				id_exceptions_o <= 'h0;
			else
				id_exceptions_o <= my_exceptions;
		end
	always @(posedge clk_i)
		if (!stalls && !id_stall_o)
			id_bp_history_o <= pd_bp_history_i;
	function [4:0] riscv_opcodes_pkg_decode_rs1;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rs1 = instr[19-:5];
	endfunction
	assign id_rs1_o = riscv_opcodes_pkg_decode_rs1(pd_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rs2;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rs2 = instr[24-:5];
	endfunction
	assign id_rs2_o = riscv_opcodes_pkg_decode_rs2(pd_insn_i[31-:32]);
	assign pd_rs1 = riscv_opcodes_pkg_decode_rs1(pd_insn_i[31-:32]);
	assign pd_rs2 = riscv_opcodes_pkg_decode_rs2(pd_insn_i[31-:32]);
	function [11:0] riscv_opcodes_pkg_decode_immI;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immI = instr[31-:12];
	endfunction
	assign immI = riscv_opcodes_pkg_decode_immI(pd_insn_i[31-:32]);
	function [31:0] riscv_opcodes_pkg_decode_immU;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immU = {instr[31-:20], 12'h000};
	endfunction
	assign immU = riscv_opcodes_pkg_decode_immU(pd_insn_i[31-:32]);
	assign ext_immI = {{XLEN - 12 {immI[11]}}, immI};
	assign ext_immU = {{XLEN - 32 {immU[31]}}, immU};
	assign use_rf_opA = ~(((use_dwbr_opA | use_wbr_opA) | (|use_memr_opA)) | use_exr_opA);
	assign use_rf_opB = ~(((use_dwbr_opB | use_wbr_opB) | (|use_memr_opB)) | use_exr_opB);
	localparam [6:2] riscv_opcodes_pkg_OPC_AUIPC = 5'b00101;
	localparam [6:2] riscv_opcodes_pkg_OPC_BRANCH = 5'b11000;
	localparam [6:2] riscv_opcodes_pkg_OPC_JALR = 5'b11001;
	localparam [6:2] riscv_opcodes_pkg_OPC_LUI = 5'b01101;
	localparam [6:2] riscv_opcodes_pkg_OPC_OP = 5'b01100;
	localparam [6:2] riscv_opcodes_pkg_OPC_OP32 = 5'b01110;
	localparam [6:2] riscv_opcodes_pkg_OPC_OP_IMM = 5'b00100;
	localparam [6:2] riscv_opcodes_pkg_OPC_OP_IMM32 = 5'b00110;
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE = 5'b01000;
	localparam [6:2] riscv_opcodes_pkg_OPC_SYSTEM = 5'b11100;
	always @(posedge clk_i)
		if (!stalls)
			casex (pd_opcR[4-:5])
				riscv_opcodes_pkg_OPC_OP_IMM: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_AUIPC: begin
					id_userf_opA_o <= 'b0;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_OP_IMM32: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_OP: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= use_rf_opB;
				end
				riscv_opcodes_pkg_OPC_LUI: begin
					id_userf_opA_o <= 'b0;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_OP32: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= use_rf_opB;
				end
				riscv_opcodes_pkg_OPC_BRANCH: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= use_rf_opB;
				end
				riscv_opcodes_pkg_OPC_JALR: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_LOAD: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= 'b0;
				end
				riscv_opcodes_pkg_OPC_STORE: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= use_rf_opB;
				end
				riscv_opcodes_pkg_OPC_SYSTEM: begin
					id_userf_opA_o <= use_rf_opA;
					id_userf_opB_o <= 'b0;
				end
				default: begin
					id_userf_opA_o <= 'b1;
					id_userf_opB_o <= 'b1;
				end
			endcase
	assign nxt_opA = nxt_operand(use_exr_opA, use_memr_opA, use_wbr_opA, ex_r_i, mem_r_i, wb_memq_i, wb_r_i, dwb_r_i, mem_opcode);
	assign nxt_opB = nxt_operand(use_exr_opB, use_memr_opB, use_wbr_opB, ex_r_i, mem_r_i, wb_memq_i, wb_r_i, dwb_r_i, mem_opcode);
	localparam [6:2] riscv_opcodes_pkg_OPC_AMO = 5'b01011;
	localparam [6:2] riscv_opcodes_pkg_OPC_LOAD_FP = 5'b00001;
	localparam [6:2] riscv_opcodes_pkg_OPC_MADD = 5'b10000;
	localparam [6:2] riscv_opcodes_pkg_OPC_MISC_MEM = 5'b00011;
	localparam [6:2] riscv_opcodes_pkg_OPC_MSUB = 5'b10001;
	localparam [6:2] riscv_opcodes_pkg_OPC_NMADD = 5'b10011;
	localparam [6:2] riscv_opcodes_pkg_OPC_NMSUB = 5'b10010;
	localparam [6:2] riscv_opcodes_pkg_OPC_OP_FP = 5'b10100;
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE_FP = 5'b01001;
	always @(posedge clk_i)
		if (!stalls)
			casex (pd_opcR[4-:5])
				riscv_opcodes_pkg_OPC_LOAD_FP:
					;
				riscv_opcodes_pkg_OPC_MISC_MEM:
					;
				riscv_opcodes_pkg_OPC_OP_IMM: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= ext_immI;
				end
				riscv_opcodes_pkg_OPC_AUIPC: begin
					id_opA_o <= pd_pc_i;
					id_opB_o <= ext_immU;
				end
				riscv_opcodes_pkg_OPC_OP_IMM32: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= ext_immI;
				end
				riscv_opcodes_pkg_OPC_LOAD: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= ext_immI;
				end
				riscv_opcodes_pkg_OPC_STORE: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= nxt_opB;
				end
				riscv_opcodes_pkg_OPC_STORE_FP:
					;
				riscv_opcodes_pkg_OPC_AMO:
					;
				riscv_opcodes_pkg_OPC_OP: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= nxt_opB;
				end
				riscv_opcodes_pkg_OPC_LUI: begin
					id_opA_o <= 0;
					id_opB_o <= ext_immU;
				end
				riscv_opcodes_pkg_OPC_OP32: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= nxt_opB;
				end
				riscv_opcodes_pkg_OPC_MADD:
					;
				riscv_opcodes_pkg_OPC_MSUB:
					;
				riscv_opcodes_pkg_OPC_NMSUB:
					;
				riscv_opcodes_pkg_OPC_NMADD:
					;
				riscv_opcodes_pkg_OPC_OP_FP:
					;
				riscv_opcodes_pkg_OPC_BRANCH: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= nxt_opB;
				end
				riscv_opcodes_pkg_OPC_JALR: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= ext_immI;
				end
				riscv_opcodes_pkg_OPC_SYSTEM: begin
					id_opA_o <= nxt_opA;
					id_opB_o <= {{XLEN - 5 {1'b0}}, pd_rs1};
				end
				default: begin
					id_opA_o <= 'hx;
					id_opB_o <= 'hx;
				end
			endcase
	localparam [14:0] riscv_opcodes_pkg_DIV = 15'b000000110001100;
	localparam [14:0] riscv_opcodes_pkg_DIVU = 15'b000000110101100;
	localparam [14:0] riscv_opcodes_pkg_DIVUW = 15'b000000110101110;
	localparam [14:0] riscv_opcodes_pkg_DIVW = 15'b000000110001110;
	localparam [14:0] riscv_opcodes_pkg_MUL = 15'b000000100001100;
	localparam [14:0] riscv_opcodes_pkg_MULH = 15'b000000100101100;
	localparam [14:0] riscv_opcodes_pkg_MULHSU = 15'b000000101001100;
	localparam [14:0] riscv_opcodes_pkg_MULHU = 15'b000000101101100;
	localparam [14:0] riscv_opcodes_pkg_MULW = 15'b000000100001110;
	localparam [14:0] riscv_opcodes_pkg_REM = 15'b000000111001100;
	localparam [14:0] riscv_opcodes_pkg_REMU = 15'b000000111101100;
	localparam [14:0] riscv_opcodes_pkg_REMUW = 15'b000000111101110;
	localparam [14:0] riscv_opcodes_pkg_REMW = 15'b000000111001110;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			multi_cycle_instruction <= 1'b0;
		else if (!stalls)
			casex ({xlen32, pd_opcR})
				{1'bz, riscv_opcodes_pkg_MUL}: multi_cycle_instruction <= (MULT_LATENCY > 0 ? has_muldiv : 1'b0);
				{1'bz, riscv_opcodes_pkg_MULH}: multi_cycle_instruction <= (MULT_LATENCY > 0 ? has_muldiv : 1'b0);
				{1'b0, riscv_opcodes_pkg_MULW}: multi_cycle_instruction <= (MULT_LATENCY > 0 ? has_muldiv : 1'b0);
				{1'bz, riscv_opcodes_pkg_MULHSU}: multi_cycle_instruction <= (MULT_LATENCY > 0 ? has_muldiv : 1'b0);
				{1'bz, riscv_opcodes_pkg_MULHU}: multi_cycle_instruction <= (MULT_LATENCY > 0 ? has_muldiv : 1'b0);
				{1'bz, riscv_opcodes_pkg_DIV}: multi_cycle_instruction <= has_muldiv;
				{1'b0, riscv_opcodes_pkg_DIVW}: multi_cycle_instruction <= has_muldiv;
				{1'bz, riscv_opcodes_pkg_DIVU}: multi_cycle_instruction <= has_muldiv;
				{1'b0, riscv_opcodes_pkg_DIVUW}: multi_cycle_instruction <= has_muldiv;
				{1'bz, riscv_opcodes_pkg_REM}: multi_cycle_instruction <= has_muldiv;
				{1'b0, riscv_opcodes_pkg_REMW}: multi_cycle_instruction <= has_muldiv;
				{1'bz, riscv_opcodes_pkg_REMU}: multi_cycle_instruction <= has_muldiv;
				{1'b0, riscv_opcodes_pkg_REMUW}: multi_cycle_instruction <= has_muldiv;
				default: multi_cycle_instruction <= 1'b0;
			endcase
	localparam [6:2] riscv_opcodes_pkg_OPC_JAL = 5'b11011;
	always @(*) begin
		if (_sv2v_0)
			;
		casex (id_opcode)
			riscv_opcodes_pkg_OPC_LOAD: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_OP_IMM: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_AUIPC: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_OP_IMM32: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_AMO: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_OP: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_LUI: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_OP32: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_JALR: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_JAL: can_bypex = ~id_insn_o[33];
			riscv_opcodes_pkg_OPC_SYSTEM: can_bypex = ~id_insn_o[33];
			default: can_bypex = 1'b0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (ex_opcode)
			riscv_opcodes_pkg_OPC_LOAD: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_OP_IMM: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_AUIPC: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_OP_IMM32: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_AMO: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_OP: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_LUI: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_OP32: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_JALR: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_JAL: can_use_exr = ~ex_insn_i[33];
			riscv_opcodes_pkg_OPC_SYSTEM: can_use_exr = ~ex_insn_i[33];
			default: can_use_exr = 1'b0;
		endcase
	end
	always @(*) begin : sv2v_autoblock_2
		reg signed [31:0] n;
		if (_sv2v_0)
			;
		for (n = 0; n < MEM_STAGES; n = n + 1)
			casex (mem_opcode[((MEM_STAGES - 1) - n) * 5+:5])
				riscv_opcodes_pkg_OPC_LOAD: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_OP_IMM: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_AUIPC: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_OP_IMM32: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_AMO: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_OP: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_LUI: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_OP32: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_JALR: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_JAL: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				riscv_opcodes_pkg_OPC_SYSTEM: can_use_memr[n] = ~mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33];
				default: can_use_memr[n] = 1'b0;
			endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (wb_opcode)
			riscv_opcodes_pkg_OPC_LOAD: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_OP_IMM: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_AUIPC: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_OP_IMM32: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_AMO: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_OP: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_LUI: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_OP32: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_JALR: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_JAL: can_use_wbr = ~wb_insn_i[33];
			riscv_opcodes_pkg_OPC_SYSTEM: can_use_wbr = ~wb_insn_i[33];
			default: can_use_wbr = 1'b0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (dwb_opcode)
			riscv_opcodes_pkg_OPC_LOAD: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_OP_IMM: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_AUIPC: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_OP_IMM32: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_AMO: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_OP: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_LUI: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_OP32: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_JALR: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_JAL: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			riscv_opcodes_pkg_OPC_SYSTEM: can_use_dwbr = (RF_REGOUT > 0 ? ~dwb_insn_i[33] : 1'b0);
			default: can_use_dwbr = 1'b0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (pd_opcR[4-:5])
			riscv_opcodes_pkg_OPC_OP_IMM: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_3
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = 1'b0;
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = 1'b0;
			end
			riscv_opcodes_pkg_OPC_OP_IMM32: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_4
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = 1'b0;
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = 1'b0;
			end
			riscv_opcodes_pkg_OPC_OP: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = use_result(pd_rs2, ex_rd, can_use_exr);
				begin : sv2v_autoblock_5
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = use_result(pd_rs2, mem_rd[n], can_use_memr[n]);
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = use_result(pd_rs2, wb_rd, can_use_wbr);
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = use_result(pd_rs2, dwb_rd, can_use_dwbr);
			end
			riscv_opcodes_pkg_OPC_OP32: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = use_result(pd_rs2, ex_rd, can_use_exr);
				begin : sv2v_autoblock_6
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = use_result(pd_rs2, mem_rd[n], can_use_memr[n]);
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = use_result(pd_rs2, wb_rd, can_use_wbr);
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = use_result(pd_rs2, dwb_rd, can_use_dwbr);
			end
			riscv_opcodes_pkg_OPC_BRANCH: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = use_result(pd_rs2, ex_rd, can_use_exr);
				begin : sv2v_autoblock_7
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = use_result(pd_rs2, mem_rd[n], can_use_memr[n]);
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = use_result(pd_rs2, wb_rd, can_use_wbr);
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = use_result(pd_rs2, dwb_rd, can_use_dwbr);
			end
			riscv_opcodes_pkg_OPC_JALR: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_8
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = 1'b0;
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = 1'b0;
			end
			riscv_opcodes_pkg_OPC_LOAD: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_9
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = 1'b0;
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = 1'b0;
			end
			riscv_opcodes_pkg_OPC_STORE: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = use_result(pd_rs2, ex_rd, can_use_exr);
				begin : sv2v_autoblock_10
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = use_result(pd_rs2, mem_rd[n], can_use_memr[n]);
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = use_result(pd_rs2, wb_rd, can_use_wbr);
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = use_result(pd_rs2, dwb_rd, can_use_dwbr);
			end
			riscv_opcodes_pkg_OPC_SYSTEM: begin
				use_exr_opA = use_result(pd_rs1, ex_rd, can_use_exr);
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_11
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = use_result(pd_rs1, mem_rd[n], can_use_memr[n]);
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = use_result(pd_rs1, wb_rd, can_use_wbr);
				use_wbr_opB = 1'b0;
				use_dwbr_opA = use_result(pd_rs1, dwb_rd, can_use_dwbr);
				use_dwbr_opB = 1'b0;
			end
			default: begin
				use_exr_opA = 1'b0;
				use_exr_opB = 1'b0;
				begin : sv2v_autoblock_12
					reg signed [31:0] n;
					for (n = 0; n < MEM_STAGES; n = n + 1)
						begin
							use_memr_opA[n] = 1'b0;
							use_memr_opB[n] = 1'b0;
						end
				end
				use_wbr_opA = 1'b0;
				use_wbr_opB = 1'b0;
				use_dwbr_opA = 1'b0;
				use_dwbr_opB = 1'b0;
			end
		endcase
	end
	always @(posedge clk_i)
		if (!stalls)
			casex (pd_opcR[4-:5])
				riscv_opcodes_pkg_OPC_OP_IMM: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= 1'b0;
				end
				riscv_opcodes_pkg_OPC_OP_IMM32: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= 1'b0;
				end
				riscv_opcodes_pkg_OPC_OP: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= use_result(pd_rs2, id_rd, can_bypex);
				end
				riscv_opcodes_pkg_OPC_OP32: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= use_result(pd_rs2, id_rd, can_bypex);
				end
				riscv_opcodes_pkg_OPC_BRANCH: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= use_result(pd_rs2, id_rd, can_bypex);
				end
				riscv_opcodes_pkg_OPC_JALR: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= 1'b0;
				end
				riscv_opcodes_pkg_OPC_LOAD: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= 1'b0;
				end
				riscv_opcodes_pkg_OPC_STORE: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= use_result(pd_rs2, id_rd, can_bypex);
				end
				riscv_opcodes_pkg_OPC_SYSTEM: begin
					id_bypex_opA_o <= use_result(pd_rs1, id_rd, can_bypex);
					id_bypex_opB_o <= 1'b0;
				end
				default: begin
					id_bypex_opA_o <= 1'b0;
					id_bypex_opB_o <= 1'b0;
				end
			endcase
	always @(*) begin
		if (_sv2v_0)
			;
		if ((id_opcode != riscv_opcodes_pkg_OPC_LOAD) || id_insn_o[33])
			stall_ld_id = 1'b0;
		else
			casex (pd_opcR[4-:5])
				riscv_opcodes_pkg_OPC_OP_IMM: stall_ld_id = pd_rs1 == id_rd;
				riscv_opcodes_pkg_OPC_OP_IMM32: stall_ld_id = pd_rs1 == id_rd;
				riscv_opcodes_pkg_OPC_OP: stall_ld_id = (pd_rs1 == id_rd) | (pd_rs2 == id_rd);
				riscv_opcodes_pkg_OPC_OP32: stall_ld_id = (pd_rs1 == id_rd) | (pd_rs2 == id_rd);
				riscv_opcodes_pkg_OPC_BRANCH: stall_ld_id = (pd_rs1 == id_rd) | (pd_rs2 == id_rd);
				riscv_opcodes_pkg_OPC_JALR: stall_ld_id = pd_rs1 == id_rd;
				riscv_opcodes_pkg_OPC_LOAD: stall_ld_id = pd_rs1 == id_rd;
				riscv_opcodes_pkg_OPC_STORE: stall_ld_id = (pd_rs1 == id_rd) | (pd_rs2 == id_rd);
				riscv_opcodes_pkg_OPC_SYSTEM: stall_ld_id = pd_rs1 == id_rd;
				default: stall_ld_id = 'b0;
			endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((ex_opcode != riscv_opcodes_pkg_OPC_LOAD) || ex_insn_i[33])
			stall_ld_ex = 1'b0;
		else
			casex (pd_opcR[4-:5])
				riscv_opcodes_pkg_OPC_OP_IMM: stall_ld_ex = pd_rs1 == ex_rd;
				riscv_opcodes_pkg_OPC_OP_IMM32: stall_ld_ex = pd_rs1 == ex_rd;
				riscv_opcodes_pkg_OPC_OP: stall_ld_ex = (pd_rs1 == ex_rd) | (pd_rs2 == ex_rd);
				riscv_opcodes_pkg_OPC_OP32: stall_ld_ex = (pd_rs1 == ex_rd) | (pd_rs2 == ex_rd);
				riscv_opcodes_pkg_OPC_BRANCH: stall_ld_ex = (pd_rs1 == ex_rd) | (pd_rs2 == ex_rd);
				riscv_opcodes_pkg_OPC_JALR: stall_ld_ex = pd_rs1 == ex_rd;
				riscv_opcodes_pkg_OPC_LOAD: stall_ld_ex = pd_rs1 == ex_rd;
				riscv_opcodes_pkg_OPC_STORE: stall_ld_ex = (pd_rs1 == ex_rd) | (pd_rs2 == ex_rd);
				riscv_opcodes_pkg_OPC_SYSTEM: stall_ld_ex = pd_rs1 == ex_rd;
				default: stall_ld_ex = 'b0;
			endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (MEM_STAGES == 1)
			stall_ld_mem[0] = 1'b0;
		else begin
			begin : sv2v_autoblock_13
				reg signed [31:0] n;
				for (n = 0; n < (MEM_STAGES - 1); n = n + 1)
					if ((mem_opcode[((MEM_STAGES - 1) - n) * 5+:5] != riscv_opcodes_pkg_OPC_LOAD) || mem_insn_i[(((MEM_STAGES - 1) - n) * 35) + 33])
						stall_ld_mem[n] = 1'b0;
					else
						casex (pd_opcR[4-:5])
							riscv_opcodes_pkg_OPC_OP_IMM: stall_ld_mem[n] = pd_rs1 == mem_rd[n];
							riscv_opcodes_pkg_OPC_OP_IMM32: stall_ld_mem[n] = pd_rs1 == mem_rd[n];
							riscv_opcodes_pkg_OPC_OP: stall_ld_mem[n] = (pd_rs1 == mem_rd[n]) | (pd_rs2 == mem_rd[n]);
							riscv_opcodes_pkg_OPC_OP32: stall_ld_mem[n] = (pd_rs1 == mem_rd[n]) | (pd_rs2 == mem_rd[n]);
							riscv_opcodes_pkg_OPC_BRANCH: stall_ld_mem[n] = (pd_rs1 == mem_rd[n]) | (pd_rs2 == mem_rd[n]);
							riscv_opcodes_pkg_OPC_JALR: stall_ld_mem[n] = pd_rs1 == mem_rd[n];
							riscv_opcodes_pkg_OPC_LOAD: stall_ld_mem[n] = pd_rs1 == mem_rd[n];
							riscv_opcodes_pkg_OPC_STORE: stall_ld_mem[n] = (pd_rs1 == mem_rd[n]) | (pd_rs2 == mem_rd[n]);
							riscv_opcodes_pkg_OPC_SYSTEM: stall_ld_mem[n] = pd_rs1 == mem_rd[n];
							default: stall_ld_mem[n] = 'b0;
						endcase
			end
			stall_ld_mem[MEM_STAGES - 1] = 1'b0;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((bu_flush_i || st_flush_i) || du_flush_i)
			id_stall_o = 'b0;
		else if (stalls)
			id_stall_o = 1'b1;
		else
			id_stall_o = (stall_ld_id | stall_ld_ex) | (|stall_ld_mem);
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (pd_opcR[4-:5])
			riscv_opcodes_pkg_OPC_LOAD: illegal_instr = illegal_lsu_instr;
			riscv_opcodes_pkg_OPC_STORE: illegal_instr = illegal_lsu_instr;
			default: illegal_instr = illegal_alu_instr & (has_muldiv ? illegal_muldiv_instr : 1'b1);
		endcase
	end
	localparam [14:0] riscv_opcodes_pkg_ADD = 15'b000000000001100;
	localparam [14:0] riscv_opcodes_pkg_ADDI = 15'bzzzzzzz00000100;
	localparam [14:0] riscv_opcodes_pkg_ADDIW = 15'bzzzzzzz00000110;
	localparam [14:0] riscv_opcodes_pkg_ADDW = 15'b000000000001110;
	localparam [14:0] riscv_opcodes_pkg_AND = 15'b000000011101100;
	localparam [14:0] riscv_opcodes_pkg_ANDI = 15'bzzzzzzz11100100;
	localparam [14:0] riscv_opcodes_pkg_AUIPC = 15'bzzzzzzzzzz00101;
	localparam [14:0] riscv_opcodes_pkg_BEQ = 15'bzzzzzzz00011000;
	localparam [14:0] riscv_opcodes_pkg_BGE = 15'bzzzzzzz10111000;
	localparam [14:0] riscv_opcodes_pkg_BGEU = 15'bzzzzzzz11111000;
	localparam [14:0] riscv_opcodes_pkg_BLT = 15'bzzzzzzz10011000;
	localparam [14:0] riscv_opcodes_pkg_BLTU = 15'bzzzzzzz11011000;
	localparam [14:0] riscv_opcodes_pkg_BNE = 15'bzzzzzzz00111000;
	localparam [14:0] riscv_opcodes_pkg_CSRRC = 15'bzzzzzzz01111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRCI = 15'bzzzzzzz11111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRS = 15'bzzzzzzz01011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRSI = 15'bzzzzzzz11011100;
	localparam [14:0] riscv_opcodes_pkg_CSRRW = 15'bzzzzzzz00111100;
	localparam [14:0] riscv_opcodes_pkg_CSRRWI = 15'bzzzzzzz10111100;
	localparam [31:0] riscv_opcodes_pkg_EBREAKC = 32'b00000000000100000000000001110000;
	localparam [31:0] riscv_opcodes_pkg_FENCE = 32'b0000zzzzzzzz00000000000000001101;
	localparam [31:0] riscv_opcodes_pkg_FENCE_I = 32'b00000000000000000001000000001101;
	localparam [14:0] riscv_opcodes_pkg_JAL = 15'bzzzzzzzzzz11011;
	localparam [14:0] riscv_opcodes_pkg_JALR = 15'bzzzzzzz00011001;
	localparam [14:0] riscv_opcodes_pkg_LUI = 15'bzzzzzzzzzz01101;
	localparam [31:0] riscv_opcodes_pkg_MRET = 32'b00110000001000000000000001110001;
	localparam [14:0] riscv_opcodes_pkg_OR = 15'b000000011001100;
	localparam [14:0] riscv_opcodes_pkg_ORI = 15'bzzzzzzz11000100;
	localparam [14:0] riscv_opcodes_pkg_SLL = 15'b000000000101100;
	localparam [14:0] riscv_opcodes_pkg_SLLI = 15'b000000z00100100;
	localparam [14:0] riscv_opcodes_pkg_SLLIW = 15'b000000000100110;
	localparam [14:0] riscv_opcodes_pkg_SLLW = 15'b000000000101110;
	localparam [14:0] riscv_opcodes_pkg_SLT = 15'b000000001001100;
	localparam [14:0] riscv_opcodes_pkg_SLTI = 15'bzzzzzzz01000100;
	localparam [14:0] riscv_opcodes_pkg_SLTIU = 15'bzzzzzzz01100100;
	localparam [14:0] riscv_opcodes_pkg_SLTU = 15'b000000001101100;
	localparam [14:0] riscv_opcodes_pkg_SRA = 15'b010000010101100;
	localparam [14:0] riscv_opcodes_pkg_SRAI = 15'b010000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SRAIW = 15'b010000010100110;
	localparam [14:0] riscv_opcodes_pkg_SRAW = 15'b010000010101110;
	localparam [31:0] riscv_opcodes_pkg_SRET = 32'b00010000001000000000000001110001;
	localparam [14:0] riscv_opcodes_pkg_SRL = 15'b000000010101100;
	localparam [14:0] riscv_opcodes_pkg_SRLI = 15'b000000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SRLIW = 15'b000000010100110;
	localparam [14:0] riscv_opcodes_pkg_SRLW = 15'b000000010101110;
	localparam [14:0] riscv_opcodes_pkg_SUB = 15'b010000000001100;
	localparam [14:0] riscv_opcodes_pkg_SUBW = 15'b010000000001110;
	localparam [31:0] riscv_opcodes_pkg_URET = 32'b00000000001000000000000001110001;
	localparam [14:0] riscv_opcodes_pkg_XOR = 15'b000000010001100;
	localparam [14:0] riscv_opcodes_pkg_XORI = 15'bzzzzzzz10000100;
	always @(*) begin
		if (_sv2v_0)
			;
		casex (pd_insn_i[31-:32])
			riscv_opcodes_pkg_FENCE: illegal_alu_instr = 1'b0;
			riscv_opcodes_pkg_FENCE_I: illegal_alu_instr = 1'b0;
			riscv_opcodes_pkg_ECALL: illegal_alu_instr = 1'b0;
			riscv_opcodes_pkg_EBREAK: illegal_alu_instr = 1'b0;
			riscv_opcodes_pkg_EBREAKC: illegal_alu_instr = ~has_rvc;
			riscv_opcodes_pkg_URET: illegal_alu_instr = ~has_u;
			riscv_opcodes_pkg_SRET: illegal_alu_instr = (~has_s | (st_prv_i < riscv_state_pkg_PRV_S)) | ((st_prv_i == riscv_state_pkg_PRV_S) && st_tsr_i);
			riscv_opcodes_pkg_MRET: illegal_alu_instr = st_prv_i != riscv_state_pkg_PRV_M;
			default:
				casex ({xlen32, pd_opcR})
					{1'bz, riscv_opcodes_pkg_LUI}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_AUIPC}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_JAL}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_JALR}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_BEQ}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_BNE}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_BLT}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_BGE}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_BLTU}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_BGEU}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_ADDI}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_ADD}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'b0, riscv_opcodes_pkg_ADDIW}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'b0, riscv_opcodes_pkg_ADDW}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_SUB}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'b0, riscv_opcodes_pkg_SUBW}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_XORI}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_XOR}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_ORI}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_OR}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_ANDI}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_AND}: illegal_alu_instr = ~is_32bit_instruction & ~has_rvc;
					{1'bz, riscv_opcodes_pkg_SLLI}: illegal_alu_instr = (~is_32bit_instruction & ~has_rvc) | (xlen32 & pd_opcR[8]);
					{1'bz, riscv_opcodes_pkg_SLL}: illegal_alu_instr = ~is_32bit_instruction;
					{1'b0, riscv_opcodes_pkg_SLLIW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'b0, riscv_opcodes_pkg_SLLW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SLTI}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SLT}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SLTIU}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SLTU}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SRLI}: illegal_alu_instr = (~is_32bit_instruction & ~has_rvc) | (xlen32 & pd_opcR[8]);
					{1'bz, riscv_opcodes_pkg_SRL}: illegal_alu_instr = ~is_32bit_instruction;
					{1'b0, riscv_opcodes_pkg_SRLIW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'b0, riscv_opcodes_pkg_SRLW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SRAI}: illegal_alu_instr = (~is_32bit_instruction & ~has_rvc) | (xlen32 & pd_opcR[8]);
					{1'bz, riscv_opcodes_pkg_SRA}: illegal_alu_instr = ~is_32bit_instruction;
					{1'b0, riscv_opcodes_pkg_SRAIW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_SRAW}: illegal_alu_instr = ~is_32bit_instruction;
					{1'bz, riscv_opcodes_pkg_CSRRW}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | illegal_csr_wr;
					{1'bz, riscv_opcodes_pkg_CSRRS}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | (|pd_rs1 & illegal_csr_wr);
					{1'bz, riscv_opcodes_pkg_CSRRC}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | (|pd_rs1 & illegal_csr_wr);
					{1'bz, riscv_opcodes_pkg_CSRRWI}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | (|pd_rs1 & illegal_csr_wr);
					{1'bz, riscv_opcodes_pkg_CSRRSI}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | (|pd_rs1 & illegal_csr_wr);
					{1'bz, riscv_opcodes_pkg_CSRRCI}: illegal_alu_instr = (~is_32bit_instruction | illegal_csr_rd) | (|pd_rs1 & illegal_csr_wr);
					default: illegal_alu_instr = 1'b1;
				endcase
		endcase
	end
	localparam [14:0] riscv_opcodes_pkg_LB = 15'bzzzzzzz00000000;
	localparam [14:0] riscv_opcodes_pkg_LBU = 15'bzzzzzzz10000000;
	localparam [14:0] riscv_opcodes_pkg_LD = 15'bzzzzzzz01100000;
	localparam [14:0] riscv_opcodes_pkg_LH = 15'bzzzzzzz00100000;
	localparam [14:0] riscv_opcodes_pkg_LHU = 15'bzzzzzzz10100000;
	localparam [14:0] riscv_opcodes_pkg_LW = 15'bzzzzzzz01000000;
	localparam [14:0] riscv_opcodes_pkg_LWU = 15'bzzzzzzz11000000;
	localparam [14:0] riscv_opcodes_pkg_SB = 15'bzzzzzzz00001000;
	localparam [14:0] riscv_opcodes_pkg_SD = 15'bzzzzzzz01101000;
	localparam [14:0] riscv_opcodes_pkg_SH = 15'bzzzzzzz00101000;
	localparam [14:0] riscv_opcodes_pkg_SW = 15'bzzzzzzz01001000;
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({xlen32, has_amo, pd_opcR})
			{2'bzz, riscv_opcodes_pkg_LB}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_LH}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_LW}: illegal_lsu_instr = ~is_32bit_instruction & ~has_rvc;
			{2'b0z, riscv_opcodes_pkg_LD}: illegal_lsu_instr = ~is_32bit_instruction & ~has_rvc;
			{2'bzz, riscv_opcodes_pkg_LBU}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_LHU}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'b0z, riscv_opcodes_pkg_LWU}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_SB}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_SH}: illegal_lsu_instr = ~is_32bit_instruction;
			{2'bzz, riscv_opcodes_pkg_SW}: illegal_lsu_instr = ~is_32bit_instruction & ~has_rvc;
			{2'b0z, riscv_opcodes_pkg_SD}: illegal_lsu_instr = ~is_32bit_instruction & ~has_rvc;
			default: illegal_lsu_instr = 1'b1;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({xlen32, pd_opcR})
			{1'bz, riscv_opcodes_pkg_MUL}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_MULH}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'b0, riscv_opcodes_pkg_MULW}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_MULHSU}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_MULHU}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_DIV}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'b0, riscv_opcodes_pkg_DIVW}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_DIVU}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'b0, riscv_opcodes_pkg_DIVUW}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_REM}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'b0, riscv_opcodes_pkg_REMW}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'bz, riscv_opcodes_pkg_REMU}: illegal_muldiv_instr = ~is_32bit_instruction;
			{1'b0, riscv_opcodes_pkg_REMUW}: illegal_muldiv_instr = ~is_32bit_instruction;
			default: illegal_muldiv_instr = 1'b1;
		endcase
	end
	localparam riscv_state_pkg_CY = 0;
	localparam [11:0] riscv_state_pkg_CYCLE = 'hc00;
	localparam [11:0] riscv_state_pkg_CYCLEH = 'hc80;
	localparam [11:0] riscv_state_pkg_FCSR = 'h3;
	localparam [11:0] riscv_state_pkg_FFLAGS = 'h1;
	localparam [11:0] riscv_state_pkg_FRM = 'h2;
	localparam [11:0] riscv_state_pkg_INSTRET = 'hc02;
	localparam [11:0] riscv_state_pkg_INSTRETH = 'hc82;
	localparam riscv_state_pkg_IR = 2;
	localparam [11:0] riscv_state_pkg_MARCHID = 'hf12;
	localparam [11:0] riscv_state_pkg_MCAUSE = 'h342;
	localparam [11:0] riscv_state_pkg_MCONFIGPTR = 'hf15;
	localparam [11:0] riscv_state_pkg_MCOUNTEREN = 'h306;
	localparam [11:0] riscv_state_pkg_MCYCLE = 'hb00;
	localparam [11:0] riscv_state_pkg_MCYCLEH = 'hb80;
	localparam [11:0] riscv_state_pkg_MEDELEG = 'h302;
	localparam [11:0] riscv_state_pkg_MEDELEGH = 'h312;
	localparam [11:0] riscv_state_pkg_MENVCFG = 'h30a;
	localparam [11:0] riscv_state_pkg_MENVCFGH = 'h31a;
	localparam [11:0] riscv_state_pkg_MEPC = 'h341;
	localparam [11:0] riscv_state_pkg_MHARTID = 'hf14;
	localparam [11:0] riscv_state_pkg_MIDELEG = 'h303;
	localparam [11:0] riscv_state_pkg_MIE = 'h304;
	localparam [11:0] riscv_state_pkg_MIMPID = 'hf13;
	localparam [11:0] riscv_state_pkg_MINSTRET = 'hb02;
	localparam [11:0] riscv_state_pkg_MINSTRETH = 'hb82;
	localparam [11:0] riscv_state_pkg_MIP = 'h344;
	localparam [11:0] riscv_state_pkg_MISA = 'h301;
	localparam [11:0] riscv_state_pkg_MNCAUSE = 'h742;
	localparam [11:0] riscv_state_pkg_MNEPC = 'h741;
	localparam [11:0] riscv_state_pkg_MNSCRATCH = 'h740;
	localparam [11:0] riscv_state_pkg_MNSTATUS = 'h744;
	localparam [11:0] riscv_state_pkg_MSCRATCH = 'h340;
	localparam [11:0] riscv_state_pkg_MSECCFG = 'h747;
	localparam [11:0] riscv_state_pkg_MSECCFGH = 'h757;
	localparam [11:0] riscv_state_pkg_MSTATEEN0 = 'h30c;
	localparam [11:0] riscv_state_pkg_MSTATEEN0H = 'h31c;
	localparam [11:0] riscv_state_pkg_MSTATEEN1 = 'h30d;
	localparam [11:0] riscv_state_pkg_MSTATEEN1H = 'h31d;
	localparam [11:0] riscv_state_pkg_MSTATEEN2 = 'h30e;
	localparam [11:0] riscv_state_pkg_MSTATEEN2H = 'h31e;
	localparam [11:0] riscv_state_pkg_MSTATEEN3 = 'h30f;
	localparam [11:0] riscv_state_pkg_MSTATEEN3H = 'h31f;
	localparam [11:0] riscv_state_pkg_MSTATUS = 'h300;
	localparam [11:0] riscv_state_pkg_MSTATUSH = 'h310;
	localparam [11:0] riscv_state_pkg_MTINST = 'h34a;
	localparam [11:0] riscv_state_pkg_MTVAL = 'h343;
	localparam [11:0] riscv_state_pkg_MTVAL2 = 'h34b;
	localparam [11:0] riscv_state_pkg_MTVEC = 'h305;
	localparam [11:0] riscv_state_pkg_MVENDORID = 'hf11;
	localparam [11:0] riscv_state_pkg_PMPADDR0 = 'h3b0;
	localparam [11:0] riscv_state_pkg_PMPADDR1 = 'h3b1;
	localparam [11:0] riscv_state_pkg_PMPADDR10 = 'h3ba;
	localparam [11:0] riscv_state_pkg_PMPADDR11 = 'h3bb;
	localparam [11:0] riscv_state_pkg_PMPADDR12 = 'h3bc;
	localparam [11:0] riscv_state_pkg_PMPADDR13 = 'h3bd;
	localparam [11:0] riscv_state_pkg_PMPADDR14 = 'h3be;
	localparam [11:0] riscv_state_pkg_PMPADDR15 = 'h3bf;
	localparam [11:0] riscv_state_pkg_PMPADDR2 = 'h3b2;
	localparam [11:0] riscv_state_pkg_PMPADDR3 = 'h3b3;
	localparam [11:0] riscv_state_pkg_PMPADDR4 = 'h3b4;
	localparam [11:0] riscv_state_pkg_PMPADDR5 = 'h3b5;
	localparam [11:0] riscv_state_pkg_PMPADDR6 = 'h3b6;
	localparam [11:0] riscv_state_pkg_PMPADDR7 = 'h3b7;
	localparam [11:0] riscv_state_pkg_PMPADDR8 = 'h3b8;
	localparam [11:0] riscv_state_pkg_PMPADDR9 = 'h3b9;
	localparam [11:0] riscv_state_pkg_PMPCFG0 = 'h3a0;
	localparam [11:0] riscv_state_pkg_PMPCFG1 = 'h3a1;
	localparam [11:0] riscv_state_pkg_PMPCFG2 = 'h3a2;
	localparam [11:0] riscv_state_pkg_PMPCFG3 = 'h3a3;
	localparam [11:0] riscv_state_pkg_SATP = 'h180;
	localparam [11:0] riscv_state_pkg_SCAUSE = 'h142;
	localparam [11:0] riscv_state_pkg_SCONTEXT = 'h5a8;
	localparam [11:0] riscv_state_pkg_SCOUNTEREN = 'h106;
	localparam [11:0] riscv_state_pkg_SCOUNTINHIBIT = 'h120;
	localparam [11:0] riscv_state_pkg_SENVCFG = 'h10a;
	localparam [11:0] riscv_state_pkg_SEPC = 'h141;
	localparam [11:0] riscv_state_pkg_SIE = 'h104;
	localparam [11:0] riscv_state_pkg_SIP = 'h144;
	localparam [11:0] riscv_state_pkg_SSCRATCH = 'h140;
	localparam [11:0] riscv_state_pkg_SSTATUS = 'h100;
	localparam [11:0] riscv_state_pkg_STVAL = 'h143;
	localparam [11:0] riscv_state_pkg_STVEC = 'h105;
	localparam [11:0] riscv_state_pkg_TIME = 'hc01;
	localparam [11:0] riscv_state_pkg_TIMEH = 'hc81;
	always @(*) begin
		if (_sv2v_0)
			;
		case (pd_insn_i[31:20])
			riscv_state_pkg_FFLAGS: illegal_csr_rd = ~has_fpu;
			riscv_state_pkg_FRM: illegal_csr_rd = ~has_fpu;
			riscv_state_pkg_FCSR: illegal_csr_rd = ~has_fpu;
			riscv_state_pkg_CYCLE: illegal_csr_rd = ((~has_u | ((~has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & ~st_mcounteren_i[riscv_state_pkg_CY])) | ((has_s & (st_prv_i == riscv_state_pkg_PRV_S)) & ~st_mcounteren_i[riscv_state_pkg_CY])) | (((has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & st_mcounteren_i[riscv_state_pkg_CY]) & st_scounteren_i[riscv_state_pkg_CY]);
			riscv_state_pkg_TIME: illegal_csr_rd = 1'b1;
			riscv_state_pkg_INSTRET: illegal_csr_rd = ((~has_u | ((~has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & ~st_mcounteren_i[riscv_state_pkg_IR])) | ((has_s & (st_prv_i == riscv_state_pkg_PRV_S)) & ~st_mcounteren_i[riscv_state_pkg_IR])) | (((has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & st_mcounteren_i[riscv_state_pkg_IR]) & st_scounteren_i[riscv_state_pkg_IR]);
			riscv_state_pkg_CYCLEH: illegal_csr_rd = (((~has_u | ~xlen32) | ((~has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & ~st_mcounteren_i[riscv_state_pkg_CY])) | ((has_s & (st_prv_i == riscv_state_pkg_PRV_S)) & ~st_mcounteren_i[riscv_state_pkg_CY])) | (((has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & st_mcounteren_i[riscv_state_pkg_CY]) & st_scounteren_i[riscv_state_pkg_CY]);
			riscv_state_pkg_TIMEH: illegal_csr_rd = 1'b1;
			riscv_state_pkg_INSTRETH: illegal_csr_rd = (((~has_u | ~xlen32) | ((~has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & ~st_mcounteren_i[riscv_state_pkg_IR])) | ((has_s & (st_prv_i == riscv_state_pkg_PRV_S)) & ~st_mcounteren_i[riscv_state_pkg_IR])) | (((has_s & (st_prv_i == riscv_state_pkg_PRV_U)) & st_mcounteren_i[riscv_state_pkg_IR]) & st_scounteren_i[riscv_state_pkg_IR]);
			riscv_state_pkg_SSTATUS: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SIE: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_STVEC: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCOUNTEREN: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCOUNTINHIBIT: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SENVCFG: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SSCRATCH: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SEPC: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCAUSE: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_STVAL: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SIP: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SATP: illegal_csr_rd = (~has_s | (st_prv_i < riscv_state_pkg_PRV_S)) | ((st_prv_i == riscv_state_pkg_PRV_S) && st_tvm_i);
			riscv_state_pkg_SCONTEXT: illegal_csr_rd = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_MVENDORID: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MARCHID: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MIMPID: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MHARTID: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCONFIGPTR: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATUS: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATUSH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MISA: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEDELEG: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEDELEGH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MIDELEG: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MIE: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MIP: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVEC: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCOUNTEREN: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSCRATCH: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEPC: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCAUSE: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVAL: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVAL2: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTINST: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MENVCFG: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MENVCFGH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSECCFG: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSECCFGH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPCFG0: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_PMPCFG1: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPCFG2: illegal_csr_rd = (XLEN > 64) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPCFG3: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR0: illegal_csr_rd = (PMP_CNT < 1) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR1: illegal_csr_rd = (PMP_CNT < 2) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR2: illegal_csr_rd = (PMP_CNT < 3) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR3: illegal_csr_rd = (PMP_CNT < 4) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR4: illegal_csr_rd = (PMP_CNT < 5) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR5: illegal_csr_rd = (PMP_CNT < 6) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR6: illegal_csr_rd = (PMP_CNT < 7) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR7: illegal_csr_rd = (PMP_CNT < 8) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR8: illegal_csr_rd = (PMP_CNT < 9) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR9: illegal_csr_rd = (PMP_CNT < 10) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR10: illegal_csr_rd = (PMP_CNT < 11) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR11: illegal_csr_rd = (PMP_CNT < 12) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR12: illegal_csr_rd = (PMP_CNT < 13) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR13: illegal_csr_rd = (PMP_CNT < 14) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR14: illegal_csr_rd = (PMP_CNT < 15) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR15: illegal_csr_rd = (PMP_CNT < 16) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN0: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN0H: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN1: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN1H: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN2: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN2H: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN3: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN3H: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MNSCRATCH: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNEPC: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNCAUSE: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNSTATUS: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCYCLE: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCYCLEH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MINSTRET: illegal_csr_rd = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MINSTRETH: illegal_csr_rd = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			default: illegal_csr_rd = 1'b1;
		endcase
	end
	localparam [11:0] riscv_state_pkg_MNMIVEC = 'h7c0;
	always @(*) begin
		if (_sv2v_0)
			;
		case (pd_insn_i[31:20])
			riscv_state_pkg_FFLAGS: illegal_csr_wr = ~has_fpu;
			riscv_state_pkg_FRM: illegal_csr_wr = ~has_fpu;
			riscv_state_pkg_FCSR: illegal_csr_wr = ~has_fpu;
			riscv_state_pkg_CYCLE: illegal_csr_wr = 1'b1;
			riscv_state_pkg_TIME: illegal_csr_wr = 1'b1;
			riscv_state_pkg_INSTRET: illegal_csr_wr = 1'b1;
			riscv_state_pkg_CYCLEH: illegal_csr_wr = 1'b1;
			riscv_state_pkg_TIMEH: illegal_csr_wr = 1'b1;
			riscv_state_pkg_INSTRETH: illegal_csr_wr = 1'b1;
			riscv_state_pkg_SSTATUS: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SIE: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_STVEC: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCOUNTEREN: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SENVCFG: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCOUNTINHIBIT: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SSCRATCH: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SEPC: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SCAUSE: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_STVAL: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SIP: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_SATP: illegal_csr_wr = (~has_s | (st_prv_i < riscv_state_pkg_PRV_S)) | ((st_prv_i == riscv_state_pkg_PRV_S) && st_tvm_i);
			riscv_state_pkg_SCONTEXT: illegal_csr_wr = ~has_s | (st_prv_i < riscv_state_pkg_PRV_S);
			riscv_state_pkg_MVENDORID: illegal_csr_wr = 1'b1;
			riscv_state_pkg_MARCHID: illegal_csr_wr = 1'b1;
			riscv_state_pkg_MIMPID: illegal_csr_wr = 1'b1;
			riscv_state_pkg_MHARTID: illegal_csr_wr = 1'b1;
			riscv_state_pkg_MCONFIGPTR: illegal_csr_wr = 1'b1;
			riscv_state_pkg_MSTATUS: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATUSH: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MISA: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEDELEG: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEDELEGH: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MIDELEG: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MIE: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MIP: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVEC: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNMIVEC: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCOUNTEREN: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSCRATCH: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MEPC: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCAUSE: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVAL: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTVAL2: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MTINST: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_PMPCFG0: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_PMPCFG1: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPCFG2: illegal_csr_wr = (XLEN > 64) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPCFG3: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR0: illegal_csr_wr = (PMP_CNT < 1) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR1: illegal_csr_wr = (PMP_CNT < 2) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR2: illegal_csr_wr = (PMP_CNT < 3) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR3: illegal_csr_wr = (PMP_CNT < 4) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR4: illegal_csr_wr = (PMP_CNT < 5) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR5: illegal_csr_wr = (PMP_CNT < 6) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR6: illegal_csr_wr = (PMP_CNT < 7) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR7: illegal_csr_wr = (PMP_CNT < 8) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR8: illegal_csr_wr = (PMP_CNT < 9) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR9: illegal_csr_wr = (PMP_CNT < 10) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR10: illegal_csr_wr = (PMP_CNT < 11) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR11: illegal_csr_wr = (PMP_CNT < 12) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR12: illegal_csr_wr = (PMP_CNT < 13) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR13: illegal_csr_wr = (PMP_CNT < 14) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR14: illegal_csr_wr = (PMP_CNT < 15) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_PMPADDR15: illegal_csr_wr = (PMP_CNT < 16) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN0: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN0H: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN1: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN1H: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN2: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN2H: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MSTATEEN3: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MSTATEEN3H: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MNSCRATCH: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNEPC: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNCAUSE: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MNSTATUS: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCYCLE: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MCYCLEH: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			riscv_state_pkg_MINSTRET: illegal_csr_wr = st_prv_i < riscv_state_pkg_PRV_M;
			riscv_state_pkg_MINSTRETH: illegal_csr_wr = (XLEN > 32) | (st_prv_i < riscv_state_pkg_PRV_M);
			default: illegal_csr_wr = 1'b1;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module riscv_if (
	rst_ni,
	clk_i,
	imem_adr_o,
	imem_req_o,
	imem_ack_i,
	imem_flush_o,
	imem_parcel_i,
	imem_parcel_valid_i,
	imem_parcel_misaligned_i,
	imem_parcel_page_fault_i,
	imem_parcel_error_i,
	bu_bp_history_i,
	if_predict_history_o,
	if_bp_history_o,
	if_predict_pc_o,
	if_nxt_pc_o,
	if_pc_o,
	if_nxt_insn_o,
	if_insn_o,
	if_exceptions_o,
	pd_exceptions_i,
	id_exceptions_i,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i,
	pd_pc_i,
	pd_stall_i,
	pd_flush_i,
	pd_latch_nxt_pc_i,
	bu_flush_i,
	st_flush_i,
	du_stall_i,
	du_we_pc_i,
	du_latch_nxt_pc_i,
	du_flush_i,
	du_dato_i,
	pd_nxt_pc_i,
	bu_nxt_pc_i,
	st_nxt_pc_i,
	st_xlen_i
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter HAS_RVC = 0;
	parameter BP_GLOBAL_BITS = 2;
	localparam PARCEL_SIZE = 16;
	input rst_ni;
	input clk_i;
	output reg [MXLEN - 1:0] imem_adr_o;
	output wire imem_req_o;
	input imem_ack_i;
	output wire imem_flush_o;
	input [MXLEN - 1:0] imem_parcel_i;
	input [(MXLEN / PARCEL_SIZE) - 1:0] imem_parcel_valid_i;
	input imem_parcel_misaligned_i;
	input imem_parcel_page_fault_i;
	input imem_parcel_error_i;
	input [BP_GLOBAL_BITS - 1:0] bu_bp_history_i;
	output wire [BP_GLOBAL_BITS - 1:0] if_predict_history_o;
	output reg [BP_GLOBAL_BITS - 1:0] if_bp_history_o;
	output reg [MXLEN - 1:0] if_predict_pc_o;
	output reg [MXLEN - 1:0] if_nxt_pc_o;
	output reg [MXLEN - 1:0] if_pc_o;
	output wire [34:0] if_nxt_insn_o;
	output reg [34:0] if_insn_o;
	output reg [27:0] if_exceptions_o;
	input wire [27:0] pd_exceptions_i;
	input wire [27:0] id_exceptions_i;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	input [MXLEN - 1:0] pd_pc_i;
	input pd_stall_i;
	input pd_flush_i;
	input pd_latch_nxt_pc_i;
	input bu_flush_i;
	input st_flush_i;
	input du_stall_i;
	input du_we_pc_i;
	input du_latch_nxt_pc_i;
	input du_flush_i;
	input [MXLEN - 1:0] du_dato_i;
	input [MXLEN - 1:0] pd_nxt_pc_i;
	input [MXLEN - 1:0] bu_nxt_pc_i;
	input [MXLEN - 1:0] st_nxt_pc_i;
	input [1:0] st_xlen_i;
	localparam ADR_MASK = (HAS_RVC != 0 ? {MXLEN {1'b1}} << 1 : {MXLEN {1'b1}} << 2);
	localparam INFLIGHT_CNT = 3;
	localparam QUEUE_DEPTH = (9 * MXLEN) / PARCEL_SIZE;
	localparam FULL_THRESHOLD = QUEUE_DEPTH - ((4 * MXLEN) / PARCEL_SIZE);
	localparam [9:0] riscv_opcodes_pkg_C_ADDI = 10'b000zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_ADDI16SP = 10'b011zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_ADDI4SPN = 10'b000zzzzz00;
	localparam [9:0] riscv_opcodes_pkg_C_ADDIW = 10'b001zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_ADDW = 10'b1001110101;
	localparam [9:0] riscv_opcodes_pkg_C_AND = 10'b1000111101;
	localparam [9:0] riscv_opcodes_pkg_C_ANDI = 10'b100z10zz01;
	localparam [9:0] riscv_opcodes_pkg_C_BEQZ = 10'b110zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_BNEZ = 10'b111zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_J = 10'b101zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_JAL = 10'b001zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_JALR = 10'b1001zzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_JR = 10'b1000zzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_LD = 10'b011zzzzz00;
	localparam [9:0] riscv_opcodes_pkg_C_LDSP = 10'b011zzzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_LI = 10'b010zzzzz01;
	localparam [9:0] riscv_opcodes_pkg_C_LW = 10'b010zzzzz00;
	localparam [9:0] riscv_opcodes_pkg_C_LWSP = 10'b010zzzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_OR = 10'b1000111001;
	localparam [9:0] riscv_opcodes_pkg_C_SD = 10'b111zzzzz00;
	localparam [9:0] riscv_opcodes_pkg_C_SDSP = 10'b111zzzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_SLLI = 10'b000zzzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_SRAI = 10'b100z01zz01;
	localparam [9:0] riscv_opcodes_pkg_C_SRLI = 10'b100z00zz01;
	localparam [9:0] riscv_opcodes_pkg_C_SUB = 10'b1000110001;
	localparam [9:0] riscv_opcodes_pkg_C_SUBW = 10'b1001110001;
	localparam [9:0] riscv_opcodes_pkg_C_SW = 10'b110zzzzz00;
	localparam [9:0] riscv_opcodes_pkg_C_SWSP = 10'b110zzzzz10;
	localparam [9:0] riscv_opcodes_pkg_C_XOR = 10'b1000110101;
	function [9:0] riscv_opcodes_pkg_decode_rvc_opcA;
		input reg [15:0] instr;
		riscv_opcodes_pkg_decode_rvc_opcA = {instr[15-:6], instr[6-:2], instr[1-:2]};
	endfunction
	function automatic rvc_is_illegal;
		input reg xlen128;
		input reg xlen64;
		input reg xlen32;
		input reg [15:0] parcel;
		begin
			rvc_is_illegal = 0;
			casex ({xlen128, xlen64, xlen32, riscv_opcodes_pkg_decode_rvc_opcA(parcel)})
				{3'bzzz, riscv_opcodes_pkg_C_LWSP}: rvc_is_illegal = (parcel[11-:5] == 0 ? 1'b1 : 1'b0);
				{3'bzz0, riscv_opcodes_pkg_C_LDSP}: rvc_is_illegal = (parcel[11-:5] == 0 ? 1'b1 : 1'b0);
				{3'bzzz, riscv_opcodes_pkg_C_SWSP}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_SDSP}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_LW}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_LD}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_SW}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_SD}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_J}: rvc_is_illegal = 1'b0;
				{3'bzz1, riscv_opcodes_pkg_C_JAL}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_JR}: rvc_is_illegal = (parcel[6-:5] != 0 ? 1'b0 : (parcel[11-:5] == 0 ? 1'b1 : 1'b0));
				{3'bzzz, riscv_opcodes_pkg_C_JALR}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_BEQZ}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_BNEZ}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_LI}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_ADDI16SP}: rvc_is_illegal = ({parcel[12], parcel[6-:5]} == 0 ? 1'b1 : 1'b0);
				{3'bzzz, riscv_opcodes_pkg_C_ADDI}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_ADDIW}: rvc_is_illegal = (parcel[11-:5] == 0 ? 1'b1 : 1'b0);
				{3'bzzz, riscv_opcodes_pkg_C_ADDI4SPN}: rvc_is_illegal = (parcel[12:5] == 5'h00 ? 1'b1 : 1'b0);
				{3'bzzz, riscv_opcodes_pkg_C_SLLI}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_SRLI}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_SRAI}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_ANDI}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_AND}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_OR}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_XOR}: rvc_is_illegal = 1'b0;
				{3'bzzz, riscv_opcodes_pkg_C_SUB}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_ADDW}: rvc_is_illegal = 1'b0;
				{3'bzz0, riscv_opcodes_pkg_C_SUBW}: rvc_is_illegal = 1'b0;
				default: rvc_is_illegal = 1'b1;
			endcase
		end
	endfunction
	wire has_rvc;
	wire xlen32;
	wire xlen64;
	wire xlen128;
	wire flushes;
	reg ddu_we_pc;
	wire du_we_pc_strb;
	wire parcel_misaligned;
	wire parcel_page_fault;
	wire parcel_error;
	wire parcel_queue_full;
	wire parcel_queue_empty;
	wire [1:0] parcel_queue_rd;
	wire parcel_valid;
	wire [31:0] parcel34;
	wire [31:0] parcel12;
	reg [31:0] rv_instr;
	wire [15:0] rvc_parcel1;
	wire [15:0] rvc_parcel2;
	reg rvc_illegal;
	reg [27:0] parcel_exceptions;
	wire is_16bit_instruction;
	wire is_32bit_instruction;
	assign has_rvc = HAS_RVC != 0;
	always @(posedge clk_i) ddu_we_pc <= du_we_pc_i;
	assign du_we_pc_strb = du_we_pc_i & ~ddu_we_pc;
	assign flushes = pd_flush_i | du_flush_i;
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	localparam [1:0] riscv_state_pkg_RV64I = 2'b10;
	assign xlen64 = st_xlen_i == riscv_state_pkg_RV64I;
	localparam [1:0] riscv_state_pkg_RV128I = 2'b11;
	assign xlen128 = st_xlen_i == riscv_state_pkg_RV128I;
	assign imem_req_o = (~parcel_queue_full & ~flushes) & ~du_stall_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			imem_adr_o <= PC_INIT & ADR_MASK;
		else if (st_flush_i)
			imem_adr_o <= st_nxt_pc_i & ADR_MASK;
		else if (du_stall_i)
			imem_adr_o <= if_nxt_pc_o & ADR_MASK;
		else if (bu_flush_i)
			imem_adr_o <= bu_nxt_pc_i & ADR_MASK;
		else if (pd_latch_nxt_pc_i)
			imem_adr_o <= pd_nxt_pc_i & ADR_MASK;
		else if (imem_req_o && imem_ack_i)
			imem_adr_o <= (imem_adr_o + (MXLEN / 8)) & ({MXLEN {1'b1}} << $clog2(MXLEN / 8));
	assign imem_flush_o = (flushes | pd_latch_nxt_pc_i) | du_latch_nxt_pc_i;
	riscv_parcel_queue #(
		.DEPTH(QUEUE_DEPTH),
		.WR_PARCELS(MXLEN / PARCEL_SIZE),
		.RD_PARCELS(4),
		.ALMOST_EMPTY_THRESHOLD(1),
		.ALMOST_FULL_THRESHOLD(FULL_THRESHOLD)
	) parcel_queue_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.flush_i(imem_flush_o),
		.parcel_i(imem_parcel_i),
		.parcel_valid_i(imem_parcel_valid_i),
		.parcel_misaligned_i(imem_parcel_misaligned_i),
		.parcel_page_fault_i(imem_parcel_page_fault_i),
		.parcel_error_i(imem_parcel_error_i),
		.parcel_rd_i({1'b0, parcel_queue_rd}),
		.parcel_q_o({parcel34, parcel12}),
		.parcel_misaligned_o(parcel_misaligned),
		.parcel_page_fault_o(parcel_page_fault),
		.parcel_error_o(parcel_error),
		.almost_empty_o(parcel_queue_empty),
		.almost_full_o(parcel_queue_full),
		.empty_o(),
		.full_o()
	);
	assign parcel_valid = ~parcel_queue_empty;
	assign is_16bit_instruction = ~&parcel12[1:0];
	assign is_32bit_instruction = ~&parcel12[4:2] & (&parcel12[1:0]);
	assign parcel_queue_rd = {((~pd_stall_i & ~du_stall_i) & parcel_valid) & is_32bit_instruction, ((~pd_stall_i & ~du_stall_i) & parcel_valid) & is_16bit_instruction};
	always @(*) begin
		if (_sv2v_0)
			;
		parcel_exceptions = 0;
		parcel_exceptions[0] = parcel_valid & parcel_misaligned;
		parcel_exceptions[1] = parcel_valid & parcel_error;
		parcel_exceptions[12] = parcel_valid & parcel_page_fault;
		parcel_exceptions[27] = |parcel_exceptions[19-:20];
	end
	parameter AUIPC_ADDI = 17'b00000100110110111;
	assign rvc_parcel1 = parcel12[15:0];
	assign rvc_parcel2 = parcel12[31:16];
	assign if_nxt_insn_o[33] = flushes | ~parcel_valid;
	always @(*) begin
		if (_sv2v_0)
			;
		if (!has_rvc || !is_16bit_instruction)
			rvc_illegal = 1'b0;
		else
			rvc_illegal = rvc_is_illegal(xlen128, xlen64, xlen32, rvc_parcel1);
	end
	localparam [14:0] riscv_opcodes_pkg_ADD = 15'b000000000001100;
	localparam [14:0] riscv_opcodes_pkg_ADDI = 15'bzzzzzzz00000100;
	localparam [14:0] riscv_opcodes_pkg_ADDIW = 15'bzzzzzzz00000110;
	localparam [14:0] riscv_opcodes_pkg_ADDW = 15'b000000000001110;
	localparam [14:0] riscv_opcodes_pkg_AND = 15'b000000011101100;
	localparam [14:0] riscv_opcodes_pkg_ANDI = 15'bzzzzzzz11100100;
	localparam [14:0] riscv_opcodes_pkg_BEQ = 15'bzzzzzzz00011000;
	localparam [14:0] riscv_opcodes_pkg_BNE = 15'bzzzzzzz00111000;
	localparam [31:0] riscv_opcodes_pkg_EBREAKC = 32'b00000000000100000000000001110000;
	localparam [14:0] riscv_opcodes_pkg_JAL = 15'bzzzzzzzzzz11011;
	localparam [14:0] riscv_opcodes_pkg_JALR = 15'bzzzzzzz00011001;
	localparam [14:0] riscv_opcodes_pkg_LD = 15'bzzzzzzz01100000;
	localparam [14:0] riscv_opcodes_pkg_LUI = 15'bzzzzzzzzzz01101;
	localparam [14:0] riscv_opcodes_pkg_LW = 15'bzzzzzzz01000000;
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	localparam [31:0] riscv_opcodes_pkg_NOPC = 32'h00000010;
	localparam [14:0] riscv_opcodes_pkg_OR = 15'b000000011001100;
	localparam [14:0] riscv_opcodes_pkg_SD = 15'bzzzzzzz01101000;
	localparam [14:0] riscv_opcodes_pkg_SLLI = 15'b000000z00100100;
	localparam [14:0] riscv_opcodes_pkg_SRAI = 15'b010000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SRLI = 15'b000000z10100100;
	localparam [14:0] riscv_opcodes_pkg_SUB = 15'b010000000001100;
	localparam [14:0] riscv_opcodes_pkg_SUBW = 15'b010000000001110;
	localparam [14:0] riscv_opcodes_pkg_SW = 15'bzzzzzzz01001000;
	localparam [31:0] riscv_opcodes_pkg_WFI = 32'b00010000010100000000000001110011;
	localparam [14:0] riscv_opcodes_pkg_XOR = 15'b000000010001100;
	function [31:0] riscv_opcodes_pkg_encode_I;
		input reg [14:0] opcode;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [11:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_I[31-:12] = imm;
			riscv_opcodes_pkg_encode_I[19-:5] = rs1;
			riscv_opcodes_pkg_encode_I[14-:3] = opcode[7:5];
			riscv_opcodes_pkg_encode_I[11-:5] = rd;
			riscv_opcodes_pkg_encode_I[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_I[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_Ishift;
		input reg [14:0] opcode;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [11:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_Ishift[31:26] = opcode[14:9];
			riscv_opcodes_pkg_encode_Ishift[25:20] = imm[5:0];
			riscv_opcodes_pkg_encode_Ishift[19-:5] = rs1;
			riscv_opcodes_pkg_encode_Ishift[14-:3] = opcode[7:5];
			riscv_opcodes_pkg_encode_Ishift[11-:5] = rd;
			riscv_opcodes_pkg_encode_Ishift[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_Ishift[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_R;
		input reg [14:0] opcode;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [4:0] rs2;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_R[31-:7] = opcode[14:8];
			riscv_opcodes_pkg_encode_R[24-:5] = rs2;
			riscv_opcodes_pkg_encode_R[19-:5] = rs1;
			riscv_opcodes_pkg_encode_R[14-:3] = opcode[7:5];
			riscv_opcodes_pkg_encode_R[11-:5] = rd;
			riscv_opcodes_pkg_encode_R[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_R[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_S;
		input reg [14:0] opcode;
		input reg [4:0] rs1;
		input reg [4:0] rs2;
		input reg [11:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_S[31-:7] = imm[11:5];
			riscv_opcodes_pkg_encode_S[11-:5] = imm[4:0];
			riscv_opcodes_pkg_encode_S[24-:5] = rs2;
			riscv_opcodes_pkg_encode_S[19-:5] = rs1;
			riscv_opcodes_pkg_encode_S[14-:3] = opcode[7:5];
			riscv_opcodes_pkg_encode_S[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_S[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_SB;
		input reg [14:0] opcode;
		input reg [4:0] rs1;
		input reg [4:0] rs2;
		input reg [12:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_SB[31] = imm[12];
			riscv_opcodes_pkg_encode_SB[7] = imm[11];
			riscv_opcodes_pkg_encode_SB[30-:6] = imm[10:5];
			riscv_opcodes_pkg_encode_SB[11-:4] = imm[4:1];
			riscv_opcodes_pkg_encode_SB[24-:5] = rs2;
			riscv_opcodes_pkg_encode_SB[19-:5] = rs1;
			riscv_opcodes_pkg_encode_SB[14-:3] = opcode[7:5];
			riscv_opcodes_pkg_encode_SB[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_SB[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_U;
		input reg [14:0] opcode;
		input reg [4:0] rd;
		input reg [31:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_U[31-:20] = imm[31:12];
			riscv_opcodes_pkg_encode_U[11-:5] = rd;
			riscv_opcodes_pkg_encode_U[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_U[1-:2] = size;
		end
	endfunction
	function [31:0] riscv_opcodes_pkg_encode_UJ;
		input reg [14:0] opcode;
		input reg [4:0] rd;
		input reg [20:0] imm;
		input reg [1:0] size;
		begin
			riscv_opcodes_pkg_encode_UJ[31] = imm[20];
			riscv_opcodes_pkg_encode_UJ[19-:8] = imm[19:12];
			riscv_opcodes_pkg_encode_UJ[20] = imm[11];
			riscv_opcodes_pkg_encode_UJ[30-:10] = imm[10:1];
			riscv_opcodes_pkg_encode_UJ[11-:5] = rd;
			riscv_opcodes_pkg_encode_UJ[6-:5] = opcode[4:0];
			riscv_opcodes_pkg_encode_UJ[1-:2] = size;
		end
	endfunction
	function [12:0] riscv_opcodes_pkg_rvc_decode_immCB;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCB = {{4 {instr[12]}}, instr[12], instr[6-:2], instr[2], instr[11-:2], instr[4-:2], 1'b0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCI;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCI = {{6 {instr[12]}}, instr[12], instr[6-:5]};
	endfunction
	function [31:0] riscv_opcodes_pkg_rvc_decode_immCI12;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCI12 = {{14 {instr[12]}}, instr[12], instr[6-:5], 12'h000};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCI4;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCI4 = {{2 {instr[12]}}, instr[12], instr[4:3], instr[5], instr[2], instr[6], 4'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCIB;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCIB = {{6 {instr[12]}}, instr[12], instr[6-:5]};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCIDSP;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCIDSP = {3'h0, instr[4:2], instr[12], instr[6:5], 3'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCIW;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCIW = {2'h0, instr[10-:4], instr[12-:2], instr[5], instr[6], 2'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCIWSP;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCIWSP = {4'h0, instr[3:2], instr[12], instr[6:4], 2'h0};
	endfunction
	function [20:0] riscv_opcodes_pkg_rvc_decode_immCJ;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCJ = {{9 {instr[12]}}, instr[12], instr[8], instr[10-:2], instr[6], instr[7], instr[2], instr[11], instr[5-:3], 1'b0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCLD;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCLD = {4'h0, instr[6-:2], instr[12-:3], 3'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCLW;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCLW = {5'h00, instr[5], instr[12-:3], instr[6], 2'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCSD;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCSD = riscv_opcodes_pkg_rvc_decode_immCLD(instr);
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCSSDSP;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCSSDSP = {3'h0, instr[9:7], instr[12:10], 3'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCSSWSP;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCSSWSP = {4'h0, instr[8:7], instr[12:9], 2'h0};
	endfunction
	function [11:0] riscv_opcodes_pkg_rvc_decode_immCSW;
		input reg [15:0] instr;
		riscv_opcodes_pkg_rvc_decode_immCSW = riscv_opcodes_pkg_rvc_decode_immCLW(instr);
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	function [4:0] riscv_opcodes_pkg_rvc_rsdp2rsd;
		input reg [2:0] r;
		riscv_opcodes_pkg_rvc_rsdp2rsd = sv2v_cast_5({2'b01, r});
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		if (has_rvc && is_16bit_instruction)
			casex ({xlen128, xlen64, xlen32, riscv_opcodes_pkg_decode_rvc_opcA(rvc_parcel1)})
				{3'bzzz, riscv_opcodes_pkg_C_LWSP}: rv_instr = (rvc_parcel1[11-:5] == 0 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_LW, rvc_parcel1[11-:5], 5'h02, riscv_opcodes_pkg_rvc_decode_immCIWSP(rvc_parcel1), 2'b00));
				{3'bzz0, riscv_opcodes_pkg_C_LDSP}: rv_instr = (rvc_parcel1[11-:5] == 0 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_LD, rvc_parcel1[11-:5], 5'h02, riscv_opcodes_pkg_rvc_decode_immCIDSP(rvc_parcel1), 2'b00));
				{3'bzzz, riscv_opcodes_pkg_C_SWSP}: rv_instr = riscv_opcodes_pkg_encode_S(riscv_opcodes_pkg_SW, 5'h02, rvc_parcel1[6-:5], riscv_opcodes_pkg_rvc_decode_immCSSWSP(rvc_parcel1), 2'b00);
				{3'bzz0, riscv_opcodes_pkg_C_SDSP}: rv_instr = riscv_opcodes_pkg_encode_S(riscv_opcodes_pkg_SD, 5'h02, rvc_parcel1[6-:5], riscv_opcodes_pkg_rvc_decode_immCSSDSP(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_LW}: rv_instr = riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_LW, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[4-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_decode_immCLW(rvc_parcel1), 2'b00);
				{3'bzz0, riscv_opcodes_pkg_C_LD}: rv_instr = riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_LD, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[4-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_decode_immCLD(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_SW}: rv_instr = riscv_opcodes_pkg_encode_S(riscv_opcodes_pkg_SW, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[4-:3]), riscv_opcodes_pkg_rvc_decode_immCSW(rvc_parcel1), 2'b00);
				{3'bzz0, riscv_opcodes_pkg_C_SD}: rv_instr = riscv_opcodes_pkg_encode_S(riscv_opcodes_pkg_SD, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[4-:3]), riscv_opcodes_pkg_rvc_decode_immCSD(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_J}: rv_instr = riscv_opcodes_pkg_encode_UJ(riscv_opcodes_pkg_JAL, 5'h00, riscv_opcodes_pkg_rvc_decode_immCJ(rvc_parcel1), 2'b00);
				{3'bzz1, riscv_opcodes_pkg_C_JAL}: rv_instr = riscv_opcodes_pkg_encode_UJ(riscv_opcodes_pkg_JAL, 5'h01, riscv_opcodes_pkg_rvc_decode_immCJ(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_JR}: rv_instr = (rvc_parcel1[6-:5] != 0 ? riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_ADD, rvc_parcel1[11-:5], 5'h00, rvc_parcel1[6-:5], 2'b00) : (rvc_parcel1[11-:5] == 0 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_JALR, 5'd0, rvc_parcel1[11-:5], 12'd0, 2'b00)));
				{3'bzzz, riscv_opcodes_pkg_C_JALR}: rv_instr = (rvc_parcel1[6-:5] != 0 ? riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_ADD, rvc_parcel1[11-:5], rvc_parcel1[11-:5], rvc_parcel1[6-:5], 2'b00) : (rvc_parcel1[11-:5] != 0 ? riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_JALR, 5'h01, rvc_parcel1[11-:5], 12'd0, 2'b00) : riscv_opcodes_pkg_EBREAKC));
				{3'bzzz, riscv_opcodes_pkg_C_BEQZ}: rv_instr = riscv_opcodes_pkg_encode_SB(riscv_opcodes_pkg_BEQ, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), 5'h00, riscv_opcodes_pkg_rvc_decode_immCB(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_BNEZ}: rv_instr = riscv_opcodes_pkg_encode_SB(riscv_opcodes_pkg_BNE, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), 5'h00, riscv_opcodes_pkg_rvc_decode_immCB(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_LI}: rv_instr = riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ADDI, rvc_parcel1[11-:5], 5'h00, riscv_opcodes_pkg_rvc_decode_immCI(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_ADDI16SP}: rv_instr = ({rvc_parcel1[12], rvc_parcel1[6-:5]} == 0 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : (rvc_parcel1[11-:5] == 2 ? riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ADDI, 5'h02, 5'h02, riscv_opcodes_pkg_rvc_decode_immCI4(rvc_parcel1), 2'b00) : riscv_opcodes_pkg_encode_U(riscv_opcodes_pkg_LUI, rvc_parcel1[11-:5], riscv_opcodes_pkg_rvc_decode_immCI12(rvc_parcel1), 2'b00)));
				{3'bzzz, riscv_opcodes_pkg_C_ADDI}: rv_instr = (rvc_parcel1[11-:5] == 0 ? riscv_opcodes_pkg_NOPC : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ADDI, rvc_parcel1[11-:5], rvc_parcel1[11-:5], riscv_opcodes_pkg_rvc_decode_immCI(rvc_parcel1), 2'b00));
				{3'bzz0, riscv_opcodes_pkg_C_ADDIW}: rv_instr = (rvc_parcel1[11-:5] == 0 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ADDIW, rvc_parcel1[11-:5], rvc_parcel1[11-:5], riscv_opcodes_pkg_rvc_decode_immCI(rvc_parcel1), 2'b00));
				{3'bzzz, riscv_opcodes_pkg_C_ADDI4SPN}: rv_instr = (rvc_parcel1 == 16'h0000 ? {{MXLEN - 16 {1'b0}}, rvc_parcel1} : riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ADDI, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[4-:3]), 5'h02, riscv_opcodes_pkg_rvc_decode_immCIW(rvc_parcel1), 2'b00));
				{3'bzzz, riscv_opcodes_pkg_C_SLLI}: rv_instr = riscv_opcodes_pkg_encode_Ishift(riscv_opcodes_pkg_SLLI, rvc_parcel1[11-:5], rvc_parcel1[11-:5], riscv_opcodes_pkg_rvc_decode_immCI(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_SRLI}: rv_instr = riscv_opcodes_pkg_encode_Ishift(riscv_opcodes_pkg_SRLI, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_decode_immCIB(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_SRAI}: rv_instr = riscv_opcodes_pkg_encode_Ishift(riscv_opcodes_pkg_SRAI, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_decode_immCIB(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_ANDI}: rv_instr = riscv_opcodes_pkg_encode_I(riscv_opcodes_pkg_ANDI, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[9-:3]), riscv_opcodes_pkg_rvc_decode_immCIB(rvc_parcel1), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_AND}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_AND, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_OR}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_OR, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_XOR}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_XOR, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				{3'bzzz, riscv_opcodes_pkg_C_SUB}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_SUB, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				{3'bzz0, riscv_opcodes_pkg_C_ADDW}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_ADDW, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				{3'bzz0, riscv_opcodes_pkg_C_SUBW}: rv_instr = riscv_opcodes_pkg_encode_R(riscv_opcodes_pkg_SUBW, riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[11-:5]), riscv_opcodes_pkg_rvc_rsdp2rsd(rvc_parcel1[6-:5]), 2'b00);
				default: rv_instr = {{MXLEN - 16 {1'b0}}, rvc_parcel1};
			endcase
		else
			case (parcel12)
				riscv_opcodes_pkg_WFI: rv_instr = riscv_opcodes_pkg_NOP;
				default: rv_instr = {parcel12[31:2], 2'b01};
			endcase
	end
	assign if_nxt_insn_o[31-:32] = rv_instr;
	assign if_nxt_insn_o[32] = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		if (st_flush_i)
			if_predict_pc_o = st_nxt_pc_i & ADR_MASK;
		else if (du_we_pc_strb)
			if_predict_pc_o = du_dato_i & ADR_MASK;
		else if (bu_flush_i)
			if_predict_pc_o = bu_nxt_pc_i & ADR_MASK;
		else if (pd_latch_nxt_pc_i)
			if_predict_pc_o = pd_nxt_pc_i & ADR_MASK;
		else if ((!pd_stall_i && !if_nxt_insn_o[33]) && !du_stall_i) begin
			if (is_16bit_instruction)
				if_predict_pc_o = (if_nxt_pc_o + 2) & ADR_MASK;
			else
				if_predict_pc_o = (if_nxt_pc_o + 4) & ADR_MASK;
		end
		else
			if_predict_pc_o = if_nxt_pc_o & ADR_MASK;
	end
	assign if_predict_history_o = bu_bp_history_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_nxt_pc_o <= PC_INIT;
		else
			if_nxt_pc_o <= if_predict_pc_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_pc_o <= PC_INIT;
		else if (du_we_pc_strb)
			if_pc_o <= du_dato_i;
		else if (!pd_stall_i && !du_stall_i)
			if_pc_o <= if_nxt_pc_o;
	wire [1:1] sv2v_tmp_3ACA2;
	assign sv2v_tmp_3ACA2 = 1'b0;
	always @(*) if_insn_o[32] = sv2v_tmp_3ACA2;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_insn_o[31-:32] <= riscv_opcodes_pkg_NOP;
		else if (!pd_stall_i)
			if_insn_o[31-:32] <= if_nxt_insn_o[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_insn_o[33] <= 1'b1;
		else if (pd_flush_i)
			if_insn_o[33] <= 1'b1;
		else if (du_stall_i)
			if_insn_o[33] <= 1'b1;
		else if ((((pd_exceptions_i[27] || id_exceptions_i[27]) || ex_exceptions_i[27]) || mem_exceptions_i[27]) || wb_exceptions_i[27])
			if_insn_o[33] <= 1'b1;
		else if (!pd_stall_i) begin
			if (pd_latch_nxt_pc_i)
				if_insn_o[33] <= 1'b1;
			else
				if_insn_o[33] <= if_nxt_insn_o[33];
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_insn_o[34] <= 1'b0;
		else
			if_insn_o[34] <= du_stall_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_exceptions_o <= {28 {1'b0}};
		else if (pd_flush_i)
			if_exceptions_o <= {28 {1'b0}};
		else if (!pd_stall_i) begin
			if_exceptions_o <= parcel_exceptions;
			if_exceptions_o[2] <= rvc_illegal & ~parcel_queue_empty;
		end
	always @(posedge clk_i)
		if (!pd_stall_i)
			if_bp_history_o <= bu_bp_history_i;
	initial _sv2v_0 = 0;
endmodule
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
module riscv_lsu (
	rst_ni,
	clk_i,
	ex_stall_i,
	lsu_stall_o,
	id_insn_i,
	lsu_bubble_o,
	lsu_r_o,
	id_exceptions_i,
	ex_exceptions_i,
	mem_exceptions_i,
	wb_exceptions_i,
	lsu_exceptions_o,
	opA_i,
	opB_i,
	st_xlen_i,
	st_be_i,
	dmem_req_o,
	dmem_lock_o,
	dmem_we_o,
	dmem_size_o,
	dmem_adr_o,
	dmem_d_o,
	dmem_ack_i,
	dmem_q_i,
	dmem_misaligned_i,
	dmem_page_fault_i
);
	reg _sv2v_0;
	parameter signed [31:0] MXLEN = 32;
	parameter [0:0] HAS_A = 0;
	input rst_ni;
	input clk_i;
	input ex_stall_i;
	output reg lsu_stall_o;
	input wire [34:0] id_insn_i;
	output reg lsu_bubble_o;
	output wire [MXLEN - 1:0] lsu_r_o;
	input wire [27:0] id_exceptions_i;
	input wire [27:0] ex_exceptions_i;
	input wire [27:0] mem_exceptions_i;
	input wire [27:0] wb_exceptions_i;
	output reg [27:0] lsu_exceptions_o;
	input [MXLEN - 1:0] opA_i;
	input [MXLEN - 1:0] opB_i;
	input [1:0] st_xlen_i;
	input st_be_i;
	output reg dmem_req_o;
	output reg dmem_lock_o;
	output reg dmem_we_o;
	output reg [2:0] dmem_size_o;
	output reg [MXLEN - 1:0] dmem_adr_o;
	output reg [MXLEN - 1:0] dmem_d_o;
	input dmem_ack_i;
	input [MXLEN - 1:0] dmem_q_i;
	input dmem_misaligned_i;
	input dmem_page_fault_i;
	wire [14:0] opcR;
	wire xlen32;
	wire [11:0] immS;
	wire [MXLEN - 1:0] ext_immS;
	reg [1:0] state;
	reg [MXLEN - 1:0] adr;
	reg [MXLEN - 1:0] d;
	reg [2:0] size;
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(id_insn_i[31-:32]);
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	assign lsu_r_o = 'h0;
	function [11:0] riscv_opcodes_pkg_decode_immS;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_immS = {instr[31-:7], instr[11-:5]};
	endfunction
	assign immS = riscv_opcodes_pkg_decode_immS(id_insn_i[31-:32]);
	assign ext_immS = {{MXLEN - 12 {immS[11]}}, immS};
	localparam [6:2] riscv_opcodes_pkg_OPC_LOAD = 5'b00000;
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE = 5'b01000;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state <= 2'b00;
			lsu_stall_o <= 1'b0;
			lsu_bubble_o <= 1'b1;
			dmem_req_o <= 1'b0;
			dmem_lock_o <= 1'b0;
		end
		else begin
			dmem_req_o <= 1'b0;
			(* full_case, parallel_case *)
			case (state)
				2'b00:
					if (!ex_stall_i) begin
						if (!id_insn_i[33] && ~(((id_exceptions_i[27] || ex_exceptions_i[27]) || mem_exceptions_i[27]) || wb_exceptions_i[27]))
							(* full_case, parallel_case *)
							case (opcR[4-:5])
								riscv_opcodes_pkg_OPC_LOAD: begin
									dmem_req_o <= 1'b1;
									dmem_lock_o <= 1'b0;
									lsu_stall_o <= 1'b0;
									lsu_bubble_o <= 1'b0;
									state <= 2'b00;
								end
								riscv_opcodes_pkg_OPC_STORE: begin
									dmem_req_o <= 1'b1;
									dmem_lock_o <= 1'b0;
									lsu_stall_o <= 1'b0;
									lsu_bubble_o <= 1'b0;
									state <= 2'b00;
								end
								default: begin
									dmem_req_o <= 1'b0;
									dmem_lock_o <= 1'b0;
									lsu_stall_o <= 1'b0;
									lsu_bubble_o <= 1'b1;
									state <= 2'b00;
								end
							endcase
						else begin
							dmem_req_o <= 1'b0;
							dmem_lock_o <= 1'b0;
							lsu_stall_o <= 1'b0;
							lsu_bubble_o <= 1'b1;
							state <= 2'b00;
						end
					end
				default: begin
					dmem_req_o <= 1'b0;
					dmem_lock_o <= 1'b0;
					lsu_stall_o <= 1'b0;
					lsu_bubble_o <= 1'b1;
					state <= 2'b00;
				end
			endcase
		end
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (state)
			2'b00:
				if (!id_insn_i[33])
					(* full_case, parallel_case *)
					case (opcR[4-:5])
						riscv_opcodes_pkg_OPC_LOAD: begin
							dmem_we_o <= 1'b0;
							dmem_size_o <= size;
							dmem_adr_o <= adr;
							dmem_d_o <= 'hx;
						end
						riscv_opcodes_pkg_OPC_STORE: begin
							dmem_we_o <= 1'b1;
							dmem_size_o <= size;
							dmem_adr_o <= adr;
							dmem_d_o <= d;
						end
						default:
							;
					endcase
			default: begin
				dmem_we_o <= 1'bx;
				dmem_size_o <= 3'bxxx;
				dmem_adr_o <= 'hx;
				dmem_d_o <= 'hx;
			end
		endcase
	localparam [14:0] riscv_opcodes_pkg_LB = 15'bzzzzzzz00000000;
	localparam [14:0] riscv_opcodes_pkg_LBU = 15'bzzzzzzz10000000;
	localparam [14:0] riscv_opcodes_pkg_LD = 15'bzzzzzzz01100000;
	localparam [14:0] riscv_opcodes_pkg_LH = 15'bzzzzzzz00100000;
	localparam [14:0] riscv_opcodes_pkg_LHU = 15'bzzzzzzz10100000;
	localparam [14:0] riscv_opcodes_pkg_LW = 15'bzzzzzzz01000000;
	localparam [14:0] riscv_opcodes_pkg_LWU = 15'bzzzzzzz11000000;
	localparam [14:0] riscv_opcodes_pkg_SB = 15'bzzzzzzz00001000;
	localparam [14:0] riscv_opcodes_pkg_SD = 15'bzzzzzzz01101000;
	localparam [14:0] riscv_opcodes_pkg_SH = 15'bzzzzzzz00101000;
	localparam [14:0] riscv_opcodes_pkg_SW = 15'bzzzzzzz01001000;
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({xlen32, opcR})
			{1'bz, riscv_opcodes_pkg_LB}: adr = opA_i + opB_i;
			{1'bz, riscv_opcodes_pkg_LH}: adr = opA_i + opB_i;
			{1'bz, riscv_opcodes_pkg_LW}: adr = opA_i + opB_i;
			{1'b0, riscv_opcodes_pkg_LD}: adr = opA_i + opB_i;
			{1'bz, riscv_opcodes_pkg_LBU}: adr = opA_i + opB_i;
			{1'bz, riscv_opcodes_pkg_LHU}: adr = opA_i + opB_i;
			{1'b0, riscv_opcodes_pkg_LWU}: adr = opA_i + opB_i;
			{1'bz, riscv_opcodes_pkg_SB}: adr = opA_i + ext_immS;
			{1'bz, riscv_opcodes_pkg_SH}: adr = opA_i + ext_immS;
			{1'bz, riscv_opcodes_pkg_SW}: adr = opA_i + ext_immS;
			{1'b0, riscv_opcodes_pkg_SD}: adr = opA_i + ext_immS;
			default: adr = opA_i + opB_i;
		endcase
	end
	generate
		if (MXLEN == 64) begin : genblk1
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_LB: size = 3'b000;
					riscv_opcodes_pkg_LH: size = 3'b001;
					riscv_opcodes_pkg_LW: size = 3'b010;
					riscv_opcodes_pkg_LD: size = 3'b011;
					riscv_opcodes_pkg_LBU: size = 3'b000;
					riscv_opcodes_pkg_LHU: size = 3'b001;
					riscv_opcodes_pkg_LWU: size = 3'b010;
					riscv_opcodes_pkg_SB: size = 3'b000;
					riscv_opcodes_pkg_SH: size = 3'b001;
					riscv_opcodes_pkg_SW: size = 3'b010;
					riscv_opcodes_pkg_SD: size = 3'b011;
					default: size = 3'bxxx;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_SB: d = opB_i[7:0] << (8 * adr[2:0]);
					riscv_opcodes_pkg_SH: d = (!st_be_i ? opB_i[15:0] : {opB_i[7:0], opB_i[15:8]}) << (8 * adr[2:0]);
					riscv_opcodes_pkg_SW: d = (!st_be_i ? opB_i[31:0] : {opB_i[7:0], opB_i[15:8], opB_i[23:16], opB_i[31:24]}) << (8 * adr[2:0]);
					riscv_opcodes_pkg_SD: d = (!st_be_i ? opB_i : {opB_i[7:0], opB_i[15:8], opB_i[23:16], opB_i[31:24], opB_i[39:32], opB_i[47:40], opB_i[55:48], opB_i[63:56]});
					default: d = 'hx;
				endcase
			end
		end
		else begin : genblk1
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_LB: size = 3'b000;
					riscv_opcodes_pkg_LH: size = 3'b001;
					riscv_opcodes_pkg_LW: size = 3'b010;
					riscv_opcodes_pkg_LBU: size = 3'b000;
					riscv_opcodes_pkg_LHU: size = 3'b001;
					riscv_opcodes_pkg_SB: size = 3'b000;
					riscv_opcodes_pkg_SH: size = 3'b001;
					riscv_opcodes_pkg_SW: size = 3'b010;
					default: size = 3'bxxx;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_SB: d = opB_i[7:0] << (8 * adr[1:0]);
					riscv_opcodes_pkg_SH: d = opB_i[15:0] << (8 * adr[1:0]);
					riscv_opcodes_pkg_SW: d = opB_i;
					default: d = 'hx;
				endcase
			end
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			lsu_exceptions_o <= 'h0;
		else if (!lsu_stall_o)
			lsu_exceptions_o <= id_exceptions_i;
	initial _sv2v_0 = 0;
endmodule
module riscv_membuf (
	rst_ni,
	clk_i,
	flush_i,
	stall_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	prot_i,
	we_i,
	d_i,
	misaligned_i,
	cm_clean_i,
	cm_invalidate_i,
	req_o,
	ack_i,
	adr_o,
	size_o,
	lock_o,
	prot_o,
	we_o,
	q_o,
	misaligned_o,
	cm_clean_o,
	cm_invalidate_o,
	empty_o,
	full_o
);
	parameter DEPTH = 2;
	parameter XLEN = 32;
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire stall_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire [2:0] prot_i;
	input wire we_i;
	input wire [XLEN - 1:0] d_i;
	input wire misaligned_i;
	input wire cm_clean_i;
	input wire cm_invalidate_i;
	output wire req_o;
	input wire ack_i;
	output wire [XLEN - 1:0] adr_o;
	output wire [2:0] size_o;
	output wire lock_o;
	output wire [2:0] prot_o;
	output wire we_o;
	output wire [XLEN - 1:0] q_o;
	output wire misaligned_o;
	output wire cm_clean_o;
	output wire cm_invalidate_o;
	output wire empty_o;
	output wire full_o;
	wire [(((1 + XLEN) + 8) + XLEN) + 2:0] queue_d;
	wire [(((1 + XLEN) + 8) + XLEN) + 2:0] queue_q;
	wire queue_we;
	wire queue_re;
	reg [$clog2(DEPTH):0] access_pending;
	assign queue_d[1 + (XLEN + (8 + (XLEN + 2)))] = req_i;
	assign queue_d[XLEN + (8 + (XLEN + 2))-:((XLEN + (8 + (XLEN + 2))) >= (8 + (XLEN + 3)) ? ((XLEN + (8 + (XLEN + 2))) - (8 + (XLEN + 3))) + 1 : ((8 + (XLEN + 3)) - (XLEN + (8 + (XLEN + 2)))) + 1)] = adr_i;
	assign queue_d[8 + (XLEN + 2)-:((8 + (XLEN + 2)) >= (5 + (XLEN + 3)) ? ((8 + (XLEN + 2)) - (5 + (XLEN + 3))) + 1 : ((5 + (XLEN + 3)) - (8 + (XLEN + 2))) + 1)] = size_i;
	assign queue_d[5 + (XLEN + 2)] = lock_i;
	assign queue_d[4 + (XLEN + 2)-:((4 + (XLEN + 2)) >= (1 + (XLEN + 3)) ? ((4 + (XLEN + 2)) - (1 + (XLEN + 3))) + 1 : ((1 + (XLEN + 3)) - (4 + (XLEN + 2))) + 1)] = prot_i;
	assign queue_d[1 + (XLEN + 2)] = we_i;
	assign queue_d[XLEN + 2-:((XLEN + 2) >= 3 ? XLEN + 0 : 4 - (XLEN + 2))] = d_i;
	assign queue_d[2] = misaligned_i;
	assign queue_d[1] = cm_clean_i;
	assign queue_d[0] = cm_invalidate_i;
	rl_queue #(
		.DEPTH(DEPTH),
		.DBITS((((((1 + XLEN) + 8) + XLEN) + 2) >= 0 ? (((1 + XLEN) + 8) + XLEN) + 3 : 1 - ((((1 + XLEN) + 8) + XLEN) + 2)))
	) rl_queue_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.clr_i(flush_i),
		.ena_i(1'b1),
		.we_i(queue_we),
		.d_i(queue_d),
		.re_i(queue_re),
		.q_o(queue_q),
		.empty_o(empty_o),
		.full_o(full_o),
		.almost_empty_o(),
		.almost_full_o()
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			access_pending <= 'h0;
		else if (flush_i)
			access_pending <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({req_i, ~stall_i})
				2'b01: access_pending <= (|access_pending ? access_pending - 1 : 'h0);
				2'b10: access_pending <= access_pending + 1;
				default:
					;
			endcase
	assign queue_we = ((req_i & (stall_i | (|access_pending))) | cm_clean_i) | cm_invalidate_i;
	assign queue_re = ~empty_o & ~stall_i;
	assign req_o = (empty_o ? req_i : queue_q[1 + (XLEN + (8 + (XLEN + 2)))]);
	assign adr_o = (empty_o ? adr_i : queue_q[XLEN + (8 + (XLEN + 2))-:((XLEN + (8 + (XLEN + 2))) >= (8 + (XLEN + 3)) ? ((XLEN + (8 + (XLEN + 2))) - (8 + (XLEN + 3))) + 1 : ((8 + (XLEN + 3)) - (XLEN + (8 + (XLEN + 2)))) + 1)]);
	assign size_o = (empty_o ? size_i : queue_q[8 + (XLEN + 2)-:((8 + (XLEN + 2)) >= (5 + (XLEN + 3)) ? ((8 + (XLEN + 2)) - (5 + (XLEN + 3))) + 1 : ((5 + (XLEN + 3)) - (8 + (XLEN + 2))) + 1)]);
	assign lock_o = (empty_o ? lock_i : queue_q[5 + (XLEN + 2)]);
	assign prot_o = (empty_o ? prot_i : queue_q[4 + (XLEN + 2)-:((4 + (XLEN + 2)) >= (1 + (XLEN + 3)) ? ((4 + (XLEN + 2)) - (1 + (XLEN + 3))) + 1 : ((1 + (XLEN + 3)) - (4 + (XLEN + 2))) + 1)]);
	assign we_o = (empty_o ? we_i : queue_q[1 + (XLEN + 2)]);
	assign q_o = (empty_o ? d_i : queue_q[XLEN + 2-:((XLEN + 2) >= 3 ? XLEN + 0 : 4 - (XLEN + 2))]);
	assign misaligned_o = (empty_o ? misaligned_i : queue_q[2]);
	assign cm_clean_o = (empty_o ? cm_clean_i : queue_q[1]);
	assign cm_invalidate_o = (empty_o ? cm_invalidate_i : queue_q[0]);
endmodule
module riscv_memmisaligned (
	instruction_i,
	adr_i,
	size_i,
	misaligned_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter HAS_RVC = 0;
	input wire instruction_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	output reg misaligned_o;
	always @(*) begin
		if (_sv2v_0)
			;
		if (instruction_i)
			misaligned_o = (HAS_RVC != 0 ? adr_i[0] : |adr_i[1:0]);
		else
			(* full_case, parallel_case *)
			case (size_i)
				3'b000: misaligned_o = 1'b0;
				3'b001: misaligned_o = adr_i[0];
				3'b010: misaligned_o = |adr_i[1:0];
				3'b011: misaligned_o = |adr_i[2:0];
				default: misaligned_o = 1'b1;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
module riscv_mem (
	rst_ni,
	clk_i,
	mem_stall_i,
	mem_stall_o,
	mem_pc_i,
	mem_pc_o,
	mem_insn_i,
	mem_insn_o,
	mem_exceptions_dn_i,
	mem_exceptions_dn_o,
	mem_exceptions_up_i,
	mem_exceptions_up_o,
	mem_r_i,
	mem_memadr_i,
	mem_r_o,
	mem_memadr_o
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	input rst_ni;
	input clk_i;
	input mem_stall_i;
	output wire mem_stall_o;
	input [MXLEN - 1:0] mem_pc_i;
	output reg [MXLEN - 1:0] mem_pc_o;
	input wire [34:0] mem_insn_i;
	output reg [34:0] mem_insn_o;
	input wire [27:0] mem_exceptions_dn_i;
	output reg [27:0] mem_exceptions_dn_o;
	input wire [27:0] mem_exceptions_up_i;
	output wire [27:0] mem_exceptions_up_o;
	input [MXLEN - 1:0] mem_r_i;
	input [MXLEN - 1:0] mem_memadr_i;
	output reg [MXLEN - 1:0] mem_r_o;
	output reg [MXLEN - 1:0] mem_memadr_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_pc_o <= PC_INIT;
		else if (!mem_stall_i)
			mem_pc_o <= mem_pc_i;
	assign mem_stall_o = mem_stall_i;
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_insn_o[31-:32] <= mem_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[34] <= 1'b0;
		else if (!mem_stall_i)
			mem_insn_o[34] <= mem_insn_i[34];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[33] <= 1'b1;
		else if (mem_exceptions_up_i[27])
			mem_insn_o[33] <= 1'b1;
		else if (!mem_stall_i)
			mem_insn_o[33] <= mem_insn_i[33];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_insn_o[32] <= 'h0;
		else if (mem_exceptions_up_i[27])
			mem_insn_o[32] <= 'h0;
		else if (!mem_stall_i)
			mem_insn_o[32] <= mem_insn_i[32];
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_r_o <= mem_r_i;
	always @(posedge clk_i)
		if (!mem_stall_i)
			mem_memadr_o <= mem_memadr_i;
	assign mem_exceptions_up_o = mem_exceptions_dn_o | mem_exceptions_up_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mem_exceptions_dn_o <= 'h0;
		else if (mem_exceptions_up_o[27])
			mem_exceptions_dn_o <= 'h0;
		else if (!mem_stall_i)
			mem_exceptions_dn_o <= mem_exceptions_dn_i;
endmodule
module riscv_mul (
	rst_ni,
	clk_i,
	mem_stall_i,
	ex_stall_i,
	mul_stall_o,
	id_insn_i,
	opA_i,
	opB_i,
	st_xlen_i,
	mul_bubble_o,
	mul_r_o
);
	reg _sv2v_0;
	parameter signed [31:0] MXLEN = 32;
	parameter signed [31:0] MULT_LATENCY = 0;
	input rst_ni;
	input clk_i;
	input mem_stall_i;
	input ex_stall_i;
	output reg mul_stall_o;
	input wire [34:0] id_insn_i;
	input [MXLEN - 1:0] opA_i;
	input [MXLEN - 1:0] opB_i;
	input [1:0] st_xlen_i;
	output reg mul_bubble_o;
	output reg [MXLEN - 1:0] mul_r_o;
	localparam DXLEN = 2 * MXLEN;
	localparam MAX_LATENCY = 3;
	localparam LATENCY = (MULT_LATENCY > MAX_LATENCY ? MAX_LATENCY : MULT_LATENCY);
	initial begin : a1
		
	end
	function [MXLEN - 1:0] sext32;
		input [31:0] operand;
		reg sign;
		begin
			sign = operand[31];
			sext32 = {{MXLEN - 32 {sign}}, operand};
		end
	endfunction
	function [MXLEN - 1:0] twos;
		input [MXLEN - 1:0] a;
		twos = ~a + 'h1;
	endfunction
	function [DXLEN - 1:0] twos_dxlen;
		input [DXLEN - 1:0] a;
		twos_dxlen = ~a + 'h1;
	endfunction
	function [MXLEN - 1:0] abs;
		input [MXLEN - 1:0] a;
		abs = (a[MXLEN - 1] ? twos(a) : a);
	endfunction
	wire xlen32;
	reg [31:0] mul_instr;
	wire [14:0] opcR;
	wire [14:0] opcR_mul;
	wire [31:0] opA32;
	wire [31:0] opB32;
	reg mult_neg;
	reg mult_neg_reg;
	reg [MXLEN - 1:0] mult_opA;
	reg [MXLEN - 1:0] mult_opA_reg;
	reg [MXLEN - 1:0] mult_opB;
	reg [MXLEN - 1:0] mult_opB_reg;
	wire [DXLEN - 1:0] mult_r;
	reg [DXLEN - 1:0] mult_r_reg;
	wire [DXLEN - 1:0] mult_r_signed;
	reg [DXLEN - 1:0] mult_r_signed_reg;
	reg is_mul;
	reg [1:0] cnt;
	reg state;
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(id_insn_i[31-:32]);
	assign opcR_mul = riscv_opcodes_pkg_decode_opcR(mul_instr);
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	assign xlen32 = st_xlen_i == riscv_state_pkg_RV32I;
	assign opA32 = opA_i[31:0];
	assign opB32 = opB_i[31:0];
	localparam [14:0] riscv_opcodes_pkg_MULHU = 15'b000000101101100;
	localparam [14:0] riscv_opcodes_pkg_MULW = 15'b000000100001110;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex (opcR)
			riscv_opcodes_pkg_MULW: mult_opA = abs(sext32(opA32));
			riscv_opcodes_pkg_MULHU: mult_opA = opA_i;
			default: mult_opA = abs(opA_i);
		endcase
	end
	localparam [14:0] riscv_opcodes_pkg_MULHSU = 15'b000000101001100;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex (opcR)
			riscv_opcodes_pkg_MULW: mult_opB = abs(sext32(opB32));
			riscv_opcodes_pkg_MULHSU: mult_opB = opB_i;
			riscv_opcodes_pkg_MULHU: mult_opB = opB_i;
			default: mult_opB = abs(opB_i);
		endcase
	end
	localparam [14:0] riscv_opcodes_pkg_MUL = 15'b000000100001100;
	localparam [14:0] riscv_opcodes_pkg_MULH = 15'b000000100101100;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex (opcR)
			riscv_opcodes_pkg_MUL: mult_neg = opA_i[MXLEN - 1] ^ opB_i[MXLEN - 1];
			riscv_opcodes_pkg_MULH: mult_neg = opA_i[MXLEN - 1] ^ opB_i[MXLEN - 1];
			riscv_opcodes_pkg_MULHSU: mult_neg = opA_i[MXLEN - 1];
			riscv_opcodes_pkg_MULHU: mult_neg = 1'b0;
			riscv_opcodes_pkg_MULW: mult_neg = opA32[31] ^ opB32[31];
			default: mult_neg = 'hx;
		endcase
	end
	assign mult_r = $unsigned(mult_opA_reg) * $unsigned(mult_opB_reg);
	assign mult_r_signed = (mult_neg_reg ? twos_dxlen(mult_r_reg) : mult_r_reg);
	generate
		if (LATENCY == 0) begin : genblk1
			wire [32:1] sv2v_tmp_E43F9;
			assign sv2v_tmp_E43F9 = id_insn_i[31-:32];
			always @(*) mul_instr = sv2v_tmp_E43F9;
			wire [MXLEN:1] sv2v_tmp_F8F8C;
			assign sv2v_tmp_F8F8C = mult_opA;
			always @(*) mult_opA_reg = sv2v_tmp_F8F8C;
			wire [MXLEN:1] sv2v_tmp_5DB8C;
			assign sv2v_tmp_5DB8C = mult_opB;
			always @(*) mult_opB_reg = sv2v_tmp_5DB8C;
			wire [1:1] sv2v_tmp_A9DCF;
			assign sv2v_tmp_A9DCF = mult_neg;
			always @(*) mult_neg_reg = sv2v_tmp_A9DCF;
			wire [DXLEN:1] sv2v_tmp_570C7;
			assign sv2v_tmp_570C7 = mult_r;
			always @(*) mult_r_reg = sv2v_tmp_570C7;
			wire [DXLEN:1] sv2v_tmp_4C873;
			assign sv2v_tmp_4C873 = mult_r_signed;
			always @(*) mult_r_signed_reg = sv2v_tmp_4C873;
		end
		else begin : genblk1
			always @(posedge clk_i)
				if (!ex_stall_i)
					mul_instr <= id_insn_i[31-:32];
			always @(posedge clk_i)
				if (!ex_stall_i) begin
					mult_opA_reg <= mult_opA;
					mult_opB_reg <= mult_opB;
					mult_neg_reg <= mult_neg;
				end
			if (LATENCY == 1) begin : genblk1
				wire [DXLEN:1] sv2v_tmp_570C7;
				assign sv2v_tmp_570C7 = mult_r;
				always @(*) mult_r_reg = sv2v_tmp_570C7;
				wire [DXLEN:1] sv2v_tmp_4C873;
				assign sv2v_tmp_4C873 = mult_r_signed;
				always @(*) mult_r_signed_reg = sv2v_tmp_4C873;
			end
			else if (LATENCY == 2) begin : genblk1
				always @(posedge clk_i) mult_r_reg <= mult_r;
				wire [DXLEN:1] sv2v_tmp_4C873;
				assign sv2v_tmp_4C873 = mult_r_signed;
				always @(*) mult_r_signed_reg = sv2v_tmp_4C873;
			end
			else begin : genblk1
				always @(posedge clk_i) mult_r_reg <= mult_r;
				always @(posedge clk_i) mult_r_signed_reg <= mult_r_signed;
			end
		end
	endgenerate
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		casex (opcR_mul)
			riscv_opcodes_pkg_MUL: mul_r_o <= mult_r_signed_reg[MXLEN - 1:0];
			riscv_opcodes_pkg_MULW: mul_r_o <= sext32(mult_r_signed_reg[31:0]);
			default: mul_r_o <= mult_r_signed_reg[DXLEN - 1:MXLEN];
		endcase
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		casex (opcR)
			riscv_opcodes_pkg_MUL: is_mul = 1'b1;
			riscv_opcodes_pkg_MULH: is_mul = 1'b1;
			riscv_opcodes_pkg_MULW: is_mul = ~xlen32;
			riscv_opcodes_pkg_MULHSU: is_mul = 1'b1;
			riscv_opcodes_pkg_MULHU: is_mul = 1'b1;
			default: is_mul = 1'b0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state <= 1'b0;
			cnt <= LATENCY;
			mul_bubble_o <= 1'b1;
			mul_stall_o <= 1'b0;
		end
		else begin
			mul_bubble_o <= 1'b1;
			(* full_case, parallel_case *)
			case (state)
				1'b0:
					if (!ex_stall_i) begin
						if (!id_insn_i[33] && is_mul) begin
							if (LATENCY == 0) begin
								mul_bubble_o <= 1'b0;
								mul_stall_o <= 1'b0;
							end
							else begin
								state <= 1'b1;
								cnt <= LATENCY - 1;
								mul_bubble_o <= 1'b1;
								mul_stall_o <= 1'b1;
							end
						end
					end
				1'b1:
					if (|cnt)
						cnt <= cnt - 1;
					else if (!mem_stall_i) begin
						state <= 1'b0;
						cnt <= LATENCY;
						mul_bubble_o <= 1'b0;
						mul_stall_o <= 1'b0;
					end
			endcase
		end
	initial _sv2v_0 = 0;
endmodule
module riscv_nodcache_core (
	rst_ni,
	clk_i,
	mem_req_i,
	mem_size_i,
	mem_lock_i,
	mem_misaligned_i,
	mem_adr_i,
	mem_we_i,
	mem_d_i,
	mem_q_o,
	mem_ack_o,
	mem_err_o,
	mem_misaligned_o,
	st_prv_i,
	biu_stb_o,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_we_o,
	biu_prot_o,
	biu_d_o,
	biu_q_i,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_ack_i,
	biu_err_i
);
	parameter XLEN = 32;
	parameter ALEN = XLEN;
	parameter DEPTH = 2;
	input rst_ni;
	input clk_i;
	input mem_req_i;
	input wire [2:0] mem_size_i;
	input mem_lock_i;
	input mem_misaligned_i;
	input [XLEN - 1:0] mem_adr_i;
	input mem_we_i;
	input [XLEN - 1:0] mem_d_i;
	output wire [XLEN - 1:0] mem_q_o;
	output wire mem_ack_o;
	output wire mem_err_o;
	output reg mem_misaligned_o;
	input [1:0] st_prv_i;
	output reg biu_stb_o;
	output wire [ALEN - 1:0] biu_adri_o;
	input [ALEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire biu_we_o;
	output wire [2:0] biu_prot_o;
	output wire [XLEN - 1:0] biu_d_o;
	input [XLEN - 1:0] biu_q_i;
	input biu_stb_ack_i;
	input biu_d_ack_i;
	input biu_ack_i;
	input biu_err_i;
	genvar _gv_n_4;
	reg hold_mem_req;
	reg hold_mem_misaligned;
	reg [XLEN - 1:0] hold_mem_adr;
	reg [XLEN - 1:0] hold_mem_d;
	reg [2:0] hold_mem_size;
	wire [2:0] hold_mem_type;
	wire [2:0] hold_mem_prot;
	reg hold_mem_lock;
	reg hold_mem_we;
	wire misaligned;
	reg [DEPTH - 1:0] misaligned_queue;
	wire misaligned_in_pipe;
	reg [$clog2(DEPTH):0] inflight;
	reg [$clog2(DEPTH):0] discard;
	always @(posedge clk_i)
		if (mem_req_i) begin
			hold_mem_misaligned <= mem_misaligned_i;
			hold_mem_adr <= mem_adr_i;
			hold_mem_size <= mem_size_i;
			hold_mem_lock <= mem_lock_i;
			hold_mem_we <= mem_we_i;
			hold_mem_d <= mem_d_i;
		end
	always @(posedge clk_i)
		if (!rst_ni)
			hold_mem_req <= 1'b0;
		else if (misaligned_in_pipe || mem_err_o)
			hold_mem_req <= 1'b0;
		else
			hold_mem_req <= (mem_req_i | hold_mem_req) & ~biu_stb_ack_i;
	assign misaligned = (hold_mem_req ? hold_mem_misaligned : mem_misaligned_i & mem_req_i);
	always @(posedge clk_i) misaligned_queue <= {misaligned_queue[0+:DEPTH - 1], misaligned};
	assign misaligned_in_pipe = misaligned | (|misaligned_queue);
	wire [1:1] sv2v_tmp_DF944;
	assign sv2v_tmp_DF944 = misaligned_queue[DEPTH - 1];
	always @(*) mem_misaligned_o = sv2v_tmp_DF944;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inflight <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({biu_stb_ack_i, biu_ack_i | biu_err_i})
				2'b01: inflight <= inflight - 1;
				2'b10: inflight <= inflight + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			discard <= 'h0;
		else if (misaligned || mem_err_o) begin
			if (|inflight && (biu_ack_i | biu_err_i))
				discard <= inflight - 1;
			else
				discard <= inflight;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	wire [1:1] sv2v_tmp_36EDC;
	assign sv2v_tmp_36EDC = (mem_req_i | hold_mem_req) & ~misaligned_in_pipe;
	always @(*) biu_stb_o = sv2v_tmp_36EDC;
	assign biu_adri_o = (hold_mem_req ? hold_mem_adr : mem_adr_i);
	assign biu_size_o = (hold_mem_req ? hold_mem_size : mem_size_i);
	assign biu_lock_o = (hold_mem_req ? hold_mem_lock : mem_lock_i);
	localparam [2:0] biu_constants_pkg_PROT_DATA = 3'b001;
	localparam [2:0] biu_constants_pkg_PROT_PRIVILEGED = 3'b010;
	localparam [2:0] biu_constants_pkg_PROT_USER = 3'b000;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	assign biu_prot_o = (biu_constants_pkg_PROT_DATA | (st_prv_i == riscv_state_pkg_PRV_U) ? biu_constants_pkg_PROT_USER : biu_constants_pkg_PROT_PRIVILEGED);
	assign biu_we_o = (hold_mem_req ? hold_mem_we : mem_we_i);
	assign biu_d_o = (hold_mem_req ? hold_mem_d : mem_d_i);
	assign biu_type_o = 3'b000;
	assign mem_q_o = biu_q_i;
	assign mem_ack_o = (|discard ? 1'b0 : (|inflight ? biu_ack_i : biu_ack_i & biu_stb_o));
	assign mem_err_o = (|discard ? 1'b0 : (|inflight ? biu_err_i : biu_err_i & biu_stb_o));
endmodule
module riscv_noicache_core (
	rst_ni,
	clk_i,
	if_nxt_pc_i,
	if_req_i,
	if_ack_o,
	if_prot_i,
	if_flush_i,
	if_parcel_pc_o,
	if_parcel_o,
	if_parcel_valid_o,
	if_parcel_misaligned_o,
	if_parcel_error_o,
	cm_dc_clean_rdy_i,
	st_prv_i,
	biu_stb_o,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_we_o,
	biu_prot_o,
	biu_d_o,
	biu_q_i,
	biu_ack_i,
	biu_err_i,
	biu_tagi_o,
	biu_tago_i
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter PARCEL_SIZE = 16;
	parameter HAS_RVC = 0;
	parameter DEPTH = 2;
	parameter BIUTAG_SIZE = $clog2(XLEN / PARCEL_SIZE);
	input rst_ni;
	input clk_i;
	input [XLEN - 1:0] if_nxt_pc_i;
	input if_req_i;
	output wire if_ack_o;
	input wire [2:0] if_prot_i;
	input if_flush_i;
	output wire [XLEN - 1:0] if_parcel_pc_o;
	output wire [XLEN - 1:0] if_parcel_o;
	output wire [(XLEN / PARCEL_SIZE) - 1:0] if_parcel_valid_o;
	output wire if_parcel_misaligned_o;
	output wire if_parcel_error_o;
	input cm_dc_clean_rdy_i;
	input [1:0] st_prv_i;
	output wire biu_stb_o;
	input biu_stb_ack_i;
	input biu_d_ack_i;
	output wire [PLEN - 1:0] biu_adri_o;
	input [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire biu_we_o;
	output wire [2:0] biu_prot_o;
	output wire [XLEN - 1:0] biu_d_o;
	input [XLEN - 1:0] biu_q_i;
	input biu_ack_i;
	input biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input [BIUTAG_SIZE - 1:0] biu_tago_i;
	reg if_flush_dly;
	reg [$clog2(DEPTH):0] inflight;
	reg [$clog2(DEPTH):0] discard;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_flush_dly <= 1'b0;
		else
			if_flush_dly <= if_flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inflight <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({biu_stb_ack_i, biu_ack_i | biu_err_i})
				2'b01: inflight <= inflight - 1;
				2'b10: inflight <= inflight + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			discard <= 'h0;
		else if (if_flush_i) begin
			if (|inflight && (biu_ack_i | biu_err_i))
				discard <= inflight - 1;
			else
				discard <= inflight;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	assign if_ack_o = cm_dc_clean_rdy_i & biu_stb_ack_i;
	assign if_parcel_misaligned_o = (HAS_RVC != 0 ? if_parcel_pc_o[0] : |if_parcel_pc_o[1:0]);
	assign if_parcel_error_o = biu_err_i;
	assign if_parcel_valid_o = (((cm_dc_clean_rdy_i & ~(if_flush_i | if_flush_dly)) & biu_ack_i) & ~|discard ? {XLEN / PARCEL_SIZE {1'b1}} << biu_tago_i : {XLEN / PARCEL_SIZE {1'b0}});
	assign if_parcel_pc_o = {{((PLEN - (BIUTAG_SIZE + 1)) - BIUTAG_SIZE) - 1 {1'b0}}, biu_adro_i[PLEN - 1:BIUTAG_SIZE + 1], biu_tago_i, 1'b0};
	assign if_parcel_o = biu_q_i;
	assign biu_stb_o = (cm_dc_clean_rdy_i & ~if_flush_i) & if_req_i;
	generate
		if (PLEN <= XLEN) begin : genblk1
			assign biu_adri_o = if_nxt_pc_i[PLEN - 1:0] & (XLEN == 64 ? ~'h7 : ~'h3);
		end
		else begin : genblk1
			assign biu_adri_o = {{PLEN - XLEN {1'b0}}, if_nxt_pc_i} & (XLEN == 64 ? ~'h7 : ~'h3);
		end
	endgenerate
	assign biu_tagi_o = if_nxt_pc_i[1+:BIUTAG_SIZE];
	assign biu_size_o = (XLEN == 64 ? 3'b011 : 3'b010);
	assign biu_lock_o = 1'b0;
	assign biu_prot_o = if_prot_i;
	assign biu_we_o = 1'b0;
	assign biu_d_o = 'h0;
	assign biu_type_o = 3'b001;
endmodule
module riscv_nommu (
	rst_ni,
	clk_i,
	stall_i,
	flush_i,
	req_i,
	adr_i,
	size_i,
	lock_i,
	we_i,
	misaligned_i,
	cm_clean_i,
	cm_invalidate_i,
	req_o,
	adr_o,
	size_o,
	lock_o,
	we_o,
	misaligned_o,
	cm_clean_o,
	cm_invalidate_o,
	pagefault_o
);
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	input wire rst_ni;
	input wire clk_i;
	input wire stall_i;
	input wire flush_i;
	input wire req_i;
	input wire [XLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input lock_i;
	input wire we_i;
	input wire misaligned_i;
	input wire cm_clean_i;
	input wire cm_invalidate_i;
	output reg req_o;
	output reg [PLEN - 1:0] adr_o;
	output reg [2:0] size_o;
	output reg lock_o;
	output reg we_o;
	output reg misaligned_o;
	output reg cm_clean_o;
	output reg cm_invalidate_o;
	output wire pagefault_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			req_o <= 1'b0;
		else if (flush_i)
			req_o <= 1'b0;
		else if (!stall_i)
			req_o <= req_i;
	always @(posedge clk_i)
		if (!stall_i) begin
			if (XLEN == 32)
				adr_o <= {{PLEN - XLEN {1'b0}}, adr_i};
			else
				adr_o <= adr_i[PLEN - 1:0];
			size_o <= size_i;
			lock_o <= lock_i;
			we_o <= we_i;
			misaligned_o <= misaligned_i;
			cm_clean_o <= cm_clean_i;
			cm_invalidate_o <= cm_invalidate_i;
		end
	assign pagefault_o = 1'b0;
endmodule
module riscv_parcel_queue (
	rst_ni,
	clk_i,
	flush_i,
	parcel_i,
	parcel_valid_i,
	parcel_misaligned_i,
	parcel_page_fault_i,
	parcel_error_i,
	parcel_rd_i,
	parcel_q_o,
	parcel_misaligned_o,
	parcel_page_fault_o,
	parcel_error_o,
	empty_o,
	full_o,
	almost_empty_o,
	almost_full_o
);
	reg _sv2v_0;
	parameter DEPTH = 2;
	parameter WR_PARCELS = 2;
	parameter RD_PARCELS = 2;
	parameter ALMOST_EMPTY_THRESHOLD = 0;
	parameter ALMOST_FULL_THRESHOLD = DEPTH;
	localparam PARCEL_SIZE = 16;
	localparam WR_PARCEL_BITS = WR_PARCELS * PARCEL_SIZE;
	localparam RD_PARCEL_BITS = RD_PARCELS * PARCEL_SIZE;
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire [WR_PARCEL_BITS - 1:0] parcel_i;
	input wire [WR_PARCELS - 1:0] parcel_valid_i;
	input wire parcel_misaligned_i;
	input wire parcel_page_fault_i;
	input wire parcel_error_i;
	input wire [$clog2(RD_PARCELS):0] parcel_rd_i;
	output wire [RD_PARCEL_BITS - 1:0] parcel_q_o;
	output wire parcel_misaligned_o;
	output wire parcel_page_fault_o;
	output wire parcel_error_o;
	output reg empty_o;
	output reg full_o;
	output reg almost_empty_o;
	output reg almost_full_o;
	localparam EMPTY_THRESHOLD = 1;
	localparam FULL_THRESHOLD = DEPTH - WR_PARCELS;
	localparam ALMOST_EMPTY_THRESHOLD_CHECK = (ALMOST_EMPTY_THRESHOLD <= 0 ? EMPTY_THRESHOLD : ALMOST_EMPTY_THRESHOLD + 1);
	localparam ALMOST_FULL_THRESHOLD_CHECK = (ALMOST_FULL_THRESHOLD >= DEPTH ? FULL_THRESHOLD : ALMOST_FULL_THRESHOLD - 2);
	function [$clog2(WR_PARCELS):0] align_cnt;
		input [WR_PARCELS - 1:0] a;
		reg found_one;
		begin
			found_one = 0;
			align_cnt = 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				for (n = 0; n < WR_PARCELS; n = n + 1)
					if (!found_one) begin
						if (!a[n])
							align_cnt = align_cnt + 1;
						else
							found_one = 1;
					end
			end
		end
	endfunction
	function [$clog2(WR_PARCELS):0] count_ones;
		input [WR_PARCELS - 1:0] a;
		begin
			count_ones = 0;
			begin : sv2v_autoblock_2
				reg signed [31:0] n;
				for (n = 0; n < WR_PARCELS; n = n + 1)
					if (a[n])
						count_ones = count_ones + 1;
			end
		end
	endfunction
	reg [(DEPTH * 16) - 1:0] parcel_sr;
	reg [(DEPTH * 16) - 1:0] nxt_parcel_sr;
	reg [(DEPTH * 3) - 1:0] parcel_st_sr;
	reg [((DEPTH + RD_PARCELS) * 3) - 1:0] nxt_parcel_st_sr;
	wire [WR_PARCEL_BITS - 1:0] align_parcel;
	wire [$clog2(RD_PARCEL_BITS):0] rd_shift;
	reg [$clog2(DEPTH):0] wadr;
	wire [$clog2(DEPTH):0] nxt_wadr;
	assign align_parcel = parcel_i >> (align_cnt(parcel_valid_i) * PARCEL_SIZE);
	assign nxt_wadr = (wadr + count_ones(parcel_valid_i)) - parcel_rd_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wadr <= 'h0;
		else if (flush_i)
			wadr <= 'h0;
		else
			wadr <= nxt_wadr;
	assign rd_shift = parcel_rd_i * PARCEL_SIZE;
	always @(*) begin
		if (_sv2v_0)
			;
		nxt_parcel_sr = parcel_sr;
		if (|parcel_valid_i) begin : sv2v_autoblock_3
			reg signed [31:0] n;
			for (n = 0; n < WR_PARCELS; n = n + 1)
				nxt_parcel_sr[(wadr + n) * 16+:16] = align_parcel[n * PARCEL_SIZE+:PARCEL_SIZE];
		end
		nxt_parcel_sr = nxt_parcel_sr >> rd_shift;
	end
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	always @(posedge clk_i)
		if (flush_i) begin : sv2v_autoblock_4
			reg signed [31:0] n;
			for (n = 0; n < DEPTH; n = n + 2)
				parcel_sr[16 * n+:32] <= riscv_opcodes_pkg_NOP;
		end
		else
			parcel_sr <= nxt_parcel_sr;
	always @(*) begin
		if (_sv2v_0)
			;
		nxt_parcel_st_sr = parcel_st_sr;
		begin : sv2v_autoblock_5
			reg signed [31:0] n;
			for (n = 0; n < WR_PARCELS; n = n + 1)
				begin
					nxt_parcel_st_sr[((wadr + n) * 3) + 2] = parcel_misaligned_i;
					nxt_parcel_st_sr[((wadr + n) * 3) + 1] = parcel_page_fault_i;
					nxt_parcel_st_sr[(wadr + n) * 3] = parcel_error_i;
				end
		end
		nxt_parcel_st_sr = nxt_parcel_st_sr >> rd_shift;
	end
	always @(posedge clk_i)
		if (flush_i) begin : sv2v_autoblock_6
			reg signed [31:0] n;
			for (n = 0; n < DEPTH; n = n + 1)
				parcel_st_sr[n * 3+:3] <= 'h0;
		end
		else
			parcel_st_sr <= nxt_parcel_st_sr;
	assign parcel_q_o = parcel_sr[0+:16 * RD_PARCELS];
	assign parcel_misaligned_o = parcel_st_sr[2];
	assign parcel_page_fault_o = parcel_st_sr[1];
	assign parcel_error_o = parcel_st_sr[0];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			almost_empty_o <= 1'b1;
		else if (flush_i)
			almost_empty_o <= 1'b1;
		else
			almost_empty_o <= nxt_wadr < ALMOST_EMPTY_THRESHOLD_CHECK;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			empty_o <= 1'b1;
		else if (flush_i)
			empty_o <= 1'b1;
		else
			empty_o <= ~|nxt_wadr;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			almost_full_o <= 1'b0;
		else if (flush_i)
			almost_full_o <= 1'b0;
		else
			almost_full_o <= nxt_wadr > ALMOST_FULL_THRESHOLD_CHECK;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			full_o <= 1'b0;
		else if (flush_i)
			full_o <= 1'b0;
		else
			full_o <= nxt_wadr > FULL_THRESHOLD;
	initial _sv2v_0 = 0;
endmodule
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
module riscv_pmachk (
	clk_i,
	stall_i,
	pma_cfg_i,
	pma_adr_i,
	instruction_i,
	adr_i,
	size_i,
	lock_i,
	we_i,
	misaligned_i,
	exception_o,
	misaligned_o,
	cacheable_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	parameter HAS_RVC = 0;
	parameter PMA_CNT = 16;
	input wire clk_i;
	input wire stall_i;
	input wire [(PMA_CNT * 14) - 1:0] pma_cfg_i;
	input wire [(PMA_CNT * XLEN) - 1:0] pma_adr_i;
	input wire instruction_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire lock_i;
	input wire we_i;
	input wire misaligned_i;
	output wire exception_o;
	output wire misaligned_o;
	output wire cacheable_o;
	function automatic signed [31:0] size2bytes;
		input reg [2:0] size;
		case (size)
			3'b000: size2bytes = 1;
			3'b001: size2bytes = 2;
			3'b010: size2bytes = 4;
			3'b011: size2bytes = 8;
			3'b100: size2bytes = 16;
			default: begin
				size2bytes = -1;
				$display("Error [%0t] /mnt/openlane_disk/RV12/rv12/riscv_pmachk.sv:82:20 - riscv_pmachk.size2bytes.<unnamed_block>\n msg: ", $time, "Illegal biu_size_t");
			end
		endcase
	endfunction
	function signed [31:0] napot_boundary;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg true;
		begin
			n = 2;
			if (!na4) begin
				true = 1'b1;
				begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; (i < XLEN) && true; i = i + 1)
						if (pmaddr[i])
							n = n + 1;
						else
							true = 1'b0;
				end
				n = n + 1;
			end
			napot_boundary = n;
		end
	endfunction
	function automatic [PLEN - 1:0] napot_lb;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg [PLEN - 1:0] mask;
		begin
			n = napot_boundary(na4, pmaddr);
			mask = {PLEN {1'b1}} << n;
			napot_lb = pmaddr;
			napot_lb = napot_lb << 2;
			napot_lb = napot_lb & mask;
		end
	endfunction
	function automatic [PLEN - 1:0] napot_ub;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg [PLEN - 1:0] mask;
		reg [PLEN - 1:0] range;
		begin
			n = napot_boundary(na4, pmaddr);
			mask = {PLEN {1'b1}} << n;
			range = 1 << n;
			napot_ub = pmaddr;
			napot_ub = napot_ub << 2;
			napot_ub = napot_ub & mask;
			napot_ub = napot_ub + range;
		end
	endfunction
	function automatic match_any;
		input [PLEN - 1:0] access_lb;
		input [PLEN - 1:0] access_ub;
		input [PLEN - 1:0] pma_lb;
		input [PLEN - 1:0] pma_ub;
		match_any = ((access_lb[PLEN - 1:2] >= pma_ub[PLEN - 1:2]) || (access_ub[PLEN - 1:2] < pma_lb[PLEN - 1:2]) ? 1'b0 : 1'b1);
	endfunction
	function automatic match_all;
		input [PLEN - 1:0] access_lb;
		input [PLEN - 1:0] access_ub;
		input [PLEN - 1:0] pma_lb;
		input [PLEN - 1:0] pma_ub;
		match_all = ((access_lb[PLEN - 1:2] >= pma_lb[PLEN - 1:2]) && (access_ub[PLEN - 1:2] < pma_ub[PLEN - 1:2]) ? 1'b1 : 1'b0);
	endfunction
	function automatic signed [31:0] highest_priority_match;
		input [PMA_CNT - 1:0] m;
		reg signed [31:0] n;
		begin
			highest_priority_match = 0;
			for (n = PMA_CNT - 1; n >= 0; n = n - 1)
				if (m[n])
					highest_priority_match = n;
		end
	endfunction
	genvar _gv_i_1;
	wire [PLEN - 1:0] access_ub;
	wire [PLEN - 1:0] access_lb;
	reg [PLEN - 1:0] pma_ub [0:PMA_CNT - 1];
	reg [PLEN - 1:0] pma_lb [0:PMA_CNT - 1];
	wire [PMA_CNT - 1:0] pma_match;
	reg [PMA_CNT - 1:0] pma_match_all;
	wire signed [31:0] matched_pma_idx;
	wire [13:0] pmacfg [0:PMA_CNT - 1];
	wire [13:0] matched_pma;
	reg we;
	reg misaligned;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < PMA_CNT; _gv_i_1 = _gv_i_1 + 1) begin : set_pmacfg
			localparam i = _gv_i_1;
			assign pmacfg[i][13-:2] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h0 ? 2'h2 : pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2]);
			assign pmacfg[i][3-:2] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h0 ? 2'h0 : pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 3-:2]);
			assign pmacfg[i][11] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h0 ? 1'b0 : pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 11]);
			assign pmacfg[i][10] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h0 ? 1'b0 : pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 10]);
			assign pmacfg[i][9] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h0 ? 1'b0 : pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 9]);
			assign pmacfg[i][8] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h1 ? pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 8] : 1'b0);
			assign pmacfg[i][7] = pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 7] & pmacfg[i][8];
			assign pmacfg[i][6] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h2 ? pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 6] : 1'b1);
			assign pmacfg[i][5] = (pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 13-:2] == 2'h2 ? pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 5] : 1'b1);
			assign pmacfg[i][4] = pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 4];
			assign pmacfg[i][1-:2] = pma_cfg_i[(((PMA_CNT - 1) - i) * 14) + 1-:2];
		end
	endgenerate
	assign access_lb = adr_i;
	assign access_ub = (adr_i + size2bytes(size_i)) - 1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < PMA_CNT; _gv_i_1 = _gv_i_1 + 1) begin : gen_pma_bounds
			localparam i = _gv_i_1;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (pmacfg[i][1-:2])
					2'd1: pma_lb[i] = (i == 0 ? {PLEN {1'b0}} : pma_ub[i - 1]);
					2'd2: pma_lb[i] = napot_lb(1'b1, pma_adr_i[((PMA_CNT - 1) - i) * XLEN+:XLEN]);
					2'd3: pma_lb[i] = napot_lb(1'b0, pma_adr_i[((PMA_CNT - 1) - i) * XLEN+:XLEN]);
					default: pma_lb[i] = {PLEN {1'bx}};
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (pmacfg[i][1-:2])
					2'd1: pma_ub[i] = pma_adr_i[((PMA_CNT - 1) - i) * XLEN+:XLEN];
					2'd2: pma_ub[i] = napot_ub(1'b1, pma_adr_i[((PMA_CNT - 1) - i) * XLEN+:XLEN]);
					2'd3: pma_ub[i] = napot_ub(1'b0, pma_adr_i[((PMA_CNT - 1) - i) * XLEN+:XLEN]);
					default: pma_ub[i] = {PLEN {1'bx}};
				endcase
			end
			assign pma_match[i] = match_any(access_lb, access_ub, pma_lb[i], pma_ub[i]) & (pmacfg[i][1-:2] != 2'd0);
			always @(posedge clk_i)
				if (!stall_i)
					pma_match_all[i] <= match_all(access_lb, access_ub, pma_lb[i], pma_ub[i]) & (pmacfg[i][1-:2] != 2'd0);
		end
	endgenerate
	assign matched_pma_idx = highest_priority_match(pma_match_all);
	assign matched_pma = pmacfg[matched_pma_idx];
	always @(posedge clk_i)
		if (!stall_i) begin
			we <= we_i;
			misaligned <= misaligned_i;
		end
	assign exception_o = ((~|pma_match_all | (instruction_i & ~matched_pma[9])) | (we & ~matched_pma[10])) | (~we & ~matched_pma[11]);
	assign misaligned_o = misaligned & ~matched_pma[4];
	assign cacheable_o = matched_pma[8];
	initial _sv2v_0 = 0;
endmodule
module riscv_pmpchk (
	clk_i,
	stall_i,
	st_pmpcfg_i,
	st_pmpaddr_i,
	st_prv_i,
	instruction_i,
	adr_i,
	size_i,
	we_i,
	exception_o
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = (XLEN == 32 ? 34 : 56);
	parameter PMP_CNT = 16;
	input wire clk_i;
	input wire stall_i;
	input wire [127:0] st_pmpcfg_i;
	input wire [(16 * XLEN) - 1:0] st_pmpaddr_i;
	input wire [1:0] st_prv_i;
	input wire instruction_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire we_i;
	output wire exception_o;
	function automatic signed [31:0] size2bytes;
		input reg [2:0] size;
		case (size)
			3'b000: size2bytes = 1;
			3'b001: size2bytes = 2;
			3'b010: size2bytes = 4;
			3'b011: size2bytes = 8;
			3'b100: size2bytes = 16;
			default: begin
				size2bytes = -1;
				$display("Error [%0t] /mnt/openlane_disk/RV12/rv12/riscv_pmpchk.sv:75:20 - riscv_pmpchk.size2bytes.<unnamed_block>\n msg: ", $time, "Illegal biu_size_t");
			end
		endcase
	endfunction
	function signed [31:0] napot_boundary;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg true;
		begin
			n = 2;
			if (!na4) begin
				true = 1'b1;
				begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; (i < XLEN) && true; i = i + 1)
						if (pmaddr[i])
							n = n + 1;
						else
							true = 1'b0;
				end
				n = n + 1;
			end
			napot_boundary = n;
		end
	endfunction
	function automatic [PLEN - 1:0] napot_lb;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg [PLEN - 1:0] mask;
		begin
			n = napot_boundary(na4, pmaddr);
			mask = {PLEN {1'b1}} << n;
			napot_lb = pmaddr;
			napot_lb = napot_lb << 2;
			napot_lb = napot_lb & mask;
		end
	endfunction
	function automatic [PLEN - 1:0] napot_ub;
		input na4;
		input [XLEN - 1:0] pmaddr;
		reg signed [31:0] n;
		reg [PLEN - 1:0] mask;
		reg [PLEN - 1:0] range;
		begin
			n = napot_boundary(na4, pmaddr);
			mask = {PLEN {1'b1}} << n;
			range = 1 << n;
			napot_ub = pmaddr;
			napot_ub = napot_ub << 2;
			napot_ub = napot_ub & mask;
			napot_ub = napot_ub + range;
		end
	endfunction
	function automatic match_any;
		input [PLEN - 1:0] access_lb;
		input [PLEN - 1:0] access_ub;
		input [PLEN - 1:0] pmp_lb;
		input [PLEN - 1:0] pmp_ub;
		match_any = ((access_lb[PLEN - 1:2] >= pmp_ub[PLEN - 1:2]) || (access_ub[PLEN - 1:2] < pmp_lb[PLEN - 1:2]) ? 1'b0 : 1'b1);
	endfunction
	function automatic match_all;
		input [PLEN - 1:0] access_lb;
		input [PLEN - 1:0] access_ub;
		input [PLEN - 1:0] pmp_lb;
		input [PLEN - 1:0] pmp_ub;
		match_all = ((access_lb[PLEN - 1:2] >= pmp_lb[PLEN - 1:2]) && (access_ub[PLEN - 1:2] < pmp_ub[PLEN - 1:2]) ? 1'b1 : 1'b0);
	endfunction
	function automatic signed [31:0] highest_priority_match;
		input [PMP_CNT - 1:0] m;
		reg signed [31:0] n;
		for (n = PMP_CNT - 1; n >= 0; n = n - 1)
			if (m[n])
				highest_priority_match = n;
	endfunction
	genvar _gv_i_2;
	wire [PLEN - 1:0] access_ub;
	wire [PLEN - 1:0] access_lb;
	reg [PLEN - 1:0] pmp_ub [0:15];
	reg [PLEN - 1:0] pmp_lb [0:15];
	wire [PMP_CNT - 1:0] pmp_match;
	reg [PMP_CNT - 1:0] pmp_match_all;
	reg signed [31:0] matched_pmp;
	wire [7:0] matched_pmpcfg;
	reg we;
	assign access_lb = adr_i;
	assign access_ub = (adr_i + size2bytes(size_i)) - 1;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < PMP_CNT; _gv_i_2 = _gv_i_2 + 1) begin : gen_pmp_bounds
			localparam i = _gv_i_2;
			always @(*) begin
				if (_sv2v_0)
					;
				case (st_pmpcfg_i[(i * 8) + 4-:2])
					2'd1: pmp_lb[i] = (i == 0 ? {PLEN {1'b0}} : pmp_ub[i - 1]);
					2'd2: pmp_lb[i] = napot_lb(1'b1, st_pmpaddr_i[i * XLEN+:XLEN]);
					2'd3: pmp_lb[i] = napot_lb(1'b0, st_pmpaddr_i[i * XLEN+:XLEN]);
					default: pmp_lb[i] = 'hx;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				case (st_pmpcfg_i[(i * 8) + 4-:2])
					2'd1: pmp_ub[i] = st_pmpaddr_i[i * XLEN+:XLEN];
					2'd2: pmp_ub[i] = napot_ub(1'b1, st_pmpaddr_i[i * XLEN+:XLEN]);
					2'd3: pmp_ub[i] = napot_ub(1'b0, st_pmpaddr_i[i * XLEN+:XLEN]);
					default: pmp_ub[i] = 'hx;
				endcase
			end
			assign pmp_match[i] = match_any(access_lb, access_ub, pmp_lb[i], pmp_ub[i]) & (st_pmpcfg_i[(i * 8) + 4-:2] != 2'd0);
			always @(posedge clk_i)
				if (!stall_i)
					pmp_match_all[i] <= match_all(access_lb, access_ub, pmp_lb[i], pmp_ub[i]);
		end
	endgenerate
	always @(posedge clk_i)
		if (!stall_i)
			matched_pmp <= highest_priority_match(pmp_match);
	assign matched_pmpcfg = st_pmpcfg_i[matched_pmp * 8+:8];
	always @(posedge clk_i)
		if (!stall_i)
			we <= we_i;
	localparam [1:0] riscv_state_pkg_PRV_M = 2'b11;
	assign exception_o = (~|pmp_match ? (st_prv_i != riscv_state_pkg_PRV_M) & (PMP_CNT > 0) : ~pmp_match_all[matched_pmp] | (((st_prv_i != riscv_state_pkg_PRV_M) | matched_pmpcfg[7]) & (((~matched_pmpcfg[0] & ~we) | (~matched_pmpcfg[1] & we)) | (~matched_pmpcfg[2] & instruction_i))));
	initial _sv2v_0 = 0;
endmodule
module riscv_rf (
	rst_ni,
	clk_i,
	rf_src1_i,
	rf_src2_i,
	rf_src1_q_o,
	rf_src2_q_o,
	rf_dst_i,
	rf_dst_d_i,
	rf_we_i,
	pd_stall_i,
	id_stall_i,
	du_re_rf_i,
	du_we_rf_i,
	du_d_i,
	du_rf_q_o,
	du_addr_i
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter REGOUT = 0;
	input rst_ni;
	input clk_i;
	input wire [4:0] rf_src1_i;
	input wire [4:0] rf_src2_i;
	output reg [MXLEN - 1:0] rf_src1_q_o;
	output reg [MXLEN - 1:0] rf_src2_q_o;
	input wire [4:0] rf_dst_i;
	input [MXLEN - 1:0] rf_dst_d_i;
	input rf_we_i;
	input pd_stall_i;
	input id_stall_i;
	input du_re_rf_i;
	input du_we_rf_i;
	input [MXLEN - 1:0] du_d_i;
	output reg [MXLEN - 1:0] du_rf_q_o;
	input [11:0] du_addr_i;
	reg [MXLEN - 1:0] rf [0:31];
	reg [4:0] src1;
	reg [4:0] src2;
	wire [MXLEN - 1:0] rfout1;
	wire [MXLEN - 1:0] rfout2;
	reg src1_is_x0;
	reg src2_is_x0;
	wire dst_is_src1;
	wire dst_is_src2;
	reg [MXLEN - 1:0] dout1;
	reg [MXLEN - 1:0] dout2;
	reg du_re_rf_dly;
	always @(posedge clk_i) du_re_rf_dly <= du_re_rf_i;
	always @(posedge clk_i)
		if (du_re_rf_i)
			src1 <= du_addr_i[4:0];
		else if (!pd_stall_i)
			src1 <= rf_src1_i;
	always @(posedge clk_i)
		if (!pd_stall_i)
			src2 <= rf_src2_i;
	assign dst_is_src1 = rf_dst_i == src1;
	assign dst_is_src2 = rf_dst_i == src2;
	assign rfout1 = rf[src1];
	assign rfout2 = rf[src2];
	always @(posedge clk_i)
		if (!pd_stall_i)
			src1_is_x0 <= ~|rf_src1_i;
	always @(posedge clk_i)
		if (!pd_stall_i)
			src2_is_x0 <= ~|rf_src2_i;
	always @(*) begin
		if (_sv2v_0)
			;
		casex (src1_is_x0)
			1'b1: dout1 = {MXLEN {1'b0}};
			1'b0: dout1 = rfout1;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (src2_is_x0)
			1'b1: dout2 = {MXLEN {1'b0}};
			1'b0: dout2 = rfout2;
		endcase
	end
	generate
		if (REGOUT > 0) begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					rf_src1_q_o <= dout1;
			always @(posedge clk_i)
				if (!id_stall_i)
					rf_src2_q_o <= dout2;
		end
		else begin : genblk1
			wire [MXLEN:1] sv2v_tmp_C1DA4;
			assign sv2v_tmp_C1DA4 = dout1;
			always @(*) rf_src1_q_o = sv2v_tmp_C1DA4;
			wire [MXLEN:1] sv2v_tmp_3FB3C;
			assign sv2v_tmp_3FB3C = dout2;
			always @(*) rf_src2_q_o = sv2v_tmp_3FB3C;
		end
	endgenerate
	always @(posedge clk_i)
		if (du_re_rf_dly)
			du_rf_q_o <= (~|src1 ? 'h0 : rfout1);
	always @(posedge clk_i)
		if (du_we_rf_i)
			rf[du_addr_i[4:0]] <= du_d_i;
		else if (rf_we_i)
			rf[rf_dst_i] <= rf_dst_d_i;
	initial _sv2v_0 = 0;
endmodule
module riscv_rsb (
	rst_ni,
	clk_i,
	ena_i,
	d_i,
	q_o,
	push_i,
	pop_i,
	empty_o
);
	parameter MXLEN = 32;
	parameter DEPTH = 4;
	input wire rst_ni;
	input wire clk_i;
	input wire ena_i;
	input wire [MXLEN - 1:0] d_i;
	output wire [MXLEN - 1:0] q_o;
	input wire push_i;
	input wire pop_i;
	output reg empty_o;
	reg [MXLEN - 1:0] stack [0:DEPTH - 1];
	reg [MXLEN - 1:0] last_value;
	reg [$clog2(DEPTH + 1) - 1:0] cnt;
	always @(posedge clk_i)
		if (ena_i && push_i)
			last_value <= d_i;
	always @(posedge clk_i)
		if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01: begin : sv2v_autoblock_1
					reg signed [31:0] n;
					for (n = 0; n < (DEPTH - 1); n = n + 1)
						stack[n] <= stack[n + 1];
				end
				2'b10: begin
					stack[0] <= d_i;
					begin : sv2v_autoblock_2
						reg signed [31:0] n;
						for (n = 1; n < DEPTH; n = n + 1)
							stack[n] <= stack[n - 1];
					end
				end
				2'b11: stack[0] <= d_i;
				2'b00:
					;
			endcase
	assign q_o = (empty_o ? last_value : stack[0]);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cnt <= 'h0;
		else if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01:
					if (!empty_o)
						cnt <= cnt - 1;
				2'b10:
					if (cnt != DEPTH)
						cnt <= cnt + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			empty_o <= 1'b1;
		else if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01: empty_o <= cnt == 1;
				2'b10: empty_o <= 1'b0;
				default:
					;
			endcase
endmodule
module riscv_state1_10 (
	rst_ni,
	clk_i,
	id_pc_i,
	id_insn_i,
	bu_flush_i,
	bu_nxt_pc_i,
	st_flush_o,
	st_nxt_pc_o,
	wb_pc_i,
	wb_insn_i,
	wb_exceptions_i,
	wb_badaddr_i,
	st_prv_o,
	st_xlen_o,
	st_be_o,
	st_tvm_o,
	st_tw_o,
	st_tsr_o,
	st_mcounteren_o,
	st_scounteren_o,
	st_pmpcfg_o,
	st_pmpaddr_o,
	int_external_i,
	int_timer_i,
	int_software_i,
	st_int_o,
	pd_stall_i,
	id_stall_i,
	pd_csr_reg_i,
	ex_csr_reg_i,
	ex_csr_we_i,
	ex_csr_wval_i,
	st_csr_rval_o,
	du_stall_i,
	du_flush_i,
	du_re_csr_i,
	du_we_csr_i,
	du_csr_rval_o,
	du_dato_i,
	du_addr_i,
	du_ie_i,
	du_ee_i,
	du_interrupts_o,
	du_exceptions_o
);
	reg _sv2v_0;
	parameter signed [31:0] MXLEN = 32;
	parameter signed [31:0] FLEN = 64;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter [0:0] IS_RV32E = 0;
	parameter [0:0] HAS_FPU = 0;
	parameter [0:0] HAS_MMU = 0;
	parameter [0:0] HAS_RVA = 0;
	parameter [0:0] HAS_RVB = 0;
	parameter [0:0] HAS_RVC = 0;
	parameter [0:0] HAS_RVM = 0;
	parameter [0:0] HAS_RVN = 0;
	parameter [0:0] HAS_RVP = 0;
	parameter [0:0] HAS_RVT = 0;
	parameter [0:0] HAS_EXT = 0;
	parameter [0:0] HAS_USER = 1;
	parameter [0:0] HAS_SUPER = 1;
	parameter [0:0] HAS_HYPER = 0;
	parameter [MXLEN - 1:0] MCONFIGPTR_VAL = {MXLEN {1'b0}};
	parameter [MXLEN - 1:0] MNMIVEC_DEFAULT = PC_INIT - 'h4;
	parameter [MXLEN - 1:0] MTVEC_DEFAULT = PC_INIT - 'h40;
	parameter [MXLEN - 1:0] HTVEC_DEFAULT = PC_INIT - 'h80;
	parameter [MXLEN - 1:0] STVEC_DEFAULT = PC_INIT - 'hc0;
	parameter [7:0] JEDEC_BANK = 9;
	parameter [6:0] JEDEC_MANUFACTURER_ID = 'h8a;
	parameter signed [31:0] PMP_CNT = 16;
	parameter [MXLEN - 1:0] HARTID = 0;
	input rst_ni;
	input clk_i;
	input [MXLEN - 1:0] id_pc_i;
	input wire [34:0] id_insn_i;
	input bu_flush_i;
	input [MXLEN - 1:0] bu_nxt_pc_i;
	output reg st_flush_o;
	output reg [MXLEN - 1:0] st_nxt_pc_o;
	input [MXLEN - 1:0] wb_pc_i;
	input wire [34:0] wb_insn_i;
	input wire [27:0] wb_exceptions_i;
	input [MXLEN - 1:0] wb_badaddr_i;
	output reg [1:0] st_prv_o;
	output reg [1:0] st_xlen_o;
	output reg st_be_o;
	output wire st_tvm_o;
	output wire st_tw_o;
	output wire st_tsr_o;
	output wire [MXLEN - 1:0] st_mcounteren_o;
	output wire [MXLEN - 1:0] st_scounteren_o;
	output wire [127:0] st_pmpcfg_o;
	output wire [(16 * MXLEN) - 1:0] st_pmpaddr_o;
	input [3:0] int_external_i;
	input int_timer_i;
	input int_software_i;
	output wire [5:0] st_int_o;
	input pd_stall_i;
	input id_stall_i;
	input [11:0] pd_csr_reg_i;
	input [11:0] ex_csr_reg_i;
	input ex_csr_we_i;
	input [MXLEN - 1:0] ex_csr_wval_i;
	output reg [MXLEN - 1:0] st_csr_rval_o;
	input du_stall_i;
	input du_flush_i;
	input du_re_csr_i;
	input du_we_csr_i;
	output reg [MXLEN - 1:0] du_csr_rval_o;
	input [MXLEN - 1:0] du_dato_i;
	input [11:0] du_addr_i;
	input [MXLEN - 1:0] du_ie_i;
	input [63:0] du_ee_i;
	output wire [MXLEN - 1:0] du_interrupts_o;
	output wire [63:0] du_exceptions_o;
	function automatic [MXLEN - 1:0] find_first_one;
		input [MXLEN - 1:0] a;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			find_first_one = 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				begin : sv2v_autoblock_2
					reg signed [31:0] _sv2v_value_on_break;
					for (n = 0; n < MXLEN; n = n + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (a[n]) begin
								find_first_one = n;
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
	reg [(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((200 + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + 15) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + 119) + MXLEN) + 16) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + 16) + MXLEN) + MXLEN) + 256) + (16 * MXLEN)) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + 128) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) + MXLEN) - 1:0] csr;
	wire is_rv32;
	wire is_rv32e;
	wire is_rv64;
	wire is_rv128;
	wire has_rvc;
	wire has_fpu;
	wire has_fpud;
	wire has_fpuq;
	wire has_mmu;
	wire has_muldiv;
	wire has_amo;
	wire has_b;
	wire has_tmem;
	wire has_simd;
	wire has_u;
	wire has_s;
	wire has_h;
	wire has_ext;
	wire [63:0] mstatus;
	wire [1:0] uxl_wval;
	wire [1:0] sxl_wval;
	reg soft_seip;
	reg soft_ueip;
	wire take_interrupt;
	wire [3:0] interrupt_cause;
	wire [3:0] trap_cause;
	reg [11:0] csr_raddr;
	reg [MXLEN - 1:0] csr_rval;
	wire [MXLEN - 1:0] csr_wval;
	assign is_rv32 = MXLEN == 32;
	assign is_rv64 = MXLEN == 64;
	assign is_rv128 = MXLEN == 128;
	assign is_rv32e = (IS_RV32E != 0) & is_rv32;
	assign has_u = HAS_USER != 0;
	assign has_s = (HAS_SUPER != 0) & has_u;
	assign has_h = 1'b0;
	assign has_rvc = HAS_RVC != 0;
	assign has_fpu = HAS_FPU != 0;
	assign has_fpuq = (FLEN == 128) & has_fpu;
	assign has_fpud = ((FLEN == 64) & has_fpu) | has_fpuq;
	assign has_mmu = (HAS_MMU != 0) & has_s;
	assign has_muldiv = HAS_RVM != 0;
	assign has_amo = HAS_RVA != 0;
	assign has_b = HAS_RVB != 0;
	assign has_tmem = HAS_RVT != 0;
	assign has_simd = HAS_RVP != 0;
	assign has_ext = HAS_EXT != 0;
	always @(posedge clk_i)
		if (du_re_csr_i)
			csr_raddr <= du_addr_i;
		else if (!pd_stall_i)
			csr_raddr <= pd_csr_reg_i;
	assign csr_wval = (du_we_csr_i ? du_dato_i : ex_csr_wval_i);
	assign mstatus = {csr[119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))], {29 {1'b0}}, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2], {9 {1'b0}}, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 7], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 8], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 9], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 10], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 11], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 12], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 13-:2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 15-:2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 19-:2], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 23], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24], 1'b0, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25], 1'b0, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26], 1'b0};
	localparam [11:0] riscv_state_pkg_CYCLE = 'hc00;
	localparam [11:0] riscv_state_pkg_CYCLEH = 'hc80;
	localparam [11:0] riscv_state_pkg_FCSR = 'h3;
	localparam [11:0] riscv_state_pkg_FFLAGS = 'h1;
	localparam [11:0] riscv_state_pkg_FRM = 'h2;
	localparam [11:0] riscv_state_pkg_INSTRET = 'hc02;
	localparam [11:0] riscv_state_pkg_INSTRETH = 'hc82;
	localparam [11:0] riscv_state_pkg_MARCHID = 'hf12;
	localparam [11:0] riscv_state_pkg_MCAUSE = 'h342;
	localparam [11:0] riscv_state_pkg_MCONFIGPTR = 'hf15;
	localparam [11:0] riscv_state_pkg_MCOUNTEREN = 'h306;
	localparam [11:0] riscv_state_pkg_MCYCLE = 'hb00;
	localparam [11:0] riscv_state_pkg_MCYCLEH = 'hb80;
	localparam [11:0] riscv_state_pkg_MEDELEG = 'h302;
	localparam [11:0] riscv_state_pkg_MEDELEGH = 'h312;
	localparam [11:0] riscv_state_pkg_MENVCFG = 'h30a;
	localparam [11:0] riscv_state_pkg_MENVCFGH = 'h31a;
	localparam [11:0] riscv_state_pkg_MEPC = 'h341;
	localparam [11:0] riscv_state_pkg_MHARTID = 'hf14;
	localparam [11:0] riscv_state_pkg_MIDELEG = 'h303;
	localparam [11:0] riscv_state_pkg_MIE = 'h304;
	localparam [11:0] riscv_state_pkg_MIMPID = 'hf13;
	localparam [11:0] riscv_state_pkg_MINSTRET = 'hb02;
	localparam [11:0] riscv_state_pkg_MINSTRETH = 'hb82;
	localparam [11:0] riscv_state_pkg_MIP = 'h344;
	localparam [11:0] riscv_state_pkg_MISA = 'h301;
	localparam [11:0] riscv_state_pkg_MNMIVEC = 'h7c0;
	localparam [11:0] riscv_state_pkg_MSCRATCH = 'h340;
	localparam [11:0] riscv_state_pkg_MSTATUS = 'h300;
	localparam [11:0] riscv_state_pkg_MSTATUSH = 'h310;
	localparam [11:0] riscv_state_pkg_MTINST = 'h34a;
	localparam [11:0] riscv_state_pkg_MTVAL = 'h343;
	localparam [11:0] riscv_state_pkg_MTVAL2 = 'h34b;
	localparam [11:0] riscv_state_pkg_MTVEC = 'h305;
	localparam [11:0] riscv_state_pkg_MVENDORID = 'hf11;
	localparam [11:0] riscv_state_pkg_PMPADDR0 = 'h3b0;
	localparam [11:0] riscv_state_pkg_PMPADDR1 = 'h3b1;
	localparam [11:0] riscv_state_pkg_PMPADDR10 = 'h3ba;
	localparam [11:0] riscv_state_pkg_PMPADDR11 = 'h3bb;
	localparam [11:0] riscv_state_pkg_PMPADDR12 = 'h3bc;
	localparam [11:0] riscv_state_pkg_PMPADDR13 = 'h3bd;
	localparam [11:0] riscv_state_pkg_PMPADDR14 = 'h3be;
	localparam [11:0] riscv_state_pkg_PMPADDR15 = 'h3bf;
	localparam [11:0] riscv_state_pkg_PMPADDR2 = 'h3b2;
	localparam [11:0] riscv_state_pkg_PMPADDR3 = 'h3b3;
	localparam [11:0] riscv_state_pkg_PMPADDR4 = 'h3b4;
	localparam [11:0] riscv_state_pkg_PMPADDR5 = 'h3b5;
	localparam [11:0] riscv_state_pkg_PMPADDR6 = 'h3b6;
	localparam [11:0] riscv_state_pkg_PMPADDR7 = 'h3b7;
	localparam [11:0] riscv_state_pkg_PMPADDR8 = 'h3b8;
	localparam [11:0] riscv_state_pkg_PMPADDR9 = 'h3b9;
	localparam [11:0] riscv_state_pkg_PMPCFG0 = 'h3a0;
	localparam [11:0] riscv_state_pkg_PMPCFG1 = 'h3a1;
	localparam [11:0] riscv_state_pkg_PMPCFG2 = 'h3a2;
	localparam [11:0] riscv_state_pkg_PMPCFG3 = 'h3a3;
	localparam [11:0] riscv_state_pkg_SATP = 'h180;
	localparam [11:0] riscv_state_pkg_SCAUSE = 'h142;
	localparam [11:0] riscv_state_pkg_SCOUNTEREN = 'h106;
	localparam [11:0] riscv_state_pkg_SEPC = 'h141;
	localparam [11:0] riscv_state_pkg_SIE = 'h104;
	localparam [11:0] riscv_state_pkg_SIP = 'h144;
	localparam [11:0] riscv_state_pkg_SSCRATCH = 'h140;
	localparam [11:0] riscv_state_pkg_SSTATUS = 'h100;
	localparam [11:0] riscv_state_pkg_STVAL = 'h143;
	localparam [11:0] riscv_state_pkg_STVEC = 'h105;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (csr_raddr)
			riscv_state_pkg_FFLAGS: csr_rval = (has_fpu ? {{MXLEN - 5 {1'b0}}, csr[(200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - 3-:5]} : 'h0);
			riscv_state_pkg_FRM: csr_rval = (has_fpu ? {{MXLEN - 3 {1'b0}}, csr[200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:3]} : 'h0);
			riscv_state_pkg_FCSR: csr_rval = (has_fpu ? {{MXLEN - 8 {1'b0}}, csr[200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)]} : 'h0);
			riscv_state_pkg_CYCLE: csr_rval = csr[(128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 - MXLEN):(128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 63];
			riscv_state_pkg_INSTRET: csr_rval = csr[(64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 - MXLEN):(64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 63];
			riscv_state_pkg_CYCLEH: csr_rval = (is_rv32 ? csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] : 'h0);
			riscv_state_pkg_INSTRETH: csr_rval = (is_rv32 ? csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] : 'h0);
			riscv_state_pkg_SSTATUS: csr_rval = {mstatus[63], mstatus[MXLEN - 2:0]} & (((1 << (MXLEN - 1)) | (2'b11 << 32)) | 'hde133);
			riscv_state_pkg_SIE: csr_rval = (has_s ? csr[16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) + 1)] & 12'h333 : 'h0);
			riscv_state_pkg_STVEC: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_SCOUNTEREN: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_SSCRATCH: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_SEPC: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_SCAUSE: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_STVAL: csr_rval = (has_s ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_SIP: csr_rval = (has_s ? (csr[16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) + 1)] & csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)]) & 12'h333 : 'h0);
			riscv_state_pkg_SATP: csr_rval = (has_s && has_mmu ? csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] : 'h0);
			riscv_state_pkg_MISA: csr_rval = {csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2], {MXLEN - 28 {1'b0}}, csr[(92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2-:26]};
			riscv_state_pkg_MVENDORID: csr_rval = {{MXLEN - 15 {1'b0}}, csr[15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))-:((15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))) ? ((15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))) - (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))) + 1)]};
			riscv_state_pkg_MARCHID: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MIMPID: csr_rval = (is_rv32 ? csr[MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) + 1)] : {{MXLEN - MXLEN {1'b0}}, csr[MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) + 1)]});
			riscv_state_pkg_MHARTID: csr_rval = csr[MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) >= (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) - (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MSTATUS: csr_rval = {mstatus[63], mstatus[MXLEN - 2:0]};
			riscv_state_pkg_MSTATUSH: csr_rval = (is_rv32 ? {{MXLEN - 6 {1'b0}}, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1], csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2], 4'h0} : 'h0);
			riscv_state_pkg_MCONFIGPTR: csr_rval = {MXLEN {1'b0}} | MCONFIGPTR_VAL;
			riscv_state_pkg_MTVEC: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MCOUNTEREN: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MNMIVEC: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))) + 1)];
			riscv_state_pkg_MEDELEG: csr_rval = csr[(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (64 - MXLEN):(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 63];
			riscv_state_pkg_MEDELEGH: csr_rval = (is_rv32 ? csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))):(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 31] : 'h0);
			riscv_state_pkg_MIDELEG: csr_rval = csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MIE: csr_rval = csr[16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) + 1)] & 12'hfff;
			riscv_state_pkg_MSCRATCH: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MEPC: csr_rval = csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MCAUSE: csr_rval = csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MTVAL: csr_rval = csr[MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MIP: csr_rval = csr[16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) + 1)];
			riscv_state_pkg_MTINST: csr_rval = {MXLEN {1'b0}};
			riscv_state_pkg_MTVAL2: csr_rval = {MXLEN {1'b0}};
			riscv_state_pkg_MENVCFG: csr_rval = csr[(256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (64 - MXLEN):(256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 63];
			riscv_state_pkg_MENVCFGH: csr_rval = (is_rv32 ? csr[256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))):(256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 31] : 'h0);
			riscv_state_pkg_PMPCFG0: csr_rval = csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 127+:8 * (MXLEN / 8)];
			riscv_state_pkg_PMPCFG1: csr_rval = (is_rv32 ? csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 95+:32] : 'h0);
			riscv_state_pkg_PMPCFG2: csr_rval = (~is_rv128 ? csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 63+:8 * (MXLEN / 8)] : 'h0);
			riscv_state_pkg_PMPCFG3: csr_rval = (is_rv32 ? csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - 31+:32] : 'h0);
			riscv_state_pkg_PMPADDR0: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - ((16 * MXLEN) - 1)+:MXLEN];
			riscv_state_pkg_PMPADDR1: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - MXLEN)+:MXLEN];
			riscv_state_pkg_PMPADDR2: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (2 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR3: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (3 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR4: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (4 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR5: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (5 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR6: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (6 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR7: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (7 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR8: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (8 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR9: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (9 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR10: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (10 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR11: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (11 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR12: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (12 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR13: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (13 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR14: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (14 * MXLEN))+:MXLEN];
			riscv_state_pkg_PMPADDR15: csr_rval = csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (15 * MXLEN))+:MXLEN];
			riscv_state_pkg_MCYCLE: csr_rval = csr[(128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 - MXLEN):(128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 63];
			riscv_state_pkg_MINSTRET: csr_rval = csr[(64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 - MXLEN):(64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 63];
			riscv_state_pkg_MCYCLEH: csr_rval = (is_rv32 ? csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] : 'h0);
			riscv_state_pkg_MINSTRETH: csr_rval = (is_rv32 ? csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] : 'h0);
			default: csr_rval = 32'h00000000;
		endcase
	end
	always @(posedge clk_i)
		if (!id_stall_i)
			st_csr_rval_o <= csr_rval;
	always @(posedge clk_i) du_csr_rval_o <= csr_rval;
	localparam [1:0] riscv_state_pkg_RV128I = 2'b11;
	localparam [1:0] riscv_state_pkg_RV32I = 2'b01;
	localparam [1:0] riscv_state_pkg_RV64I = 2'b10;
	wire [2:1] sv2v_tmp_5EFF7;
	assign sv2v_tmp_5EFF7 = (is_rv128 ? riscv_state_pkg_RV128I : (is_rv64 ? riscv_state_pkg_RV64I : riscv_state_pkg_RV32I));
	always @(*) csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2] = sv2v_tmp_5EFF7;
	wire [26:1] sv2v_tmp_A1BCD;
	assign sv2v_tmp_A1BCD = {2'b00, has_ext, 2'b00, has_u, 1'b0, has_s, 1'b0, has_fpuq, has_simd, 2'b00, has_muldiv, 3'b000, ~is_rv32e, 2'b00, has_fpu, is_rv32e, has_fpud, has_rvc, has_b, has_amo};
	always @(*) csr[(92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2-:26] = sv2v_tmp_A1BCD;
	wire [8:1] sv2v_tmp_D1936;
	assign sv2v_tmp_D1936 = JEDEC_BANK - 1;
	always @(*) csr[15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))-:8] = sv2v_tmp_D1936;
	wire [7:1] sv2v_tmp_4A388;
	assign sv2v_tmp_4A388 = JEDEC_MANUFACTURER_ID[6:0];
	always @(*) csr[(15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) - 8-:7] = sv2v_tmp_4A388;
	localparam riscv_rv12_pkg_ARCHID = 12;
	wire [((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_A3F5D;
	assign sv2v_tmp_A3F5D = (1 << (MXLEN - 1)) | riscv_rv12_pkg_ARCHID;
	always @(*) csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_A3F5D;
	localparam riscv_rv12_pkg_REVPRV_MAJOR = 1;
	wire [(((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 32)) >= ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 25)) ? (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 32)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 25))) + 1 : (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 25)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 32))) + 1) * 1:1] sv2v_tmp_7DEDA;
	assign sv2v_tmp_7DEDA = riscv_rv12_pkg_REVPRV_MAJOR;
	always @(*) csr[(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 32):(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 25)] = sv2v_tmp_7DEDA;
	localparam riscv_rv12_pkg_REVPRV_MINOR = 10;
	wire [(((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 24)) >= ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 17)) ? (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 24)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 17))) + 1 : (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 17)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 24))) + 1) * 1:1] sv2v_tmp_54CA7;
	assign sv2v_tmp_54CA7 = riscv_rv12_pkg_REVPRV_MINOR;
	always @(*) csr[(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 24):(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 17)] = sv2v_tmp_54CA7;
	localparam riscv_rv12_pkg_REVUSR_MAJOR = 2;
	wire [(((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 16)) >= ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 9)) ? (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 16)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 9))) + 1 : (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 9)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 16))) + 1) * 1:1] sv2v_tmp_3DA03;
	assign sv2v_tmp_3DA03 = riscv_rv12_pkg_REVUSR_MAJOR;
	always @(*) csr[(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 16):(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 9)] = sv2v_tmp_3DA03;
	localparam riscv_rv12_pkg_REVUSR_MINOR = 2;
	wire [(((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 8)) >= ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 1)) ? (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 8)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 1))) + 1 : (((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 1)) - ((MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 8))) + 1) * 1:1] sv2v_tmp_B00AF;
	assign sv2v_tmp_B00AF = riscv_rv12_pkg_REVUSR_MINOR;
	always @(*) csr[(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 8):(MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) - (MXLEN - 1)] = sv2v_tmp_B00AF;
	wire [((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) >= (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) - (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_4D53E;
	assign sv2v_tmp_4D53E = HARTID;
	always @(*) csr[MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) >= (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))) - (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_4D53E;
	wire [1:1] sv2v_tmp_C6C56;
	assign sv2v_tmp_C6C56 = &csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 15-:2] | &csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 13-:2];
	always @(*) csr[119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))] = sv2v_tmp_C6C56;
	assign st_tvm_o = csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 9];
	assign st_tw_o = csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 8];
	assign st_tsr_o = csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 7];
	generate
		if (MXLEN == 128) begin : genblk1
			assign sxl_wval = (|csr_wval[35:34] ? csr_wval[35:34] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2]);
			assign uxl_wval = (|csr_wval[33:32] ? csr_wval[33:32] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2]);
		end
		else if (MXLEN == 64) begin : genblk1
			assign sxl_wval = ((csr_wval[35:34] == riscv_state_pkg_RV32I) || (csr_wval[35:34] == riscv_state_pkg_RV64I) ? csr_wval[35:34] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2]);
			assign uxl_wval = ((csr_wval[33:32] == riscv_state_pkg_RV32I) || (csr_wval[33:32] == riscv_state_pkg_RV64I) ? csr_wval[33:32] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2]);
		end
		else begin : genblk1
			assign sxl_wval = 2'b00;
			assign uxl_wval = 2'b00;
		end
	endgenerate
	localparam [1:0] riscv_state_pkg_PRV_S = 2'b01;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		case (st_prv_o)
			riscv_state_pkg_PRV_S: begin
				st_xlen_o = (has_s ? csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2] : csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2]);
				st_be_o = (has_s ? csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1]);
			end
			riscv_state_pkg_PRV_U: begin
				st_xlen_o = (has_u ? csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2] : csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2]);
				st_be_o = (has_u ? csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 23] : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1]);
			end
			default: begin
				st_xlen_o = csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2];
				st_be_o = csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1];
			end
		endcase
	end
	localparam [31:0] riscv_opcodes_pkg_MRET = 32'b00110000001000000000000001110001;
	localparam [31:0] riscv_opcodes_pkg_SRET = 32'b00010000001000000000000001110001;
	localparam [1:0] riscv_state_pkg_PRV_H = 2'b10;
	localparam [1:0] riscv_state_pkg_PRV_M = 2'b11;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			st_prv_o <= riscv_state_pkg_PRV_M;
			st_nxt_pc_o <= PC_INIT;
			st_flush_o <= 1'b1;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 1] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 2] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2] <= (has_s ? csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2] : 2'b00);
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2] <= (has_u ? csr[92 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:2] : 2'b00);
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 7] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 8] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 9] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 10] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 11] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 12] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 13-:2] <= {2 {has_ext}};
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 15-:2] <= 2'b00;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= riscv_state_pkg_PRV_M;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 19-:2] <= 2'b00;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= has_s;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 23] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= 1'b0;
			csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= 1'b0;
		end
		else begin
			st_flush_o <= 1'b0;
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MSTATUS)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MSTATUS))) begin
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 3-:2] <= (has_s && (MXLEN > 32) ? sxl_wval : 2'b00);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2] <= (has_u && (MXLEN > 32) ? uxl_wval : 2'b00);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 7] <= (has_s ? csr_wval[22] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 8] <= (has_s ? csr_wval[21] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 9] <= (has_s ? csr_wval[20] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 10] <= (has_s ? csr_wval[19] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 11] <= (has_s ? csr_wval[18] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 12] <= (has_u ? csr_wval[17] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 13-:2] <= (has_ext ? csr_wval[16:15] : 2'b00);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 15-:2] <= (has_s && has_fpu ? csr_wval[14:13] : 2'b00);
				case (csr_wval[12:11])
					riscv_state_pkg_PRV_M: csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= riscv_state_pkg_PRV_M;
					riscv_state_pkg_PRV_H: csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= (has_h ? riscv_state_pkg_PRV_H : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2]);
					riscv_state_pkg_PRV_S: csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= (has_s ? riscv_state_pkg_PRV_S : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2]);
					riscv_state_pkg_PRV_U: csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= (has_u ? riscv_state_pkg_PRV_U : csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2]);
				endcase
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 19-:2] <= csr_wval[10:9];
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= (has_s ? csr_wval[8] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= csr_wval[7];
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 23] <= csr_wval[6];
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= (has_s ? csr_wval[5] : 1'b0);
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= csr_wval[3];
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= (has_s ? csr_wval[1] : 1'b0);
			end
			if (has_s) begin
				if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SSTATUS)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SSTATUS))) begin
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 5-:2] <= uxl_wval;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 10] <= csr_wval[19];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 11] <= csr_wval[18];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 13-:2] <= (has_ext ? csr_wval[16:15] : 2'b00);
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 15-:2] <= (has_fpu ? csr_wval[14:13] : 2'b00);
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= csr_wval[7];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= csr_wval[5];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= csr_wval[1];
				end
			end
			if (!id_insn_i[33] && !bu_flush_i)
				case (id_insn_i[31-:32])
					riscv_opcodes_pkg_MRET: begin
						st_prv_o <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2];
						st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)];
						st_flush_o <= 1'b1;
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22];
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= 1'b1;
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= (has_u ? riscv_state_pkg_PRV_U : riscv_state_pkg_PRV_M);
					end
					riscv_opcodes_pkg_SRET: begin
						st_prv_o <= {1'b0, csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21]};
						st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)];
						st_flush_o <= 1'b1;
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24];
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= 1'b1;
						csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= 1'b0;
					end
				endcase
			if (wb_exceptions_i[26]) begin
				st_prv_o <= riscv_state_pkg_PRV_M;
				st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))) + 1)];
				st_flush_o <= 1'b1;
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25];
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= 1'b0;
				csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= st_prv_o;
			end
			else if ((take_interrupt && !du_stall_i) && !du_flush_i) begin
				st_flush_o <= 1'b1;
				if ((has_s && (st_prv_o >= riscv_state_pkg_PRV_S)) && ((wb_exceptions_i[25-:6] & csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)]) & 12'h333)) begin
					st_prv_o <= riscv_state_pkg_PRV_S;
					st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] & (~'h3 + (csr[(MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN - 1)] ? interrupt_cause << 2 : 0));
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= 1'b0;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= st_prv_o[0];
				end
				else begin
					st_prv_o <= riscv_state_pkg_PRV_M;
					st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) + 1)] & (~'h3 + (csr[(MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN - 1)] ? interrupt_cause << 2 : 0));
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= 1'b0;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= st_prv_o;
				end
			end
			else if (|(wb_exceptions_i[19-:20] & ~du_ee_i)) begin
				st_flush_o <= 1'b1;
				if ((has_s && (st_prv_o >= riscv_state_pkg_PRV_S)) && |(wb_exceptions_i[19-:20] & csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1)])) begin
					st_prv_o <= riscv_state_pkg_PRV_S;
					st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 24] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26] <= 1'b0;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 21] <= st_prv_o[0];
				end
				else begin
					st_prv_o <= riscv_state_pkg_PRV_M;
					st_nxt_pc_o <= csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) + 1)] & ~'h3;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 22] <= csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25];
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25] <= 1'b0;
					csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 17-:2] <= st_prv_o;
				end
			end
		end
	generate
		if (MXLEN == 32) begin : genblk2
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= 'h0;
					csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= 'h0;
				end
				else begin
					if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MCYCLE)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MCYCLE)))
						csr[(128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 32-:32] <= csr_wval;
					else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MCYCLEH)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MCYCLEH)))
						csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] <= csr_wval;
					else
						csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] + 'h1;
					if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MINSTRET)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MINSTRET)))
						csr[(64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - 32-:32] <= csr_wval;
					else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MINSTRETH)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MINSTRETH)))
						csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:32] <= csr_wval;
					else
						csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] + wb_insn_i[32];
				end
		end
		else begin : genblk2
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= 'h0;
					csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= 'h0;
				end
				else begin
					if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MCYCLE)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MCYCLE)))
						csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr_wval[63:0];
					else
						csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr[128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) ? ((128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))) + 1 : ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) - (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] + 'h1;
					if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MINSTRET)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MINSTRET)))
						csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr_wval[63:0];
					else
						csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] <= csr[64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))-:((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) ? ((64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))) - (64 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))) + 1)] + wb_insn_i[32];
				end
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))) + 1)] <= MNMIVEC_DEFAULT;
		else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MNMIVEC)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MNMIVEC)))
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))) + 1)] <= {csr_wval[MXLEN - 1:2], 2'b00};
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) + 1)] <= MTVEC_DEFAULT;
		else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MTVEC)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MTVEC)))
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) + 1)] <= csr_wval & ~'h2;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) + 1)] <= 'h0;
		else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MCOUNTEREN)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MCOUNTEREN)))
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) + 1)] <= csr_wval & 'h7;
	assign st_mcounteren_o = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))) + 1)];
	localparam riscv_state_pkg_CAUSE_MMODE_ECALL = 11;
	generate
		if (!HAS_SUPER) begin : genblk3
			wire [((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_0E164;
			assign sv2v_tmp_0E164 = 0;
			always @(*) csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_0E164;
		end
		else if (MXLEN == 32) begin
			;
		end
		else begin : genblk3
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MEDELEG)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MEDELEG))) begin
					csr[(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 32:(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 63] <= csr_wval;
					csr[(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 52] = 1'b0;
				end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MEDELEGH)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MEDELEGH)))
					csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))):(64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 31] <= csr_wval;
		end
		if (!HAS_SUPER) begin : genblk4
			wire [((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_20E71;
			assign sv2v_tmp_20E71 = 'h0;
			always @(*) csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_20E71;
		end
		else begin : genblk4
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MIDELEG)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MIDELEG)))
					csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)] <= csr_wval;
		end
	endgenerate
	localparam riscv_state_pkg_SEI = 9;
	localparam riscv_state_pkg_SSI = 1;
	localparam riscv_state_pkg_STI = 5;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			csr[16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) + 1)] <= 'h0;
			soft_seip <= 1'b0;
			soft_ueip <= 1'b0;
		end
		else begin
			csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 4] <= int_external_i[riscv_state_pkg_PRV_M];
			csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 6] <= has_s & (int_external_i[riscv_state_pkg_PRV_S] | soft_seip);
			if (((ex_csr_we_i & (ex_csr_reg_i == riscv_state_pkg_MIP)) & (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i & (du_addr_i == riscv_state_pkg_MIP)))
				soft_seip <= csr_wval[riscv_state_pkg_SEI] & has_s;
			csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 8] <= int_timer_i;
			if (((ex_csr_we_i & (ex_csr_reg_i == riscv_state_pkg_MIP)) & (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i & (du_addr_i == riscv_state_pkg_MIP)))
				csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 10] <= csr_wval[riscv_state_pkg_STI] & has_s;
			csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 12] <= int_software_i;
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MIP)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MIP)))
				csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 14] <= csr_wval[riscv_state_pkg_SSI] & has_s;
			else if (has_s) begin
				if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SIP)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SIP)))
					csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 14] <= csr_wval[riscv_state_pkg_SSI] & csr[(MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - ((MXLEN - 1) - riscv_state_pkg_SSI)];
			end
		end
	localparam riscv_state_pkg_CNT_OVF = 13;
	localparam riscv_state_pkg_MEI = 11;
	localparam riscv_state_pkg_MSI = 3;
	localparam riscv_state_pkg_MTI = 7;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			csr[16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))-:((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) ? ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
		else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MIE)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MIE))) begin
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 4] <= csr_wval[riscv_state_pkg_MEI];
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 6] <= csr_wval[riscv_state_pkg_SEI] & has_s;
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 8] <= csr_wval[riscv_state_pkg_MTI];
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 10] <= csr_wval[riscv_state_pkg_STI] & has_s;
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 12] <= csr_wval[riscv_state_pkg_MSI];
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 14] <= csr_wval[riscv_state_pkg_SSI] & has_s;
			csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 2] <= csr_wval[riscv_state_pkg_CNT_OVF];
		end
		else if (has_s) begin
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SIE)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SIE))) begin
				csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 6] <= csr_wval[riscv_state_pkg_SEI];
				csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 10] <= csr_wval[riscv_state_pkg_STI];
				csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 14] <= csr_wval[riscv_state_pkg_SSI];
			end
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) + 1)] <= 'h0;
		else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MSCRATCH)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MSCRATCH)))
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))) + 1)] <= csr_wval;
	assign st_int_o[4 + riscv_state_pkg_PRV_M[1]] = ((st_prv_o < riscv_state_pkg_PRV_M) | ((st_prv_o == riscv_state_pkg_PRV_M) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 4] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 4]);
	assign st_int_o[4 + riscv_state_pkg_PRV_S[1]] = ((st_prv_o < riscv_state_pkg_PRV_S) | ((st_prv_o == riscv_state_pkg_PRV_S) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 6] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 6]);
	assign st_int_o[0 + riscv_state_pkg_PRV_M[1]] = (((st_prv_o < riscv_state_pkg_PRV_M) | ((st_prv_o == riscv_state_pkg_PRV_M) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 12] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 12])) & ~st_int_o[4 + riscv_state_pkg_PRV_M[1]];
	assign st_int_o[0 + riscv_state_pkg_PRV_S[1]] = (((st_prv_o < riscv_state_pkg_PRV_S) | ((st_prv_o == riscv_state_pkg_PRV_S) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 14] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 14])) & ~st_int_o[4 + riscv_state_pkg_PRV_S[1]];
	assign st_int_o[2 + riscv_state_pkg_PRV_M[1]] = (((st_prv_o < riscv_state_pkg_PRV_M) | ((st_prv_o == riscv_state_pkg_PRV_M) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 25])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 8] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 8])) & ~(st_int_o[4 + riscv_state_pkg_PRV_M[1]] | st_int_o[0 + riscv_state_pkg_PRV_M[1]]);
	assign st_int_o[2 + riscv_state_pkg_PRV_S[1]] = (((st_prv_o < riscv_state_pkg_PRV_S) | ((st_prv_o == riscv_state_pkg_PRV_S) & csr[(119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - 26])) & (csr[(16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))) - 10] & csr[(16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))) - 10])) & ~(st_int_o[4 + riscv_state_pkg_PRV_S[1]] | st_int_o[0 + riscv_state_pkg_PRV_S[1]]);
	assign trap_cause = find_first_one(wb_exceptions_i[19-:20] & ~du_ee_i);
	assign interrupt_cause = find_first_one(wb_exceptions_i[25-:6] & ~du_ie_i);
	assign take_interrupt = |(wb_exceptions_i[25-:6] & ~du_ie_i);
	assign du_exceptions_o = du_ee_i & wb_exceptions_i[19-:20];
	assign du_interrupts_o = du_ie_i & wb_exceptions_i[25-:6];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)] <= 'h0;
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
			csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)] <= 'h0;
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
			csr[MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) + 1)] <= 'h0;
			csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
		end
		else begin
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MEPC)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MEPC)))
				csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)] <= {csr_wval[MXLEN - 1:2], csr_wval[1] & has_rvc, 1'b0};
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SEPC)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SEPC)))
				csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= {csr_wval[MXLEN - 1:2], csr_wval[1] & has_rvc, 1'b0};
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MCAUSE)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MCAUSE)))
				csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)] <= csr_wval;
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SCAUSE)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SCAUSE)))
				csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= csr_wval;
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_MTVAL)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_MTVAL)))
				csr[MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) + 1)] <= csr_wval;
			if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_STVAL)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_STVAL)))
				csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= csr_wval;
			if (wb_exceptions_i[26]) begin
				csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)] <= (bu_flush_i ? bu_nxt_pc_i : wb_pc_i);
				csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)] <= (1 << (MXLEN - 1)) | 'h0;
			end
			else if (take_interrupt) begin
				if ((has_s && (st_prv_o >= riscv_state_pkg_PRV_S)) && ((wb_exceptions_i[25-:6] & csr[MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) + 1)]) & 12'h333)) begin
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= (1 << (MXLEN - 1)) | interrupt_cause;
					if (!st_flush_o)
						csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= wb_pc_i;
				end
				else begin
					csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)] <= (1 << (MXLEN - 1)) | interrupt_cause;
					if (!st_flush_o)
						csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)] <= wb_pc_i;
				end
			end
			else if (|(wb_exceptions_i[19-:20] & ~du_ee_i)) begin
				if ((has_s && (st_prv_o >= riscv_state_pkg_PRV_S)) && |(wb_exceptions_i[19-:20] & csr[64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))-:((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) ? ((64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))) - (64 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))) + 1)])) begin
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= wb_pc_i;
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= trap_cause;
					if (wb_exceptions_i[2])
						csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= wb_insn_i[31-:32];
					else
						csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= wb_badaddr_i;
				end
				else begin
					csr[MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))) + 1)] <= wb_pc_i;
					csr[MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) >= (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))) + 1 : ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) - (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))) + 1)] <= trap_cause;
					if (wb_exceptions_i[2])
						csr[MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) + 1)] <= wb_insn_i[31-:32];
					else
						csr[MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))-:((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) >= (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) ? ((MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))) - (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))) + 1 : ((16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))) - (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))) + 1)] <= wb_badaddr_i;
				end
			end
		end
	genvar _gv_idx_1;
	localparam riscv_state_pkg_PMPCFG_MASK = 8'h9f;
	generate
		if (MXLEN > 64) begin : genblk5
			for (_gv_idx_1 = 0; _gv_idx_1 < 16; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg0
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG0)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG0))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[idx * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
		end
		else if (MXLEN > 32) begin : genblk5
			for (_gv_idx_1 = 0; _gv_idx_1 < 8; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg0
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG0)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG0))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[0 + (idx * 8)+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 8; _gv_idx_1 < 16; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg2
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG2)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG2))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[(idx - 8) * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 0; _gv_idx_1 < 16; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpaddr
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					if (idx == 15) begin : genblk1
						always @(posedge clk_i or negedge rst_ni)
							if (!rst_ni)
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= 'h0;
							else if ((((ex_csr_we_i && (ex_csr_reg_i == (riscv_state_pkg_PMPADDR0 + idx))) && (st_prv_o == riscv_state_pkg_PRV_M)) && !csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))]) || (du_we_csr_i && (du_addr_i == (riscv_state_pkg_PMPADDR0 + idx))))
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= {10'h000, csr_wval[53:0]};
					end
					else begin : genblk1
						always @(posedge clk_i or negedge rst_ni)
							if (!rst_ni)
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= 'h0;
							else if (((((ex_csr_we_i && (ex_csr_reg_i == (riscv_state_pkg_PMPADDR0 + idx))) && (st_prv_o == riscv_state_pkg_PRV_M)) && !csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))]) && !((csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (((idx + 1) * 8) + 4))-:2] == 2'd1) && csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (((idx + 1) * 8) + 7))])) || (du_we_csr_i && (du_addr_i == (riscv_state_pkg_PMPADDR0 + idx))))
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= {10'h000, csr_wval[53:0]};
					end
				end
				else begin : genblk1
					wire [MXLEN * 1:1] sv2v_tmp_800AB;
					assign sv2v_tmp_800AB = 'h0;
					always @(*) csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] = sv2v_tmp_800AB;
				end
			end
		end
		else begin : genblk5
			for (_gv_idx_1 = 0; _gv_idx_1 < 4; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg0
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG0)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG0))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[idx * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 4; _gv_idx_1 < 8; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg1
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG1)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG1))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[(idx - 4) * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 8; _gv_idx_1 < 12; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg2
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG2)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG2))) begin
							if (!csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[(idx - 8) * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 12; _gv_idx_1 < 16; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpcfg3
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= 'h0;
						else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_PMPCFG3)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_PMPCFG3))) begin
							if ((idx < PMP_CNT) && !csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))])
								csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] <= csr_wval[(idx - 12) * 8+:8] & riscv_state_pkg_PMPCFG_MASK;
						end
				end
				else begin : genblk1
					wire [8:1] sv2v_tmp_112B4;
					assign sv2v_tmp_112B4 = 'h0;
					always @(*) csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (idx * 8))+:8] = sv2v_tmp_112B4;
				end
			end
			for (_gv_idx_1 = 0; _gv_idx_1 < 16; _gv_idx_1 = _gv_idx_1 + 1) begin : gen_pmpaddr
				localparam idx = _gv_idx_1;
				if (idx < PMP_CNT) begin : genblk1
					if (idx == 15) begin : genblk1
						always @(posedge clk_i or negedge rst_ni)
							if (!rst_ni)
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= 'h0;
							else if ((((ex_csr_we_i && (ex_csr_reg_i == (riscv_state_pkg_PMPADDR0 + idx))) && (st_prv_o == riscv_state_pkg_PRV_M)) && !csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))]) || (du_we_csr_i && (du_addr_i == (riscv_state_pkg_PMPADDR0 + idx))))
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= csr_wval;
					end
					else begin : genblk1
						always @(posedge clk_i or negedge rst_ni)
							if (!rst_ni)
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= 'h0;
							else if (((((ex_csr_we_i && (ex_csr_reg_i == (riscv_state_pkg_PMPADDR0 + idx))) && (st_prv_o == riscv_state_pkg_PRV_M)) && !csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - ((idx * 8) + 7))]) && !((csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (((idx + 1) * 8) + 4))-:2] == 2'd1) && csr[(128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (127 - (((idx + 1) * 8) + 7))])) || (du_we_csr_i && (du_addr_i == (riscv_state_pkg_PMPADDR0 + idx))))
								csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] <= csr_wval;
					end
				end
				else begin : genblk1
					wire [MXLEN * 1:1] sv2v_tmp_800AB;
					assign sv2v_tmp_800AB = 'h0;
					always @(*) csr[((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (((16 * MXLEN) - 1) - (idx * MXLEN))+:MXLEN] = sv2v_tmp_800AB;
				end
			end
		end
	endgenerate
	assign st_pmpcfg_o = csr[128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))-:((128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) >= ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))) ? ((128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))) + 1 : (((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))) - (128 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))) + 1)];
	assign st_pmpaddr_o = csr[(16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))-:(((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))) ? (((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))) - ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) + 1)];
	generate
		if (HAS_SUPER) begin : genblk6
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= STVEC_DEFAULT;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_STVEC)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_STVEC)))
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= csr_wval & ~'h2;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SCOUNTEREN)) && (st_prv_o == riscv_state_pkg_PRV_M)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SCOUNTEREN)))
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= csr_wval & 'h7;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SSCRATCH)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SSCRATCH)))
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= csr_wval;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= 'h0;
				else if (((ex_csr_we_i && (ex_csr_reg_i == riscv_state_pkg_SATP)) && (st_prv_o >= riscv_state_pkg_PRV_S)) || (du_we_csr_i && (du_addr_i == riscv_state_pkg_SATP)))
					csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] <= ex_csr_wval_i;
		end
		else begin : genblk6
			wire [((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_8AA43;
			assign sv2v_tmp_8AA43 = 'h0;
			always @(*) csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_8AA43;
			wire [((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_22EC8;
			assign sv2v_tmp_22EC8 = 'h0;
			always @(*) csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_22EC8;
			wire [((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_4A680;
			assign sv2v_tmp_4A680 = 'h0;
			always @(*) csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_4A680;
			wire [((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_458E7;
			assign sv2v_tmp_458E7 = 'h0;
			always @(*) csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_458E7;
		end
	endgenerate
	assign st_scounteren_o = csr[MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)];
	generate
		if (HAS_USER) begin
			;
		end
		else begin : genblk7
			wire [((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_04475;
			assign sv2v_tmp_04475 = 'h0;
			always @(*) csr[200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))-:((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >= (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) ? ((200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1 : ((192 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) - (200 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (15 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (119 + (MXLEN + (16 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (16 + (MXLEN + (MXLEN + (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) + 1)] = sv2v_tmp_04475;
			wire [((256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) >= (192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))) ? ((256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))) + 1 : ((192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))) - (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))) + 1) * 1:1] sv2v_tmp_23F22;
			assign sv2v_tmp_23F22 = 'h0;
			always @(*) csr[256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))-:((256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) >= (192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))) ? ((256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1)))))))))))))))))))))) - (192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0))))))))))))))))))))))) + 1 : ((192 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + 0)))))))))))))))))))))) - (256 + ((16 * MXLEN) + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (128 + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN + (MXLEN - 1))))))))))))))))))))))) + 1)] = sv2v_tmp_23F22;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module riscv_wb (
	rst_ni,
	clk_i,
	wb_stall_o,
	mem_pc_i,
	wb_pc_o,
	mem_insn_i,
	wb_insn_o,
	mem_exceptions_i,
	wb_exceptions_o,
	wb_badaddr_o,
	mem_r_i,
	mem_memadr_i,
	dmem_ack_i,
	dmem_err_i,
	dmem_q_i,
	dmem_misaligned_i,
	dmem_page_fault_i,
	wb_memq_o,
	wb_dst_o,
	wb_r_o,
	wb_we_o
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	input wire rst_ni;
	input wire clk_i;
	output reg wb_stall_o;
	input wire [MXLEN - 1:0] mem_pc_i;
	output reg [MXLEN - 1:0] wb_pc_o;
	input wire [34:0] mem_insn_i;
	output reg [34:0] wb_insn_o;
	input wire [27:0] mem_exceptions_i;
	output reg [27:0] wb_exceptions_o;
	output reg [MXLEN - 1:0] wb_badaddr_o;
	input wire [MXLEN - 1:0] mem_r_i;
	input wire [MXLEN - 1:0] mem_memadr_i;
	input wire dmem_ack_i;
	input wire dmem_err_i;
	input wire [MXLEN - 1:0] dmem_q_i;
	input wire dmem_misaligned_i;
	input wire dmem_page_fault_i;
	output reg [MXLEN - 1:0] wb_memq_o;
	output reg [4:0] wb_dst_o;
	output reg [MXLEN - 1:0] wb_r_o;
	output reg wb_we_o;
	wire [14:0] opcR;
	wire [6:2] opcode;
	wire [4:0] dst;
	reg [27:0] exceptions;
	wire [MXLEN - 1:0] dmem_q;
	wire [7:0] m_qb;
	wire [15:0] m_qh;
	wire [31:0] m_qw;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_pc_o <= PC_INIT;
		else if (!wb_stall_o)
			wb_pc_o <= mem_pc_i;
	always @(posedge clk_i)
		if (!wb_stall_o)
			wb_insn_o[31-:32] <= mem_insn_i[31-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_insn_o[34] <= 1'b0;
		else if (!wb_stall_o)
			wb_insn_o[34] <= mem_insn_i[34];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_insn_o[33] <= 1'b1;
		else if (wb_exceptions_o[27])
			wb_insn_o[33] <= 1'b1;
		else if (!wb_stall_o)
			wb_insn_o[33] <= mem_insn_i[33];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_insn_o[32] <= 'h0;
		else if (wb_exceptions_o[27])
			wb_insn_o[32] <= 'h0;
		else if (wb_stall_o)
			wb_insn_o[32] <= 'h0;
		else
			wb_insn_o[32] <= mem_insn_i[32];
	function [14:0] riscv_opcodes_pkg_decode_opcR;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_opcR = {instr[31-:7], instr[14-:3], instr[6-:5]};
	endfunction
	assign opcR = riscv_opcodes_pkg_decode_opcR(mem_insn_i[31-:32]);
	function [4:0] riscv_opcodes_pkg_decode_rd;
		input reg [31:0] instr;
		riscv_opcodes_pkg_decode_rd = instr[11-:5];
	endfunction
	assign dst = riscv_opcodes_pkg_decode_rd(mem_insn_i[31-:32]);
	localparam [6:2] riscv_opcodes_pkg_OPC_LOAD = 5'b00000;
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE = 5'b01000;
	always @(*) begin
		if (_sv2v_0)
			;
		exceptions = mem_exceptions_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_LOAD) && !mem_insn_i[33])
			exceptions[4] = dmem_misaligned_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_STORE) && !mem_insn_i[33])
			exceptions[6] = dmem_misaligned_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_LOAD) && !mem_insn_i[33])
			exceptions[5] = dmem_err_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_STORE) && !mem_insn_i[33])
			exceptions[7] = dmem_err_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_LOAD) && !mem_insn_i[33])
			exceptions[13] = dmem_page_fault_i;
		if ((opcR[4-:5] == riscv_opcodes_pkg_OPC_STORE) && !mem_insn_i[33])
			exceptions[15] = dmem_page_fault_i;
		exceptions[27] = (|exceptions[19-:20] | (|exceptions[25-:6])) | exceptions[26];
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_exceptions_o <= 'h0;
		else if (!wb_stall_o)
			wb_exceptions_o <= exceptions;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_badaddr_o <= 'h0;
		else if ((((((exceptions[4] || exceptions[6]) || exceptions[5]) || exceptions[7]) || exceptions[13]) || exceptions[15]) || exceptions[3])
			wb_badaddr_o <= mem_memadr_i;
		else if (exceptions[2])
			wb_badaddr_o <= {{MXLEN - 32 {1'b0}}, mem_insn_i[31-:32]};
		else
			wb_badaddr_o <= {MXLEN {1'b0}};
	always @(*) begin
		if (_sv2v_0)
			;
		casex ({mem_insn_i[33], mem_exceptions_i[27], wb_exceptions_o[27], opcR[4-:5]})
			{3'b000, riscv_opcodes_pkg_OPC_LOAD}: wb_stall_o = ~(((dmem_ack_i | dmem_err_i) | dmem_misaligned_i) | dmem_page_fault_i);
			{3'b000, riscv_opcodes_pkg_OPC_STORE}: wb_stall_o = ~(((dmem_ack_i | dmem_err_i) | dmem_misaligned_i) | dmem_page_fault_i);
			default: wb_stall_o = 1'b0;
		endcase
	end
	assign dmem_q = dmem_q_i;
	localparam [14:0] riscv_opcodes_pkg_LB = 15'bzzzzzzz00000000;
	localparam [14:0] riscv_opcodes_pkg_LBU = 15'bzzzzzzz10000000;
	localparam [14:0] riscv_opcodes_pkg_LD = 15'bzzzzzzz01100000;
	localparam [14:0] riscv_opcodes_pkg_LH = 15'bzzzzzzz00100000;
	localparam [14:0] riscv_opcodes_pkg_LHU = 15'bzzzzzzz10100000;
	localparam [14:0] riscv_opcodes_pkg_LW = 15'bzzzzzzz01000000;
	localparam [14:0] riscv_opcodes_pkg_LWU = 15'bzzzzzzz11000000;
	generate
		if (MXLEN == 64) begin : genblk1
			wire [MXLEN - 1:0] m_qd;
			assign m_qb = dmem_q >> (8 * mem_memadr_i[2:0]);
			assign m_qh = dmem_q >> (8 * mem_memadr_i[2:0]);
			assign m_qw = dmem_q >> (8 * mem_memadr_i[2:0]);
			assign m_qd = dmem_q;
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_LB: wb_memq_o = {{MXLEN - 8 {m_qb[7]}}, m_qb};
					riscv_opcodes_pkg_LH: wb_memq_o = {{MXLEN - 16 {m_qh[15]}}, m_qh};
					riscv_opcodes_pkg_LW: wb_memq_o = {{MXLEN - 32 {m_qw[31]}}, m_qw};
					riscv_opcodes_pkg_LD: wb_memq_o = {m_qd};
					riscv_opcodes_pkg_LBU: wb_memq_o = {{MXLEN - 8 {1'b0}}, m_qb};
					riscv_opcodes_pkg_LHU: wb_memq_o = {{MXLEN - 16 {1'b0}}, m_qh};
					riscv_opcodes_pkg_LWU: wb_memq_o = {{MXLEN - 32 {1'b0}}, m_qw};
					default: wb_memq_o = 'hx;
				endcase
			end
		end
		else begin : genblk1
			assign m_qb = dmem_q >> (8 * mem_memadr_i[1:0]);
			assign m_qh = dmem_q >> (8 * mem_memadr_i[1:0]);
			assign m_qw = dmem_q;
			always @(*) begin
				if (_sv2v_0)
					;
				casex (opcR)
					riscv_opcodes_pkg_LB: wb_memq_o = {{MXLEN - 8 {m_qb[7]}}, m_qb};
					riscv_opcodes_pkg_LH: wb_memq_o = {{MXLEN - 16 {m_qh[15]}}, m_qh};
					riscv_opcodes_pkg_LW: wb_memq_o = {m_qw};
					riscv_opcodes_pkg_LBU: wb_memq_o = {{MXLEN - 8 {1'b0}}, m_qb};
					riscv_opcodes_pkg_LHU: wb_memq_o = {{MXLEN - 16 {1'b0}}, m_qh};
					default: wb_memq_o = 'hx;
				endcase
			end
		end
	endgenerate
	always @(posedge clk_i)
		if (!wb_stall_o)
			wb_dst_o <= dst;
	always @(posedge clk_i)
		if (!wb_stall_o)
			casex (opcR[4-:5])
				riscv_opcodes_pkg_OPC_LOAD: wb_r_o <= wb_memq_o;
				default: wb_r_o <= mem_r_i;
			endcase
	localparam [6:2] riscv_opcodes_pkg_OPC_BRANCH = 5'b11000;
	localparam [6:2] riscv_opcodes_pkg_OPC_MISC_MEM = 5'b00011;
	localparam [6:2] riscv_opcodes_pkg_OPC_STORE_FP = 5'b01001;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wb_we_o <= 'b0;
		else if (exceptions[27] || wb_exceptions_o[27])
			wb_we_o <= 'b0;
		else
			casex (opcR[4-:5])
				riscv_opcodes_pkg_OPC_MISC_MEM: wb_we_o <= 'b0;
				riscv_opcodes_pkg_OPC_LOAD: wb_we_o <= (~mem_insn_i[33] & |dst) & ~wb_stall_o;
				riscv_opcodes_pkg_OPC_STORE: wb_we_o <= 'b0;
				riscv_opcodes_pkg_OPC_STORE_FP: wb_we_o <= 'b0;
				riscv_opcodes_pkg_OPC_BRANCH: wb_we_o <= 'b0;
				default: wb_we_o <= ~mem_insn_i[33] & |dst;
			endcase
	initial _sv2v_0 = 0;
endmodule
module rl_ram_1r1w_generic (
	rst_ni,
	clk_i,
	waddr_i,
	din_i,
	we_i,
	be_i,
	raddr_i,
	dout_o
);
	parameter ABITS = 10;
	parameter DBITS = 32;
	parameter INIT_FILE = "";
	input rst_ni;
	input clk_i;
	input [ABITS - 1:0] waddr_i;
	input [DBITS - 1:0] din_i;
	input we_i;
	input [((DBITS + 7) / 8) - 1:0] be_i;
	input [ABITS - 1:0] raddr_i;
	output reg [DBITS - 1:0] dout_o;
	genvar _gv_i_3;
	reg [DBITS - 1:0] mem_array [(2 ** ABITS) - 1:0];
	initial if (INIT_FILE != "") begin
		$display("INFO   : Loading %s (%m)", INIT_FILE);
		$readmemh(INIT_FILE, mem_array);
	end
	generate
		for (_gv_i_3 = 0; _gv_i_3 < ((DBITS + 7) / 8); _gv_i_3 = _gv_i_3 + 1) begin : write
			localparam i = _gv_i_3;
			if (((i * 8) + 8) > DBITS) begin : genblk1
				always @(posedge clk_i)
					if (we_i && be_i[i])
						mem_array[waddr_i][DBITS - 1:i * 8] <= din_i[DBITS - 1:i * 8];
			end
			else begin : genblk1
				always @(posedge clk_i)
					if (we_i && be_i[i])
						mem_array[waddr_i][i * 8+:8] <= din_i[i * 8+:8];
			end
		end
	endgenerate
	always @(posedge clk_i) dout_o <= mem_array[raddr_i];
endmodule
module rl_ram_1r1w (
	rst_ni,
	clk_i,
	waddr_i,
	din_i,
	we_i,
	be_i,
	raddr_i,
	re_i,
	dout_o
);
	parameter ABITS = 10;
	parameter DBITS = 32;
	parameter TECHNOLOGY = "GENERIC";
	parameter INIT_FILE = "";
	parameter RW_CONTENTION = "BYPASS";
	input rst_ni;
	input clk_i;
	input [ABITS - 1:0] waddr_i;
	input [DBITS - 1:0] din_i;
	input we_i;
	input [((DBITS + 7) / 8) - 1:0] be_i;
	input [ABITS - 1:0] raddr_i;
	input re_i;
	output wire [DBITS - 1:0] dout_o;
	wire contention;
	reg contention_reg;
	wire [DBITS - 1:0] mem_dout;
	reg [DBITS - 1:0] din_dly;
	generate
		if ((TECHNOLOGY == "N3XS") || (TECHNOLOGY == "n3xs")) begin : genblk1
			rl_ram_1r1w_easic_n3xs #(
				.ABITS(ABITS),
				.DBITS(DBITS)
			) ram_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.waddr_i(waddr_i),
				.din_i(din_i),
				.we_i(we_i),
				.be_i(be_i),
				.raddr_i(raddr_i),
				.re_i(~contention),
				.dout_o(mem_dout)
			);
		end
		else if ((TECHNOLOGY == "N3X") || (TECHNOLOGY == "n3x")) begin : genblk1
			rl_ram_1r1w_easic_n3x #(
				.ABITS(ABITS),
				.DBITS(DBITS)
			) ram_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.waddr_i(waddr_i),
				.din_i(din_i),
				.we_i(we_i),
				.be_i(be_i),
				.raddr_i(raddr_i),
				.re_i(~contention),
				.dout_o(mem_dout)
			);
		end
		else if (TECHNOLOGY == "LATTICE_DPRAM") begin : genblk1
			rl_ram_1r1w_lattice #(
				.ABITS(ABITS),
				.DBITS(DBITS),
				.INIT_FILE(INIT_FILE)
			) ram_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.waddr_i(waddr_i),
				.din_i(din_i),
				.we_i(we_i),
				.be_i(be_i),
				.raddr_i(raddr_i),
				.dout_o(mem_dout)
			);
		end
		else begin : genblk1
			initial $display("INFO   : No memory technology specified. Using generic inferred memory (%m)");
			rl_ram_1r1w_generic #(
				.ABITS(ABITS),
				.DBITS(DBITS),
				.INIT_FILE(INIT_FILE)
			) ram_inst(
				.rst_ni(rst_ni),
				.clk_i(clk_i),
				.waddr_i(waddr_i),
				.din_i(din_i),
				.we_i(we_i),
				.be_i(be_i),
				.raddr_i(raddr_i),
				.dout_o(mem_dout)
			);
		end
		if (RW_CONTENTION == "DONT_CARE") begin : genblk2
			assign dout_o = mem_dout;
		end
		else begin : genblk2
			assign contention = (re_i & we_i) & (raddr_i == waddr_i);
			always @(posedge clk_i) begin
				contention_reg <= contention;
				din_dly <= din_i;
			end
			assign dout_o = (contention_reg ? din_dly : mem_dout);
		end
	endgenerate
endmodule