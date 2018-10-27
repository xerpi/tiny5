import definitions::*;

module forwarding(
	input pipeline_id_reg_t id_reg_i,
	input pipeline_ex_reg_t ex_reg_i,
	input pipeline_mem_reg_t mem_reg_i,
	input pipeline_wb_reg_t wb_reg_i,
	output logic ex_alu_out_to_reg1_bypass_o,
	output logic ex_alu_out_to_reg2_bypass_o,
	output logic mem_alu_out_to_reg1_bypass_o,
	output logic mem_alu_out_to_reg2_bypass_o,
	output logic wb_alu_out_to_reg1_bypass_o,
	output logic wb_alu_out_to_reg2_bypass_o
);
	logic ex_alu_writes_regfile;
	logic mem_alu_writes_regfile;
	logic wb_alu_writes_regfile;

	assign ex_alu_writes_regfile = ex_reg_i.valid &&
		stage_will_write_alu_to_regfile(ex_reg_i.regfile_we,
						ex_reg_i.regfile_wr_addr,
						ex_reg_i.regfile_wr_sel);

	assign mem_alu_writes_regfile = mem_reg_i.valid &&
		stage_will_write_alu_to_regfile(mem_reg_i.regfile_we,
						mem_reg_i.regfile_wr_addr,
						mem_reg_i.regfile_wr_sel);

	assign wb_alu_writes_regfile = wb_reg_i.valid &&
		stage_will_write_alu_to_regfile(wb_reg_i.regfile_we,
						wb_reg_i.regfile_wr_addr,
						wb_reg_i.regfile_wr_sel);

	assign ex_alu_out_to_reg1_bypass_o = ex_alu_writes_regfile &&
		(id_reg_i.instr.common.rs1 == ex_reg_i.regfile_wr_addr);

	assign ex_alu_out_to_reg2_bypass_o = ex_alu_writes_regfile &&
		(id_reg_i.instr.common.rs2 == ex_reg_i.regfile_wr_addr);

	assign mem_alu_out_to_reg1_bypass_o = mem_alu_writes_regfile &&
		(id_reg_i.instr.common.rs1 == mem_reg_i.regfile_wr_addr);

	assign mem_alu_out_to_reg2_bypass_o = mem_alu_writes_regfile &&
		(id_reg_i.instr.common.rs2 == mem_reg_i.regfile_wr_addr);

	assign wb_alu_out_to_reg1_bypass_o = wb_alu_writes_regfile &&
		(id_reg_i.instr.common.rs1 == wb_reg_i.regfile_wr_addr);

	assign wb_alu_out_to_reg2_bypass_o = wb_alu_writes_regfile &&
		(id_reg_i.instr.common.rs2 == wb_reg_i.regfile_wr_addr);
endmodule
