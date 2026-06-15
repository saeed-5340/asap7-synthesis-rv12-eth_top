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
