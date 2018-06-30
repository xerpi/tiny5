import definitions::*;

interface tilelink #(
	w = 4, a = 32, z = 4, o = 1, i = 1
) (input logic clk_i);
	/* Channel A signals */
	logic [    2 : 0] a_opcode;
	logic [    2 : 0] a_param;
	logic [z - 1 : 0] a_size;
	logic [o - 1 : 0] a_source;
	logic [a - 1 : 0] a_address;
	logic [w - 1 : 0] a_mask;
	logic [8 * w : 0] a_data;
	logic a_valid;
	logic a_ready;

	/* Channel D signals */
	logic [    2 : 0] d_opcode;
	logic [    1 : 0] d_param;
	logic [z - 1 : 0] d_size;
	logic [o - 1 : 0] d_source;
	logic [i - 1 : 0] d_sink;
	logic [8 * w : 0] d_data;
	logic d_error;
	logic d_valid;
	logic d_ready;

	task Get(input logic [a - 1 : 0] address,
		 input logic [o - 1 : 0] source,
		 input logic [z - 1 : 0] size,
		 input logic [w - 1 : 0] mask);

		a_opcode = TL_CHANNEL_A_OPCODE_GET;
		a_param = 0;
		a_size = size;
		a_source = source;
		a_address = address;
		a_mask = mask;
		a_valid = 1;
	endtask;

	task PutPartialData(input logic [a - 1 : 0] address,
		 	    input logic [o - 1 : 0] source,
		 	    input logic [z - 1 : 0] size,
		 	    input logic [w - 1 : 0] mask,
		 	    input logic [8 * w : 0] data);

		a_opcode = TL_CHANNEL_A_OPCODE_PUT_PARTIAL_DATA;
		a_param = 0;
		a_size = size;
		a_source = source;
		a_address = address;
		a_mask = mask;
		a_data = data;
		a_valid = 1;
		a_ready = 1;

	endtask;

	task PutFullData(input logic [a - 1 : 0] address,
		 	 input logic [o - 1 : 0] source,
		 	 input logic [z - 1 : 0] size,
		 	 input logic [w - 1 : 0] mask,
		 	 input logic [8 * w : 0] data);

		a_opcode = TL_CHANNEL_A_OPCODE_PUT_FULL_DATA;
		a_param = 0;
		a_size = size;
		a_source = source;
		a_address = address;
		a_mask = mask;
		a_data = data;
		a_valid = 1;
		a_ready = 1;

	endtask;

	task AccessAck(input logic [a - 1 : 0] address,
		       input logic [o - 1 : 0] source,
		       input logic [z - 1 : 0] size,
		       input logic [w - 1 : 0] mask,
		       input logic error,
		       input logic valid);

		d_opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK;
		d_param = 0;
		d_size = size;
		d_source = source;
		// d_sink = ;
		// d_data = ;
		d_error = error;
		d_valid = valid;

	endtask;

	task AccessAckData(input logic [a - 1 : 0] address,
		       	   input logic [o - 1 : 0] source,
		       	   input logic [8 * w : 0] data,
		       	   input logic [z - 1 : 0] size,
		       	   input logic [w - 1 : 0] mask,
		       	   input logic error,
		       	   input logic valid);

		d_opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA;
		d_param = 0;
		d_size = size;
		d_source = source;
		// d_sink = ;
		d_data = data;
		d_error = error;
		d_valid = valid;
		//d_ready = ready;

	endtask;

	modport master_ul(
		/* Channel A signals */
		output a_opcode,
		output a_param,
		output a_size,
		output a_source,
		output a_address,
		output a_mask,
		output a_data,
		output a_valid,
		input a_ready,

		/* Channel D signals */
		input d_opcode,
		input d_param,
		input d_size,
		input d_source,
		input d_sink,
		input d_data,
		input d_error,
		input d_valid,
		output d_ready
	);

	modport slave_ul(
		/* Channel A signals */
		input a_opcode,
		input a_param,
		input a_size,
		input a_source,
		input a_address,
		input a_mask,
		input a_data,
		input a_valid,
		output a_ready,

		/* Channel D signals */
		output d_opcode,
		output d_param,
		output d_size,
		output d_source,
		output d_sink,
		output d_data,
		output d_error,
		output d_valid,
		input d_ready
	);
endinterface
