interface memory_interface # (
	parameter ADDR_SIZE = 32,
	parameter CACHE_LINE_SIZE = 32 * 8
) ();
	logic [ADDR_SIZE - 1 : 0] addr;
	logic [CACHE_LINE_SIZE - 1 : 0] rd_data;
	logic [CACHE_LINE_SIZE - 1 : 0] wr_data;
	logic write;
	logic valid;
	logic ready;

	modport master(
		output addr,
		input rd_data,
		output wr_data,
		output write,
		output valid,
		input ready
	);

	modport slave(
		input addr,
		output rd_data,
		input wr_data,
		input write,
		input valid,
		output ready
	);
endinterface
