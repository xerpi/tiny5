module memory_arbiter(
	input logic clk_i,
	input logic reset_i,
	memory_interface.slave icache_memory_bus,
	memory_interface.slave dcache_memory_bus,
	memory_interface.master memory_bus
);
	typedef enum logic [2:0] {
		READY,
		ICACHE_REQUEST,
		ICACHE_WAIT,
		DCACHE_REQUEST,
		DCACHE_WAIT
	} memory_arbiter_state_t;

	memory_arbiter_state_t state;
	memory_arbiter_state_t next_state;

	always_comb begin
		priority case (state)
		READY: begin
			memory_bus.valid = 0;
			icache_memory_bus.ready = 1;
			dcache_memory_bus.ready = 1;
		end
		ICACHE_REQUEST,
		ICACHE_WAIT: begin
			memory_bus.addr = icache_memory_bus.addr;
			icache_memory_bus.rd_data = memory_bus.rd_data;
			memory_bus.wr_data = icache_memory_bus.wr_data;
			memory_bus.write = icache_memory_bus.write;
			memory_bus.valid = icache_memory_bus.valid;
			icache_memory_bus.ready = memory_bus.ready;
			dcache_memory_bus.ready = 0;
		end
		DCACHE_REQUEST,
		DCACHE_WAIT: begin
			memory_bus.addr = dcache_memory_bus.addr;
			dcache_memory_bus.rd_data = memory_bus.rd_data;
			memory_bus.wr_data = dcache_memory_bus.wr_data;
			memory_bus.write = dcache_memory_bus.write;
			memory_bus.valid = dcache_memory_bus.valid;
			dcache_memory_bus.ready = memory_bus.ready;
			icache_memory_bus.ready = 0;
		end
		endcase
	end

	always_comb begin
		priority case (state)
		READY: begin
			/* Dcache has priority over Icache */
			if (dcache_memory_bus.valid)
				next_state = DCACHE_REQUEST;
			else if (icache_memory_bus.valid)
				next_state = ICACHE_REQUEST;
		end
		ICACHE_REQUEST:
			if (!icache_memory_bus.valid)
				next_state = ICACHE_WAIT;
		ICACHE_WAIT:
			if (icache_memory_bus.valid)
				next_state = READY;
		DCACHE_REQUEST:
			if (!dcache_memory_bus.valid)
				next_state = DCACHE_WAIT;
		DCACHE_WAIT:
			if (dcache_memory_bus.valid)
				next_state = READY;
		endcase
	end

	always_ff @ (posedge clk_i) begin
		if (reset_i)
			state <= READY;
		else
			state <= next_state;
	end
endmodule
