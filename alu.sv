module alu(
	input logic [31:0] din1_i,
	input logic [31:0] din2_i,
	output logic [31:0] dout_o
);
	always_comb begin
		dout_o = din1_i + din2_i;
	end
endmodule;
