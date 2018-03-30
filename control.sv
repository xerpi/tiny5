import definitions::*;

module control(
	input logic clk_i,
	input logic reset_i,
	input logic [31:0] ir_i,
	output logic pc_we_o,
	output logic ir_we_o,
	output logic regfile_we_o,
	output next_pc_sel_t next_pc_sel_o,
	output regfile_in_sel_t regfile_in_sel_o,
	output mem_rd_addr_sel_t mem_rd_addr_sel_o,
	output alu_op_t alu_op_o,
	output alu_in1_sel_t alu_in1_sel_o,
	output alu_in2_sel_t alu_in2_sel_o
);
	enum logic [1:0] {
		RESET,
		FETCH,
		DEMW
	} state;

	instruction_t instr;
	assign instr = ir_i;

	/* TODOs */
	assign next_pc_sel_o = NEXT_PC_SEL_PC_4;

	/* Current state driven output logic */
	always_comb begin
		priority case (state)
		RESET: begin
			pc_we_o = 0;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_PC;
		end
		FETCH: begin
			pc_we_o = 0;
			ir_we_o = 1;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_PC;
		end
		DEMW: begin
			pc_we_o = 1;
			ir_we_o = 0;
			mem_rd_addr_sel_o = MEM_RD_ADDR_SEL_ALU_OUT;
		end
		endcase
	end

	/* Current instruction driven output logic (decoder) */
	always_comb begin
		regfile_we_o = 0;

		if (state == DEMW) begin
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
			OPCODE_OP_IMM: begin
				priority case (instr.itype.funct3)
				FUNCT3_OP_IMM_ADDI: begin
					regfile_we_o = 1;
					regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
					alu_op_o = ALU_OP_ADD;
					alu_in1_sel_o = ALU_IN1_SEL_REGFILE_OUT1;
					alu_in2_sel_o = ALU_IN2_SEL_IR_ITYPE_IMM;
				end
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
				FUNCT3_OP_AND:
					alu_op_o = ALU_OP_AND;
				FUNCT3_OP_OR:
					alu_op_o = ALU_OP_OR;
				endcase
			end
			endcase
		end
	end

	/* Next state logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= RESET;
		end else begin
			priority case (state)
			FETCH:
				state <= DEMW;
			RESET, DEMW:
				state <= FETCH;
			endcase
		end
	end
endmodule
