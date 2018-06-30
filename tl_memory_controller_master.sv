import definitions::*;

module tl_memory_controller_master(
	input logic clk_i,
	input logic reset_i,
	tilelink.master_ul tilelink,
	tinymemif.slave memif
);
	enum logic [1:0] {
		READY,
		DO_GET,
		DO_PUT_FULL_DATA,
		DO_PUT_PARTIAL_DATA
	} state, next_state;

	struct packed {
		logic [tilelink.z - 1 : 0] a_size;
		logic [tilelink.o - 1 : 0] a_source;
		logic [tilelink.a - 1 : 0] a_address;
		logic [tilelink.w - 1 : 0] a_mask;
	} do_get_info;

	/* Output logic */
	always_comb begin
		case (state)
		READY: begin
			memif.busy = 0;
			tilelink.a_valid = 0;
		end
		DO_GET: begin
			memif.busy = 1;
			memif.rd_data = tilelink.d_data;
			tilelink.d_ready = 1;
			tilelink.a_opcode = TL_CHANNEL_A_OPCODE_GET;
			tilelink.a_param = 0;
			tilelink.a_size = do_get_info.a_size;
			tilelink.a_source = do_get_info.a_source;
			tilelink.a_address = do_get_info.a_address;
			tilelink.a_mask = do_get_info.a_mask;
			tilelink.a_valid = 1;
		end
		DO_PUT_FULL_DATA: begin
			memif.busy = 1;
			tilelink.d_ready = 1;
		end
		DO_PUT_PARTIAL_DATA: begin
			memif.busy = 1;
			tilelink.d_ready = 1;
		end
		endcase
	end

	/* Next state combinational logic */
	always_comb begin
		next_state = state;

		case (state)
		READY: begin
			if (memif.rd_enable) begin
				next_state = DO_GET;
			end else if (memif.wr_enable) begin
				next_state = DO_PUT_FULL_DATA;
			end
		end
		DO_GET: begin
			if (tilelink.d_valid && tilelink.d_opcode == TL_CHANNEL_D_OPCODE_ACCESS_ACK_DATA)
				next_state = READY;
		end
		DO_PUT_FULL_DATA, DO_PUT_PARTIAL_DATA: begin
			if (tilelink.d_valid && tilelink.d_opcode == TL_CHANNEL_D_OPCODE_ACCESS_ACK)
				next_state = READY;
		end
		endcase
	end

	/* Next state sequential logic */
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			state <= READY;
		end else begin
			case (state)
			READY: begin
				if (memif.rd_enable) begin
					do_get_info.a_source <= 'b0;
					do_get_info.a_address <= memif.rd_addr;

					if (memif.rd_size == MEM_ACCESS_SIZE_BYTE) begin
						do_get_info.a_size <= 0;
						do_get_info.a_mask <= 'b0001;
					end else if (memif.rd_size == MEM_ACCESS_SIZE_HALF) begin
						do_get_info.a_size <= 1;
						do_get_info.a_mask <= 'b0011;
					end else if (memif.rd_size == MEM_ACCESS_SIZE_WORD) begin
						do_get_info.a_size <= 2;
						do_get_info.a_mask <= 'b1111;
					end
				end
			end
			endcase

			state <= next_state;
		end
	end
endmodule
