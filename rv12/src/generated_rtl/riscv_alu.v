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
