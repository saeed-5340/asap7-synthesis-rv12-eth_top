module riscv_rf (
	rst_ni,
	clk_i,
	rf_src1_i,
	rf_src2_i,
	rf_src1_q_o,
	rf_src2_q_o,
	rf_dst_i,
	rf_dst_d_i,
	rf_we_i,
	pd_stall_i,
	id_stall_i,
	du_re_rf_i,
	du_we_rf_i,
	du_d_i,
	du_rf_q_o,
	du_addr_i
);
	reg _sv2v_0;
	parameter MXLEN = 32;
	parameter REGOUT = 0;
	input rst_ni;
	input clk_i;
	input wire [4:0] rf_src1_i;
	input wire [4:0] rf_src2_i;
	output reg [MXLEN - 1:0] rf_src1_q_o;
	output reg [MXLEN - 1:0] rf_src2_q_o;
	input wire [4:0] rf_dst_i;
	input [MXLEN - 1:0] rf_dst_d_i;
	input rf_we_i;
	input pd_stall_i;
	input id_stall_i;
	input du_re_rf_i;
	input du_we_rf_i;
	input [MXLEN - 1:0] du_d_i;
	output reg [MXLEN - 1:0] du_rf_q_o;
	input [11:0] du_addr_i;
	reg [MXLEN - 1:0] rf [0:31];
	reg [4:0] src1;
	reg [4:0] src2;
	wire [MXLEN - 1:0] rfout1;
	wire [MXLEN - 1:0] rfout2;
	reg src1_is_x0;
	reg src2_is_x0;
	wire dst_is_src1;
	wire dst_is_src2;
	reg [MXLEN - 1:0] dout1;
	reg [MXLEN - 1:0] dout2;
	reg du_re_rf_dly;
	always @(posedge clk_i) du_re_rf_dly <= du_re_rf_i;
	always @(posedge clk_i)
		if (du_re_rf_i)
			src1 <= du_addr_i[4:0];
		else if (!pd_stall_i)
			src1 <= rf_src1_i;
	always @(posedge clk_i)
		if (!pd_stall_i)
			src2 <= rf_src2_i;
	assign dst_is_src1 = rf_dst_i == src1;
	assign dst_is_src2 = rf_dst_i == src2;
	assign rfout1 = rf[src1];
	assign rfout2 = rf[src2];
	always @(posedge clk_i)
		if (!pd_stall_i)
			src1_is_x0 <= ~|rf_src1_i;
	always @(posedge clk_i)
		if (!pd_stall_i)
			src2_is_x0 <= ~|rf_src2_i;
	always @(*) begin
		if (_sv2v_0)
			;
		casex (src1_is_x0)
			1'b1: dout1 = {MXLEN {1'b0}};
			1'b0: dout1 = rfout1;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casex (src2_is_x0)
			1'b1: dout2 = {MXLEN {1'b0}};
			1'b0: dout2 = rfout2;
		endcase
	end
	generate
		if (REGOUT > 0) begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					rf_src1_q_o <= dout1;
			always @(posedge clk_i)
				if (!id_stall_i)
					rf_src2_q_o <= dout2;
		end
		else begin : genblk1
			wire [MXLEN:1] sv2v_tmp_C1DA4;
			assign sv2v_tmp_C1DA4 = dout1;
			always @(*) rf_src1_q_o = sv2v_tmp_C1DA4;
			wire [MXLEN:1] sv2v_tmp_3FB3C;
			assign sv2v_tmp_3FB3C = dout2;
			always @(*) rf_src2_q_o = sv2v_tmp_3FB3C;
		end
	endgenerate
	always @(posedge clk_i)
		if (du_re_rf_dly)
			du_rf_q_o <= (~|src1 ? 'h0 : rfout1);
	always @(posedge clk_i)
		if (du_we_rf_i)
			rf[du_addr_i[4:0]] <= du_d_i;
		else if (rf_we_i)
			rf[rf_dst_i] <= rf_dst_d_i;
	initial _sv2v_0 = 0;
endmodule
