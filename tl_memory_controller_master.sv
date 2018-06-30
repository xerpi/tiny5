import definitions::*;

module tl_memory_controller_master(
	input logic clk_i,
	input logic reset_i,
	tilelink.master_ul tilelink,
	tinymemif.slave memif
);

endmodule
