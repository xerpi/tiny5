module memory #(
	parameter SIZE = 64 * 1024 * 8,
	parameter LINE_SIZE = 32 * 8,
	parameter ADDR_SIZE = 32,
	parameter DELAY_CYCLES = 5,
	localparam NUM_LINES = SIZE / LINE_SIZE,
	localparam INDEX_BITS = $clog2(NUM_LINES),
	localparam OFFSET_BITS = $clog2(LINE_SIZE / 8)
) (
	input logic clk_i,
	input logic reset_i,
	memory_interface.slave memory_bus
);
	logic [LINE_SIZE - 1 : 0] data[NUM_LINES - 1 : 0];
	logic [INDEX_BITS - 1 : 0] access_index;
	logic [$clog2(DELAY_CYCLES) - 1 : 0] counter;
	logic [$clog2(DELAY_CYCLES) - 1 : 0] next_counter;
	logic ready;

	assign next_counter = (counter > 0) ? counter - 1 : 0;
	assign ready = (counter == 0);

	assign access_index = memory_bus.addr[(INDEX_BITS + OFFSET_BITS) - 1 : OFFSET_BITS];
	assign memory_bus.rd_data = data[access_index];
	assign memory_bus.ready = ready;

	/* Simulate RAM delay */
	always_ff @(posedge clk_i) begin
		if (reset_i)
			counter <= 0;
		else if (ready && memory_bus.valid)
			counter <= DELAY_CYCLES;
		else
			counter <= next_counter;
	end

	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			for (integer i = 0; i < NUM_LINES; i++)
				data[i] <= {LINE_SIZE{1'b0}};
		end else if (ready && memory_bus.valid && memory_bus.write) begin
			data[access_index] <= memory_bus.wr_data;
		end
	end

	initial begin
		$readmemh("memory.hex.txt", data);
	end
endmodule
