import definitions::*;

module top_dpi_mem(
	input logic clk_i,
	input logic reset_i
);
	mem_if memif();

	dpi_mem mem(
		.clk_i(clk_i),
		.memif(memif)
	);

	datapath dp(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.memif(memif)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
