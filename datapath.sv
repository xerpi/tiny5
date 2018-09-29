import definitions::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	mem_if.slave memif
);
	/* registers */
	logic [31:0] pc;
	logic [31:0] ir;

	/* nets */
	instruction_t instr;
	logic [31:0] next_pc;
	logic [31:0] next_ir;
	logic [31:0] alu_in1;
	logic [31:0] alu_in2;

	/* regfile inputs */
	logic [31:0] rf_rin;

	/* regfile outputs */
	logic [31:0] rf_rout1;
	logic [31:0] rf_rout2;

	/* immediate outputs */
	logic [31:0] immediate_imm;

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
	logic ctrl_csr_we;

	/* alu outputs */
	logic [31:0] alu_out;

	/* compare unit outputs */
	logic cmp_unit_res;

	/* CSR outputs */
	logic [31:0] csr_dout;

	assign instr = ir;

	regfile regfile(
		.clk_i(clk_i),
		.rs1_i(instr.common.rs1),
		.rs2_i(instr.common.rs2),
		.rd_i(instr.common.rd),
		.rin_i(rf_rin),
		.we_i(ctrl_regfile_we),
		.rout1_o(rf_rout1),
		.rout2_o(rf_rout2)
	);

	immediate immediate(
		.instr_i(ir),
		.imm_o(immediate_imm)
	);

	control control(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.ir_i(ir),
		.pc_we_o(ctrl_pc_we),
		.ir_we_o(ctrl_ir_we),
		.regfile_we_o(ctrl_regfile_we),
		.next_pc_sel_o(ctrl_next_pc_sel),
		.regfile_in_sel_o(ctrl_regfile_in_sel),
		.mem_rd_addr_sel_o(ctrl_mem_rd_addr_sel),
		.mem_rd_size_o(memif.rd_size),
		.mem_wr_size_o(memif.wr_size),
		.mem_wr_enable_o(memif.wr_enable),
		.alu_op_o(ctrl_alu_op),
		.alu_in1_sel_o(ctrl_alu_in1_sel),
		.alu_in2_sel_o(ctrl_alu_in2_sel),
		.compare_unit_op_o(ctrl_compare_unit_op),
		.csr_we_o(ctrl_csr_we)
	);

	alu alu(
		.alu_op_i(ctrl_alu_op),
		.in1_i(alu_in1),
		.in2_i(alu_in2),
		.out_o(alu_out)
	);

	compare_unit cmp_unit(
		.compare_unit_op_i(ctrl_compare_unit_op),
		.in1_i(rf_rout1),
		.in2_i(rf_rout2),
		.res_o(cmp_unit_res)
	);

	csr csr(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.sel_i(instr.itype.imm),
		.din_i(alu_out),
		.we_i(ctrl_csr_we),
		.dout_o(csr_dout)
	);

	always_comb begin
		memif.wr_addr = alu_out;
		memif.wr_data = rf_rout2;

		priority case (ctrl_next_pc_sel)
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		NEXT_PC_SEL_ALU_OUT:
			next_pc = alu_out;
		NEXT_PC_SEL_COMPARE_UNIT_OUT:
			if (cmp_unit_res == 0)
				next_pc = pc + 4;
			else
				next_pc = alu_out;
		endcase

		priority case (ctrl_regfile_in_sel)
		REGFILE_IN_SEL_ALU_OUT:
			rf_rin = alu_out;
		REGFILE_IN_SEL_PC_4:
			rf_rin = pc + 4;
		REGFILE_IN_SEL_MEM_RD:
			rf_rin = memif.rd_data;
		REGFILE_IN_SEL_MEM_RD_SEXT8:
			rf_rin = {{24{memif.rd_data[7]}}, memif.rd_data[7:0]};
		REGFILE_IN_SEL_MEM_RD_SEXT16:
			rf_rin = {{16{memif.rd_data[15]}}, memif.rd_data[15:0]};
		REGFILE_IN_SEL_CSR_OUT:
			rf_rin = csr_dout;
		endcase

		priority case (ctrl_mem_rd_addr_sel)
		MEM_RD_ADDR_SEL_PC:
			memif.rd_addr = pc;
		MEM_RD_ADDR_SEL_ALU_OUT:
			memif.rd_addr = alu_out;
		endcase

		priority case (ctrl_alu_in1_sel)
		ALU_IN1_SEL_REGFILE_OUT1:
			alu_in1 = rf_rout1;
		ALU_IN1_SEL_PC:
			alu_in1 = pc;
		ALU_IN1_SEL_CSR_OUT:
			alu_in1 = csr_dout;
		endcase

		priority case (ctrl_alu_in2_sel)
		ALU_IN2_SEL_REGFILE_OUT2:
			alu_in2 = rf_rout2;
		ALU_IN2_SEL_IMM:
			alu_in2 = immediate_imm;
		ALU_IN2_SEL_CSR_OUT:
			alu_in2 = csr_dout;
		endcase

		next_ir = memif.rd_data;
	end

	/* Next PC/IR logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			pc <= 'h00010000;
			ir <= 0;
		end else begin
			if (ctrl_pc_we) begin
				pc <= next_pc;
			end

			if (ctrl_ir_we) begin
				ir <= next_ir;
			end
		end
	end
endmodule
