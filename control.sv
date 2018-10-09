import definitions::*;

module control(
	input pipeline_id_reg_t id_reg_i,
	input pipeline_ex_reg_t ex_reg_i,
	input pipeline_mem_reg_t mem_reg_i,
	input pipeline_wb_reg_t wb_reg_i,
	output pipeline_if_ctrl_t if_ctrl_o,
	output pipeline_id_ctrl_t id_ctrl_o,
	output pipeline_ex_ctrl_t ex_ctrl_o,
	output pipeline_mem_ctrl_t mem_ctrl_o,
	output pipeline_wb_ctrl_t wb_ctrl_o
);
	/* Check data hazards */
	logic ex_data_hazard;
	logic mem_data_hazard;
	logic wb_data_hazard;
	logic data_hazard;

	assign ex_data_hazard = ex_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, ex_reg_i.regfile_rd);
	assign mem_data_hazard = mem_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, mem_reg_i.regfile_rd);
	assign wb_data_hazard = wb_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, wb_reg_i.regfile_rd);
	assign data_hazard = ex_data_hazard || mem_data_hazard || wb_data_hazard;

	/* IF stage */
	logic control_hazard;

	assign if_ctrl_o.pc_we = 1;

	always_comb begin
		control_hazard = 0;
		if_ctrl_o.next_pc_sel = NEXT_PC_SEL_PC_4;

		if (mem_reg_i.valid) begin
			priority case (mem_reg_i.instr.common.opcode)
			OPCODE_JAL,
			OPCODE_JALR: begin
				control_hazard = 1;
				if_ctrl_o.next_pc_sel = NEXT_PC_SEL_ALU_OUT;
			end
			OPCODE_BRANCH: begin
				if (mem_reg_i.cmp_unit_res) begin
					control_hazard = 1;
					if_ctrl_o.next_pc_sel = NEXT_PC_SEL_ALU_OUT;
				end else begin
					if_ctrl_o.next_pc_sel = NEXT_PC_SEL_PC_4;
				end
			end
			endcase
		end
	end

	assign if_ctrl_o.pc_reg_stall = data_hazard && !control_hazard;
	assign if_ctrl_o.id_reg_stall = data_hazard && !control_hazard;
	assign if_ctrl_o.id_reg_valid = !control_hazard;

	/* ID stage */
	assign id_ctrl_o.ex_reg_valid = id_reg_i.valid && !data_hazard && !control_hazard;

	always_comb begin
		id_ctrl_o.regfile_we = 0;
		id_ctrl_o.csr_we = 0;

		priority case (id_reg_i.instr.common.opcode)
		OPCODE_LUI: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_AUIPC: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_JAL: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_JALR: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_LOAD: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_OP_IMM: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_OP: begin
			id_ctrl_o.regfile_we = 1;
		end
		OPCODE_SYSTEM: begin
			priority case (id_reg_i.instr.itype.funct3)
			FUNCT3_SYSTEM_CSRRW, FUNCT3_SYSTEM_CSRRS,
			FUNCT3_SYSTEM_CSRRC, FUNCT3_SYSTEM_CSRRWI,
			FUNCT3_SYSTEM_CSRRSI, FUNCT3_SYSTEM_CSRRCI: begin
				id_ctrl_o.regfile_we = 1;
				id_ctrl_o.csr_we = 1;
			end
			endcase
		end
		endcase

		if (!id_reg_i.valid) begin
			id_ctrl_o.regfile_we = 0;
			id_ctrl_o.csr_we = 0;
		end
	end

	/* EX stage */
	assign ex_ctrl_o.mem_reg_valid = ex_reg_i.valid && !control_hazard;

	always_comb begin
		priority case (ex_reg_i.instr.common.opcode)
		OPCODE_LUI: begin
			ex_ctrl_o.alu_op = ALU_OP_IN2_PASSTHROUGH;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_AUIPC: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_PC;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_JAL: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_PC;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_JALR: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_BRANCH: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_PC;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;

			priority case (ex_reg_i.instr.btype.funct3)
			FUNCT3_BRANCH_BEQ:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_EQ;
			FUNCT3_BRANCH_BNE:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_NE;
			FUNCT3_BRANCH_BLT:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_LT;
			FUNCT3_BRANCH_BGE:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_GE;
			FUNCT3_BRANCH_BLTU:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_LTU;
			FUNCT3_BRANCH_BGEU:
				ex_ctrl_o.compare_unit_op = COMPARE_UNIT_OP_GEU;
			endcase
		end
		OPCODE_LOAD: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_STORE: begin
			ex_ctrl_o.alu_op = ALU_OP_ADD;
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
		end
		OPCODE_OP_IMM: begin
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;

			priority case (ex_reg_i.instr.itype.funct3)
			FUNCT3_OP_IMM_ADDI:
				ex_ctrl_o.alu_op = ALU_OP_ADD;
			FUNCT3_OP_IMM_SLTI:
				ex_ctrl_o.alu_op = ALU_OP_SLT;
			FUNCT3_OP_IMM_SLTIU:
				ex_ctrl_o.alu_op = ALU_OP_SLTU;
			FUNCT3_OP_IMM_XORI:
				ex_ctrl_o.alu_op = ALU_OP_XOR;
			FUNCT3_OP_IMM_ORI:
				ex_ctrl_o.alu_op = ALU_OP_OR;
			FUNCT3_OP_IMM_ANDI:
				ex_ctrl_o.alu_op = ALU_OP_AND;
			FUNCT3_OP_IMM_SLLI:
				ex_ctrl_o.alu_op = ALU_OP_SLL;
			FUNCT3_OP_IMM_SRI:
				if (ex_reg_i.instr.itype.imm[10] == 0)
					ex_ctrl_o.alu_op = ALU_OP_SRL;
				else
					ex_ctrl_o.alu_op = ALU_OP_SRA;
			endcase
		end
		OPCODE_OP: begin
			ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
			ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_REGFILE_OUT2;

			priority case (ex_reg_i.instr.rtype.funct3)
			FUNCT3_OP_ADD_SUB: begin
				if (ex_reg_i.instr.rtype.funct7[5] == 0)
					ex_ctrl_o.alu_op = ALU_OP_ADD;
				else
					ex_ctrl_o.alu_op = ALU_OP_SUB;
			end
			FUNCT3_OP_SLL:
				ex_ctrl_o.alu_op = ALU_OP_SLL;
			FUNCT3_OP_SLT:
				ex_ctrl_o.alu_op = ALU_OP_SLT;
			FUNCT3_OP_SLTU:
				ex_ctrl_o.alu_op = ALU_OP_SLTU;
			FUNCT3_OP_XOR:
				ex_ctrl_o.alu_op = ALU_OP_XOR;
			FUNCT3_OP_SR:
				if (ex_reg_i.instr.rtype.funct7[5] == 0)
					ex_ctrl_o.alu_op = ALU_OP_SRL;
				else
					ex_ctrl_o.alu_op = ALU_OP_SRA;
			FUNCT3_OP_OR:
				ex_ctrl_o.alu_op = ALU_OP_OR;
			FUNCT3_OP_AND:
				ex_ctrl_o.alu_op = ALU_OP_AND;
			endcase
		end
		OPCODE_SYSTEM: begin
			priority case (ex_reg_i.instr.itype.funct3)
			FUNCT3_SYSTEM_CSRRW: begin
				ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				ex_ctrl_o.alu_op = ALU_OP_IN1_PASSTHROUGH;
			end
			FUNCT3_SYSTEM_CSRRS: begin
				ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				ex_ctrl_o.alu_op = ALU_OP_OR;
			end
			FUNCT3_SYSTEM_CSRRC: begin
				ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_REGFILE_OUT1;
				ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_CSR_OUT;
				ex_ctrl_o.alu_op = ALU_OP_XOR;
			end
			FUNCT3_SYSTEM_CSRRWI: begin
				ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
				ex_ctrl_o.alu_op = ALU_OP_IN2_PASSTHROUGH;
			end
			FUNCT3_SYSTEM_CSRRSI: begin
				ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_CSR_OUT;
				ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
				ex_ctrl_o.alu_op = ALU_OP_OR;
			end
			FUNCT3_SYSTEM_CSRRCI: begin
				ex_ctrl_o.alu_in1_sel = ALU_IN1_SEL_CSR_OUT;
				ex_ctrl_o.alu_in2_sel = ALU_IN2_SEL_IMM;
				ex_ctrl_o.alu_op = ALU_OP_XOR;
			end
			endcase
		end
		endcase
	end

	/* MEM stage */
	always_comb begin
		mem_ctrl_o.dmem_rd_size = MEM_ACCESS_SIZE_WORD;
		mem_ctrl_o.dmem_wr_size = MEM_ACCESS_SIZE_WORD;
		mem_ctrl_o.dmem_wr_enable = 0;

		priority case (mem_reg_i.instr.common.opcode)
		OPCODE_LOAD: begin
			priority case (mem_reg_i.instr.itype.funct3)
			FUNCT3_LOAD_LB, FUNCT3_LOAD_LBU:
				mem_ctrl_o.dmem_rd_size = MEM_ACCESS_SIZE_BYTE;
			FUNCT3_LOAD_LH, FUNCT3_LOAD_LHU:
				mem_ctrl_o.dmem_rd_size = MEM_ACCESS_SIZE_HALF;
			FUNCT3_LOAD_LW:
				mem_ctrl_o.dmem_rd_size = MEM_ACCESS_SIZE_WORD;
			endcase
		end
		OPCODE_STORE: begin
			mem_ctrl_o.dmem_wr_enable = 1;

			priority case (mem_reg_i.instr.itype.funct3)
			FUNCT3_STORE_SB:
				mem_ctrl_o.dmem_wr_size = MEM_ACCESS_SIZE_BYTE;
			FUNCT3_STORE_SH:
				mem_ctrl_o.dmem_wr_size = MEM_ACCESS_SIZE_HALF;
			FUNCT3_STORE_SW:
				mem_ctrl_o.dmem_wr_size = MEM_ACCESS_SIZE_WORD;
			endcase
		end
		endcase

		if (!mem_reg_i.valid)
			mem_ctrl_o.dmem_wr_enable = 0;
	end

	/* WB stage */
	always_comb begin
		priority case (wb_reg_i.instr.common.opcode)
		OPCODE_LUI: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_ALU_OUT;
		end
		OPCODE_AUIPC: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_ALU_OUT;
		end
		OPCODE_JAL: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_PC_4;
		end
		OPCODE_JALR: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_PC_4;
		end
		OPCODE_LOAD: begin
			priority case (wb_reg_i.instr.itype.funct3)
			FUNCT3_LOAD_LB:
				wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_MEM_RD_SEXT8;
			FUNCT3_LOAD_LH:
				wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_MEM_RD_SEXT16;
			FUNCT3_LOAD_LW, FUNCT3_LOAD_LBU, FUNCT3_LOAD_LHU:
				wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_MEM_RD;
			endcase
		end
		OPCODE_OP_IMM: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_ALU_OUT;
		end
		OPCODE_OP: begin
			wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_ALU_OUT;
		end
		OPCODE_SYSTEM: begin
			priority case (wb_reg_i.instr.itype.funct3)
			FUNCT3_SYSTEM_CSRRW, FUNCT3_SYSTEM_CSRRS,
			FUNCT3_SYSTEM_CSRRC, FUNCT3_SYSTEM_CSRRWI,
			FUNCT3_SYSTEM_CSRRSI, FUNCT3_SYSTEM_CSRRCI: begin
				wb_ctrl_o.regfile_in_sel = REGFILE_IN_SEL_CSR_OUT;
			end
			endcase
		end
		endcase
	end
endmodule
