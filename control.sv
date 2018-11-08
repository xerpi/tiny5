import definitions::*;

module control(
	input clk_i,
	input reset_i,
	input pipeline_id_reg_t id_reg_i,
	input pipeline_ex_reg_t ex_reg_i,
	input pipeline_mem_reg_t mem_reg_i,
	input pipeline_wb_reg_t wb_reg_i,
	input logic icache_ready_i,
	input logic icache_miss_i,
	input logic dcache_ready_i,
	input logic dcache_miss_i,
	output pipeline_control_t control_o,
	output logic icache_valid_o,
	output logic dcache_valid_o
);
	/* Check data hazards with the current instruction being decoded */
	logic ex_data_hazard;
	logic mem_data_hazard;
	logic wb_data_hazard;
	logic data_hazard;

	assign ex_data_hazard = ex_reg_i.valid && ex_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, ex_reg_i.regfile_wr_addr);
	assign mem_data_hazard = mem_reg_i.valid && mem_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, mem_reg_i.regfile_wr_addr);
	assign wb_data_hazard = wb_reg_i.valid && wb_reg_i.regfile_we &&
		data_hazard_raw_check(id_reg_i.instr, wb_reg_i.regfile_wr_addr);

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
		(wb_data_hazard && !(wb_alu_out_to_reg1_bypass || wb_alu_out_to_reg2_bypass));

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
	logic icache_controller_busy;

	cache_controller icache_controller(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.valid(1'b1),
		.busy(icache_controller_busy),
		.cache_ready(icache_ready_i),
		.cache_miss(icache_miss_i),
		.cache_valid(icache_valid_o)
	);

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
	logic dcache_access;
	logic dcache_controller_busy;

	assign dcache_access = mem_reg_i.is_mem_access && mem_reg_i.valid;

	cache_controller dcache_controller(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.valid(dcache_access),
		.busy(dcache_controller_busy), // && is_mem_access
		.cache_ready(dcache_ready_i),
		.cache_miss(dcache_miss_i),
		.cache_valid(dcache_valid_o)
	);

	/* Pipeline interlock logic */
	assign control_o.pc_reg_stall = (data_hazard && !control_hazard) ||
					icache_controller_busy ||
					dcache_controller_busy;

	assign control_o.id_reg_stall = (data_hazard && !control_hazard) ||
					dcache_controller_busy;
	assign control_o.id_reg_valid = !control_hazard &&
					!icache_controller_busy;

	assign control_o.ex_reg_stall = dcache_controller_busy;
	assign control_o.ex_reg_valid = id_reg_i.valid && !data_hazard && !control_hazard;

	assign control_o.mem_reg_stall = dcache_controller_busy;
	assign control_o.mem_reg_valid = ex_reg_i.valid && !control_hazard;

	assign control_o.wb_reg_valid = mem_reg_i.valid && !dcache_controller_busy;
endmodule
