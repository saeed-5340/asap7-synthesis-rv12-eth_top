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
