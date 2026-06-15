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
				$display("Error [%0t] /mnt/openlane_disk/asap7-synthesis-rv12-eth_top/rv12/src/verilog/core/memory/riscv_pmpchk.sv:75:20 - riscv_pmpchk.size2bytes.<unnamed_block>\n msg: ", $time, "Illegal biu_size_t");
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
