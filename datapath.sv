import definitions::*;
import cache_interface_types::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	cache_interface.master icache_bus,
	cache_interface.master dcache_bus
);
	/* Pipeline registers */
	logic [31:0] pc;
	pipeline_id_reg_t id_reg;
	pipeline_ex_reg_t ex_reg;
	pipeline_mem_reg_t mem_reg;
	pipeline_wb_reg_t wb_reg;

	/* Pipeline next state signals */
	logic [31:0] next_pc;
	pipeline_id_reg_t next_id_reg;
	pipeline_ex_reg_t next_ex_reg;
	pipeline_mem_reg_t next_mem_reg;
	pipeline_wb_reg_t next_wb_reg;

	/* Pipeline control signal */
	pipeline_control_t control;

	/* Inter-stage signals */
	logic [31:0] wb_regfile_wr_data;
	logic [31:0] ex_alu_out;

	/* Control unit */
	control control_unit(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.id_reg_i(id_reg),
		.ex_reg_i(ex_reg),
		.mem_reg_i(mem_reg),
		.wb_reg_i(wb_reg),
		.icache_ready_i(icache_bus.ready),
		.icache_miss_i(icache_bus.miss),
		.dcache_ready_i(dcache_bus.ready),
		.dcache_miss_i(dcache_bus.miss),
		.control_o(control),
		.icache_valid_o(icache_bus.valid),
		.dcache_valid_o(dcache_bus.valid)
	);

	/* IF stage */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			pc <= 'h00001000;
		else
			pc <= control.pc_reg_stall ? pc : next_pc;
	end

	assign icache_bus.addr = pc;
	assign icache_bus.write = 0;

	always_comb begin
		priority case (control.next_pc_sel)
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		NEXT_PC_SEL_ALU_OUT:
			next_pc = mem_reg.alu_out;
		endcase
	end

	assign next_id_reg.pc = pc;
	assign next_id_reg.instr = icache_bus.rd_data;
	assign next_id_reg.valid = control.id_reg_valid;

	/* ID stage */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			id_reg <= 'b0;
		else
			id_reg <= control.id_reg_stall ? id_reg : next_id_reg;
	end

	logic [31:0] id_regfile_out1;
	logic [31:0] id_regfile_out2;

	regfile regfile(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rd_addr1_i(id_reg.instr.common.rs1),
		.rd_addr2_i(id_reg.instr.common.rs2),
		.wr_addr_i(wb_reg.regfile_wr_addr),
		.wr_data_i(wb_regfile_wr_data),
		.wr_en_i(wb_reg.regfile_we && wb_reg.valid),
		.rd_data1_o(id_regfile_out1),
		.rd_data2_o(id_regfile_out2)
	);

	csr csr(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rd_addr_i(id_reg.instr.itype.imm),
		.wr_addr_i(wb_reg.csr_wr_addr),
		.wr_data_i(wb_reg.alu_out),
		.wr_en_i(wb_reg.csr_we && wb_reg.valid),
		.instret_i(wb_reg.valid),
		.rd_data_o(next_ex_reg.csr_out)
	);

	immediate immediate(
		.instr_i(id_reg.instr),
		.imm_o(next_ex_reg.imm)
	);

	assign next_ex_reg.pc = id_reg.pc;

	always_comb begin
		priority case (control.alu_out_to_reg1_bypass)
		ALU_OUT_BYPASS_FROM_NONE:
			next_ex_reg.regfile_out1 = id_regfile_out1;
		ALU_OUT_BYPASS_FROM_EX:
			next_ex_reg.regfile_out1 = ex_alu_out;
		ALU_OUT_BYPASS_FROM_MEM:
			next_ex_reg.regfile_out1 = mem_reg.alu_out;
		ALU_OUT_BYPASS_FROM_WB:
			next_ex_reg.regfile_out1 = wb_reg.alu_out;
		endcase
	end

	always_comb begin
		priority case (control.alu_out_to_reg2_bypass)
		ALU_OUT_BYPASS_FROM_NONE:
			next_ex_reg.regfile_out2 = id_regfile_out2;
		ALU_OUT_BYPASS_FROM_EX:
			next_ex_reg.regfile_out2 = ex_alu_out;
		ALU_OUT_BYPASS_FROM_MEM:
			next_ex_reg.regfile_out2 = mem_reg.alu_out;
		ALU_OUT_BYPASS_FROM_WB:
			next_ex_reg.regfile_out2 = wb_reg.alu_out;
		endcase
	end

	assign next_ex_reg.regfile_wr_addr = id_reg.instr.common.rd;
	assign next_ex_reg.csr_wr_addr = id_reg.instr.itype.imm;
	assign next_ex_reg.regfile_we = control.decode_out.regfile_we;
	assign next_ex_reg.csr_we = control.decode_out.csr_we;
	assign next_ex_reg.alu_op = control.decode_out.alu_op;
	assign next_ex_reg.alu_in1_sel = control.decode_out.alu_in1_sel;
	assign next_ex_reg.alu_in2_sel = control.decode_out.alu_in2_sel;
	assign next_ex_reg.compare_unit_op = control.decode_out.compare_unit_op;
	assign next_ex_reg.regfile_wr_sel = control.decode_out.regfile_wr_sel;
	assign next_ex_reg.dcache_rd_size = control.decode_out.dcache_rd_size;
	assign next_ex_reg.dcache_wr_size = control.decode_out.dcache_wr_size;
	assign next_ex_reg.dcache_wr_enable = control.decode_out.dcache_wr_enable;
	assign next_ex_reg.dcache_rd_signed = control.decode_out.dcache_rd_signed;
	assign next_ex_reg.is_branch = control.decode_out.is_branch;
	assign next_ex_reg.is_jump = control.decode_out.is_jump;
	assign next_ex_reg.is_ecall = control.decode_out.is_ecall;
	assign next_ex_reg.is_mem_access = control.decode_out.is_mem_access;
	assign next_ex_reg.valid = control.ex_reg_valid;

	/* EX stage */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			ex_reg <= 'b0;
		else
			ex_reg <= control.ex_reg_stall ? ex_reg : next_ex_reg;
	end

	logic [31:0] ex_alu_in1;
	logic [31:0] ex_alu_in2;

	always_comb begin
		priority case (ex_reg.alu_in1_sel)
		ALU_IN1_SEL_REGFILE_OUT1:
			ex_alu_in1 = ex_reg.regfile_out1;
		ALU_IN1_SEL_IMM:
			ex_alu_in1 = ex_reg.imm;
		endcase

		priority case (ex_reg.alu_in2_sel)
		ALU_IN2_SEL_REGFILE_OUT2:
			ex_alu_in2 = ex_reg.regfile_out2;
		ALU_IN2_SEL_IMM:
			ex_alu_in2 = ex_reg.imm;
		ALU_IN2_SEL_PC:
			ex_alu_in2 = ex_reg.pc;
		ALU_IN2_SEL_CSR_OUT:
			ex_alu_in2 = ex_reg.csr_out;
		endcase
	end

	alu alu(
		.alu_op_i(ex_reg.alu_op),
		.in1_i(ex_alu_in1),
		.in2_i(ex_alu_in2),
		.out_o(ex_alu_out)
	);

	compare_unit cmp_unit(
		.compare_unit_op_i(ex_reg.compare_unit_op),
		.in1_i(ex_reg.regfile_out1),
		.in2_i(ex_reg.regfile_out2),
		.res_o(next_mem_reg.cmp_unit_res)
	);

	assign next_mem_reg.pc = ex_reg.pc;
	assign next_mem_reg.regfile_out2 = ex_reg.regfile_out2;
	assign next_mem_reg.csr_out = ex_reg.csr_out;
	assign next_mem_reg.regfile_wr_addr = ex_reg.regfile_wr_addr;
	assign next_mem_reg.csr_wr_addr = ex_reg.csr_wr_addr;
	assign next_mem_reg.regfile_we = ex_reg.regfile_we;
	assign next_mem_reg.csr_we = ex_reg.csr_we;
	assign next_mem_reg.alu_out = ex_alu_out;
	assign next_mem_reg.regfile_wr_sel = ex_reg.regfile_wr_sel;
	assign next_mem_reg.dcache_rd_size = ex_reg.dcache_rd_size;
	assign next_mem_reg.dcache_wr_size = ex_reg.dcache_wr_size;
	assign next_mem_reg.dcache_wr_enable = ex_reg.dcache_wr_enable;
	assign next_mem_reg.dcache_rd_signed = ex_reg.dcache_rd_signed;
	assign next_mem_reg.is_branch = ex_reg.is_branch;
	assign next_mem_reg.is_jump = ex_reg.is_jump;
	assign next_mem_reg.is_ecall = ex_reg.is_ecall;
	assign next_mem_reg.is_mem_access = ex_reg.is_mem_access;
	assign next_mem_reg.valid = control.mem_reg_valid;

	/* MEM stage */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			mem_reg <= 'b0;
		else
			mem_reg <= control.mem_reg_stall ? mem_reg : next_mem_reg;
	end

	assign dcache_bus.addr = mem_reg.alu_out;
	assign dcache_bus.wr_data = mem_reg.regfile_out2;
	assign dcache_bus.wr_size = mem_reg.dcache_wr_size;
	assign dcache_bus.write = mem_reg.dcache_wr_enable;

	logic [31:0] mem_dcache_rd_data_sext;

	always_comb begin
		if (mem_reg.dcache_rd_signed) begin
			priority case (mem_reg.dcache_rd_size)
			CACHE_ACCESS_SIZE_WORD:
				mem_dcache_rd_data_sext = dcache_bus.rd_data;
			CACHE_ACCESS_SIZE_HALF:
				mem_dcache_rd_data_sext = {{16{dcache_bus.rd_data[15]}}, dcache_bus.rd_data[15:0]};
			CACHE_ACCESS_SIZE_BYTE:
				mem_dcache_rd_data_sext = {{24{dcache_bus.rd_data[7]}}, dcache_bus.rd_data[7:0]};
			endcase
		end else begin
			priority case (mem_reg.dcache_rd_size)
			CACHE_ACCESS_SIZE_WORD:
				mem_dcache_rd_data_sext = dcache_bus.rd_data;
			CACHE_ACCESS_SIZE_HALF:
				mem_dcache_rd_data_sext = {16'b0, dcache_bus.rd_data[15:0]};
			CACHE_ACCESS_SIZE_BYTE:
				mem_dcache_rd_data_sext = {24'b0, dcache_bus.rd_data[7:0]};
			endcase
		end
	end

	assign next_wb_reg.pc = mem_reg.pc;
	assign next_wb_reg.csr_out = mem_reg.csr_out;
	assign next_wb_reg.regfile_wr_addr = mem_reg.regfile_wr_addr;
	assign next_wb_reg.csr_wr_addr = mem_reg.csr_wr_addr;
	assign next_wb_reg.regfile_we = mem_reg.regfile_we;
	assign next_wb_reg.csr_we = mem_reg.csr_we;
	assign next_wb_reg.alu_out = mem_reg.alu_out;
	assign next_wb_reg.regfile_wr_sel = mem_reg.regfile_wr_sel;
	assign next_wb_reg.dcache_rd_data = mem_dcache_rd_data_sext;
	assign next_wb_reg.is_ecall = mem_reg.is_ecall;
	assign next_wb_reg.valid = control.wb_reg_valid;

	/* WB stage */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			wb_reg <= 'b0;
		else
			wb_reg <= next_wb_reg;
	end

	always_comb begin
		priority case (wb_reg.regfile_wr_sel)
		REGFILE_WR_SEL_ALU_OUT:
			wb_regfile_wr_data = wb_reg.alu_out;
		REGFILE_WR_SEL_PC_4:
			wb_regfile_wr_data = wb_reg.pc + 4;
		REGFILE_WR_SEL_DMEM_RD_DATA:
			wb_regfile_wr_data = wb_reg.dcache_rd_data;
		REGFILE_WR_SEL_CSR_OUT:
			wb_regfile_wr_data = wb_reg.csr_out;
		endcase
	end
endmodule
