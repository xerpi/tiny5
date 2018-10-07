module regfile(
	input logic clk_i,
	input logic [4:0] rd_addr1_i,
	input logic [4:0] rd_addr2_i,
	input logic [4:0] wr_addr_i,
	input logic [31:0] wr_data_i,
	input logic wr_en_i,
	output logic [31:0] rd_data1_o,
	output logic [31:0] rd_data2_o
);
	logic [31:0] registers[31:1];

	assign rd_data1_o = (rd_addr1_i > 0) ? registers[rd_addr1_i] : 'b0;
	assign rd_data2_o = (rd_addr2_i > 0) ? registers[rd_addr2_i] : 'b0;

	always_ff @(posedge clk_i) begin
		if (wr_en_i && wr_addr_i > 0) begin
			registers[wr_addr_i] <= wr_data_i;
		end
	end
endmodule
