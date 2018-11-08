module memory #(
	parameter SIZE = 64 * 1024 * 8,
	parameter LINE_SIZE = 32 * 8,
	parameter ADDR_SIZE = 32,
	parameter DELAY_CYCLES = 5,
	localparam HEX_LOAD_ADDR = 'h1000
) (
	input logic clk_i,
	input logic reset_i,
	memory_interface.slave memory_bus
);
	logic [8 - 1 : 0] data[SIZE / 8];
	logic [$clog2(DELAY_CYCLES) - 1 : 0] counter;
	logic [$clog2(DELAY_CYCLES) - 1 : 0] next_counter;
	logic ready;

	assign next_counter = (counter > 0) ? counter - 1 : 0;
	assign ready = (counter == 0);

	always_comb begin
		for (integer i = 0; i < LINE_SIZE / 8; i++) begin
			memory_bus.rd_data[i * 8 +: 8] = data[memory_bus.addr + i];
		end
	end

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
			$readmemh("memory.hex.txt", data, HEX_LOAD_ADDR);
		end else if (ready && memory_bus.valid && memory_bus.write) begin
			for (integer i = 0; i < LINE_SIZE / 8; i++) begin
				data[memory_bus.addr + i] <= memory_bus.wr_data[i * 8 +: 8];
			end
		end
	end
endmodule
