import cache_interface_types::*;

module cache_controller(
	input logic clk_i,
	input logic reset_i,
	/* CPU control signals */
	input logic valid,
	output logic busy,
	/* Cache interface signals */
	input logic cache_ready,
	input logic cache_miss,
	output logic cache_valid
);
	typedef enum logic [1:0] {
		READY,
		REQUEST,
		WAIT
	} cache_controller_state_t;

	cache_controller_state_t state;
	cache_controller_state_t next_state;

	always_comb begin
		priority case (state)
		READY: begin
			busy = cache_miss;
			cache_valid = valid;
		end
		REQUEST: begin
			busy = 1;
			cache_valid = 1;
		end
		WAIT: begin
			busy = !cache_ready;
			cache_valid = 0;
		end
		endcase
	end

	always_comb begin
		next_state = state;
		priority case (state)
		READY: begin
			if (valid && cache_miss)
				next_state = REQUEST;
		end
		REQUEST:
			if (!cache_ready)
				next_state = WAIT;
		WAIT:
			if (cache_ready)
				next_state = READY;
		endcase
	end

	always_ff @ (posedge clk_i) begin
		if (reset_i)
			state <= READY;
		else
			state <= next_state;
	end
endmodule
