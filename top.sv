module top(
	input logic clk_i,
	input logic reset_i
);
	logic [31:0] mem_rd_addr;
	logic [31:0] mem_rd_data;
	logic [31:0] mem_wr_addr;
	logic [31:0] mem_wr_data;
	logic mem_wr_enable;

	mem_tb mem(
		.clk_i(clk_i),
		.rd_addr_i(mem_rd_addr),
		.rd_data_o(mem_rd_data),
		.wr_addr_i(mem_wr_addr),
		.wr_data_i(mem_wr_data),
		.wr_enable_i(mem_wr_enable)
	);

	datapath dp(
		.clk_i(clk_i),
		.reset_i(reset_i),
		/* Memory interface */
		.mem_rd_addr_o(mem_rd_addr),
		.mem_rd_data_i(mem_rd_data),
		.mem_wr_addr_o(mem_wr_addr),
		.mem_wr_data_o(mem_wr_data),
		.mem_wr_enable_o(mem_wr_enable)
	);

	initial begin
		$display("Hello World");
		//$readmemh("data.hex", mem);
	end
endmodule
