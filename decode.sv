import definitions::*;
import cache_interface_types::*;

module decode(
	input instruction_t instr_i,
	output decode_out_t decode_o
);
	always_comb begin
		decode_o.regfile_we = 0;
		decode_o.csr_we = 0;
		decode_o.dcache_wr_enable = 0;
		decode_o.dcache_rd_signed = 0;
		decode_o.is_branch = 0;
		decode_o.is_jump = 0;
		decode_o.is_ecall = 0;
		decode_o.is_mem_access = 0;

		priority case (instr_i.common.opcode)
		OPCODE_LUI: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_ALU_OUT;
			decode_o.alu_op = ALU_OP_IN1_PASSTHROUGH;
			decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
		end
		OPCODE_AUIPC: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_ALU_OUT;
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
			decode_o.alu_in2_sel = ALU_IN2_SEL_PC;
		end
		OPCODE_JAL: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_PC_4;
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
			decode_o.alu_in2_sel = ALU_IN2_SEL_PC;
			decode_o.is_jump = 1;
		end
		OPCODE_JALR: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_PC_4;
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			decode_o.alu_in2_sel = ALU_IN2_SEL_IMM;
			decode_o.is_jump = 1;
		end
		OPCODE_BRANCH: begin
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
			decode_o.alu_in2_sel = ALU_IN2_SEL_PC;
			decode_o.is_branch = 1;

			priority case (instr_i.btype.funct3)
			FUNCT3_BRANCH_BEQ:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_EQ;
			FUNCT3_BRANCH_BNE:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_NE;
			FUNCT3_BRANCH_BLT:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_LT;
			FUNCT3_BRANCH_BGE:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_GE;
			FUNCT3_BRANCH_BLTU:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_LTU;
			FUNCT3_BRANCH_BGEU:
				decode_o.compare_unit_op = COMPARE_UNIT_OP_GEU;
			endcase
		end
		OPCODE_LOAD: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_DMEM_RD_DATA;
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			decode_o.alu_in2_sel = ALU_IN2_SEL_IMM;
			decode_o.is_mem_access = 1;

			priority case (instr_i.itype.funct3)
			FUNCT3_LOAD_LB, FUNCT3_LOAD_LBU:
				decode_o.dcache_rd_size = CACHE_ACCESS_SIZE_BYTE;
			FUNCT3_LOAD_LH, FUNCT3_LOAD_LHU:
				decode_o.dcache_rd_size = CACHE_ACCESS_SIZE_HALF;
			FUNCT3_LOAD_LW:
				decode_o.dcache_rd_size = CACHE_ACCESS_SIZE_WORD;
			endcase

			priority case (instr_i.itype.funct3)
			FUNCT3_LOAD_LB, FUNCT3_LOAD_LH, FUNCT3_LOAD_LW:
				decode_o.dcache_rd_signed = 1;
			endcase
		end
		OPCODE_STORE: begin
			decode_o.dcache_wr_enable = 1;
			decode_o.alu_op = ALU_OP_ADD;
			decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			decode_o.alu_in2_sel = ALU_IN2_SEL_IMM;
			decode_o.is_mem_access = 1;

			priority case (instr_i.itype.funct3)
			FUNCT3_STORE_SB:
				decode_o.dcache_wr_size = CACHE_ACCESS_SIZE_BYTE;
			FUNCT3_STORE_SH:
				decode_o.dcache_wr_size = CACHE_ACCESS_SIZE_HALF;
			FUNCT3_STORE_SW:
				decode_o.dcache_wr_size = CACHE_ACCESS_SIZE_WORD;
			endcase
		end
		OPCODE_OP_IMM: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_ALU_OUT;
			decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			decode_o.alu_in2_sel = ALU_IN2_SEL_IMM;

			priority case (instr_i.itype.funct3)
			FUNCT3_OP_IMM_ADDI:
				decode_o.alu_op = ALU_OP_ADD;
			FUNCT3_OP_IMM_SLTI:
				decode_o.alu_op = ALU_OP_SLT;
			FUNCT3_OP_IMM_SLTIU:
				decode_o.alu_op = ALU_OP_SLTU;
			FUNCT3_OP_IMM_XORI:
				decode_o.alu_op = ALU_OP_XOR;
			FUNCT3_OP_IMM_ORI:
				decode_o.alu_op = ALU_OP_OR;
			FUNCT3_OP_IMM_ANDI:
				decode_o.alu_op = ALU_OP_AND;
			FUNCT3_OP_IMM_SLLI:
				decode_o.alu_op = ALU_OP_SLL;
			FUNCT3_OP_IMM_SRI:
				if (instr_i.itype.imm[10])
					decode_o.alu_op = ALU_OP_SRA;
				else
					decode_o.alu_op = ALU_OP_SRL;
			endcase
		end
		OPCODE_OP: begin
			decode_o.regfile_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_ALU_OUT;
			decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			decode_o.alu_in2_sel = ALU_IN2_SEL_REGFILE_OUT2;

			priority case (instr_i.rtype.funct3)
			FUNCT3_OP_ADD_SUB: begin
				if (instr_i.rtype.funct7[5])
					decode_o.alu_op = ALU_OP_SUB;
				else
					decode_o.alu_op = ALU_OP_ADD;
			end
			FUNCT3_OP_SLL:
				decode_o.alu_op = ALU_OP_SLL;
			FUNCT3_OP_SLT:
				decode_o.alu_op = ALU_OP_SLT;
			FUNCT3_OP_SLTU:
				decode_o.alu_op = ALU_OP_SLTU;
			FUNCT3_OP_XOR:
				decode_o.alu_op = ALU_OP_XOR;
			FUNCT3_OP_SR:
				if (instr_i.rtype.funct7[5])
					decode_o.alu_op = ALU_OP_SRA;
				else
					decode_o.alu_op = ALU_OP_SRL;
			FUNCT3_OP_OR:
				decode_o.alu_op = ALU_OP_OR;
			FUNCT3_OP_AND:
				decode_o.alu_op = ALU_OP_AND;
			endcase
		end
		OPCODE_MISC_MEM: begin
			priority case (instr_i.itype.funct3)
			FUNCT3_MISC_MEM_FENCE:
				; /* TODO */
			FUNCT3_MISC_MEM_FENCE_I:
				; /* TODO */
			endcase
		end
		OPCODE_SYSTEM: begin
			decode_o.regfile_we = 1;
			decode_o.csr_we = 1;
			decode_o.regfile_wr_sel = REGFILE_WR_SEL_CSR_OUT;

			priority case (instr_i.itype.funct3)
			FUNCT3_SYSTEM_PRIV: begin
				decode_o.regfile_we = 0;
				decode_o.csr_we = 0;

				priority case (instr_i.itype.imm)
				FUNCT12_SYSTEM_PRIV_ECALL:
					/* TODO */
					decode_o.is_ecall = 1;
				FUNCT12_SYSTEM_PRIV_EBREAK:
					/* TODO */
					;
				endcase
			end
			FUNCT3_SYSTEM_CSRRW: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				decode_o.alu_op = ALU_OP_IN1_PASSTHROUGH;
			end
			FUNCT3_SYSTEM_CSRRS: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				decode_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				decode_o.alu_op = ALU_OP_OR;
			end
			FUNCT3_SYSTEM_CSRRC: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				decode_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				decode_o.alu_op = ALU_OP_XOR;
			end
			FUNCT3_SYSTEM_CSRRWI: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
				decode_o.alu_op = ALU_OP_IN1_PASSTHROUGH;
			end
			FUNCT3_SYSTEM_CSRRSI: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
				decode_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				decode_o.alu_op = ALU_OP_OR;
			end
			FUNCT3_SYSTEM_CSRRCI: begin
				decode_o.alu_in1_sel = ALU_IN1_SEL_IMM;
				decode_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				decode_o.alu_op = ALU_OP_XOR;
			end
			endcase
		end
		endcase
	end
endmodule
