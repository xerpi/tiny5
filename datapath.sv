import definitions::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	mem_if.slave imemif,
	mem_if.slave dmemif
);
	/* Pipeline registers */
	logic [31:0] pc;
	pipeline_if_id_reg_t if_id_reg;
	pipeline_id_ex_reg_t id_ex_reg;
	pipeline_ex_mem_reg_t ex_mem_reg;
	pipeline_mem_wb_reg_t mem_wb_reg;

	/* Pipeline registers next state */
	logic [31:0] next_pc;
	pipeline_if_id_reg_t next_if_id_reg;
	pipeline_id_ex_reg_t next_id_ex_reg;
	pipeline_ex_mem_reg_t next_ex_mem_reg;
	pipeline_mem_wb_reg_t next_mem_wb_reg;

	/* Pipeline per-stage control signals (control output) */
	pipeline_if_ctrl_t if_ctrl;
	pipeline_id_ctrl_t id_ctrl;
	pipeline_ex_ctrl_t ex_ctrl;
	pipeline_mem_ctrl_t mem_ctrl;
	pipeline_wb_ctrl_t wb_ctrl;

	logic [31:0] regfile_rin;
	logic [31:0] alu_in1;
	logic [31:0] alu_in2;

	control control(
		.if_id_reg_i(if_id_reg),
		.id_ex_reg_i(id_ex_reg),
		.ex_mem_reg_i(ex_mem_reg),
		.mem_wb_reg_i(mem_wb_reg),
		.if_ctrl_o(if_ctrl),
		.id_ctrl_o(id_ctrl),
		.ex_ctrl_o(ex_ctrl),
		.mem_ctrl_o(mem_ctrl),
		.wb_ctrl_o(wb_ctrl)
	);

	/* IF stage */
	assign imemif.rd_addr = pc;
	assign imemif.rd_size = MEM_ACCESS_SIZE_WORD;
	assign imemif.wr_enable = 0;

	assign next_if_id_reg.pc = pc;
	assign next_if_id_reg.instr = imemif.rd_data;

	always_comb begin
		priority case (if_ctrl.next_pc_sel)
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		NEXT_PC_SEL_ALU_OUT:
			next_pc = mem_wb_reg.alu_out;
		NEXT_PC_SEL_COMPARE_UNIT_OUT:
			if (mem_wb_reg.cmp_unit_res == 0)
				next_pc = pc + 4;
			else
				next_pc = mem_wb_reg.alu_out;
		endcase
	end

	always_ff @(posedge clk_i) begin
		/* TODO: Improve this */
		if (reset_i)
			pc <= 'h00010000;
		else if (if_ctrl.pc_we)
			pc <= next_pc;

		if_id_reg <= next_if_id_reg;
	end

	/* ID stage */
	assign next_id_ex_reg.pc = if_id_reg.pc;
	assign next_id_ex_reg.instr = if_id_reg.instr;

	regfile regfile(
		.clk_i(clk_i),
		.rs1_i(if_id_reg.instr.common.rs1),
		.rs2_i(if_id_reg.instr.common.rs2),
		.rd_i(mem_wb_reg.instr.common.rd),
		.rin_i(regfile_rin),
		.we_i(wb_ctrl.regfile_we),
		.rout1_o(next_id_ex_reg.regfile_out1),
		.rout2_o(next_id_ex_reg.regfile_out2)
	);

	csr csr(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rs_i(if_id_reg.instr.itype.imm),
		.rd_i(mem_wb_reg.instr.itype.imm),
		.in_i(mem_wb_reg.alu_out),
		.we_i(wb_ctrl.csr_we),
		.out_o(next_id_ex_reg.csr_out)
	);

	immediate immediate(
		.instr_i(if_id_reg.instr),
		.imm_o(next_id_ex_reg.imm)
	);

	always_ff @(posedge clk_i) begin
		id_ex_reg <= next_id_ex_reg;
	end

	/* EX stage */
	assign next_ex_mem_reg.pc = id_ex_reg.pc;
	assign next_ex_mem_reg.instr = id_ex_reg.instr;
	assign next_ex_mem_reg.regfile_out2 = id_ex_reg.regfile_out2;
	assign next_ex_mem_reg.csr_out = id_ex_reg.csr_out;

	always_comb begin
		priority case (ex_ctrl.alu_in1_sel)
		ALU_IN1_SEL_REGFILE_OUT1:
			alu_in1 = id_ex_reg.regfile_out1;
		ALU_IN1_SEL_PC:
			alu_in1 = id_ex_reg.pc;
		ALU_IN1_SEL_CSR_OUT:
			alu_in1 = id_ex_reg.csr_out;
		endcase

		priority case (ex_ctrl.alu_in2_sel)
		ALU_IN2_SEL_REGFILE_OUT2:
			alu_in2 = id_ex_reg.regfile_out2;
		ALU_IN2_SEL_IMM:
			alu_in2 = id_ex_reg.imm;
		ALU_IN2_SEL_CSR_OUT:
			alu_in2 = id_ex_reg.csr_out;
		endcase
	end

	alu alu(
		.alu_op_i(ex_ctrl.alu_op),
		.in1_i(alu_in1),
		.in2_i(alu_in2),
		.out_o(next_ex_mem_reg.alu_out)
	);

	compare_unit cmp_unit(
		.compare_unit_op_i(ex_ctrl.compare_unit_op),
		.in1_i(id_ex_reg.regfile_out1),
		.in2_i(id_ex_reg.regfile_out2),
		.res_o(next_ex_mem_reg.cmp_unit_res)
	);

	always_ff @(posedge clk_i) begin
		ex_mem_reg <= next_ex_mem_reg;
	end

	/* MEM stage */
	assign dmemif.rd_addr = ex_mem_reg.alu_out;
	assign dmemif.rd_size = mem_ctrl.dmem_rd_size;
	assign dmemif.wr_addr = ex_mem_reg.alu_out;
	assign dmemif.wr_data = ex_mem_reg.regfile_out2;
	assign dmemif.wr_size = mem_ctrl.dmem_wr_size;
	assign dmemif.wr_enable = mem_ctrl.dmem_wr_enable;

	assign next_mem_wb_reg.pc = ex_mem_reg.pc;
	assign next_mem_wb_reg.instr = ex_mem_reg.instr;
	assign next_mem_wb_reg.csr_out = ex_mem_reg.csr_out;
	assign next_mem_wb_reg.alu_out = ex_mem_reg.alu_out;
	assign next_mem_wb_reg.cmp_unit_res = ex_mem_reg.cmp_unit_res;
	assign next_mem_wb_reg.dmem_rd_data = dmemif.rd_data;

	always_ff @(posedge clk_i) begin
		mem_wb_reg <= next_mem_wb_reg;
	end

	/* WB stage */
	always_comb begin
		priority case (wb_ctrl.regfile_in_sel)
		REGFILE_IN_SEL_ALU_OUT:
			regfile_rin = mem_wb_reg.alu_out;
		REGFILE_IN_SEL_PC_4:
			regfile_rin = mem_wb_reg.pc + 4;
		REGFILE_IN_SEL_MEM_RD:
			regfile_rin = dmemif.rd_data;
		REGFILE_IN_SEL_MEM_RD_SEXT8:
			regfile_rin = {{24{dmemif.rd_data[7]}}, dmemif.rd_data[7:0]};
		REGFILE_IN_SEL_MEM_RD_SEXT16:
			regfile_rin = {{16{dmemif.rd_data[15]}}, dmemif.rd_data[15:0]};
		REGFILE_IN_SEL_CSR_OUT:
			regfile_rin = mem_wb_reg.csr_out;
		endcase
	end
endmodule
