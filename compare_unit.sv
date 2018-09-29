typedef enum logic [2:0] {
	COMPARE_UNIT_OP_EQ,
	COMPARE_UNIT_OP_NE,
	COMPARE_UNIT_OP_LT,
	COMPARE_UNIT_OP_GE,
	COMPARE_UNIT_OP_LTU,
	COMPARE_UNIT_OP_GEU
} compare_unit_op_t;

module compare_unit(
	input compare_unit_op_t compare_unit_op_i,
	input logic [31:0] in1_i,
	input logic [31:0] in2_i,
	output logic res_o
);
	always_comb begin
		priority case (compare_unit_op_i)
		COMPARE_UNIT_OP_EQ:
			res_o = in1_i == in2_i;
		COMPARE_UNIT_OP_NE:
			res_o = in1_i != in2_i;
		COMPARE_UNIT_OP_LT:
			res_o = $signed(in1_i) < $signed(in2_i);
		COMPARE_UNIT_OP_GE:
			res_o = $signed(in1_i) >= $signed(in2_i);
		COMPARE_UNIT_OP_LTU:
			res_o = in1_i < in2_i;
		COMPARE_UNIT_OP_GEU:
			res_o = in1_i >= in2_i;
		endcase
	end
endmodule
