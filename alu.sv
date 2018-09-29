typedef enum logic [3:0] {
	ALU_OP_IN1_PASSTHROUGH,
	ALU_OP_IN2_PASSTHROUGH,
	ALU_OP_ADD,
	ALU_OP_SUB,
	ALU_OP_SLL,
	ALU_OP_SLT,
	ALU_OP_SLTU,
	ALU_OP_XOR,
	ALU_OP_SRL,
	ALU_OP_SRA,
	ALU_OP_OR,
	ALU_OP_AND
} alu_op_t;

module alu(
	input alu_op_t alu_op_i,
	input logic [31:0] in1_i,
	input logic [31:0] in2_i,
	output logic [31:0] out_o
);
	always_comb begin
		priority case (alu_op_i)
		ALU_OP_IN1_PASSTHROUGH:
			out_o = in1_i;
		ALU_OP_IN2_PASSTHROUGH:
			out_o = in2_i;
		ALU_OP_ADD:
			out_o = in1_i + in2_i;
		ALU_OP_SUB:
			out_o = in1_i - in2_i;
		ALU_OP_SLL:
			out_o = in1_i << in2_i[4:0];
		ALU_OP_SLT:
			out_o = {31'b0, $signed(in1_i) < $signed(in2_i)};
		ALU_OP_SLTU:
			out_o = {31'b0, in1_i < in2_i};
		ALU_OP_XOR:
			out_o = in1_i ^ in2_i;
		ALU_OP_SRL:
			out_o = in1_i >> in2_i[4:0];
		ALU_OP_SRA:
			out_o = $signed(in1_i) >>> in2_i[4:0];
		ALU_OP_OR:
			out_o = in1_i | in2_i;
		ALU_OP_AND:
			out_o = in1_i & in2_i;
		endcase
	end
endmodule
