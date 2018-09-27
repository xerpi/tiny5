force -freeze sim:/top_simple_mem/clk_i 1 0, 0 {50 ps} -r 100
force -freeze sim:/top_simple_mem/reset_i 1 0, 0 {100 ps} -freeze

add wave -radix 16 sim:/top_simple_mem/reset_i
add wave -radix 16 sim:/top_simple_mem/clk_i
add wave -radix 16 sim:/top_simple_mem/dp/pc
add wave -radix 16 sim:/top_simple_mem/dp/ir
add wave -radix 16 sim:/top_simple_mem/dp/ctrl_next_pc_sel
add wave -radix 16 sim:/top_simple_mem/dp/ctrl_alu_in1_sel
add wave -radix 16 sim:/top_simple_mem/dp/regfile/registers
