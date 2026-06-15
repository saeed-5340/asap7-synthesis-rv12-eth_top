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
