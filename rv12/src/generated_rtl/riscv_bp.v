module riscv_bp (
	rst_ni,
	clk_i,
	id_stall_i,
	if_parcel_pc_i,
	if_parcel_bp_history_i,
	bp_bp_predict_o,
	ex_pc_i,
	bu_bp_history_i,
	bu_bp_predict_i,
	bu_bp_btaken_i,
	bu_bp_update_i
);
	parameter MXLEN = 32;
	parameter [MXLEN - 1:0] PC_INIT = 'h200;
	parameter HAS_BPU = 0;
	parameter HAS_RVC = 0;
	parameter BP_GLOBAL_BITS = 2;
	parameter BP_LOCAL_BITS = 10;
	parameter BP_LOCAL_BITS_LSB = (HAS_RVC != 0 ? 1 : 2);
	parameter TECHNOLOGY = "GENERIC";
	parameter AVOID_X = 0;
	input rst_ni;
	input clk_i;
	input id_stall_i;
	input [MXLEN - 1:0] if_parcel_pc_i;
	input [BP_GLOBAL_BITS - 1:0] if_parcel_bp_history_i;
	output reg [1:0] bp_bp_predict_o;
	input [MXLEN - 1:0] ex_pc_i;
	input [BP_GLOBAL_BITS - 1:0] bu_bp_history_i;
	input [1:0] bu_bp_predict_i;
	input bu_bp_btaken_i;
	input bu_bp_update_i;
	localparam ADR_BITS = BP_GLOBAL_BITS + BP_LOCAL_BITS;
	localparam MEMORY_DEPTH = 1 << ADR_BITS;
	wire [ADR_BITS - 1:0] radr;
	wire [ADR_BITS - 1:0] wadr;
	reg [MXLEN - 1:0] if_parcel_pc_dly;
	wire [1:0] new_prediction;
	wire [1:0] current_prediction;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			if_parcel_pc_dly <= PC_INIT;
		else if (!id_stall_i)
			if_parcel_pc_dly <= if_parcel_pc_i;
	assign radr = (id_stall_i ? {if_parcel_bp_history_i, if_parcel_pc_dly[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]} : {if_parcel_bp_history_i, if_parcel_pc_i[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]});
	assign wadr = {bu_bp_history_i, ex_pc_i[BP_LOCAL_BITS_LSB+:BP_LOCAL_BITS]};
	assign new_prediction[0] = bu_bp_predict_i[1] ^ bu_bp_btaken_i;
	assign new_prediction[1] = (bu_bp_predict_i[1] & ~bu_bp_predict_i[0]) | (bu_bp_btaken_i & bu_bp_predict_i[0]);
	rl_ram_1r1w #(
		.ABITS(ADR_BITS),
		.DBITS(2),
		.TECHNOLOGY(TECHNOLOGY),
		.RW_CONTENTION("DONT_CARE")
	) bp_ram_inst(
		.rst_ni(rst_ni),
		.clk_i(clk_i),
		.waddr_i(wadr),
		.din_i(new_prediction),
		.we_i(bu_bp_update_i),
		.be_i(1'b1),
		.raddr_i(radr),
		.re_i(1'b1),
		.dout_o(current_prediction)
	);
	generate
		if (AVOID_X) begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					bp_bp_predict_o <= (current_prediction == 2'bxx ? $random : current_prediction);
		end
		else begin : genblk1
			always @(posedge clk_i)
				if (!id_stall_i)
					bp_bp_predict_o <= current_prediction;
		end
	endgenerate
endmodule
