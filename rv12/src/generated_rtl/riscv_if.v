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
