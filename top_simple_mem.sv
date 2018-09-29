import definitions::*;

module top_simple_mem(
	input logic clk_i,
	input logic reset_i
);
	mem_if imemif();
	mem_if dmemif();

	simple_mem imem(
		.clk_i(clk_i),
		.memif(imemif)
	);

	simple_mem dmem(
		.clk_i(clk_i),
		.memif(dmemif)
	);

	datapath dp(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.imemif(imemif),
		.dmemif(dmemif)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
