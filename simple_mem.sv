import definitions::*;

module simple_mem #(
	parameter START_ADDR = 'h00010000,
	parameter MEM_SIZE = 64 * 1024
) (
	input logic clk_i,
	tinymemif.slave memif
);
	logic [7:0] memory[MEM_SIZE:0];

	logic [31:0] phys_rd_addr;

	assign phys_rd_addr = memif.rd_addr[$clog2(START_ADDR) - 1:0];

	assign memif.busy = 'b0;

	always_comb begin
		priority case (memif.rd_size)
		MEM_ACCESS_SIZE_BYTE:
			memif.rd_data = {24'b0, memory[phys_rd_addr]};
		MEM_ACCESS_SIZE_HALF:
			memif.rd_data = {16'b0, memory[phys_rd_addr + 1], memory[phys_rd_addr]};
		MEM_ACCESS_SIZE_WORD:
			memif.rd_data = {memory[phys_rd_addr + 3], memory[phys_rd_addr + 2],
				memory[phys_rd_addr + 1], memory[phys_rd_addr]};
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (memif.wr_enable) begin
			priority case (memif.wr_size)
			MEM_ACCESS_SIZE_BYTE:
				memory[memif.wr_addr] <= memif.wr_data[7:0];
			MEM_ACCESS_SIZE_HALF: begin
				memory[memif.wr_addr] <= memif.wr_data[7:0];
				memory[memif.wr_addr + 1] <= memif.wr_data[15:8];
			end
			MEM_ACCESS_SIZE_WORD: begin
				memory[memif.wr_addr] = memif.wr_data[7:0];
				memory[memif.wr_addr + 1] <= memif.wr_data[15:8];
				memory[memif.wr_addr + 2] <= memif.wr_data[23:16];
				memory[memif.wr_addr + 3] <= memif.wr_data[31:24];
			end
			endcase
		end
	end

	initial begin
		$readmemh("test.hex.txt", memory);
	end
endmodule
