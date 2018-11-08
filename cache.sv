import cache_interface_types::*;

module cache # (
	parameter SIZE = 4 * 1024 * 8,
	parameter LINE_SIZE = 32 * 8,
	parameter ADDR_SIZE = 32,
	parameter WORD_SIZE = 32,
	localparam NUM_LINES = SIZE / LINE_SIZE,
	localparam WORDS_PER_LINE = LINE_SIZE / WORD_SIZE,
	localparam INDEX_BITS = $clog2(NUM_LINES),
	localparam WORD_BITS = $clog2(WORDS_PER_LINE),
	localparam WOFF_BITS = $clog2(WORD_SIZE / 8),
	localparam TAG_BITS = ADDR_SIZE - INDEX_BITS - WORD_BITS - WOFF_BITS
) (
	input logic clk_i,
	input logic reset_i,
	cache_interface.slave cache_bus,
	memory_interface.master memory_bus
);
	typedef struct packed {
		logic [TAG_BITS - 1 : 0] tag;
		logic [INDEX_BITS - 1 : 0] index;
		logic [WORD_BITS - 1 : 0] word;
		logic [WOFF_BITS - 1 : 0] woff;
	} cache_addr_t;

	typedef struct packed {
		logic valid;
		logic dirty;
		logic [WORDS_PER_LINE - 1 : 0][WORD_SIZE - 1 : 0] data;
		logic [TAG_BITS - 1 : 0] tag;
	} cache_line_t;

	typedef enum logic [5:0] {
		READY,
		FILL_REQUEST,
		FILL_WAIT,
		WRITEBACK_REQUEST,
		WRITEBACK_WAIT
	} cache_state_t;

	/* Registers */
	cache_line_t lines[NUM_LINES];
	cache_state_t state;

	/* Wires */
	cache_state_t next_state;
	cache_addr_t cpu_addr;
	cache_line_t cur_line;
	cache_line_t next_line;
	logic is_miss;
	logic cache_wr_enable;
	logic [ADDR_SIZE - 1 : 0] writeback_addr;

	assign cpu_addr = cache_bus.addr;
	assign cur_line = lines[cpu_addr.index];

	assign is_miss = !cur_line.valid || (cpu_addr.tag != cur_line.tag);
	assign writeback_addr = {cur_line.tag, cpu_addr.index, {WORD_BITS + WOFF_BITS{1'b0}}};

	assign cache_bus.miss = is_miss;

	/* FSM next state logic */
	always_comb begin
		next_state = state;

		priority case (state)
		READY: begin
			if (cache_bus.valid && is_miss && memory_bus.ready) begin
				if (cur_line.dirty)
					next_state = WRITEBACK_REQUEST;
				else
					next_state = FILL_REQUEST;
			end
		end
		FILL_REQUEST: begin
			if (!memory_bus.ready)
				next_state = FILL_WAIT;
		end
		FILL_WAIT: begin
			if (memory_bus.ready)
				next_state = READY;
		end
		WRITEBACK_REQUEST: begin
			if (!memory_bus.ready)
				next_state = WRITEBACK_WAIT;
		end
		WRITEBACK_WAIT: begin
			if (memory_bus.ready)
				next_state = FILL_REQUEST;
		end
		endcase
	end

	/* FSM output logic */
	always_comb begin
		priority case (state)
		READY: begin
			cache_bus.rd_data = cur_line.data[cpu_addr.word];
			cache_bus.ready = 1;
			cache_wr_enable = cache_bus.valid &&
					  cache_bus.write &&
					  !is_miss;
			memory_bus.addr = 0;
			memory_bus.wr_data = 0;
			memory_bus.write = 0;
			memory_bus.valid = 0;
		end
		FILL_REQUEST: begin
			cache_bus.ready = 0;
			cache_wr_enable = 0;
			memory_bus.addr = cache_bus.addr;
			memory_bus.wr_data = 0;
			memory_bus.write = 0;
			memory_bus.valid = 1;
		end
		FILL_WAIT: begin
			cache_bus.rd_data = next_line.data[cpu_addr.word];
			cache_bus.ready = memory_bus.ready;
			cache_wr_enable = memory_bus.ready;
			memory_bus.addr = cache_bus.addr;
			memory_bus.wr_data = 0;
			memory_bus.write = 0;
			memory_bus.valid = 0;
		end
		WRITEBACK_REQUEST: begin
			cache_bus.ready = 0;
			cache_wr_enable = 0;
			memory_bus.addr = writeback_addr;
			memory_bus.wr_data = cur_line.data;
			memory_bus.write = 1;
			memory_bus.valid = 1;
		end
		WRITEBACK_WAIT: begin
			cache_bus.ready = 0;
			cache_wr_enable = memory_bus.ready;
			memory_bus.addr = writeback_addr;
			memory_bus.wr_data = cur_line.data;
			memory_bus.write = 1;
			memory_bus.valid = 0;
		end
		endcase
	end

	always_comb begin
		next_line = cur_line;
		case (state)
		READY: begin
			priority case (cache_bus.wr_size)
			CACHE_ACCESS_SIZE_BYTE:
				next_line.data[cpu_addr.word]
					      [8 * cpu_addr.woff +: 8] = cache_bus.wr_data[7:0];
			CACHE_ACCESS_SIZE_HALF:
				next_line.data[cpu_addr.word]
					      [8 * cpu_addr.woff +: 16] = cache_bus.wr_data[15:0];
			CACHE_ACCESS_SIZE_WORD:
				next_line.data[cpu_addr.word] = cache_bus.wr_data;
			endcase
			next_line.tag = cur_line.tag;
			next_line.valid = cur_line.valid;
			next_line.dirty = cur_line.dirty || cache_bus.write;
		end
		FILL_WAIT: begin
			next_line.data = memory_bus.rd_data;
			if (cache_bus.write) begin
				priority case (cache_bus.wr_size)
				CACHE_ACCESS_SIZE_BYTE:
					next_line.data[cpu_addr.word]
						      [8 * cpu_addr.woff +: 8] = cache_bus.wr_data[7:0];
				CACHE_ACCESS_SIZE_HALF:
					next_line.data[cpu_addr.word]
						      [8 * cpu_addr.woff +: 16] = cache_bus.wr_data[15:0];
				CACHE_ACCESS_SIZE_WORD:
					next_line.data[cpu_addr.word] = cache_bus.wr_data;
				endcase
			end
			next_line.tag = cpu_addr.tag;
			next_line.valid = 1;
			next_line.dirty = cache_bus.write;
		end
		WRITEBACK_WAIT:  begin
			next_line.data = cur_line.data;
			next_line.tag = cur_line.tag;
			next_line.valid = cur_line.valid;
			next_line.dirty = 0;
		end
		endcase
	end

	/* FSM flip-flop */
	always_ff @ (posedge clk_i) begin
		if (reset_i)
			state <= READY;
		else
			state <= next_state;
	end

	always_ff @ (posedge clk_i) begin
		if (reset_i) begin
			for (integer i = 0; i < NUM_LINES; i++)
				lines[i] <= '0;
		end else if (cache_wr_enable) begin
			lines[cpu_addr.index] <= next_line;
		end
	end
endmodule
