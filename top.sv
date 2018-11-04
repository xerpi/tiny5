import definitions::*;

module top(
	input logic clk_i,
	input logic reset_i
);
	localparam MEMORY_SIZE = 64 * 1024 * 8;
	localparam MEMORY_DELAY_CYCLES = 5;
	localparam CACHE_SIE = 4 * 1024 * 8;
	localparam LINE_SIZE = 32 * 8;
	localparam WORD_SIZE = 32;
	localparam ADDR_SIZE = 32;

	memory_interface # (
		.ADDR_SIZE(ADDR_SIZE),
		.LINE_SIZE(LINE_SIZE)
	) memory_bus ();

	memory_interface # (
		.ADDR_SIZE(ADDR_SIZE),
		.LINE_SIZE(LINE_SIZE)
	) icache_memory_bus ();

	memory_interface # (
		.ADDR_SIZE(ADDR_SIZE),
		.LINE_SIZE(LINE_SIZE)
	) dcache_memory_bus ();

	cache_interface # (
		.ADDR_SIZE(ADDR_SIZE),
		.WORD_SIZE(WORD_SIZE)
	) icache_bus ();

	cache_interface # (
		.ADDR_SIZE(ADDR_SIZE),
		.WORD_SIZE(WORD_SIZE)
	) dcache_bus ();

	memory_arbiter memory_arbiter(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.icache_memory_bus(icache_memory_bus),
		.dcache_memory_bus(dcache_memory_bus),
		.memory_bus(memory_bus)
	);

	memory # (
		.SIZE(MEMORY_SIZE),
		.LINE_SIZE(LINE_SIZE),
		.ADDR_SIZE(ADDR_SIZE),
		.DELAY_CYCLES(MEMORY_DELAY_CYCLES)
	) memory (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.memory_bus(memory_bus)
	);

	cache # (
		.SIZE(CACHE_SIE),
		.LINE_SIZE(LINE_SIZE),
		.WORD_SIZE(WORD_SIZE),
		.ADDR_SIZE(ADDR_SIZE)
	) icache (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.cache_bus(icache_bus),
		.memory_bus(icache_memory_bus)
	);

	cache # (
		.SIZE(CACHE_SIE),
		.LINE_SIZE(LINE_SIZE),
		.WORD_SIZE(WORD_SIZE),
		.ADDR_SIZE(ADDR_SIZE)
	) dcache (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.cache_bus(dcache_bus),
		.memory_bus(dcache_memory_bus)
	);

	datapath datapath(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.icache_bus(icache_bus),
		.dcache_bus(dcache_bus)
	);

	initial begin
		$display("Tiny5 init");
	end
endmodule
