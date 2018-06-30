import definitions::*;

module tl_memory_controller_slave(
	input logic clk_i,
	input logic reset_i,
	tilelink.slave_ul tilelink,
	memory_array_interface.master memif
);
	enum logic [1:0] {
		READY,
		DO_GET,
		DO_PUT_FULL_DATA,
		DO_PUT_PARTIAL_DATA
	} state, next_state;

	struct {
		logic [tilelink.z - 1 : 0] a_size;
		logic [tilelink.o - 1 : 0] a_source;
		logic [tilelink.a - 1 : 0] a_address;
		logic [tilelink.w - 1 : 0] a_mask;
	} do_get_info;

	/* Output logic */
	always_comb begin
		case (state)
		READY:
			tilelink.a_ready = 1;
		DO_GET: begin
			tilelink.a_ready = 0;
			tilelink.d_opcode = TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA;
			tilelink.d_param = 0;
			tilelink.d_size = do_get_info.a_size;
			tilelink.d_source = do_get_info.a_source;
			tilelink.d_data = memif.rd_data;
			tilelink.d_error = 0;
			tilelink.d_valid = 1;

			memif.rd_addr = do_get_info.a_address;
			case (do_get_info.a_mask)
			'b0001:
				memif.rd_size = MEM_ACCESS_SIZE_BYTE;
			'b0011:
				memif.rd_size = MEM_ACCESS_SIZE_HALF;
			'b111:
				memif.rd_size = MEM_ACCESS_SIZE_WORD;
			endcase
			memif.wr_enable = 0;
		end
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
		DO_GET, DO_PUT_FULL_DATA, DO_PUT_PARTIAL_DATA:
			if (tilelink.d_ready)
				next_state = READY;
		endcase
	end

	/* Next state sequential logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= READY;
		end else begin
			case (state)
			READY:
				if (tilelink.a_valid) begin
					case (tilelink.a_opcode)
					TL_CHANNEL_A_OPCODE_GET: begin
						do_get_info.a_size <= tilelink.a_size;
						do_get_info.a_source <= tilelink.a_source;
						do_get_info.a_address <= tilelink.a_address;
						do_get_info.a_mask <= tilelink.a_mask;
					end
					endcase
				end
			endcase

			state <= next_state;
		end
	end
endmodule
