import definitions::*;

interface tilelink #(
	w = 4, a = 32, z = 32, o = 1, i = 1
) (input logic clk_i);

	typedef enum logic [2:0] {
		TL_CHANNEL_A_OPCODE_GET = 4,
		TL_CHANNEL_A_OPCODE_PUT_FULL = 0,
		TL_CHANNEL_A_OPCODE_PUT_PARTIAL = 1
	} tl_channel_a_opcode_t;

	typedef enum logic [2:0] {
		TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA = 1,
		TL_CHANNEL_D_OPCODE_ACCESS_ACK = 0
	} tl_channel_d_opcode_t;

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
	} tl_channel_a;

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
	} tl_channel_d;

	task Get(input logic [a - 1 : 0] address,
		 input logic [o - 1 : 0] source,
		 input logic [z - 1 : 0] size,
		 input logic [w - 1 : 0] mask);

		tl_channel_a.opcode = TL_CHANNEL_A_OPCODE_GET;
		tl_channel_a.param = 0;
		tl_channel_a.size = size;
		tl_channel_a.source = source;
		tl_channel_a.address = address;
		tl_channel_a.mask = mask;
		tl_channel_a.valid = 1;
		tl_channel_a.ready = 1;
		// tl_channel_a.data = 0; // Data is ignored

	endtask;

	task PutPartialData(input logic [a - 1 : 0] address,
		 	    input logic [o - 1 : 0] source,
		 	    input logic [z - 1 : 0] size,
		 	    input logic [w - 1 : 0] mask,
		 	    input logic [8 * w : 0] data);

		tl_channel_a.opcode = TL_CHANNEL_A_OPCODE_PUT_PARTIAL;
		tl_channel_a.param = 0;
		tl_channel_a.size = size;
		tl_channel_a.source = source;
		tl_channel_a.address = address;
		tl_channel_a.mask = mask;
		tl_channel_a.data = data;
		tl_channel_a.valid = 1;
		tl_channel_a.ready = 1;

	endtask;

	task PutFullData(input logic [a - 1 : 0] address,
		 	 input logic [o - 1 : 0] source,
		 	 input logic [z - 1 : 0] size,
		 	 input logic [w - 1 : 0] mask,
		 	 input logic [8 * w : 0] data);

		tl_channel_a.opcode = TL_CHANNEL_A_OPCODE_PUT_FULL;
		tl_channel_a.param = 0;
		tl_channel_a.size = size;
		tl_channel_a.source = source;
		tl_channel_a.address = address;
		tl_channel_a.mask = mask;
		tl_channel_a.data = data;
		tl_channel_a.valid = 1;
		tl_channel_a.ready = 1;

	endtask;

	task AccessAck(input logic [a - 1 : 0] address,
		       input logic [o - 1 : 0] source,
		       input logic [z - 1 : 0] size,
		       input logic [w - 1 : 0] mask,
		       input logic error,
		       input logic valid);

		tl_channel_d.opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK;
		tl_channel_d.param = 0;
		tl_channel_d.size = size;
		tl_channel_d.source = source;
		// tl_channel_d.sink = ;
		// tl_channel_d.data = ;
		tl_channel_d.error = error;
		tl_channel_d.valid = valid;

	endtask;

	task AccessAckData(input logic [a - 1 : 0] address,
		       	   input logic [o - 1 : 0] source,
		       	   input logic [8 * w : 0] data,
		       	   input logic [z - 1 : 0] size,
		       	   input logic [w - 1 : 0] mask,
		       	   input logic error,
		       	   input logic valid);

		tl_channel_d.opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA;
		tl_channel_d.param = 0;
		tl_channel_d.size = size;
		tl_channel_d.source = source;
		// tl_channel_d.sink = ;
		tl_channel_d.data = data;
		tl_channel_d.error = error;
		tl_channel_d.valid = valid;
		//tl_channel_d.ready = ready;

	endtask;


	modport master(
		output tl_channel_a,
		input tl_channel_d

	);

	modport slave(
		input tl_channel_a,
		output tl_channel_d
	);
endinterface
