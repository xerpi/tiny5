import definitions::*;

module top_simple_mem(
	input logic clk_i,
	input logic reset_i
);
	tinymemif memif_cpu_master();
	tinymemif memif_slave_mem();
	tilelink tl();

	datapath dp(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.memif(memif_cpu_master)
	);

	tl_memory_controller_master tl_master(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.tilelink(tl),
		.memif(memif_cpu_master)
	);

	tl_memory_controller_slave tl_slave(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.tilelink(tl),
		.memif(memif_slave_mem)
	);

	simple_mem mem(
		.clk_i(clk_i),
		.memif(memif_slave_mem)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
