force -freeze sim:/top/clk_i 1 0, 0 {50 ps} -r 100
force -freeze sim:/top/reset_i 1 0, 0 {100 ps} -freeze

add wave -radix 16 sim:/top/reset_i
add wave -radix 16 sim:/top/clk_i
add wave -radix 16 sim:/top/datapath/pc
add wave -radix 16 sim:/top/datapath/id_reg
add wave -radix 16 sim:/top/datapath/ex_reg
add wave -radix 16 sim:/top/datapath/mem_reg
add wave -radix 16 sim:/top/datapath/wb_reg
add wave -radix 16 sim:/top/datapath/regfile/registers
