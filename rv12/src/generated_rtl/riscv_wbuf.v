module riscv_wbuf (
	rst_ni,
	clk_i,
	mem_req_i,
	mem_adr_i,
	mem_size_i,
	mem_type_i,
	mem_lock_i,
	mem_prot_i,
	mem_we_i,
	mem_d_i,
	mem_q_o,
	mem_ack_o,
	mem_err_o,
	cacheflush_i,
	mem_req_o,
	mem_adr_o,
	mem_size_o,
	mem_type_o,
	mem_lock_o,
	mem_prot_o,
	mem_we_o,
	mem_d_o,
	mem_q_i,
	mem_ack_i,
	mem_err_i,
	cacheflush_o
);
	parameter XLEN = 32;
	parameter DEPTH = 8;
	input rst_ni;
	input clk_i;
	input mem_req_i;
	input [XLEN - 1:0] mem_adr_i;
	input wire [2:0] mem_size_i;
	input wire [2:0] mem_type_i;
	input mem_lock_i;
	input wire [2:0] mem_prot_i;
	input mem_we_i;
	input [XLEN - 1:0] mem_d_i;
	output reg [XLEN - 1:0] mem_q_o;
	output reg mem_ack_o;
	output reg mem_err_o;
	input cacheflush_i;
	output wire mem_req_o;
	output wire [XLEN - 1:0] mem_adr_o;
	output wire [2:0] mem_size_o;
	output wire [2:0] mem_type_o;
	output wire mem_lock_o;
	output wire [2:0] mem_prot_o;
	output wire mem_we_o;
	output wire [XLEN - 1:0] mem_d_o;
	input [XLEN - 1:0] mem_q_i;
	input mem_ack_i;
	input mem_err_i;
	output wire cacheflush_o;
	localparam FIFO_DEPTH = 2 ** $clog2(DEPTH);
	integer n;
	reg [(XLEN + XLEN) + 12:0] fifo_data [0:FIFO_DEPTH - 1];
	reg [$clog2(FIFO_DEPTH) - 1:0] fifo_wadr;
	wire fifo_we;
	wire fifo_re;
	reg fifo_empty;
	reg fifo_full;
	wire we_ack;
	reg mem_we_ack;
	reg access_pending;
	reg read_pending;
	reg mem_we_o_dly;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_wadr <= 'h0;
		else
			case ({fifo_we, fifo_re})
				2'b01: fifo_wadr <= fifo_wadr - 1;
				2'b10: fifo_wadr <= fifo_wadr + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			for (n = 0; n < FIFO_DEPTH; n = n + 1)
				fifo_data[n] <= 'h0;
		else
			case ({fifo_we, fifo_re})
				2'b01: begin
					for (n = 0; n < (FIFO_DEPTH - 1); n = n + 1)
						fifo_data[n] <= fifo_data[n + 1];
					fifo_data[FIFO_DEPTH - 1] <= 'h0;
				end
				2'b10: fifo_data[fifo_wadr] <= {mem_adr_i, mem_d_i, mem_size_i, mem_type_i, mem_lock_i, mem_prot_i, mem_we_i, we_ack, cacheflush_i};
				2'b11: begin
					for (n = 0; n < (FIFO_DEPTH - 1); n = n + 1)
						fifo_data[n] <= fifo_data[n + 1];
					fifo_data[FIFO_DEPTH - 1] <= 'h0;
					fifo_data[fifo_wadr - 1] <= {mem_adr_i, mem_d_i, mem_size_i, mem_type_i, mem_lock_i, mem_prot_i, mem_we_i, we_ack, cacheflush_i};
				end
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_full <= 1'b0;
		else
			case ({fifo_we, fifo_re})
				2'b01: fifo_full <= 1'b0;
				2'b10: fifo_full <= &fifo_wadr;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_empty <= 1'b1;
		else
			case ({fifo_we, fifo_re})
				2'b01: fifo_empty <= ~|fifo_wadr[$clog2(FIFO_DEPTH) - 1:1] & fifo_wadr[0];
				2'b10: fifo_empty <= 1'b0;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			read_pending <= 1'b0;
		else
			read_pending <= (read_pending & ~mem_ack_o) | (mem_req_i & ~mem_we_i);
	assign we_ack = (mem_req_i & mem_we_i) & ~read_pending;
	always @(posedge clk_i) mem_we_ack <= we_ack;
	wire [XLEN:1] sv2v_tmp_DC577;
	assign sv2v_tmp_DC577 = mem_q_i;
	always @(*) mem_q_o = sv2v_tmp_DC577;
	wire [1:1] sv2v_tmp_C6128;
	assign sv2v_tmp_C6128 = ((~fifo_full & mem_we_ack) | ((fifo_full & fifo_re) & fifo_data[FIFO_DEPTH - 1][2])) | (mem_ack_i & ~fifo_data[0][1]);
	always @(*) mem_ack_o = sv2v_tmp_C6128;
	assign fifo_we = access_pending & (mem_req_i & ~(fifo_empty & mem_ack_i));
	assign fifo_re = mem_ack_i & ~fifo_empty;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			access_pending <= 1'b0;
		else
			access_pending <= mem_req_o | (access_pending & ~mem_ack_i);
	assign mem_req_o = (~access_pending ? mem_req_i : (mem_req_i | ~fifo_empty) & mem_ack_i);
	assign mem_adr_o = (~fifo_empty ? fifo_data[0][XLEN + (XLEN + 12)-:((XLEN + (XLEN + 12)) >= (XLEN + 13) ? ((XLEN + (XLEN + 12)) - (XLEN + 13)) + 1 : ((XLEN + 13) - (XLEN + (XLEN + 12))) + 1)] : mem_adr_i);
	assign mem_size_o = (~fifo_empty ? fifo_data[0][12-:3] : mem_size_i);
	assign mem_type_o = (~fifo_empty ? fifo_data[0][9-:3] : mem_type_i);
	assign mem_lock_o = (~fifo_empty ? fifo_data[0][6] : mem_lock_i);
	assign mem_prot_o = (~fifo_empty ? fifo_data[0][5-:3] : mem_prot_i);
	assign mem_we_o = (~fifo_empty ? fifo_data[0][2] : mem_we_i);
	assign mem_d_o = (~fifo_empty ? fifo_data[0][XLEN + 12-:((XLEN + 12) >= 13 ? XLEN + 0 : 14 - (XLEN + 12))] : mem_d_i);
	assign cacheflush_o = (~fifo_empty ? fifo_data[0][0] : cacheflush_i);
	always @(posedge clk_i)
		if (mem_req_o)
			mem_we_o_dly <= mem_we_o;
endmodule
