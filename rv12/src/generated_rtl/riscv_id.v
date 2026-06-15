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
