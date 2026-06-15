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
				$display("Error [%0t] /mnt/openlane_disk/asap7-synthesis-rv12-eth_top/rv12/src/verilog/core/memory/riscv_pmachk.sv:82:20 - riscv_pmachk.size2bytes.<unnamed_block>\n msg: ", $time, "Illegal biu_size_t");
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
