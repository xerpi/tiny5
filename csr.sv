import definitions::*;

module csr(
	input logic clk_i,
	input logic reset_i,
	input logic [11:0] rd_addr_i,
	input logic [11:0] wr_addr_i,
	input logic [31:0] wr_data_i,
	input logic wr_en_i,
	input logic instret_i,
	output logic [31:0] rd_data_o
);
	logic [63:0] reg_cycle;
	logic [63:0] reg_time;
	logic [63:0] reg_instret;

	logic [63:0] next_cycle;
	logic [63:0] next_instret;

	assign next_cycle = reg_cycle + 1;
	assign next_instret = instret_i ? reg_instret + 1 : reg_instret;

	always_comb begin
		case (rd_addr_i)
		CSR_REG_CYCLE:
			rd_data_o = reg_cycle[31:0];
		CSR_REG_TIME:
			rd_data_o = reg_time[31:0];
		CSR_REG_INSTRET:
			rd_data_o = reg_instret[31:0];
		CSR_REG_CYCLEH:
			rd_data_o = reg_cycle[63:32];
		CSR_REG_TIMEH:
			rd_data_o = reg_time[63:32];
		CSR_REG_INSTRETH:
			rd_data_o = reg_instret[63:32];
		default:
			rd_data_o = 32'b0;
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			reg_cycle <= 0;
			reg_time <= 0;
			reg_instret <= 0;
		end else begin
			reg_cycle <= next_cycle;
			reg_instret <= next_instret;

			if (wr_en_i) begin
				/*priority case (wr_addr_i)
				TODO: Implement writable registers
				CSR_REG_FOO:
					reg_foo[31:0] <= wr_data_i;
				endcase*/
			end
		end
	end
endmodule
