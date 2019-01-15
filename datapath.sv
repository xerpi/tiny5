import definitions::*;
import cache_interface_types::*;
`include "utils.svh"

module datapath # (
	parameter ADDR_SIZE = 32,
	parameter WORD_SIZE = 32,
	parameter CACHE_SIZE = 4 * 1024 * 8,
	parameter CACHE_LINE_SIZE = 32 * 8,
	localparam CACHE_OFFSET_BITS = $clog2(WORD_SIZE / 8)
) (
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
	pipeline_mul_m0_reg_t mul_m0_reg;
	pipeline_mul_m1234_reg_t mul_m1_reg;
	pipeline_mul_m1234_reg_t mul_m2_reg;
	pipeline_mul_m1234_reg_t mul_m3_reg;
	pipeline_mul_m1234_reg_t mul_m4_reg;
	pipeline_mul_wmul_reg_t mul_wmul_reg;

	/* Pipeline next state signals */
	logic [31:0] next_pc;
	pipeline_id_reg_t next_id_reg;
	pipeline_ex_reg_t next_ex_reg;
	pipeline_mem_reg_t next_mem_reg;
	pipeline_wb_reg_t next_wb_reg;
	pipeline_mul_m0_reg_t next_mul_m0_reg;
	pipeline_mul_m1234_reg_t next_mul_m1_reg;
	pipeline_mul_m1234_reg_t next_mul_m2_reg;
	pipeline_mul_m1234_reg_t next_mul_m3_reg;
	pipeline_mul_m1234_reg_t next_mul_m4_reg;
	pipeline_mul_wmul_reg_t next_mul_wmul_reg;

	/* Pipeline control signal */
	pipeline_control_t control;

	/* Inter-stage signals */
	logic [31:0] wb_regfile_wr_data;
	logic [31:0] ex_alu_out;
	logic store_buffer_full;
	logic store_buffer_empty;
	logic store_buffer_snoop_hit;
	logic store_buffer_snoop_line_conflict;

	/* Control unit */
	control control_unit(
		.id_reg_i(id_reg),
		.ex_reg_i(ex_reg),
		.mem_reg_i(mem_reg),
		.wb_reg_i(wb_reg),
		.mul_m0_reg_i(mul_m0_reg),
		.mul_m1_reg_i(mul_m1_reg),
		.mul_m2_reg_i(mul_m2_reg),
		.mul_m3_reg_i(mul_m3_reg),
		.mul_m4_reg_i(mul_m4_reg),
		.mul_wmul_reg_i(mul_wmul_reg),
		.icache_hit_i(icache_bus.hit),
		.dcache_hit_i(dcache_bus.hit),
		.store_buffer_full_i(store_buffer_full),
		.store_buffer_empty_i(store_buffer_empty),
		.store_buffer_snoop_hit_i(store_buffer_snoop_hit),
		.store_buffer_snoop_line_conflict_i(store_buffer_snoop_line_conflict),
		.control_o(control),
		.icache_access_o(icache_bus.access)
	);

	/* IF stage */
	`FF_RESET_EN(clk_i, reset_i, next_pc, pc, !control.pc_reg_stall, 'h00001000);

	assign icache_bus.addr = pc;
	assign icache_bus.rd_size = CACHE_ACCESS_SIZE_WORD;
	assign icache_bus.wr_data = 0; /* don't care */
	assign icache_bus.wr_size = CACHE_ACCESS_SIZE_WORD; /* don't care */
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
	`FF_RESET_EN(clk_i, reset_i, next_id_reg, id_reg, !control.id_reg_stall, 'b0);

	logic [31:0] id_regfile_out1;
	logic [31:0] id_regfile_out2;
	logic [31:0] id_regfile_out1_bypass;
	logic [31:0] id_regfile_out2_bypass;
	logic [4:0] id_regfile_wr_addr;
	logic [31:0] id_regfile_wr_data;
	logic id_regfile_wr_en;

	always_comb begin
		if (mul_wmul_reg.valid) begin
			id_regfile_wr_addr = mul_wmul_reg.regfile_wr_addr;
			id_regfile_wr_data = mul_wmul_reg.muldiv_out;
			id_regfile_wr_en = 1;
		end else begin
			id_regfile_wr_addr = wb_reg.regfile_wr_addr;
			id_regfile_wr_data = wb_regfile_wr_data;
			id_regfile_wr_en = wb_reg.regfile_we && wb_reg.valid;
		end
	end

	regfile regfile(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rd_addr1_i(id_reg.instr.common.rs1),
		.rd_addr2_i(id_reg.instr.common.rs2),
		.wr_addr_i(id_regfile_wr_addr),
		.wr_data_i(id_regfile_wr_data),
		.wr_en_i(id_regfile_wr_en),
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

	always_comb begin
		priority case (control.alu_out_to_reg1_bypass)
		ALU_OUT_BYPASS_FROM_NONE:
			id_regfile_out1_bypass = id_regfile_out1;
		ALU_OUT_BYPASS_FROM_EX:
			id_regfile_out1_bypass = ex_alu_out;
		ALU_OUT_BYPASS_FROM_MEM:
			id_regfile_out1_bypass = mem_reg.alu_out;
		ALU_OUT_BYPASS_FROM_WB:
			id_regfile_out1_bypass = wb_reg.alu_out;
		endcase
	end

	always_comb begin
		priority case (control.alu_out_to_reg2_bypass)
		ALU_OUT_BYPASS_FROM_NONE:
			id_regfile_out2_bypass = id_regfile_out2;
		ALU_OUT_BYPASS_FROM_EX:
			id_regfile_out2_bypass = ex_alu_out;
		ALU_OUT_BYPASS_FROM_MEM:
			id_regfile_out2_bypass = mem_reg.alu_out;
		ALU_OUT_BYPASS_FROM_WB:
			id_regfile_out2_bypass = wb_reg.alu_out;
		endcase
	end

	assign next_ex_reg.pc = id_reg.pc;
	assign next_ex_reg.regfile_out1 = id_regfile_out1_bypass;
	assign next_ex_reg.regfile_out2 = id_regfile_out2_bypass;
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
	`FF_RESET_EN(clk_i, reset_i, next_ex_reg, ex_reg, !control.ex_reg_stall, 'b0);

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
	`FF_RESET_EN(clk_i, reset_i, next_mem_reg, mem_reg, !control.mem_reg_stall, 'b0);

	logic [WORD_SIZE - 1 : 0] mem_dcache_rd_data_sext;
	logic [ADDR_SIZE - 1 : 0] store_buffer_get_addr;
	logic [WORD_SIZE - 1 : 0] store_buffer_snoop_data;
	logic [WORD_SIZE - 1 : 0] cache_sign_extend_data_in;

	assign dcache_bus.rd_size = mem_reg.dcache_rd_size;

	/* Store buffer (cache input) */
	store_buffer # (
		.NUM_ENTRIES(4),
		.ADDR_SIZE(ADDR_SIZE),
		.WORD_SIZE(WORD_SIZE),
		.CACHE_SIZE(CACHE_SIZE),
		.CACHE_LINE_SIZE(CACHE_LINE_SIZE)
	) store_buffer (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.put_addr_i(mem_reg.alu_out),
		.put_data_i(mem_reg.regfile_out2),
		.put_size_i(mem_reg.dcache_wr_size),
		.put_enable_i(control.mem_sb_put_enable),
		.get_addr_o(store_buffer_get_addr),
		.get_data_o(dcache_bus.wr_data),
		.get_size_o(dcache_bus.wr_size),
		.get_enable_i(control.mem_sb_get_enable),
		.full_o(store_buffer_full),
		.empty_o(store_buffer_empty),
		.dcache_hit_i(dcache_bus.hit),
		.snoop_addr_i(mem_reg.alu_out),
		.snoop_data_o(store_buffer_snoop_data),
		.snoop_size_i(mem_reg.dcache_rd_size),
		.snoop_hit_o(store_buffer_snoop_hit),
		.snoop_line_conflict_o(store_buffer_snoop_line_conflict)
	);

	/* Cache access mux: LOAD has priority over the store buffer. */
	always_comb begin
		if (control.mem_sb_get_enable) begin
			dcache_bus.addr = store_buffer_get_addr;
			dcache_bus.write = 1;
			dcache_bus.access = 1;
		end else begin
			dcache_bus.addr = mem_reg.alu_out;
			dcache_bus.write = 0;
			dcache_bus.access = control.mem_valid_load;
		end
	end

	assign cache_sign_extend_data_in = control.mem_use_sb_snoop_data ?
		store_buffer_snoop_data : dcache_bus.rd_data;

	/* Cache output */
	cache_sign_extend # (
		.WORD_SIZE(WORD_SIZE)
	) dcache_sign_extend (
		.data_in(cache_sign_extend_data_in),
		.is_signed(mem_reg.dcache_rd_signed),
		.size(mem_reg.dcache_rd_size),
		.data_out(mem_dcache_rd_data_sext)
	);

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
	`FF_RESET(clk_i, reset_i, next_wb_reg, wb_reg, 'b0);

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

	/* Multiply M0 stage */
	assign next_mul_m0_reg.op1 = id_regfile_out1_bypass;
	assign next_mul_m0_reg.op2 = id_regfile_out2_bypass;
	assign next_mul_m0_reg.muldiv_op = control.decode_out.muldiv_op;
	assign next_mul_m0_reg.regfile_wr_addr = id_reg.instr.common.rd;
	assign next_mul_m0_reg.valid = control.mul_m0_reg_valid;

	`FF_RESET_EN(clk_i, reset_i, next_mul_m0_reg, mul_m0_reg, !control.mul_m0_reg_stall, 'b0);

	muldiv muldiv(
		.muldiv_op_i(mul_m0_reg.muldiv_op),
		.in1_i(mul_m0_reg.op1),
		.in2_i(mul_m0_reg.op2),
		.out_o(next_mul_m1_reg.muldiv_out)
	);

	assign next_mul_m1_reg.regfile_wr_addr = mul_m0_reg.regfile_wr_addr;
	assign next_mul_m1_reg.valid = control.mul_m1_reg_valid;

	/* Multiply M1 stage */
	`FF_RESET_EN(clk_i, reset_i, next_mul_m1_reg, mul_m1_reg, !control.mul_m1_reg_stall, 'b0);

	assign next_mul_m2_reg = mul_m1_reg;

	/* Multiply M2 stage */
	`FF_RESET_EN(clk_i, reset_i, next_mul_m2_reg, mul_m2_reg, !control.mul_m2_reg_stall, 'b0);

	assign next_mul_m3_reg = mul_m2_reg;

	/* Multiply M3 stage */
	`FF_RESET_EN(clk_i, reset_i, next_mul_m3_reg, mul_m3_reg, !control.mul_m3_reg_stall, 'b0);

	assign next_mul_m4_reg = mul_m3_reg;

	/* Multiply M4 stage */
	`FF_RESET_EN(clk_i, reset_i, next_mul_m4_reg, mul_m4_reg, !control.mul_m4_reg_stall, 'b0);

	assign next_mul_wmul_reg.muldiv_out = mul_m4_reg.muldiv_out;
	assign next_mul_wmul_reg.regfile_wr_addr = mul_m4_reg.regfile_wr_addr;
	assign next_mul_wmul_reg.valid = mul_m4_reg.valid;

	/* Multiply Writeback stage */
	`FF_RESET(clk_i, reset_i, next_mul_wmul_reg, mul_wmul_reg, 'b0);
endmodule
