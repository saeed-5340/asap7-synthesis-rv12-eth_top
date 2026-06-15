module riscv_cache_biu_ctrl (
	rst_ni,
	clk_i,
	flush_i,
	biucmd_i,
	biucmd_ack_o,
	biucmd_busy_o,
	biucmd_noncacheable_req_i,
	biucmd_noncacheable_ack_o,
	biucmd_tag_i,
	inflight_cnt_o,
	req_i,
	adr_i,
	size_i,
	prot_i,
	lock_i,
	we_i,
	be_i,
	d_i,
	evictbuffer_adr_i,
	evictbuffer_d_i,
	in_biubuffer_o,
	biubuffer_o,
	biu_line_o,
	biu_line_dirty_o,
	biu_stb_o,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_prot_o,
	biu_we_o,
	biu_d_o,
	biu_q_i,
	biu_ack_i,
	biu_err_i,
	biu_tagi_o,
	biu_tago_i
);
	reg _sv2v_0;
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter SIZE = 64;
	parameter BLOCK_SIZE = XLEN;
	parameter WAYS = 2;
	parameter INFLIGHT_DEPTH = 2;
	parameter BIUTAG_SIZE = 2;
	function automatic integer riscv_cache_pkg_no_of_block_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_bits = 8 * block_size;
	endfunction
	localparam BLK_BITS = riscv_cache_pkg_no_of_block_bits(BLOCK_SIZE);
	localparam INFLIGHT_BITS = $clog2(INFLIGHT_DEPTH + 1);
	input wire rst_ni;
	input wire clk_i;
	input wire flush_i;
	input wire [1:0] biucmd_i;
	output reg biucmd_ack_o;
	output reg biucmd_busy_o;
	input wire biucmd_noncacheable_req_i;
	output wire biucmd_noncacheable_ack_o;
	input wire [BIUTAG_SIZE - 1:0] biucmd_tag_i;
	output reg [INFLIGHT_BITS - 1:0] inflight_cnt_o;
	input wire req_i;
	input wire [PLEN - 1:0] adr_i;
	input wire [2:0] size_i;
	input wire [2:0] prot_i;
	input wire lock_i;
	input wire we_i;
	input wire [(XLEN / 8) - 1:0] be_i;
	input wire [XLEN - 1:0] d_i;
	input wire [PLEN - 1:0] evictbuffer_adr_i;
	input wire [BLK_BITS - 1:0] evictbuffer_d_i;
	output wire in_biubuffer_o;
	output reg [BLK_BITS - 1:0] biubuffer_o;
	output reg [BLK_BITS - 1:0] biu_line_o;
	output wire biu_line_dirty_o;
	output reg biu_stb_o;
	input wire biu_stb_ack_i;
	input wire biu_d_ack_i;
	output reg [PLEN - 1:0] biu_adri_o;
	input wire [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output reg [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire [2:0] biu_prot_o;
	output reg biu_we_o;
	output reg [XLEN - 1:0] biu_d_o;
	input wire [XLEN - 1:0] biu_q_i;
	input wire biu_ack_i;
	input wire biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input wire [BIUTAG_SIZE - 1:0] biu_tago_i;
	function automatic integer riscv_cache_pkg_no_of_sets;
		input integer cache_size;
		input integer block_size;
		input integer ways;
		riscv_cache_pkg_no_of_sets = ((cache_size * 1024) / block_size) / ways;
	endfunction
	localparam SETS = riscv_cache_pkg_no_of_sets(SIZE, BLOCK_SIZE, WAYS);
	function automatic integer riscv_cache_pkg_no_of_block_offset_bits;
		input integer block_size;
		riscv_cache_pkg_no_of_block_offset_bits = $clog2(block_size);
	endfunction
	localparam BLK_OFFS_BITS = riscv_cache_pkg_no_of_block_offset_bits(BLOCK_SIZE);
	function automatic integer riscv_cache_pkg_no_of_data_offset_bits;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_no_of_data_offset_bits = $clog2(no_of_block_bits / xlen);
	endfunction
	localparam DAT_OFFS_BITS = riscv_cache_pkg_no_of_data_offset_bits(XLEN, BLK_BITS);
	function automatic integer riscv_cache_pkg_burst_size;
		input integer xlen;
		input integer no_of_block_bits;
		riscv_cache_pkg_burst_size = no_of_block_bits / xlen;
	endfunction
	localparam BURST_SIZE = riscv_cache_pkg_burst_size(XLEN, BLK_BITS);
	localparam BURST_BITS = $clog2(BURST_SIZE);
	localparam BURST_OFFS = XLEN / 8;
	localparam BURST_LSB = $clog2(BURST_OFFS);
	function automatic [3:0] biu_type2cnt;
		input reg [2:0] biu_type;
		case (biu_type)
			3'b000: biu_type2cnt = 0;
			3'b001: biu_type2cnt = 0;
			3'b010: biu_type2cnt = 3;
			3'b011: biu_type2cnt = 3;
			3'b100: biu_type2cnt = 7;
			3'b101: biu_type2cnt = 7;
			3'b110: biu_type2cnt = 15;
			3'b111: biu_type2cnt = 15;
			default: biu_type2cnt = 4'hx;
		endcase
	endfunction
	function automatic [XLEN - 1:0] be_mux;
		input [(XLEN / 8) - 1:0] be;
		input [XLEN - 1:0] data_old;
		input [XLEN - 1:0] data_new;
		reg signed [31:0] i;
		for (i = 0; i < (XLEN / 8); i = i + 1)
			be_mux[i * 8+:8] = (be[i] ? data_new[i * 8+:8] : data_old[i * 8+:8]);
	endfunction
	genvar _gv_way_1;
	integer n;
	reg [1:0] biufsm_state;
	reg [BURST_SIZE - 1:0] biubuffer_valid;
	reg biubuffer_dirty;
	wire [DAT_OFFS_BITS - 1:0] dat_offset;
	wire biu_adro_eq_cache_adr;
	wire [XLEN - 1:0] biu_q;
	reg [PLEN - 1:0] biu_adri_hold;
	reg [XLEN - 1:0] biu_d_hold;
	reg biu_we_hold;
	reg [BURST_BITS - 1:0] burst_cnt;
	reg [INFLIGHT_BITS - 1:0] discard;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			biufsm_state <= 2'd0;
			biucmd_busy_o <= 1'b0;
		end
		else
			(* full_case, parallel_case *)
			case (biufsm_state)
				2'd0:
					(* full_case, parallel_case *)
					case (biucmd_i)
						2'h0:
							;
						2'h1: begin
							biucmd_busy_o <= 1'b1;
							if (biu_stb_ack_i)
								biufsm_state <= 2'd2;
							else
								biufsm_state <= 2'd1;
						end
						2'h2: begin
							biucmd_busy_o <= 1'b1;
							if (biu_stb_ack_i)
								biufsm_state <= 2'd2;
							else
								biufsm_state <= 2'd1;
						end
					endcase
				2'd1:
					if (biu_stb_ack_i)
						biufsm_state <= 2'd2;
				2'd2:
					if (biu_err_i || (~|burst_cnt && biu_ack_i)) begin
						biufsm_state <= 2'd0;
						biucmd_busy_o <= 1'b0;
					end
			endcase
	assign biu_adro_eq_cache_adr = biu_adro_i[PLEN - 1:BURST_LSB] == adr_i[PLEN - 1:BURST_LSB];
	assign biu_q = (we_i && biu_adro_eq_cache_adr ? be_mux(be_i, biu_q_i, d_i) : biu_q_i);
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0: begin
				if (biucmd_i == 2'h2)
					biubuffer_o <= evictbuffer_d_i >> XLEN;
				biubuffer_valid <= 'h0;
				biubuffer_dirty <= 1'b0;
			end
			2'd2:
				if (!biu_we_hold) begin
					if (biu_ack_i) begin
						biubuffer_o[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS] * XLEN+:XLEN] <= biu_q;
						biubuffer_valid[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS]] <= 1'b1;
						biubuffer_dirty <= biubuffer_dirty | we_i;
					end
				end
				else if (biu_d_ack_i) begin
					biubuffer_o <= biubuffer_o >> XLEN;
					biubuffer_valid <= 'h0;
					biubuffer_dirty <= 1'b0;
				end
			default:
				;
		endcase
	assign dat_offset = adr_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS];
	assign in_biubuffer_o = (req_i & (biu_adri_hold[PLEN - 1:BLK_OFFS_BITS] == adr_i[PLEN - 1:BLK_OFFS_BITS])) & (biubuffer_valid >> dat_offset);
	always @(*) begin
		if (_sv2v_0)
			;
		biu_line_o = biubuffer_o;
		biu_line_o[biu_adro_i[BLK_OFFS_BITS - 1-:DAT_OFFS_BITS] * XLEN+:XLEN] = biu_q;
	end
	assign biu_line_dirty_o = biubuffer_dirty | we_i;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd2: biucmd_ack_o = (~|burst_cnt & biu_ack_i) | biu_err_i;
			default: biucmd_ack_o = 1'b0;
		endcase
	end
	always @(posedge clk_i)
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0: burst_cnt <= {BURST_BITS {1'b1}};
			2'd2:
				if (biu_ack_i)
					burst_cnt <= burst_cnt - 1;
		endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inflight_cnt_o <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({biu_stb_ack_i, biu_ack_i | biu_err_i})
				2'b01: inflight_cnt_o <= inflight_cnt_o - 1;
				2'b10: inflight_cnt_o <= (inflight_cnt_o + 1) + biu_type2cnt(biu_type_o);
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			discard <= 'h0;
		else if (flush_i) begin
			if (|inflight_cnt_o && (biu_ack_i | biu_err_i))
				discard <= inflight_cnt_o - 1;
			else
				discard <= inflight_cnt_o;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	assign biucmd_noncacheable_ack_o = (biu_ack_i & ~flush_i) & ~|discard;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (biufsm_state)
			2'd0:
				(* full_case, parallel_case *)
				case (biucmd_i)
					2'h0: begin
						biu_stb_o = biucmd_noncacheable_req_i;
						biu_adri_o = adr_i[0+:PLEN];
						biu_we_o = we_i;
						biu_d_o = d_i;
					end
					2'h1: begin
						biu_stb_o = 1'b1;
						biu_adri_o = {adr_i[PLEN - 1:BURST_LSB], {BURST_LSB {1'b0}}};
						biu_we_o = 1'b0;
						biu_d_o = 'hx;
					end
					2'h2: begin
						biu_stb_o = 1'b1;
						biu_adri_o = evictbuffer_adr_i;
						biu_we_o = 1'b1;
						biu_d_o = evictbuffer_d_i[0+:XLEN];
					end
				endcase
			2'd1: begin
				biu_stb_o = 1'b1;
				biu_adri_o = biu_adri_hold;
				biu_we_o = biu_we_hold;
				biu_d_o = biu_d_hold;
			end
			2'd2: begin
				biu_stb_o = 1'b0;
				biu_adri_o = 'hx;
				biu_we_o = 1'bx;
				biu_d_o = biubuffer_o[0+:XLEN];
			end
			default: begin
				biu_stb_o = 1'b0;
				biu_adri_o = 'hx;
				biu_we_o = 1'bx;
				biu_d_o = 'hx;
			end
		endcase
	end
	always @(posedge clk_i)
		if (biufsm_state == 2'd0) begin
			biu_adri_hold <= biu_adri_o;
			biu_we_hold <= biu_we_o;
			biu_d_hold <= biu_d_o;
		end
	assign biu_tagi_o = biucmd_tag_i;
	assign biu_size_o = (biucmd_noncacheable_req_i ? size_i : (XLEN == 64 ? 3'b011 : 3'b010));
	localparam [2:0] biu_constants_pkg_PROT_CACHEABLE = 3'b100;
	localparam [2:0] biu_constants_pkg_PROT_NONCACHEABLE = 3'b000;
	assign biu_prot_o = prot_i | (biucmd_noncacheable_req_i ? biu_constants_pkg_PROT_NONCACHEABLE : biu_constants_pkg_PROT_CACHEABLE);
	assign biu_lock_o = lock_i;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((biufsm_state == 2'd0) && (biucmd_i == 2'h0))
			biu_type_o = 3'b001;
		else
			(* full_case, parallel_case *)
			case (BURST_SIZE)
				16: biu_type_o = 3'b110;
				8: biu_type_o = 3'b100;
				default: biu_type_o = 3'b010;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
