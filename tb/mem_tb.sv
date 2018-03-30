import definitions::*;

import "DPI-C" function void mem_write8(input int unsigned address, input byte unsigned data);
import "DPI-C" function byte unsigned mem_read8(input int unsigned address);
import "DPI-C" function void mem_write16(input int unsigned address, input shortint unsigned data);
import "DPI-C" function shortint unsigned mem_read16(input int unsigned address);
import "DPI-C" function void mem_write32(input int unsigned address, input int unsigned data);
import "DPI-C" function int unsigned mem_read32(input int unsigned address);

module mem_tb(
	input logic clk_i,
	input logic [31:0] rd_addr_i,
	input mem_access_size_t rd_size_i,
	input logic [31:0] wr_addr_i,
	input logic [31:0] wr_data_i,
	input mem_access_size_t wr_size_i,
	input logic wr_enable_i,
	output logic [31:0] rd_data_o
);
	always_comb begin
		priority case (rd_size_i)
		MEM_ACCESS_SIZE_BYTE:
			rd_data_o = {24'b0, mem_read8(rd_addr_i)};
		MEM_ACCESS_SIZE_HALF:
			rd_data_o = {16'b0, mem_read16(rd_addr_i)};
		MEM_ACCESS_SIZE_WORD:
			rd_data_o = mem_read32(rd_addr_i);
		endcase
	end

	always_ff @(posedge clk_i) begin
		if (wr_enable_i) begin
			priority case (wr_size_i)
			MEM_ACCESS_SIZE_BYTE:
				mem_write8(wr_addr_i, wr_data_i[7:0]);
			MEM_ACCESS_SIZE_HALF:
				mem_write16(wr_addr_i, wr_data_i[15:0]);
			MEM_ACCESS_SIZE_WORD:
				mem_write32(wr_addr_i, wr_data_i);
			endcase
		end
	end
endmodule
