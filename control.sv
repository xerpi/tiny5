import definitions::*;

module control(
	input pipeline_id_reg_t id_reg_i,
	input pipeline_ex_reg_t ex_reg_i,
	input pipeline_mem_reg_t mem_reg_i,
	input pipeline_wb_reg_t wb_reg_i,
	output pipeline_control_t control_o
);
	/* Check data hazards with the current instruction being decoded */
	logic ex_data_hazard;
	logic mem_data_hazard;
	logic wb_data_hazard;
	logic data_hazard;

	assign ex_data_hazard = ex_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, ex_reg_i.regfile_wr_addr);
	assign mem_data_hazard = mem_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, mem_reg_i.regfile_wr_addr);
	assign wb_data_hazard = wb_reg_i.valid && data_hazard_raw_check(id_reg_i.instr, wb_reg_i.regfile_wr_addr);
	assign data_hazard = ex_data_hazard || mem_data_hazard || wb_data_hazard;

	/* IF stage control signals */
	logic control_hazard;

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

	assign control_o.pc_reg_stall = data_hazard && !control_hazard;
	assign control_o.id_reg_stall = data_hazard && !control_hazard;
	assign control_o.id_reg_valid = !control_hazard;

	/* ID stage control signals */

	decode decode(
		.instr_i(id_reg_i.instr),
		.decode_o(control_o.decode_out)
	);

	assign control_o.ex_reg_valid = id_reg_i.valid && !data_hazard && !control_hazard;

	/* EX stage control signals */
	assign control_o.mem_reg_valid = ex_reg_i.valid && !control_hazard;
endmodule
