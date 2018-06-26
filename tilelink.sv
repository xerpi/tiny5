import definitions::*;

interface tilelink #(
	w = 4, a = 32, z = 32, o = 1, i = 1
) (input logic clk_i);

	typedef enum logic [2:0] {
		MESSAGE_CHANNEL_A_GET = 4
	};

	struct packed {
		logic [    2 : 0] opcode;
		logic [    2 : 0] param;
		logic [z - 1 : 0] size;
		logic [o - 1 : 0] source;
		logic [a - 1 : 0] address;
		logic [w - 1 : 0] mask;
		logic [8 * w : 0] data;
		logic valid;
		logic ready;
	} channel_A;

	struct packed {
		logic [    2 : 0] opcode;
		logic [    1 : 0] param;
		logic [z - 1 : 0] size;
		logic [o - 1 : 0] source;
		logic [i - 1 : 0] sink;
		logic [8 * w : 0] data;
		logic error;
		logic valid;
		logic ready;
	} channel_D;

	task Get() {
		channel_A.opcode = MESSAGE_CHANNEL_A_GET;
	}

	modport master(
		output channel_A;
		input channel_D;

	);

	modport slave(
		input channel_A;
		input channel_D;
	);
endinterface
