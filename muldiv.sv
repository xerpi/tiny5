import definitions::*;

module muldiv(
	input funct3_op_muldiv_t muldiv_op_i,
	input logic [31:0] in1_i,
	input logic [31:0] in2_i,
	output logic [31:0] out_o
);
	logic [63:0] in1_64_signed;
	logic [63:0] in2_64_signed;
	logic [63:0] in1_64_unsigned;
	logic [63:0] in2_64_unsigned;
	logic [63:0] mul_ss;
	logic [63:0] mul_uu;
	logic [63:0] mul_su;

	assign in1_64_signed = {{32{in1_i[31]}}, in1_i};
	assign in2_64_signed = {{32{in2_i[31]}}, in2_i};
	assign in1_64_unsigned = {32'd0, in1_i};
	assign in2_64_unsigned = {32'd0, in2_i};

	assign mul_ss = in1_64_signed * in2_64_signed;
	assign mul_uu = in1_64_unsigned * in2_64_unsigned;
	assign mul_su = in1_64_signed * in2_64_unsigned;

	always_comb begin
		priority case (muldiv_op_i)
		FUNCT3_OP_MULDIV_MUL:
			out_o = mul_ss[0 +: 32];
		FUNCT3_OP_MULDIV_MULH:
			out_o = mul_ss[32 +: 32];
		FUNCT3_OP_MULDIV_MULHSU:
			out_o = mul_su[32 +: 32];
		FUNCT3_OP_MULDIV_MULHU:
			out_o = mul_uu[32 +: 32];
		FUNCT3_OP_MULDIV_DIV: begin
			if (in2_i == 0)
				out_o = -1;
			else
				out_o = $signed(in1_i) / $signed(in2_i);
		end
		FUNCT3_OP_MULDIV_DIVU: begin
			if (in2_i == 0)
				out_o = 'hFFFFFFFF;
			else
				out_o = in1_i / in2_i;
		end
		FUNCT3_OP_MULDIV_REM: begin
			if (in2_i == 0)
				out_o = in1_i;
			else
				out_o = $signed(in1_i) % $signed(in2_i);
		end
		FUNCT3_OP_MULDIV_REMU: begin
			if (in2_i == 0)
				out_o = in1_i;
			else
				out_o = in1_i % in2_i;
		end
		endcase
	end
endmodule
