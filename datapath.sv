import definitions::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	/* Memory interface */
	input logic [31:0] mem_rd_data_i,
	output logic [31:0] mem_rd_addr_o,
	output mem_access_size_t mem_rd_size_o,
	output logic [31:0] mem_wr_addr_o,
	output logic [31:0] mem_wr_data_o,
	output mem_access_size_t mem_wr_size_o,
	output logic mem_wr_enable_o
);
	/* registers */
	logic [31:0] pc;
	logic [31:0] ir;

	/* nets */
	instruction_t instr;
	logic [31:0] next_pc;
	logic [31:0] next_ir;
	logic [31:0] alu_din1;
	logic [31:0] alu_din2;

	/* regfile inputs */
	logic [31:0] rf_rin;

	/* regfile outputs */
	logic [31:0] rf_rout1;
	logic [31:0] rf_rout2;

	/* control outputs */
	logic ctrl_pc_we;
	logic ctrl_ir_we;
	logic ctrl_regfile_we;
	next_pc_sel_t ctrl_next_pc_sel;
	regfile_in_sel_t ctrl_regfile_in_sel;
	mem_rd_addr_sel_t ctrl_mem_rd_addr_sel;
	alu_op_t ctrl_alu_op;
	alu_in1_sel_t ctrl_alu_in1_sel;
	alu_in2_sel_t ctrl_alu_in2_sel;
	compare_unit_op_t ctrl_compare_unit_op;

	/* alu outputs */
	logic [31:0] alu_dout;

	/* compare unit outputs */
	logic cmp_unit_res;

	assign instr = ir;

	regfile rf(
		.clk_i(clk_i),
		.rs1_i(instr.common.rs1),
		.rs2_i(instr.common.rs2),
		.rd_i(instr.common.rd),
		.rin_i(rf_rin),
		.we_i(ctrl_regfile_we),
		.rout1_o(rf_rout1),
		.rout2_o(rf_rout2)
	);

	control ctrl(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.ir_i(ir),
		.pc_we_o(ctrl_pc_we),
		.ir_we_o(ctrl_ir_we),
		.regfile_we_o(ctrl_regfile_we),
		.next_pc_sel_o(ctrl_next_pc_sel),
		.regfile_in_sel_o(ctrl_regfile_in_sel),
		.mem_rd_addr_sel_o(ctrl_mem_rd_addr_sel),
		.mem_rd_size_o(mem_rd_size_o),
		.mem_wr_size_o(mem_wr_size_o),
		.mem_wr_enable_o(mem_wr_enable_o),
		.alu_op_o(ctrl_alu_op),
		.alu_in1_sel_o(ctrl_alu_in1_sel),
		.alu_in2_sel_o(ctrl_alu_in2_sel),
		.compare_unit_op_o(ctrl_compare_unit_op)
	);

	alu al(
		.alu_op_i(ctrl_alu_op),
		.din1_i(alu_din1),
		.din2_i(alu_din2),
		.dout_o(alu_dout)
	);

	compare_unit cmp_unit(
		.compare_unit_op_i(ctrl_compare_unit_op),
		.in1_i(rf_rout1),
		.in2_i(rf_rout2),
		.res_o(cmp_unit_res)
	);

	always_comb begin
		mem_wr_addr_o = alu_dout;
		mem_wr_data_o = rf_rout2;

		priority case (ctrl_next_pc_sel)
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		NEXT_PC_SEL_ALU_OUT:
			next_pc = alu_dout;
		NEXT_PC_SEL_COMPARE_UNIT_OUT:
			if (cmp_unit_res == 0)
				next_pc = pc + 4;
			else
				next_pc = alu_dout;
		endcase

		priority case (ctrl_regfile_in_sel)
		REGFILE_IN_SEL_ALU_OUT:
			rf_rin = alu_dout;
		REGFILE_IN_SEL_PC_4:
			rf_rin = pc + 4;
		REGFILE_IN_SEL_MEM_RD:
			rf_rin = mem_rd_data_i;
		REGFILE_IN_SEL_MEM_RD_SEXT8:
			rf_rin = {{24{mem_rd_data_i[7]}}, mem_rd_data_i[7:0]};
		REGFILE_IN_SEL_MEM_RD_SEXT16:
			rf_rin = {{16{mem_rd_data_i[15]}}, mem_rd_data_i[15:0]};
		endcase

		priority case (ctrl_mem_rd_addr_sel)
		MEM_RD_ADDR_SEL_PC:
			mem_rd_addr_o = pc;
		MEM_RD_ADDR_SEL_ALU_OUT:
			mem_rd_addr_o = alu_dout;
		endcase

		priority case (ctrl_alu_in1_sel)
		ALU_IN1_SEL_REGFILE_OUT1:
			alu_din1 = rf_rout1;
		ALU_IN1_SEL_PC:
			alu_din1 = pc;
		endcase

		priority case (ctrl_alu_in2_sel)
		ALU_IN2_SEL_REGFILE_OUT2:
			alu_din2 = rf_rout2;
		ALU_IN2_SEL_IR_UTYPE_IMM:
			alu_din2 = {instr.utype.imm, 12'b0};
		ALU_IN2_SEL_IR_ITYPE_IMM:
			alu_din2 = {{20{instr.itype.imm[11]}}, instr.itype.imm};
		ALU_IN2_SEL_IR_JTYPE_IMM:
			alu_din2 = {{11{instr.jtype.imm20}}, instr.jtype.imm20,
				instr.jtype.imm12, instr.jtype.imm11,
				instr.jtype.imm1, 1'b0};
		ALU_IN2_SEL_IR_BTYPE_IMM:
			alu_din2 = {{19{instr.btype.imm12}}, instr.btype.imm12,
				instr.btype.imm11, instr.btype.imm5,
				instr.btype.imm1, 1'b0};
		ALU_IN2_SEL_IR_STYPE_IMM:
			alu_din2 = {{20{instr.stype.imm5[6]}}, instr.stype.imm5,
				instr.stype.imm0};
		endcase

		next_ir = mem_rd_data_i;
	end

	/* Next PC/IR logic */
	always_ff @(posedge clk_i) begin
		if (ctrl_pc_we) begin
			pc <= next_pc;
		end

		if (ctrl_ir_we) begin
			ir <= next_ir;
		end
	end
endmodule
