module riscv_nodcache_core (
	rst_ni,
	clk_i,
	mem_req_i,
	mem_size_i,
	mem_lock_i,
	mem_misaligned_i,
	mem_adr_i,
	mem_we_i,
	mem_d_i,
	mem_q_o,
	mem_ack_o,
	mem_err_o,
	mem_misaligned_o,
	st_prv_i,
	biu_stb_o,
	biu_adri_o,
	biu_adro_i,
	biu_size_o,
	biu_type_o,
	biu_lock_o,
	biu_we_o,
	biu_prot_o,
	biu_d_o,
	biu_q_i,
	biu_stb_ack_i,
	biu_d_ack_i,
	biu_ack_i,
	biu_err_i
);
	parameter XLEN = 32;
	parameter ALEN = XLEN;
	parameter DEPTH = 2;
	input rst_ni;
	input clk_i;
	input mem_req_i;
	input wire [2:0] mem_size_i;
	input mem_lock_i;
	input mem_misaligned_i;
	input [XLEN - 1:0] mem_adr_i;
	input mem_we_i;
	input [XLEN - 1:0] mem_d_i;
	output wire [XLEN - 1:0] mem_q_o;
	output wire mem_ack_o;
	output wire mem_err_o;
	output reg mem_misaligned_o;
	input [1:0] st_prv_i;
	output reg biu_stb_o;
	output wire [ALEN - 1:0] biu_adri_o;
	input [ALEN - 1:0] biu_adro_i;
	output wire [2:0] biu_size_o;
	output wire [2:0] biu_type_o;
	output wire biu_lock_o;
	output wire biu_we_o;
	output wire [2:0] biu_prot_o;
	output wire [XLEN - 1:0] biu_d_o;
	input [XLEN - 1:0] biu_q_i;
	input biu_stb_ack_i;
	input biu_d_ack_i;
	input biu_ack_i;
	input biu_err_i;
	genvar _gv_n_4;
	reg hold_mem_req;
	reg hold_mem_misaligned;
	reg [XLEN - 1:0] hold_mem_adr;
	reg [XLEN - 1:0] hold_mem_d;
	reg [2:0] hold_mem_size;
	wire [2:0] hold_mem_type;
	wire [2:0] hold_mem_prot;
	reg hold_mem_lock;
	reg hold_mem_we;
	wire misaligned;
	reg [DEPTH - 1:0] misaligned_queue;
	wire misaligned_in_pipe;
	reg [$clog2(DEPTH):0] inflight;
	reg [$clog2(DEPTH):0] discard;
	always @(posedge clk_i)
		if (mem_req_i) begin
			hold_mem_misaligned <= mem_misaligned_i;
			hold_mem_adr <= mem_adr_i;
			hold_mem_size <= mem_size_i;
			hold_mem_lock <= mem_lock_i;
			hold_mem_we <= mem_we_i;
			hold_mem_d <= mem_d_i;
		end
	always @(posedge clk_i)
		if (!rst_ni)
			hold_mem_req <= 1'b0;
		else if (misaligned_in_pipe || mem_err_o)
			hold_mem_req <= 1'b0;
		else
			hold_mem_req <= (mem_req_i | hold_mem_req) & ~biu_stb_ack_i;
	assign misaligned = (hold_mem_req ? hold_mem_misaligned : mem_misaligned_i & mem_req_i);
	always @(posedge clk_i) misaligned_queue <= {misaligned_queue[0+:DEPTH - 1], misaligned};
	assign misaligned_in_pipe = misaligned | (|misaligned_queue);
	wire [1:1] sv2v_tmp_DF944;
	assign sv2v_tmp_DF944 = misaligned_queue[DEPTH - 1];
	always @(*) mem_misaligned_o = sv2v_tmp_DF944;
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
		else if (misaligned || mem_err_o) begin
			if (|inflight && (biu_ack_i | biu_err_i))
				discard <= inflight - 1;
			else
				discard <= inflight;
		end
		else if (|discard && (biu_ack_i | biu_err_i))
			discard <= discard - 1;
	wire [1:1] sv2v_tmp_36EDC;
	assign sv2v_tmp_36EDC = (mem_req_i | hold_mem_req) & ~misaligned_in_pipe;
	always @(*) biu_stb_o = sv2v_tmp_36EDC;
	assign biu_adri_o = (hold_mem_req ? hold_mem_adr : mem_adr_i);
	assign biu_size_o = (hold_mem_req ? hold_mem_size : mem_size_i);
	assign biu_lock_o = (hold_mem_req ? hold_mem_lock : mem_lock_i);
	localparam [2:0] biu_constants_pkg_PROT_DATA = 3'b001;
	localparam [2:0] biu_constants_pkg_PROT_PRIVILEGED = 3'b010;
	localparam [2:0] biu_constants_pkg_PROT_USER = 3'b000;
	localparam [1:0] riscv_state_pkg_PRV_U = 2'b00;
	assign biu_prot_o = (biu_constants_pkg_PROT_DATA | (st_prv_i == riscv_state_pkg_PRV_U) ? biu_constants_pkg_PROT_USER : biu_constants_pkg_PROT_PRIVILEGED);
	assign biu_we_o = (hold_mem_req ? hold_mem_we : mem_we_i);
	assign biu_d_o = (hold_mem_req ? hold_mem_d : mem_d_i);
	assign biu_type_o = 3'b000;
	assign mem_q_o = biu_q_i;
	assign mem_ack_o = (|discard ? 1'b0 : (|inflight ? biu_ack_i : biu_ack_i & biu_stb_o));
	assign mem_err_o = (|discard ? 1'b0 : (|inflight ? biu_err_i : biu_err_i & biu_stb_o));
endmodule
