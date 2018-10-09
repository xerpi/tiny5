import definitions::*;

module decode(
	input instruction_t instr_i,
	output logic regfile_we_o,
	output logic csr_we_o
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
endmodule
