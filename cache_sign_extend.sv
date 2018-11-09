import cache_interface_types::*;

module cache_sign_extend # (
	parameter WORD_SIZE = 32,
	localparam OFFSET_SIZE = $clog2(WORD_SIZE / 8),
	localparam BYTE_BITS = $clog2(WORD_SIZE / 8),
	localparam HALF_BITS = $clog2(WORD_SIZE / 16)
) (
	input logic [WORD_SIZE - 1 : 0] data_in,
	input logic [OFFSET_SIZE - 1 : 0] offset,
	input logic is_signed,
	input cache_access_size_t size,
	output logic [WORD_SIZE - 1 : 0] data_out
);
	logic [BYTE_BITS - 1 : 0] byte_offset;
	logic [HALF_BITS - 1 : 0] half_offset;
	logic byte_parity;
	logic half_parity;

	assign byte_offset = offset[OFFSET_SIZE - 1 : (8 / 8 - 1)];
	assign half_offset = offset[OFFSET_SIZE - 1 : (16 / 8 - 1)];
	assign byte_parity = is_signed & data_in[8 * byte_offset + 7];
	assign half_parity = is_signed & data_in[16 * half_offset + 15];

	always_comb begin
		priority case (size)
		CACHE_ACCESS_SIZE_WORD:
			data_out = data_in;
		CACHE_ACCESS_SIZE_HALF:
			data_out = {{16{half_parity}}, data_in[16 * half_offset +: 16]};
		CACHE_ACCESS_SIZE_BYTE:
			data_out = {{24{byte_parity}}, data_in[8 * byte_offset +: 8]};
		endcase
	end
endmodule
