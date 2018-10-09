import definitions::*;

module decode(
	input instruction_t instr_i,
	output logic regfile_we_o,
	output logic csr_we_o,
	output alu_op_t alu_op_o
);
	always_comb begin
		regfile_we_o = 0;
		priority case (instr_i.common.opcode)
		OPCODE_LUI, OPCODE_AUIPC, OPCODE_JAL, OPCODE_JALR,
		OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_OP: begin
			regfile_we_o = 1;
		end
		OPCODE_SYSTEM: begin
			priority case (instr_i.itype.funct3)
			FUNCT3_SYSTEM_CSRRW, FUNCT3_SYSTEM_CSRRS,
			FUNCT3_SYSTEM_CSRRC, FUNCT3_SYSTEM_CSRRWI,
			FUNCT3_SYSTEM_CSRRSI, FUNCT3_SYSTEM_CSRRCI: begin
				regfile_we_o = 1;
			end
			endcase
		end
		endcase
	end

	always_comb begin
		csr_we_o = 0;
		priority case (instr_i.common.opcode)
		OPCODE_SYSTEM: begin
			priority case (instr_i.itype.funct3)
			FUNCT3_SYSTEM_CSRRW, FUNCT3_SYSTEM_CSRRS,
			FUNCT3_SYSTEM_CSRRC, FUNCT3_SYSTEM_CSRRWI,
			FUNCT3_SYSTEM_CSRRSI, FUNCT3_SYSTEM_CSRRCI: begin
				csr_we_o = 1;
			end
			endcase
		end
		endcase
	end

	always_comb begin
		priority case (instr_i.common.opcode)
		OPCODE_LUI:
			alu_op_o = ALU_OP_IN2_PASSTHROUGH;
		OPCODE_AUIPC, OPCODE_JAL, OPCODE_JALR, OPCODE_BRANCH,
		OPCODE_LOAD, OPCODE_STORE:
			alu_op_o = ALU_OP_ADD;
		OPCODE_OP_IMM: begin
			priority case (instr_i.itype.funct3)
			FUNCT3_OP_IMM_ADDI:
				alu_op_o = ALU_OP_ADD;
			FUNCT3_OP_IMM_SLTI:
				alu_op_o = ALU_OP_SLT;
			FUNCT3_OP_IMM_SLTIU:
				alu_op_o = ALU_OP_SLTU;
			FUNCT3_OP_IMM_XORI:
				alu_op_o = ALU_OP_XOR;
			FUNCT3_OP_IMM_ORI:
				alu_op_o = ALU_OP_OR;
			FUNCT3_OP_IMM_ANDI:
				alu_op_o = ALU_OP_AND;
			FUNCT3_OP_IMM_SLLI:
				alu_op_o = ALU_OP_SLL;
			FUNCT3_OP_IMM_SRI:
				if (instr_i.itype.imm[10] == 0)
					alu_op_o = ALU_OP_SRL;
				else
					alu_op_o = ALU_OP_SRA;
			endcase
		end
		OPCODE_OP: begin
			priority case (instr_i.rtype.funct3)
			FUNCT3_OP_ADD_SUB: begin
				if (instr_i.rtype.funct7[5] == 0)
					alu_op_o = ALU_OP_ADD;
				else
					alu_op_o = ALU_OP_SUB;
			end
			FUNCT3_OP_SLL:
				alu_op_o = ALU_OP_SLL;
			FUNCT3_OP_SLT:
				alu_op_o = ALU_OP_SLT;
			FUNCT3_OP_SLTU:
				alu_op_o = ALU_OP_SLTU;
			FUNCT3_OP_XOR:
				alu_op_o = ALU_OP_XOR;
			FUNCT3_OP_SR:
				if (instr_i.rtype.funct7[5] == 0)
					alu_op_o = ALU_OP_SRL;
				else
					alu_op_o = ALU_OP_SRA;
			FUNCT3_OP_OR:
				alu_op_o = ALU_OP_OR;
			FUNCT3_OP_AND:
				alu_op_o = ALU_OP_AND;
			endcase
		end
		OPCODE_SYSTEM: begin
			priority case (instr_i.itype.funct3)
			FUNCT3_SYSTEM_CSRRW:
				alu_op_o = ALU_OP_IN1_PASSTHROUGH;
			FUNCT3_SYSTEM_CSRRS, FUNCT3_SYSTEM_CSRRSI:
				alu_op_o = ALU_OP_OR;
			FUNCT3_SYSTEM_CSRRC, FUNCT3_SYSTEM_CSRRCI:
				alu_op_o = ALU_OP_XOR;
			FUNCT3_SYSTEM_CSRRWI:
				alu_op_o = ALU_OP_IN2_PASSTHROUGH;
			endcase
		end
		endcase
	end
endmodule
