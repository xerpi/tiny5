import definitions::*;

module tl_memory_controller(
	input logic clk_i,
	input logic reset_i,
	tilelink.slave_ul tilelink,
	memory_array_interface.slave memif
);
	enum logic [1:0] {
		READY,
		DO_GET,
		DO_PUT_FULL_DATA,
		DO_PUT_PARTIAL_DATA
	} state, next_state;

	/* Output logic */
	always_comb begin
		case (state)
		READY:
			tilelink.a_ready = 1;
		DO_GET:
			tilelink.a_ready = 0;
		DO_PUT_FULL_DATA:
			tilelink.a_ready = 0;
		DO_PUT_PARTIAL_DATA:
			tilelink.a_ready = 0;
		endcase
	end

	/* Next state combinational logic */
	always_comb begin
		case (state)
		READY: begin
			if (tilelink.a_valid) begin
				case (tilelink.a_opcode)
				TL_CHANNEL_A_OPCODE_GET:
					next_state = DO_GET;
				TL_CHANNEL_A_OPCODE_PUT_FULL_DATA:
					next_state = DO_PUT_FULL_DATA;
				TL_CHANNEL_A_OPCODE_PUT_PARTIAL_DATA:
					next_state = DO_PUT_PARTIAL_DATA;
				endcase
			end
		end
		DO_GET:
			next_state = READY;
		DO_PUT_FULL_DATA:
			next_state = READY;
		DO_PUT_PARTIAL_DATA:
			next_state = READY;
		endcase
	end

	/* Next state sequential logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= READY;
		end else begin
			state <= next_state;
		end
	end
endmodule
