import definitions::*;

interface tilelink #(
	w = 4, a = 32, z = 32, o = 1, i = 1
) (input logic clk_i);

	typedef enum logic [2:0] {
		TL_MESSAGE_CHANNEL_A_GET = 4,
		TL_MESSAGE_CHANNEL_A_PUT_FULL = 0,
		TL_MESSAGE_CHANNEL_A_PUT_PARTIAL = 1,
		TL_MESSAGE_CHANNEL_D_ACCESS_ACK_DATA = 1,
		TL_MESSAGE_CHANNEL_D_ACCESS_ACK = 0
	} tl_message_t;

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
	} tl_channel_A;

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
	} tl_channel_D;

	task Get(input logic [a - 1 : 0] address,
		 input logic [o - 1 : 0] source,
		 input logic [z - 1 : 0] size,
		 input logic [w - 1 : 0] mask);

		channel_A.opcode = TL_MESSAGE_CHANNEL_A_GET;
		channel_A.param = 0;
		channel_A.size = size;
		channel_A.source = source;
		channel_A.address = address;
		channel_A.mask = mask;
		channel_A.valid = 1;
		channel_A.ready = 1;
		// channel_A.data = 0; // Data is ignored

	endtask;

	task PutPartialData(input logic [a - 1 : 0] address,
		 	    input logic [o - 1 : 0] source,
		 	    input logic [z - 1 : 0] size,
		 	    input logic [w - 1 : 0] mask,
		 	    input logic [8 * w : 0] data);

		channel_A.opcode = TL_MESSAGE_CHANNEL_A_PUT_PARTIAL;
		channel_A.param = 0;
		channel_A.size = size;
		channel_A.source = source;
		channel_A.address = address;
		channel_A.mask = mask;
		channel_A.data = data;
		channel_A.valid = 1;
		channel_A.ready = 1;

	endtask;

	task PutFullData(input logic [a - 1 : 0] address,
		 	 input logic [o - 1 : 0] source,
		 	 input logic [z - 1 : 0] size,
		 	 input logic [w - 1 : 0] mask,
		 	 input logic [8 * w : 0] data);

		channel_A.opcode = MESSAGE_CHANNEL_A_PUT_FULL;
		channel_A.param = 0;
		channel_A.size = size;
		channel_A.source = source;
		channel_A.address = address;
		channel_A.mask = mask;
		channel_A.data = data;
		channel_A.valid = 1;
		channel_A.ready = 1;

	endtask;

	task AccessAck(input logic [a - 1 : 0] address,
		       input logic [o - 1 : 0] source,
		       input logic [z - 1 : 0] size,
		       input logic [w - 1 : 0] mask,
		       input logic error,
		       input logic valid);

		channel_D.opcode = MESSAGE_CHANNEL_D_ACCESS_ACK;
		channel_D.param = 0;
		channel_D.size = size;
		channel_D.source = source;
		// channel_D.sink = ;
		// channel_D.data = ;
		channel_D.error = error;
		channel_D.valid = valid;

	endtask;

	task AccessAckData(input logic [a - 1 : 0] address,
		       	   input logic [o - 1 : 0] source,
		       	   input logic [8 * w : 0] data,
		       	   input logic [z - 1 : 0] size,
		       	   input logic [w - 1 : 0] mask,
		       	   input logic error,
		       	   input logic valid);

		channel_D.opcode = MESSAGE_CHANNEL_D_ACCESS_ACK_DATA;
		channel_D.param = 0;
		channel_D.size = size;
		channel_D.source = source;
		// channel_D.sink = ;
		channel_D.data = data;
		channel_D.error = error;
		channel_D.valid = valid;
		channel_D.ready = ready;

	endtask;


	modport master(
		output channel_A,
		input channel_D

	);

	modport slave(
		input channel_A,
		output channel_D
	);
endinterface
