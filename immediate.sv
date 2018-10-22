import definitions::*;

module immediate(
	input instruction_t instr_i,
	output logic [31:0] imm_o
);
	instruction_t instr;
	logic [31:0] utype_imm;
	logic [31:0] itype_imm;
	logic [31:0] jtype_imm;
	logic [31:0] btype_imm;
	logic [31:0] stype_imm;
	logic [31:0] csr_uimm;

	assign instr = instr_i;

	assign utype_imm = {
		instr.utype.imm, 12'b0
	};
	assign itype_imm = {
		{20{instr.itype.imm[11]}}, instr.itype.imm
	};
	assign jtype_imm = {
		{11{instr.jtype.imm20}}, instr.jtype.imm20,
		instr.jtype.imm12, instr.jtype.imm11,
		instr.jtype.imm1, 1'b0
	};
	assign btype_imm = {
		{19{instr.btype.imm12}}, instr.btype.imm12,
		instr.btype.imm11, instr.btype.imm5,
		instr.btype.imm1, 1'b0
	};
	assign stype_imm = {
		{20{instr.stype.imm5[6]}}, instr.stype.imm5,
		instr.stype.imm0
	};
	assign csr_uimm = {
		27'b0, instr.itype.rs1
	};

	always_comb begin
		case (instr.common.opcode)
		OPCODE_LUI, OPCODE_AUIPC:
			imm_o = utype_imm;
		OPCODE_JAL:
			imm_o = jtype_imm;
		OPCODE_JALR, OPCODE_LOAD, OPCODE_OP_IMM:
			imm_o = itype_imm;
		OPCODE_BRANCH:
			imm_o = btype_imm;
		OPCODE_STORE:
			imm_o = stype_imm;
		OPCODE_SYSTEM: begin
			priority case (instr.itype.funct3)
			FUNCT3_SYSTEM_CSRRWI,
			FUNCT3_SYSTEM_CSRRSI,
			FUNCT3_SYSTEM_CSRRCI:
				imm_o = csr_uimm;
			endcase
		end
		default:
			imm_o = 0;
		endcase
	end
endmodule
