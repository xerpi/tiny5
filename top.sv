import definitions::*;

module top(
	input logic clk_i,
	input logic reset_i
);
	mem_if imemif();
	mem_if dmemif();

	memory imem(
		.clk_i(clk_i),
		.memif(imemif)
	);

	memory dmem(
		.clk_i(clk_i),
		.memif(dmemif)
	);

	datapath datapath(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.imemif(imemif),
		.dmemif(dmemif)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
