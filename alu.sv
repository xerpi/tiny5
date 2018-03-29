import definitions::*;

module alu(
	input alu_op_t alu_op_i,
	input logic [31:0] din1_i,
	input logic [31:0] din2_i,
	output logic [31:0] dout_o
);
	always_comb begin
		case (alu_op_i)
		ALU_OP_IN2_PASSTHROUGH:
			dout_o = din2_i;
		ALU_OP_ADD:
			dout_o = din1_i + din2_i;
		ALU_OP_SUB:
			dout_o = din1_i - din2_i;
		endcase
	end
endmodule;
