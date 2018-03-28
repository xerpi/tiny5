import definitions::*;

module datapath(
	input logic clk_i,
	input logic reset_i,
	/* Memory interface */
	output logic [31:0] mem_rd_addr_o,
	input logic [31:0] mem_rd_data_i,
	output logic [31:0] mem_wr_addr_o,
	output logic [31:0] mem_wr_data_o,
	output logic mem_wr_enable_o
);
	/* registers */
	logic [31:0] pc;
	logic [31:0] ir;

	logic [31:0] next_pc;
	logic [31:0] next_ir;

	/* regfile inputs */
	logic [31:0] rf_rin;

	/* regfile outputs */
	logic [31:0] rf_rout1;
	logic [31:0] rf_rout2;

	/* control outputs */
	logic ctrl_pc_we;
	next_pc_sel_t ctrl_next_pc_sel;
	regfile_in_sel_t ctrl_regfile_in_sel;
	logic ctrl_ir_we;
	logic ctrl_mem_rd_addr_sel;
	alu_op_t ctrl_alu_op;

	/* alu outputs */
	logic [31:0] alu_dout;

	/* TODOs */
	assign mem_wr_addr_o = 0;
	assign mem_wr_data_o = 'h11223344;
	assign mem_wr_enable_o = 0;

	regfile rf(
		.clk_i(clk_i),
		.rs1_i(1),
		.rs2_i(1),
		.rd_i(1),
		.rin_i(rf_rin),
		.we_i(1),
		.rout1_o(rf_rout1),
		.rout2_o(rf_rout2)
	);

	control ctrl(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.ir_i(ir),
		.pc_we_o(ctrl_pc_we),
		.ir_we_o(ctrl_ir_we),
		.alu_op_o(ctrl_alu_op),
		.next_pc_sel_o(ctrl_next_pc_sel),
		.regfile_in_sel_o(ctrl_regfile_in_sel),
		.mem_rd_addr_sel_o(ctrl_mem_rd_addr_sel)
	);

	alu al(
		.alu_op_i(ctrl_alu_op),
		.din1_i(rf_rout1),
		.din2_i(rf_rout2),
		.dout_o(alu_dout)
	);

	always_comb begin
		unique case (ctrl_next_pc_sel)
		NEXT_PC_SEL_PC:
			next_pc = pc;
		NEXT_PC_SEL_PC_4:
			next_pc = pc + 4;
		endcase

		unique case (ctrl_regfile_in_sel)
		REGFILE_IN_SEL_ALU_OUT:
			rf_rin = alu_dout;
		endcase

		unique case (ctrl_mem_rd_addr_sel)
		MEM_RD_ADDR_SEL_PC:
			mem_rd_addr_o = pc;
		MEM_RD_ADDR_SEL_ALU_OUT:
			mem_rd_addr_o = alu_dout;
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
