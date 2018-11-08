force -freeze sim:/top/clk_i 1 0, 0 {50 ps} -r 100
force -freeze sim:/top/reset_i 1 0, 0 {100 ps} -freeze

add wave -radix 16 sim:/top/reset_i
add wave -radix 16 sim:/top/clk_i

add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/pc
add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/id_reg
add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/ex_reg
add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/mem_reg
add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/wb_reg
add wave -radix 16 -expand -group {Datapath} sim:/top/datapath/regfile/registers

add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/icache_busy
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/dcache_busy

add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.addr
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.rd_data
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.wr_data
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.wr_size
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.write
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.valid
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.ready
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.miss

add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.addr
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.rd_data
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.wr_data
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.wr_size
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.write
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.valid
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.ready
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.miss

add wave -radix 16 -expand -group {ICache} sim:/top/icache/state
add wave -radix 16 -expand -group {ICache} sim:/top/icache/is_miss
add wave -radix 16 -expand -group {ICache} sim:/top/icache/lines

add wave -radix 16 -expand -group {DCache} sim:/top/dcache/state
add wave -radix 16 -expand -group {DCache} sim:/top/dcache/is_miss
add wave -radix 16 -expand -group {DCache} sim:/top/dcache/lines

add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.addr
add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.rd_data
add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.wr_data
add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.write
add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.valid
add wave -radix 16 -expand -group {ICache memory bus} sim:/top/icache_memory_bus.ready

add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.addr
add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.rd_data
add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.wr_data
add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.write
add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.valid
add wave -radix 16 -expand -group {DCache memory bus} sim:/top/dcache_memory_bus.ready

add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.addr
add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.rd_data
add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.wr_data
add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.write
add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.valid
add wave -radix 16 -expand -group {Memory bus} sim:/top/memory_bus.ready
