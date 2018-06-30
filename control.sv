import definitions::*;

module control(
	input logic clk_i,
	input logic reset_i,
	input logic error_i,
	input logic [31:0] ir_i,
	output logic pc_we_o,
	output logic ir_we_o,
	output logic regfile_we_o,
	output next_pc_sel_t next_pc_sel_o,
	output regfile_in_sel_t regfile_in_sel_o,
	output mem_rd_addr_sel_t mem_rd_addr_sel_o,
	output mem_access_size_t mem_rd_size_o,
	output logic mem_rd_enable_o,
	output mem_access_size_t mem_wr_size_o,
	output logic mem_wr_enable_o,
	input logic mem_busy_i,
	output alu_op_t alu_op_o,
	output alu_in1_sel_t alu_in1_sel_o,
	output alu_in2_sel_t alu_in2_sel_o,
	output compare_unit_op_t compare_unit_op_o,
	output logic csr_we_o
);
	enum logic [2:0] {
		RESET,
		FETCH_ISSUE,
		FETCH_WAIT,
		DEMW_ISSUE,
		DEMW_WAIT,
		ERROR
	} state, next_state;

	instruction_t instr;
	assign instr = ir_i;

	logic halt;
	assign halt = mem_busy_i;

	/* Current-state-only driven output logic */
	always_comb begin
		priority case (state)
		RESET: begin
			pc_we_o = 0;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_PC;
		end
		FETCH_ISSUE: begin
			pc_we_o = 0;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_PC;
		end
		FETCH_WAIT: begin
			pc_we_o = 0;
			if (halt)
				ir_we_o = 0;
			else
				ir_we_o = 1;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_PC;
		end
		DEMW_ISSUE: begin
			pc_we_o = 0;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_ALU_OUT;
		end
		DEMW_WAIT: begin
			if (halt)
				pc_we_o = 0;
			else
				pc_we_o = 1;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_ALU_OUT;
		end
		ERROR: begin
			pc_we_o = 0;
			ir_we_o = 0;
		end
		endcase
	end

	/* Current instruction (and state) driven output logic (decoder) */
	always_comb begin
		/* Strict defaults */
		regfile_we_o = 0;
		next_pc_sel_o = NEXT_PC_SEL_PC_4;
		mem_rd_size_o = MEM_ACCESS_SIZE_WORD;
		mem_wr_size_o = MEM_ACCESS_SIZE_WORD;
		mem_rd_enable_o = 0;
		mem_wr_enable_o = 0;
		csr_we_o = 0;

		/* Don't care defaults */
		regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
		alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
		alu_in2_sel_o = ALU_IN2_SEL_REGFILE_OUT2;
		compare_unit_op_o = COMPARE_UNIT_OP_EQ;

		if (state == FETCH_ISSUE) begin
			mem_rd_enable_o = 1;
		end if (state == DEMW_WAIT) begin
			if (!halt) begin
				/* LOAD completed, write to the regfile */
				if (instr.common.opcode == OPCODE_LOAD) begin
					priority case (instr.itype.funct3)
					FUNCT3_LOAD_LB:
						regfile_in_sel_o = REGFILE_IN_SEL_MEM_RD_SEXT8;
					FUNCT3_LOAD_LH:
						regfile_in_sel_o = REGFILE_IN_SEL_MEM_RD_SEXT16;
					FUNCT3_LOAD_LW, FUNCT3_LOAD_LBU, FUNCT3_LOAD_LHU:
						regfile_in_sel_o = REGFILE_IN_SEL_MEM_RD;
					endcase

					regfile_we_o = 1;
				end
			end
		end if (state == DEMW_ISSUE) begin
			priority case (instr.common.opcode)
			OPCODE_LUI: begin
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
				alu_op_o = ALU_OP_IN2_PASSTHROUGH;
				alu_in2_sel_o = ALU_IN2_SEL_IR_UTYPE_IMM;
			end
			OPCODE_AUIPC: begin
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_PC;
				alu_in2_sel_o = ALU_IN2_SEL_IR_UTYPE_IMM;
			end
			OPCODE_JAL: begin
				next_pc_sel_o = NEXT_PC_SEL_ALU_OUT;
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_PC_4;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_PC;
				alu_in2_sel_o = ALU_IN2_SEL_IR_JTYPE_IMM;
			end
			OPCODE_JALR: begin
				next_pc_sel_o = NEXT_PC_SEL_ALU_OUT;
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_PC_4;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
				alu_in2_sel_o = ALU_IN2_SEL_IR_ITYPE_IMM;
			end
			OPCODE_BRANCH: begin
				next_pc_sel_o = NEXT_PC_SEL_COMPARE_UNIT_OUT;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_PC;
				alu_in2_sel_o = ALU_IN2_SEL_IR_BTYPE_IMM;

				priority case (instr.btype.funct3)
				FUNCT3_BRANCH_BEQ:
					compare_unit_op_o = COMPARE_UNIT_OP_EQ;
				FUNCT3_BRANCH_BNE:
					compare_unit_op_o = COMPARE_UNIT_OP_NE;
				FUNCT3_BRANCH_BLT:
					compare_unit_op_o = COMPARE_UNIT_OP_LT;
				FUNCT3_BRANCH_BGE:
					compare_unit_op_o = COMPARE_UNIT_OP_GE;
				FUNCT3_BRANCH_BLTU:
					compare_unit_op_o = COMPARE_UNIT_OP_LTU;
				FUNCT3_BRANCH_BGEU:
					compare_unit_op_o = COMPARE_UNIT_OP_GEU;
				endcase
			end
			OPCODE_LOAD: begin
				/* For LOADs this is done when we receive the data! */
				regfile_we_o = 0;
				mem_rd_enable_o = 1;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
				alu_in2_sel_o = ALU_IN2_SEL_IR_ITYPE_IMM;

				priority case (instr.itype.funct3)
				FUNCT3_LOAD_LB, FUNCT3_LOAD_LBU:
					mem_rd_size_o = MEM_ACCESS_SIZE_BYTE;
				FUNCT3_LOAD_LH, FUNCT3_LOAD_LHU:
					mem_rd_size_o = MEM_ACCESS_SIZE_HALF;
				FUNCT3_LOAD_LW:
					mem_rd_size_o = MEM_ACCESS_SIZE_WORD;
				endcase
			end
			OPCODE_STORE: begin
				mem_wr_enable_o = 1;
				alu_op_o = ALU_OP_ADD;
				alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
				alu_in2_sel_o = ALU_IN2_SEL_IR_STYPE_IMM;

				priority case (instr.itype.funct3)
				FUNCT3_STORE_SB:
					mem_wr_size_o = MEM_ACCESS_SIZE_BYTE;
				FUNCT3_STORE_SH:
					mem_wr_size_o = MEM_ACCESS_SIZE_HALF;
				FUNCT3_STORE_SW:
					mem_wr_size_o = MEM_ACCESS_SIZE_WORD;
				endcase
			end
			OPCODE_OP_IMM: begin
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
				alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
				alu_in2_sel_o = ALU_IN2_SEL_IR_ITYPE_IMM;

				priority case (instr.itype.funct3)
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
					if (instr.itype.imm[10] == 0)
						alu_op_o = ALU_OP_SRL;
					else
						alu_op_o = ALU_OP_SRA;
				endcase
			end
			OPCODE_OP: begin
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
				alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
				alu_in2_sel_o = ALU_IN2_SEL_REGFILE_OUT2;

				priority case (instr.rtype.funct3)
				FUNCT3_OP_ADD_SUB: begin
					if (instr.rtype.funct7[5] == 0)
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
					if (instr.rtype.funct7[5] == 0)
						alu_op_o = ALU_OP_SRL;
					else
						alu_op_o = ALU_OP_SRA;
				FUNCT3_OP_OR:
					alu_op_o = ALU_OP_OR;
				FUNCT3_OP_AND:
					alu_op_o = ALU_OP_AND;
				endcase
			end
			OPCODE_MISC_MEM: begin
				priority case (instr.itype.funct3)
				FUNCT3_MISC_MEM_FENCE:
					; /* do nothing */
				FUNCT3_MISC_MEM_FENCE_I:
					; /* do nothing */
				endcase
			end
			OPCODE_SYSTEM: begin
				regfile_we_o = 1;
				csr_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_CSR_OUT;

				priority case (instr.itype.funct3)
				FUNCT3_SYSTEM_CSRRW: begin
					alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
					alu_op_o = ALU_OP_IN1_PASSTHROUGH;
				end
				FUNCT3_SYSTEM_CSRRS: begin
					alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
					alu_in2_sel_o = ALU_IN2_SEL_CSR_OUT;
					alu_op_o = ALU_OP_OR;
				end
				FUNCT3_SYSTEM_CSRRC: begin
					alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
					alu_in2_sel_o = ALU_IN2_SEL_CSR_OUT;
					alu_op_o = ALU_OP_XOR;
				end
				FUNCT3_SYSTEM_CSRRWI: begin
					alu_in1_sel_o = ALU_IN1_SEL_IR_CSR_UIMM;
					alu_op_o = ALU_OP_IN1_PASSTHROUGH;
				end
				FUNCT3_SYSTEM_CSRRSI: begin
					alu_in1_sel_o = ALU_IN1_SEL_IR_CSR_UIMM;
					alu_in2_sel_o = ALU_IN2_SEL_CSR_OUT;
					alu_op_o = ALU_OP_OR;
				end
				FUNCT3_SYSTEM_CSRRCI: begin
					alu_in1_sel_o = ALU_IN1_SEL_IR_CSR_UIMM;
					alu_in2_sel_o = ALU_IN2_SEL_CSR_OUT;
					alu_op_o = ALU_OP_XOR;
				end
				endcase
			end
			endcase
		end
	end

	/* Next state combinational logic */
	always_comb begin
		if (error_i) begin
			next_state = ERROR;
		end else begin
			priority case (state)
			FETCH_ISSUE:
				next_state = FETCH_WAIT;
			FETCH_WAIT: begin
				if (halt) begin
					next_state = FETCH_WAIT;
				end else begin
					next_state = DEMW_ISSUE;
				end
			end
			DEMW_ISSUE:
				next_state = DEMW_WAIT;
			DEMW_WAIT: begin
				if (halt) begin
					next_state = DEMW_WAIT;
				end else begin
					next_state = FETCH_ISSUE;
				end
			end
			RESET:
				next_state = FETCH_ISSUE;
			ERROR:
				next_state = ERROR;
			endcase
		end
	end

	/* Next state sequential logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= RESET;
		end else begin
			state <= next_state;
		end
	end
endmodule
