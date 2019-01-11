import cache_interface_types::*;

interface cache_interface # (
	parameter ADDR_SIZE = 32,
	parameter WORD_SIZE = 32
) ();
	logic [ADDR_SIZE - 1 : 0] addr;
	logic [WORD_SIZE - 1 : 0] rd_data;
	cache_access_size_t	  rd_size;
	logic [WORD_SIZE - 1 : 0] wr_data;
	cache_access_size_t	  wr_size;
	logic 			  write;
	logic 			  access;
	logic 			  hit;

	modport master(
		output addr,
		input  rd_data,
		output rd_size,
		output wr_data,
		output wr_size,
		output write,
		output access,
		input  hit
	);

	modport slave(
		input  addr,
		output rd_data,
		input  rd_size,
		input  wr_data,
		input  wr_size,
		input  write,
		input  access,
		output hit
	);
endinterface
