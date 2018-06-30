import definitions::*;

interface tinymemif();
	logic [31:0] rd_addr;
	logic [31:0] rd_data;
	mem_access_size_t rd_size;
	logic rd_enable;
	logic [31:0] wr_addr;
	logic [31:0] wr_data;
	mem_access_size_t wr_size;
	logic wr_enable;
	logic busy;

	modport master(
		output rd_addr,
		input rd_data,
		output rd_size,
		output rd_enable,
		output wr_addr,
		output wr_data,
		output wr_size,
		output wr_enable,
		input busy
	);

	modport slave(
		input rd_addr,
		output rd_data,
		input rd_size,
		input rd_enable,
		input wr_addr,
		input wr_data,
		input wr_size,
		input wr_enable,
		output busy
	);
endinterface
