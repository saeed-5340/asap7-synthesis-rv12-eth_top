module riscv_parcel_queue (
	rst_ni,
	clk_i,
	flush_i,
	parcel_i,
	parcel_valid_i,
	parcel_misaligned_i,
	parcel_page_fault_i,
	parcel_error_i,
	parcel_rd_i,
	parcel_q_o,
	parcel_misaligned_o,
	parcel_page_fault_o,
	parcel_error_o,
	empty_o,
	full_o,
	almost_empty_o,
	almost_full_o
);
	reg _sv2v_0;
	parameter DEPTH = 2;
	parameter WR_PARCELS = 2;
	parameter RD_PARCELS = 2;
	parameter ALMOST_EMPTY_THRESHOLD = 0;
	parameter ALMOST_FULL_THRESHOLD = DEPTH;
	localparam PARCEL_SIZE = 16;
	localparam WR_PARCEL_BITS = WR_PARCELS * PARCEL_SIZE;
	localparam RD_PARCEL_BITS = RD_PARCELS * PARCEL_SIZE;
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire [WR_PARCEL_BITS - 1:0] parcel_i;
	input wire [WR_PARCELS - 1:0] parcel_valid_i;
	input wire parcel_misaligned_i;
	input wire parcel_page_fault_i;
	input wire parcel_error_i;
	input wire [$clog2(RD_PARCELS):0] parcel_rd_i;
	output wire [RD_PARCEL_BITS - 1:0] parcel_q_o;
	output wire parcel_misaligned_o;
	output wire parcel_page_fault_o;
	output wire parcel_error_o;
	output reg empty_o;
	output reg full_o;
	output reg almost_empty_o;
	output reg almost_full_o;
	localparam EMPTY_THRESHOLD = 1;
	localparam FULL_THRESHOLD = DEPTH - WR_PARCELS;
	localparam ALMOST_EMPTY_THRESHOLD_CHECK = (ALMOST_EMPTY_THRESHOLD <= 0 ? EMPTY_THRESHOLD : ALMOST_EMPTY_THRESHOLD + 1);
	localparam ALMOST_FULL_THRESHOLD_CHECK = (ALMOST_FULL_THRESHOLD >= DEPTH ? FULL_THRESHOLD : ALMOST_FULL_THRESHOLD - 2);
	function [$clog2(WR_PARCELS):0] align_cnt;
		input [WR_PARCELS - 1:0] a;
		reg found_one;
		begin
			found_one = 0;
			align_cnt = 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] n;
				for (n = 0; n < WR_PARCELS; n = n + 1)
					if (!found_one) begin
						if (!a[n])
							align_cnt = align_cnt + 1;
						else
							found_one = 1;
					end
			end
		end
	endfunction
	function [$clog2(WR_PARCELS):0] count_ones;
		input [WR_PARCELS - 1:0] a;
		begin
			count_ones = 0;
			begin : sv2v_autoblock_2
				reg signed [31:0] n;
				for (n = 0; n < WR_PARCELS; n = n + 1)
					if (a[n])
						count_ones = count_ones + 1;
			end
		end
	endfunction
	reg [(DEPTH * 16) - 1:0] parcel_sr;
	reg [(DEPTH * 16) - 1:0] nxt_parcel_sr;
	reg [(DEPTH * 3) - 1:0] parcel_st_sr;
	reg [((DEPTH + RD_PARCELS) * 3) - 1:0] nxt_parcel_st_sr;
	wire [WR_PARCEL_BITS - 1:0] align_parcel;
	wire [$clog2(RD_PARCEL_BITS):0] rd_shift;
	reg [$clog2(DEPTH):0] wadr;
	wire [$clog2(DEPTH):0] nxt_wadr;
	assign align_parcel = parcel_i >> (align_cnt(parcel_valid_i) * PARCEL_SIZE);
	assign nxt_wadr = (wadr + count_ones(parcel_valid_i)) - parcel_rd_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wadr <= 'h0;
		else if (flush_i)
			wadr <= 'h0;
		else
			wadr <= nxt_wadr;
	assign rd_shift = parcel_rd_i * PARCEL_SIZE;
	always @(*) begin
		if (_sv2v_0)
			;
		nxt_parcel_sr = parcel_sr;
		if (|parcel_valid_i) begin : sv2v_autoblock_3
			reg signed [31:0] n;
			for (n = 0; n < WR_PARCELS; n = n + 1)
				nxt_parcel_sr[(wadr + n) * 16+:16] = align_parcel[n * PARCEL_SIZE+:PARCEL_SIZE];
		end
		nxt_parcel_sr = nxt_parcel_sr >> rd_shift;
	end
	localparam [31:0] riscv_opcodes_pkg_NOP = 32'h00000011;
	always @(posedge clk_i)
		if (flush_i) begin : sv2v_autoblock_4
			reg signed [31:0] n;
			for (n = 0; n < DEPTH; n = n + 2)
				parcel_sr[16 * n+:32] <= riscv_opcodes_pkg_NOP;
		end
		else
			parcel_sr <= nxt_parcel_sr;
	always @(*) begin
		if (_sv2v_0)
			;
		nxt_parcel_st_sr = parcel_st_sr;
		begin : sv2v_autoblock_5
			reg signed [31:0] n;
			for (n = 0; n < WR_PARCELS; n = n + 1)
				begin
					nxt_parcel_st_sr[((wadr + n) * 3) + 2] = parcel_misaligned_i;
					nxt_parcel_st_sr[((wadr + n) * 3) + 1] = parcel_page_fault_i;
					nxt_parcel_st_sr[(wadr + n) * 3] = parcel_error_i;
				end
		end
		nxt_parcel_st_sr = nxt_parcel_st_sr >> rd_shift;
	end
	always @(posedge clk_i)
		if (flush_i) begin : sv2v_autoblock_6
			reg signed [31:0] n;
			for (n = 0; n < DEPTH; n = n + 1)
				parcel_st_sr[n * 3+:3] <= 'h0;
		end
		else
			parcel_st_sr <= nxt_parcel_st_sr;
	assign parcel_q_o = parcel_sr[0+:16 * RD_PARCELS];
	assign parcel_misaligned_o = parcel_st_sr[2];
	assign parcel_page_fault_o = parcel_st_sr[1];
	assign parcel_error_o = parcel_st_sr[0];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			almost_empty_o <= 1'b1;
		else if (flush_i)
			almost_empty_o <= 1'b1;
		else
			almost_empty_o <= nxt_wadr < ALMOST_EMPTY_THRESHOLD_CHECK;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			empty_o <= 1'b1;
		else if (flush_i)
			empty_o <= 1'b1;
		else
			empty_o <= ~|nxt_wadr;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			almost_full_o <= 1'b0;
		else if (flush_i)
			almost_full_o <= 1'b0;
		else
			almost_full_o <= nxt_wadr > ALMOST_FULL_THRESHOLD_CHECK;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			full_o <= 1'b0;
		else if (flush_i)
			full_o <= 1'b0;
		else
			full_o <= nxt_wadr > FULL_THRESHOLD;
	initial _sv2v_0 = 0;
endmodule
