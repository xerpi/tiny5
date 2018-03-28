import "DPI-C" function void mem_write8(input int unsigned address, input byte unsigned data);
import "DPI-C" function byte unsigned mem_read8(input int unsigned address);
import "DPI-C" function void mem_write16(input int unsigned address, input shortint unsigned data);
import "DPI-C" function shortint unsigned mem_read16(input int unsigned address);
import "DPI-C" function void mem_write32(input int unsigned address, input int unsigned data);
import "DPI-C" function int unsigned mem_read32(input int unsigned address);

module mem_tb(
	input logic clk_i,
	input logic [31:0] rd_addr_i,
	output logic [31:0] rd_data_o,
	input logic [31:0] wr_addr_i,
	input logic [31:0] wr_data_i,
	input logic wr_enable_i
);

	always_ff @(posedge clk_i) begin
		if (wr_enable_i) begin
			mem_write32(wr_addr_i, wr_data_i);
		end

		rd_data_o <= mem_read32(rd_addr_i);
	end

endmodule
