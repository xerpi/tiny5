import definitions::*;

module memory #(
	parameter START_ADDR = 'h00001000,
	parameter MEM_SIZE = 64 * 1024
) (
	input logic clk_i,
	mem_if.master memif
);
	logic [7:0] data[MEM_SIZE:0];

	always_comb begin
		priority case (memif.rd_size)
		MEM_ACCESS_SIZE_BYTE:
			memif.rd_data = {24'b0, data[memif.rd_addr]};
		MEM_ACCESS_SIZE_HALF:
			memif.rd_data = {16'b0, data[memif.rd_addr + 1], data[memif.rd_addr]};
		MEM_ACCESS_SIZE_WORD:
			memif.rd_data = {data[memif.rd_addr + 3], data[memif.rd_addr + 2],
				data[memif.rd_addr + 1], data[memif.rd_addr]};
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (memif.wr_enable) begin
			priority case (memif.wr_size)
			MEM_ACCESS_SIZE_BYTE:
				data[memif.wr_addr] <= memif.wr_data[7:0];
			MEM_ACCESS_SIZE_HALF: begin
				data[memif.wr_addr] <= memif.wr_data[7:0];
				data[memif.wr_addr + 1] <= memif.wr_data[15:8];
			end
			MEM_ACCESS_SIZE_WORD: begin
				data[memif.wr_addr] <= memif.wr_data[7:0];
				data[memif.wr_addr + 1] <= memif.wr_data[15:8];
				data[memif.wr_addr + 2] <= memif.wr_data[23:16];
				data[memif.wr_addr + 3] <= memif.wr_data[31:24];
			end
			endcase
		end
	end

	initial begin
		$readmemh("memory.hex.txt", data, START_ADDR);
	end
endmodule
