import definitions::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	mem_if.slave imemif,
	mem_if.slave dmemif
);
	/* Pipeline registers */
	logic [31:0] pc;
	pipeline_id_reg_t id_reg;
	pipeline_ex_reg_t ex_reg;
	pipeline_mem_reg_t mem_reg;
	pipeline_wb_reg_t wb_reg;

	/* Pipeline registers next state */
	logic [31:0] next_pc;
	pipeline_id_reg_t next_id_reg;
	pipeline_ex_reg_t next_ex_reg;
	pipeline_mem_reg_t next_mem_reg;
	pipeline_wb_reg_t next_wb_reg;

	/* Pipeline per-stage control signals (control output) */
	pipeline_if_ctrl_t if_ctrl;
	pipeline_id_ctrl_t id_ctrl;
	pipeline_ex_ctrl_t ex_ctrl;
	pipeline_mem_ctrl_t mem_ctrl;
	pipeline_wb_ctrl_t wb_ctrl;

	logic [31:0] regfile_wr_data;
	logic [31:0] alu_in1;
	logic [31:0] alu_in2;

	control control(
		.id_reg_i(id_reg),
		.ex_reg_i(ex_reg),
		.mem_reg_i(mem_reg),
		.wb_reg_i(wb_reg),
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

	assign next_id_reg.pc = pc;
	assign next_id_reg.instr = imemif.rd_data;
	assign next_id_reg.valid = if_ctrl.id_reg_valid;

	always_comb begin
		priority case (if_ctrl.next_pc_sel)
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		NEXT_PC_SEL_ALU_OUT:
			next_pc = mem_reg.alu_out;
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (reset_i)
			pc <= 'h00010000;
		else if (if_ctrl.pc_we)
			pc <= if_ctrl.pc_reg_stall ? pc : next_pc;
	end

	always_ff @(posedge clk_i) begin
		if (reset_i)
			id_reg <= 'b0;
		else
			id_reg <= if_ctrl.id_reg_stall ? id_reg : next_id_reg;
	end

	/* ID stage */
	assign next_ex_reg.pc = id_reg.pc;
	assign next_ex_reg.instr = id_reg.instr;
	assign next_ex_reg.regfile_rd = id_reg.instr.common.rd;
	assign next_ex_reg.regfile_we = id_ctrl.regfile_we;
	assign next_ex_reg.csr_we = id_ctrl.csr_we;
	assign next_ex_reg.valid = id_ctrl.ex_reg_valid;

	regfile regfile(
		.clk_i(clk_i),
		.rd_addr1_i(id_reg.instr.common.rs1),
		.rd_addr2_i(id_reg.instr.common.rs2),
		.wr_addr_i(wb_reg.regfile_rd),
		.wr_data_i(regfile_wr_data),
		.wr_en_i(wb_reg.regfile_we & wb_reg.valid),
		.rd_data1_o(next_ex_reg.regfile_out1),
		.rd_data2_o(next_ex_reg.regfile_out2)
	);

	csr csr(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rd_addr_i(id_reg.instr.itype.imm),
		.wr_addr_i(wb_reg.instr.itype.imm),
		.wr_data_i(wb_reg.alu_out),
		.wr_en_i(wb_reg.csr_we & wb_reg.valid),
		.rd_data_o(next_ex_reg.csr_out)
	);

	immediate immediate(
		.instr_i(id_reg.instr),
		.imm_o(next_ex_reg.imm)
	);

	always_ff @(posedge clk_i) begin
		if (reset_i)
			ex_reg <= 'b0;
		else
			ex_reg <= next_ex_reg;
	end

	/* EX stage */
	assign next_mem_reg.pc = ex_reg.pc;
	assign next_mem_reg.instr = ex_reg.instr;
	assign next_mem_reg.regfile_out2 = ex_reg.regfile_out2;
	assign next_mem_reg.csr_out = ex_reg.csr_out;
	assign next_mem_reg.regfile_rd = ex_reg.regfile_rd;
	assign next_mem_reg.regfile_we = ex_reg.regfile_we;
	assign next_mem_reg.csr_we = ex_reg.csr_we;
	assign next_mem_reg.valid = ex_ctrl.mem_reg_valid;

	always_comb begin
		priority case (ex_ctrl.alu_in1_sel)
		ALU_IN1_SEL_REGFILE_OUT1:
			alu_in1 = ex_reg.regfile_out1;
		ALU_IN1_SEL_PC:
			alu_in1 = ex_reg.pc;
		ALU_IN1_SEL_CSR_OUT:
			alu_in1 = ex_reg.csr_out;
		endcase

		priority case (ex_ctrl.alu_in2_sel)
		ALU_IN2_SEL_REGFILE_OUT2:
			alu_in2 = ex_reg.regfile_out2;
		ALU_IN2_SEL_IMM:
			alu_in2 = ex_reg.imm;
		ALU_IN2_SEL_CSR_OUT:
			alu_in2 = ex_reg.csr_out;
		endcase
	end

	alu alu(
		.alu_op_i(ex_ctrl.alu_op),
		.in1_i(alu_in1),
		.in2_i(alu_in2),
		.out_o(next_mem_reg.alu_out)
	);

	compare_unit cmp_unit(
		.compare_unit_op_i(ex_ctrl.compare_unit_op),
		.in1_i(ex_reg.regfile_out1),
		.in2_i(ex_reg.regfile_out2),
		.res_o(next_mem_reg.cmp_unit_res)
	);

	always_ff @(posedge clk_i) begin
		if (reset_i)
			mem_reg <= 'b0;
		else
			mem_reg <= next_mem_reg;
	end

	/* MEM stage */
	assign dmemif.rd_addr = mem_reg.alu_out;
	assign dmemif.rd_size = mem_ctrl.dmem_rd_size;
	assign dmemif.wr_addr = mem_reg.alu_out;
	assign dmemif.wr_data = mem_reg.regfile_out2;
	assign dmemif.wr_size = mem_ctrl.dmem_wr_size;
	assign dmemif.wr_enable = mem_ctrl.dmem_wr_enable;

	assign next_wb_reg.pc = mem_reg.pc;
	assign next_wb_reg.instr = mem_reg.instr;
	assign next_wb_reg.csr_out = mem_reg.csr_out;
	assign next_wb_reg.alu_out = mem_reg.alu_out;
	assign next_wb_reg.dmem_rd_data = dmemif.rd_data;
	assign next_wb_reg.regfile_rd = mem_reg.regfile_rd;
	assign next_wb_reg.regfile_we = mem_reg.regfile_we;
	assign next_wb_reg.csr_we = mem_reg.csr_we;
	assign next_wb_reg.valid = mem_reg.valid;

	always_ff @(posedge clk_i) begin
		if (reset_i)
			wb_reg <= 'b0;
		else
			wb_reg <= next_wb_reg;
	end

	/* WB stage */
	always_comb begin
		priority case (wb_ctrl.regfile_in_sel)
		REGFILE_IN_SEL_ALU_OUT:
			regfile_wr_data = wb_reg.alu_out;
		REGFILE_IN_SEL_PC_4:
			regfile_wr_data = wb_reg.pc + 4;
		REGFILE_IN_SEL_MEM_RD:
			regfile_wr_data = wb_reg.dmem_rd_data;
		REGFILE_IN_SEL_MEM_RD_SEXT8:
			regfile_wr_data = {{24{wb_reg.dmem_rd_data[7]}}, wb_reg.dmem_rd_data[7:0]};
		REGFILE_IN_SEL_MEM_RD_SEXT16:
			regfile_wr_data = {{16{wb_reg.dmem_rd_data[15]}}, wb_reg.dmem_rd_data[15:0]};
		REGFILE_IN_SEL_CSR_OUT:
			regfile_wr_data = wb_reg.csr_out;
		endcase
	end
endmodule
