module memory_arbiter(
	memory_interface.slave icache_memory_bus,
	memory_interface.slave dcache_memory_bus,
	memory_interface.master memory_bus
);
	always_comb begin
		/* Dcache has priority over Icache */
		if (dcache_memory_bus.valid) begin
			memory_bus.addr = dcache_memory_bus.addr;
			dcache_memory_bus.rd_data = memory_bus.rd_data;
			memory_bus.wr_data = dcache_memory_bus.wr_data;
			memory_bus.write = dcache_memory_bus.write;
			memory_bus.valid = dcache_memory_bus.valid;
		end else begin
			memory_bus.addr = icache_memory_bus.addr;
			icache_memory_bus.rd_data = memory_bus.rd_data;
			memory_bus.wr_data = icache_memory_bus.wr_data;
			memory_bus.write = icache_memory_bus.write;
			memory_bus.valid = icache_memory_bus.valid;
		end

		icache_memory_bus.ready = memory_bus.ready;
		dcache_memory_bus.ready = memory_bus.ready;
	end
endmodule
