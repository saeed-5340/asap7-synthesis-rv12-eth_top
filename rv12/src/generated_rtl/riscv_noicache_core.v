module riscv_noicache_core (
	rst_ni,
	clk_i,
	if_nxt_pc_i,
	if_req_i,
	if_ack_o,
	if_prot_i,
	if_flush_i,
	if_parcel_pc_o,
	if_parcel_o,
	if_parcel_valid_o,
	if_parcel_misaligned_o,
	if_parcel_error_o,
	cm_dc_clean_rdy_i,
	st_prv_i,
	biu_stb_o,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_we_o,
	biu_prot_o,
	biu_d_o,
	biu_q_i,
	biu_ack_i,
	biu_err_i,
	biu_tagi_o,
	biu_tago_i
);
	parameter XLEN = 32;
	parameter PLEN = XLEN;
	parameter PARCEL_SIZE = 16;
	parameter HAS_RVC = 0;
	parameter DEPTH = 2;
	parameter BIUTAG_SIZE = $clog2(XLEN / PARCEL_SIZE);
	input rst_ni;
	input clk_i;
	input [XLEN - 1:0] if_nxt_pc_i;
	input if_req_i;
	output wire if_ack_o;
	input wire [2:0] if_prot_i;
	input if_flush_i;
	output wire [XLEN - 1:0] if_parcel_pc_o;
	output wire [XLEN - 1:0] if_parcel_o;
	output wire [(XLEN / PARCEL_SIZE) - 1:0] if_parcel_valid_o;
	output wire if_parcel_misaligned_o;
	output wire if_parcel_error_o;
	input cm_dc_clean_rdy_i;
	input [1:0] st_prv_i;
	output wire biu_stb_o;
	input biu_stb_ack_i;
	input biu_d_ack_i;
	output wire [PLEN - 1:0] biu_adri_o;
	input [PLEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire biu_we_o;
	output wire [2:0] biu_prot_o;
	output wire [XLEN - 1:0] biu_d_o;
	input [XLEN - 1:0] biu_q_i;
	input biu_ack_i;
	input biu_err_i;
	output wire [BIUTAG_SIZE - 1:0] biu_tagi_o;
	input [BIUTAG_SIZE - 1:0] biu_tago_i;
	reg if_flush_dly;
	reg [$clog2(DEPTH):0] inflight;
	reg [$clog2(DEPTH):0] discard;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_flush_dly <= 1'b0;
		else
			if_flush_dly <= if_flush_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inflight <= 'h0;
		else
			(* full_case, parallel_case *)
			case ({biu_stb_ack_i, biu_ack_i | biu_err_i})
				2'b01: inflight <= inflight - 1;
				2'b10: inflight <= inflight + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			discard <= 'h0;
		else if (if_flush_i) begin
			if (|inflight && (biu_ack_i | biu_err_i))
				discard <= inflight - 1;
			else
				discard <= inflight;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	assign if_ack_o = cm_dc_clean_rdy_i & biu_stb_ack_i;
	assign if_parcel_misaligned_o = (HAS_RVC != 0 ? if_parcel_pc_o[0] : |if_parcel_pc_o[1:0]);
	assign if_parcel_error_o = biu_err_i;
	assign if_parcel_valid_o = (((cm_dc_clean_rdy_i & ~(if_flush_i | if_flush_dly)) & biu_ack_i) & ~|discard ? {XLEN / PARCEL_SIZE {1'b1}} << biu_tago_i : {XLEN / PARCEL_SIZE {1'b0}});
	assign if_parcel_pc_o = {{((PLEN - (BIUTAG_SIZE + 1)) - BIUTAG_SIZE) - 1 {1'b0}}, biu_adro_i[PLEN - 1:BIUTAG_SIZE + 1], biu_tago_i, 1'b0};
	assign if_parcel_o = biu_q_i;
	assign biu_stb_o = (cm_dc_clean_rdy_i & ~if_flush_i) & if_req_i;
	generate
		if (PLEN <= XLEN) begin : genblk1
			assign biu_adri_o = if_nxt_pc_i[PLEN - 1:0] & (XLEN == 64 ? ~'h7 : ~'h3);
		end
		else begin : genblk1
			assign biu_adri_o = {{PLEN - XLEN {1'b0}}, if_nxt_pc_i} & (XLEN == 64 ? ~'h7 : ~'h3);
		end
	endgenerate
	assign biu_tagi_o = if_nxt_pc_i[1+:BIUTAG_SIZE];
	assign biu_size_o = (XLEN == 64 ? 3'b011 : 3'b010);
	assign biu_lock_o = 1'b0;
	assign biu_prot_o = if_prot_i;
	assign biu_we_o = 1'b0;
	assign biu_d_o = 'h0;
	assign biu_type_o = 3'b001;
endmodule
