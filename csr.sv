import definitions::*;

module csr(
	input logic clk_i,
	input logic reset_i,
	input logic [11:0] sel_i,
	input logic [31:0] din_i,
	input logic we_i,
	output logic [31:0] dout_o
);
	logic [63:0] reg_cycle;
	logic [63:0] reg_time;
	logic [63:0] reg_instret;

	logic [63:0] next_cycle;

	assign next_cycle = reg_cycle + 1;

	always_comb begin
		case (sel_i)
		CSR_REG_CYCLE:
			dout_o = reg_cycle[31:0];
		CSR_REG_TIME:
			dout_o = reg_time[31:0];
		CSR_REG_INSTRET:
			dout_o = reg_instret[31:0];
		CSR_REG_CYCLEH:
			dout_o = reg_cycle[63:32];
		CSR_REG_TIMEH:
			dout_o = reg_time[63:32];
		CSR_REG_INSTRETH:
			dout_o = reg_instret[63:32];
		default:
			dout_o = 32'b0;
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
				/*priority case (sel_i)
				TODO: Implement writable registers
				CSR_REG_FOO:
					reg_foo[31:0] <= din_i;
				endcase*/
			end
		end
	end
endmodule
