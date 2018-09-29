import definitions::*;

module csr(
	input logic clk_i,
	input logic reset_i,
	input logic [11:0] rs_i,
	input logic [11:0] rd_i,
	input logic [31:0] in_i,
	input logic we_i,
	output logic [31:0] out_o
);
	logic [63:0] reg_cycle;
	logic [63:0] reg_time;
	logic [63:0] reg_instret;

	logic [63:0] next_cycle;

	assign next_cycle = reg_cycle + 1;

	always_comb begin
		case (rs_i)
		CSR_REG_CYCLE:
			out_o = reg_cycle[31:0];
		CSR_REG_TIME:
			out_o = reg_time[31:0];
		CSR_REG_INSTRET:
			out_o = reg_instret[31:0];
		CSR_REG_CYCLEH:
			out_o = reg_cycle[63:32];
		CSR_REG_TIMEH:
			out_o = reg_time[63:32];
		CSR_REG_INSTRETH:
			out_o = reg_instret[63:32];
		default:
			out_o = 32'b0;
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			reg_cycle <= 0;
			reg_time <= 0;
			reg_instret <= 0;
		end else begin
			reg_cycle <= next_cycle;

			if (we_i) begin
				/*priority case (rd_i)
				TODO: Implement writable registers
				CSR_REG_FOO:
					reg_foo[31:0] <= in_i;
				endcase*/
			end
		end
	end
endmodule
