import definitions::*;

module tl_memory_controller(
	input logic clk_i,
	tilelink.slave_ul tilelink,
	memory_array_interface.slave memif
);
	always_comb begin

	end

	always_ff @(posedge clk_i) begin

	end
endmodule
