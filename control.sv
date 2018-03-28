import definitions::*;

module control(
	input logic clk_i,
	input logic [31:0] ir_i,
	output logic pc_we_o,
	output logic ir_we_o,
	output alu_op_t alu_op_o,
	output next_pc_sel_t next_pc_sel_o,
	output regfile_in_sel_t regfile_in_sel_o,
	output mem_rd_addr_sel_t mem_rd_addr_sel_o
);
	enum {
		FETCH,
		DEMW
	} state;

	instruction_t instr;
	assign instr = ir_i;

	assign next_pc_sel_o = 0;

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
			case (instr.opcode)
			OPCODE_LUI: begin
				alu_op_o = ALU_OP_LUI;
				regfile_in_sel_o = REGFILE_IN_SEL_ALU_OUT;
			end
			endcase
		end
	end

	/* Next state logic */
	always_ff @(posedge clk_i) begin
		state <= (state == FETCH) ? DEMW : FETCH;
	end
endmodule
