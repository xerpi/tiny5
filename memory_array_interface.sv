import definitions::*;

interface memory_array_interface();
	logic [31:0] rd_addr;
	logic [31:0] rd_data;
	mem_access_size_t rd_size;
	logic [31:0] wr_addr;
	logic [31:0] wr_data;
	mem_access_size_t wr_size;
	logic wr_enable;

	modport master(
		output rd_addr,
		input rd_data,
		output rd_size,
		output wr_addr,
		output wr_data,
		output wr_size,
		output wr_enable
	);

	modport slave(
		input rd_addr,
		output rd_data,
		input rd_size,
		input wr_addr,
		input wr_data,
		input wr_size,
		input wr_enable
	);
endinterface
