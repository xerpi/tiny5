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
		unique case (state)
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
		if (state == DEMW) begin
			regfile_we_o = 0;

			case (instr.opcode)
			OPCODE_LUI: begin
				regfile_we_o = 1;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
				alu_op_o = ALU_OP_IN1_PASSTHROUGH;
				alu_in1_sel_o = ALU_IN1_SEL_IR_UTYPE_IMM;
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
