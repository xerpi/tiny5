module regfile(
	input logic clk_i,
	input logic [4:0] rs1_i,
	input logic [4:0] rs2_i,
	input logic [4:0] rd_i,
	input logic [31:0] rin_i,
	input logic we_i,
	output logic [31:0] rout1_o,
	output logic [31:0] rout2_o
);
	logic [31:0] registers[31:1];

	assign rout1_o = (rs1_i > 0) ? registers[rs1_i] : 'b0;
	assign rout2_o = (rs2_i > 0) ? registers[rs2_i] : 'b0;

	always_ff @(posedge clk_i) begin
		if (we_i && rd_i > 0) begin
			registers[rd_i] <= rin_i;
		end
	end
endmodule
