import definitions::*;

module control(
	input pipeline_id_reg_t id_reg_i,
	input pipeline_ex_reg_t ex_reg_i,
	input pipeline_mem_reg_t mem_reg_i,
	input pipeline_wb_reg_t wb_reg_i,
	input pipeline_mul_m0_reg_t mul_m0_reg_i,
	input pipeline_mul_m1234_reg_t mul_m1_reg_i,
	input pipeline_mul_m1234_reg_t mul_m2_reg_i,
	input pipeline_mul_m1234_reg_t mul_m3_reg_i,
	input pipeline_mul_m1234_reg_t mul_m4_reg_i,
	input pipeline_mul_wmul_reg_t mul_wmul_reg_i,
	input logic icache_hit_i,
	input logic dcache_hit_i,
	input logic store_buffer_full_i,
	input logic store_buffer_empty_i,
	input logic store_buffer_snoop_hit_i,
	input logic store_buffer_snoop_line_conflict_i,
	output pipeline_control_t control_o,
	output logic icache_access_o
);
	/* Check data hazards with the current instruction being decoded */
	logic ex_data_hazard;
	logic mem_data_hazard;
	logic wb_data_hazard;
	logic mul_m0_data_hazard;
	logic mul_m1_data_hazard;
	logic mul_m2_data_hazard;
	logic mul_m3_data_hazard;
	logic mul_m4_data_hazard;
	logic mul_wmul_data_hazard;
	logic data_hazard;

	assign ex_data_hazard = ex_reg_i.valid && ex_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, ex_reg_i.regfile_wr_addr);
	assign mem_data_hazard = mem_reg_i.valid && mem_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, mem_reg_i.regfile_wr_addr);
	assign wb_data_hazard = wb_reg_i.valid && wb_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, wb_reg_i.regfile_wr_addr);
	assign mul_m0_data_hazard = mul_m0_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_m0_reg_i.regfile_wr_addr);
	assign mul_m1_data_hazard = mul_m1_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_m1_reg_i.regfile_wr_addr);
	assign mul_m2_data_hazard = mul_m2_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_m2_reg_i.regfile_wr_addr);
	assign mul_m3_data_hazard = mul_m3_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_m3_reg_i.regfile_wr_addr);
	assign mul_m4_data_hazard = mul_m4_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_m4_reg_i.regfile_wr_addr);
	assign mul_wmul_data_hazard = mul_wmul_reg_i.valid &&
		data_hazard_raw_check(id_reg_i.instr, mul_wmul_reg_i.regfile_wr_addr);

	/* Bypass/forwarding */
	logic ex_alu_out_to_reg1_bypass;
	logic ex_alu_out_to_reg2_bypass;
	logic mem_alu_out_to_reg1_bypass;
	logic mem_alu_out_to_reg2_bypass;
	logic wb_alu_out_to_reg1_bypass;
	logic wb_alu_out_to_reg2_bypass;

	forwarding forwarding(
		.id_reg_i(id_reg_i),
		.ex_reg_i(ex_reg_i),
		.mem_reg_i(mem_reg_i),
		.wb_reg_i(wb_reg_i),
		.ex_alu_out_to_reg1_bypass_o(ex_alu_out_to_reg1_bypass),
		.ex_alu_out_to_reg2_bypass_o(ex_alu_out_to_reg2_bypass),
		.mem_alu_out_to_reg1_bypass_o(mem_alu_out_to_reg1_bypass),
		.mem_alu_out_to_reg2_bypass_o(mem_alu_out_to_reg2_bypass),
		.wb_alu_out_to_reg1_bypass_o(wb_alu_out_to_reg1_bypass),
		.wb_alu_out_to_reg2_bypass_o(wb_alu_out_to_reg2_bypass)
	);

	assign data_hazard =
		(ex_data_hazard && !(ex_alu_out_to_reg1_bypass || ex_alu_out_to_reg2_bypass)) ||
		(mem_data_hazard && !(mem_alu_out_to_reg1_bypass || mem_alu_out_to_reg2_bypass)) ||
		(wb_data_hazard && !(wb_alu_out_to_reg1_bypass || wb_alu_out_to_reg2_bypass)) ||
		mul_m0_data_hazard || mul_m1_data_hazard || mul_m2_data_hazard ||
		mul_m3_data_hazard || mul_m4_data_hazard || mul_wmul_data_hazard;

	always_comb begin
		if (ex_alu_out_to_reg1_bypass)
			control_o.alu_out_to_reg1_bypass = ALU_OUT_BYPASS_FROM_EX;
		else if (mem_alu_out_to_reg1_bypass)
			control_o.alu_out_to_reg1_bypass = ALU_OUT_BYPASS_FROM_MEM;
		else if (wb_alu_out_to_reg1_bypass)
			control_o.alu_out_to_reg1_bypass = ALU_OUT_BYPASS_FROM_WB;
		else
			control_o.alu_out_to_reg1_bypass = ALU_OUT_BYPASS_FROM_NONE;
	end

	always_comb begin
		if (ex_alu_out_to_reg2_bypass)
			control_o.alu_out_to_reg2_bypass = ALU_OUT_BYPASS_FROM_EX;
		else if (mem_alu_out_to_reg2_bypass)
			control_o.alu_out_to_reg2_bypass = ALU_OUT_BYPASS_FROM_MEM;
		else if (wb_alu_out_to_reg2_bypass)
			control_o.alu_out_to_reg2_bypass = ALU_OUT_BYPASS_FROM_WB;
		else
			control_o.alu_out_to_reg2_bypass = ALU_OUT_BYPASS_FROM_NONE;
	end

	/* IF stage control signals */
	logic control_hazard;
	logic icache_busy;

	assign icache_access_o = 1;
	assign icache_busy = !icache_hit_i;

	always_comb begin
		control_hazard = 0;
		control_o.next_pc_sel = NEXT_PC_SEL_PC_4;

		if (mem_reg_i.valid) begin
			if (mem_reg_i.is_jump) begin
				control_hazard = 1;
				control_o.next_pc_sel = NEXT_PC_SEL_ALU_OUT;
			end else if (mem_reg_i.is_branch) begin
				if (mem_reg_i.cmp_unit_res) begin
					control_hazard = 1;
					control_o.next_pc_sel = NEXT_PC_SEL_ALU_OUT;
				end else begin
					control_o.next_pc_sel = NEXT_PC_SEL_PC_4;
				end
			end
		end
	end

	/* ID stage control signals */
	decode decode(
		.instr_i(id_reg_i.instr),
		.decode_o(control_o.decode_out)
	);

	/* EX stage control signals */

	/* MEM stage control signals */
	logic valid_mem_access;
	logic valid_load;
	logic valid_store;
	logic load_cache_miss;
	logic load_cache_miss_sb_miss;
	logic load_and_sb_line_conflict;
	logic store_and_sb_full;
	logic store_buffer_drain;

	assign valid_mem_access = mem_reg_i.is_mem_access && mem_reg_i.valid;
	assign valid_load = valid_mem_access && !mem_reg_i.dcache_wr_enable;
	assign valid_store = valid_mem_access && mem_reg_i.dcache_wr_enable;
	assign load_cache_miss = valid_load && !dcache_hit_i;

	/* Store buffer lock/drain logic */
	assign load_and_sb_line_conflict = valid_load && store_buffer_snoop_line_conflict_i;
	assign load_cache_miss_sb_miss = load_cache_miss && !store_buffer_snoop_hit_i;
	assign store_and_sb_full = valid_store && store_buffer_full_i;
	assign store_buffer_drain = (!valid_load && !store_buffer_empty_i) ||
				    (valid_load && store_buffer_snoop_line_conflict_i);

	assign control_o.mem_valid_load = valid_load;
	assign control_o.mem_sb_put_enable = valid_store && !store_buffer_full_i;
	assign control_o.mem_sb_get_enable = store_buffer_drain;
	assign control_o.mem_use_sb_snoop_data = store_buffer_snoop_hit_i;

	/* Pipeline interlock logic */
	logic stall_full_pipeline;
	logic mul_m2_m3_m4_valid;

	assign mul_m2_m3_m4_valid = mul_m2_reg_i.valid || mul_m3_reg_i.valid ||
				    mul_m4_reg_i.valid;

	assign stall_full_pipeline = load_and_sb_line_conflict ||
				     load_cache_miss_sb_miss ||
				     store_and_sb_full;

	assign control_o.pc_reg_stall = (data_hazard && !control_hazard) ||
					icache_busy ||
					mul_m2_m3_m4_valid ||
					stall_full_pipeline;

	assign control_o.id_reg_stall = (data_hazard && !control_hazard) ||
					mul_m2_m3_m4_valid ||
					stall_full_pipeline;
	assign control_o.id_reg_valid = !control_hazard &&
					!icache_busy;

	assign control_o.ex_reg_stall = stall_full_pipeline ||
					mul_m2_m3_m4_valid;
	assign control_o.ex_reg_valid = id_reg_i.valid &&
					!control_o.decode_out.is_muldiv &&
					!data_hazard && !control_hazard;

	assign control_o.mem_reg_stall = stall_full_pipeline ||
					 (icache_busy && control_hazard) ||
					 mul_m2_m3_m4_valid;
	assign control_o.mem_reg_valid = ex_reg_i.valid && !control_hazard;

	assign control_o.wb_reg_valid = mem_reg_i.valid &&
					!stall_full_pipeline &&
					!mul_m2_m3_m4_valid;

	assign control_o.mul_m0_reg_stall = stall_full_pipeline;
	assign control_o.mul_m0_reg_valid = id_reg_i.valid &&
					    control_o.decode_out.is_muldiv &&
					    !data_hazard && !control_hazard;

	assign control_o.mul_m1_reg_stall = stall_full_pipeline;
	assign control_o.mul_m1_reg_valid = mul_m0_reg_i.valid &&
					    !control_hazard;

	assign control_o.mul_m2_reg_stall = stall_full_pipeline;

	assign control_o.mul_m3_reg_stall = stall_full_pipeline;

	assign control_o.mul_m4_reg_stall = stall_full_pipeline;

	/* For RISC-V tests */
	always_comb begin
		if (wb_reg_i.valid && wb_reg_i.is_ecall) begin
			$display("**ECALL**\nR3: 0x%h (%d)\nPC: 0x%h",
				top.datapath.regfile.registers[3],
				top.datapath.regfile.registers[3],
				wb_reg_i.pc);
			$display("Cycles: %d\nInsret: %d",
				top.datapath.csr.reg_cycle + 1,
				top.datapath.csr.reg_instret + 1);
			$finish();
		end
	end
endmodule
