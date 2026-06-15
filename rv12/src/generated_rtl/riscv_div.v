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
