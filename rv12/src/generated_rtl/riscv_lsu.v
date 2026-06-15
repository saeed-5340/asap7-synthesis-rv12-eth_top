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
