module riscv_rsb (
	rst_ni,
	clk_i,
	ena_i,
	d_i,
	q_o,
	push_i,
	pop_i,
	empty_o
);
	parameter MXLEN = 32;
	parameter DEPTH = 4;
	input wire rst_ni;
	input wire clk_i;
	input wire ena_i;
	input wire [MXLEN - 1:0] d_i;
	output wire [MXLEN - 1:0] q_o;
	input wire push_i;
	input wire pop_i;
	output reg empty_o;
	reg [MXLEN - 1:0] stack [0:DEPTH - 1];
	reg [MXLEN - 1:0] last_value;
	reg [$clog2(DEPTH + 1) - 1:0] cnt;
	always @(posedge clk_i)
		if (ena_i && push_i)
			last_value <= d_i;
	always @(posedge clk_i)
		if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01: begin : sv2v_autoblock_1
					reg signed [31:0] n;
					for (n = 0; n < (DEPTH - 1); n = n + 1)
						stack[n] <= stack[n + 1];
				end
				2'b10: begin
					stack[0] <= d_i;
					begin : sv2v_autoblock_2
						reg signed [31:0] n;
						for (n = 1; n < DEPTH; n = n + 1)
							stack[n] <= stack[n - 1];
					end
				end
				2'b11: stack[0] <= d_i;
				2'b00:
					;
			endcase
	assign q_o = (empty_o ? last_value : stack[0]);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cnt <= 'h0;
		else if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01:
					if (!empty_o)
						cnt <= cnt - 1;
				2'b10:
					if (cnt != DEPTH)
						cnt <= cnt + 1;
				default:
					;
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			empty_o <= 1'b1;
		else if (ena_i)
			(* full_case, parallel_case *)
			case ({push_i, pop_i})
				2'b01: empty_o <= cnt == 1;
				2'b10: empty_o <= 1'b0;
				default:
					;
			endcase
endmodule
