import definitions::*;

import "DPI-C" function void mem_write8(input int unsigned address, input byte unsigned data);
import "DPI-C" function byte unsigned mem_read8(input int unsigned address);
import "DPI-C" function void mem_write16(input int unsigned address, input shortint unsigned data);
import "DPI-C" function shortint unsigned mem_read16(input int unsigned address);
import "DPI-C" function void mem_write32(input int unsigned address, input int unsigned data);
import "DPI-C" function int unsigned mem_read32(input int unsigned address);

module dpi_mem(
	input logic clk_i,
	tinymemif.slave memif
);
	assign memif.busy = 'b0;

	always_comb begin
		priority case (memif.rd_size)
		MEM_ACCESS_SIZE_BYTE:
			memif.rd_data = {24'b0, mem_read8(memif.rd_addr)};
		MEM_ACCESS_SIZE_HALF:
			memif.rd_data = {16'b0, mem_read16(memif.rd_addr)};
		MEM_ACCESS_SIZE_WORD:
			memif.rd_data = mem_read32(memif.rd_addr);
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (memif.wr_enable) begin
			priority case (memif.wr_size)
			MEM_ACCESS_SIZE_BYTE:
				mem_write8(memif.wr_addr, memif.wr_data[7:0]);
			MEM_ACCESS_SIZE_HALF:
				mem_write16(memif.wr_addr, memif.wr_data[15:0]);
			MEM_ACCESS_SIZE_WORD:
				mem_write32(memif.wr_addr, memif.wr_data);
			endcase
		end
	end
endmodule
