import definitions::*;

module tl_memory_controller_slave(
	input logic clk_i,
	input logic reset_i,
	tilelink.slave_ul tilelink,
	tinymemif.master memif
);
	enum logic [1:0] {
		READY,
		HANDLE_GET,
		HANDLE_PUT_FULL_DATA,
		HANDLE_PUT_PARTIAL_DATA
	} state, next_state;

	struct packed {
		logic [tilelink.z - 1 : 0] a_size;
		logic [tilelink.o - 1 : 0] a_source;
		logic [tilelink.a - 1 : 0] a_address;
		logic [tilelink.w - 1 : 0] a_mask;
	} handle_get_info;

	/* Output logic */
	always_comb begin
		case (state)
		READY: begin
			tilelink.a_ready = 1;
			tilelink.d_valid = 0;
		end
		HANDLE_GET: begin
			tilelink.a_ready = 0;
			tilelink.d_opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA;
			tilelink.d_param = 0;
			tilelink.d_size = handle_get_info.a_size;
			tilelink.d_source = handle_get_info.a_source;
			tilelink.d_data = memif.rd_data;
			tilelink.d_error = 0;
			tilelink.d_valid = 1;

			memif.rd_addr = handle_get_info.a_address;
			case (handle_get_info.a_mask)
			'b0001:
				memif.rd_size = MEM_ACCESS_SIZE_BYTE;
			'b0011:
				memif.rd_size = MEM_ACCESS_SIZE_HALF;
			'b1111:
				memif.rd_size = MEM_ACCESS_SIZE_WORD;
			endcase
			memif.wr_enable = 0;
		end
		HANDLE_PUT_FULL_DATA:
			tilelink.a_ready = 0;
		HANDLE_PUT_PARTIAL_DATA:
			tilelink.a_ready = 0;
		endcase
	end

	/* Next state combinational logic */
	always_comb begin
		next_state = state;

		case (state)
		READY: begin
			if (tilelink.a_valid) begin
				priority case (tilelink.a_opcode)
				TL_CHANNEL_A_OPCODE_GET:
					next_state = HANDLE_GET;
				TL_CHANNEL_A_OPCODE_PUT_FULL_DATA:
					next_state = HANDLE_PUT_FULL_DATA;
				TL_CHANNEL_A_OPCODE_PUT_PARTIAL_DATA:
					next_state = HANDLE_PUT_PARTIAL_DATA;
				endcase
			end
		end
		HANDLE_GET, HANDLE_PUT_FULL_DATA, HANDLE_PUT_PARTIAL_DATA:
			if (tilelink.d_ready)
				next_state = READY;
		endcase
	end

	/* Next state sequential logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= READY;
		end else begin
			priority case (state)
			READY:
				if (tilelink.a_valid) begin
					priority case (tilelink.a_opcode)
					TL_CHANNEL_A_OPCODE_GET: begin
						handle_get_info.a_size <= tilelink.a_size;
						handle_get_info.a_source <= tilelink.a_source;
						handle_get_info.a_address <= tilelink.a_address;
						handle_get_info.a_mask <= tilelink.a_mask;
					end
					endcase
				end
			endcase

			state <= next_state;
		end
	end
endmodule
