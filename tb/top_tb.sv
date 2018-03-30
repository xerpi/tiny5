import definitions::*;

module top_tb(
	input logic clk_i,
	input logic reset_i
);
	/* mem outputs */
	logic [31:0] mem_rd_data;

	/* datapath outputs */
	logic [31:0] dp_mem_rd_addr;
	mem_access_size_t dp_mem_rd_size;
	logic [31:0] dp_mem_wr_addr;
	logic [31:0] dp_mem_wr_data;
	mem_access_size_t dp_mem_wr_size;
	logic dp_mem_wr_enable;

	mem_tb mem(
		.clk_i(clk_i),
		.rd_addr_i(dp_mem_rd_addr),
		.rd_size_i(dp_mem_rd_size),
		.wr_addr_i(dp_mem_wr_addr),
		.wr_data_i(dp_mem_wr_data),
		.wr_size_i(dp_mem_wr_size),
		.wr_enable_i(dp_mem_wr_enable),
		.rd_data_o(mem_rd_data)
	);

	datapath dp(
		.clk_i(clk_i),
		.reset_i(reset_i),
		/* Memory interface */
		.mem_rd_data_i(mem_rd_data),
		.mem_rd_addr_o(dp_mem_rd_addr),
		.mem_rd_size_o(dp_mem_rd_size),
		.mem_wr_addr_o(dp_mem_wr_addr),
		.mem_wr_data_o(dp_mem_wr_data),
		.mem_wr_size_o(dp_mem_wr_size),
		.mem_wr_enable_o(dp_mem_wr_enable)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
