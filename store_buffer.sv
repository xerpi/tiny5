import cache_interface_types::*;

module store_buffer # (
	parameter NUM_ENTRIES		= 4,
	parameter ADDR_SIZE		= 32,
	parameter WORD_SIZE		= 32,
	localparam ENTRY_IDX_BITS	= $clog2(NUM_ENTRIES)
) (
	input  logic			 clk_i,
	input  logic			 reset_i,
	input  logic [ADDR_SIZE - 1 : 0] put_addr_i,
	input  logic [WORD_SIZE - 1 : 0] put_data_i,
	input  cache_access_size_t	 put_size_i,
	input  logic			 put_enable_i,
	output logic [ADDR_SIZE - 1 : 0] get_addr_o,
	output logic [WORD_SIZE - 1 : 0] get_data_o,
	output cache_access_size_t	 get_size_o,
	input  logic			 get_enable_i,
	output logic			 full_o,
	output logic			 empty_o,
	input  logic			 dcache_hit_i
);
	typedef struct packed {
		logic [ADDR_SIZE - 1 : 0] addr;
		logic [WORD_SIZE - 1 : 0] data;
		cache_access_size_t	  size;
	} sb_entry_t;

	/* Registers */
	sb_entry_t		       entries[NUM_ENTRIES];
	logic [ENTRY_IDX_BITS - 1 : 0] head;
	logic [ENTRY_IDX_BITS - 1 : 0] tail;
	logic			       full;

	/* Wires */
	logic empty;
	logic advance;
	logic retreat;

	assign empty   = !full && (head == tail);
	assign advance = !full && put_enable_i;
	assign retreat = !empty && get_enable_i && dcache_hit_i;

	/* I/O */
	assign get_addr_o = entries[tail].addr;
	assign get_data_o = entries[tail].data;
	assign get_size_o = entries[tail].size;
	assign full_o	  = full;
	assign empty_o	  = empty;

	/* Head index register */
	always_ff @ (posedge clk_i) begin
		if (reset_i)
			head <= '0;
		else if (advance)
			head <= head + 1;
	end

	/* Tail index register */
	always_ff @ (posedge clk_i) begin
		if (reset_i)
			tail <= '0;
		else if (retreat)
			tail <= tail + 1;
	end

	/* Full status flip-flop */
	always_ff @ (posedge clk_i) begin
		if (reset_i || retreat)
			full <= 0;
		else if (advance)
			full <= (head + 1) == tail;
	end

	/* Entry array registers */
	always_ff @ (posedge clk_i) begin
		if (reset_i) begin
			for (integer i = 0; i < NUM_ENTRIES; i++)
				entries[i] <= '0;
		end else if (advance) begin
			entries[head].addr <= put_addr_i;
			entries[head].data <= put_data_i;
			entries[head].size <= put_size_i;
		end
	end
endmodule
