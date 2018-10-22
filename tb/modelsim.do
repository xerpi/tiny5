force -freeze sim:/top_simple_mem/clk_i 1 0, 0 {50 ps} -r 100
force -freeze sim:/top_simple_mem/reset_i 1 0, 0 {100 ps} -freeze

add wave -radix 16 sim:/top_simple_mem/reset_i
add wave -radix 16 sim:/top_simple_mem/clk_i
add wave -radix 16 sim:/top_simple_mem/datapath/pc
add wave -radix 16 sim:/top_simple_mem/datapath/id_reg
add wave -radix 16 sim:/top_simple_mem/datapath/ex_reg
add wave -radix 16 sim:/top_simple_mem/datapath/mem_reg
add wave -radix 16 sim:/top_simple_mem/datapath/wb_reg
add wave -radix 16 sim:/top_simple_mem/datapath/regfile/registers
