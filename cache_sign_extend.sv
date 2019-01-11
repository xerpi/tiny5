import cache_interface_types::*;

module cache_sign_extend # (
	parameter WORD_SIZE = 32
) (
	input  logic [WORD_SIZE - 1 : 0] data_in,
	input  logic			 is_signed,
	input  cache_access_size_t	 size,
	output logic [WORD_SIZE - 1 : 0] data_out
);
	logic byte_parity;
	logic half_parity;

	assign byte_parity = is_signed & data_in[7];
	assign half_parity = is_signed & data_in[15];

	always_comb begin
		priority case (size)
		CACHE_ACCESS_SIZE_WORD:
			data_out = data_in;
		CACHE_ACCESS_SIZE_HALF:
			data_out = {{16{half_parity}}, data_in[0 +: 16]};
		CACHE_ACCESS_SIZE_BYTE:
			data_out = {{24{byte_parity}}, data_in[0 +: 8]};
		endcase
	end
endmodule
