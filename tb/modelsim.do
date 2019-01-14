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

add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/control_o
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/icache_busy
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/valid_load
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/load_cache_miss
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/load_and_sb_line_conflict
add wave -radix 16 -expand -group {Control} sim:/top/datapath/control_unit/store_buffer_drain

add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/put_addr_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/put_data_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/put_size_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/put_enable_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/head
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/tail
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/full
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/empty
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/advance
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/retreat
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/get_addr_o
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/get_data_o
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/get_size_o
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/get_enable_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/entries
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/dcache_hit_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/snoop_addr_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/snoop_data_o
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/snoop_size_i
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/snoop_hit_o
add wave -radix 16 -expand -group {Store buffer} sim:/top/datapath/store_buffer/snoop_line_conflict_o

add wave -radix 16 -expand -group {Dcache sign extend} sim:/top/datapath/dcache_sign_extend/data_in
add wave -radix 16 -expand -group {Dcache sign extend} sim:/top/datapath/dcache_sign_extend/is_signed
add wave -radix 16 -expand -group {Dcache sign extend} sim:/top/datapath/dcache_sign_extend/size
add wave -radix 16 -expand -group {Dcache sign extend} sim:/top/datapath/dcache_sign_extend/data_out

add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.addr
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.rd_data
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.access
add wave -radix 16 -expand -group {ICache bus} sim:/top/icache_bus.hit

add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.addr
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.rd_data
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.rd_size
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.wr_data
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.wr_size
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.write
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.access
add wave -radix 16 -expand -group {DCache bus} sim:/top/dcache_bus.hit

add wave -radix 16 -expand -group {ICache} sim:/top/icache/state
add wave -radix 16 -expand -group {ICache} sim:/top/icache/hit
add wave -radix 16 -expand -group {ICache} sim:/top/icache/cur_line
add wave -radix 16 -expand -group {ICache} sim:/top/icache/lines

add wave -radix 16 -expand -group {DCache} sim:/top/dcache/state
add wave -radix 16 -expand -group {DCache} sim:/top/dcache/hit
add wave -radix 16 -expand -group {DCache} sim:/top/dcache/cur_line
add wave -radix 16 -expand -group {DCache} sim:/top/dcache/lines

add wave -radix 16 -expand -group {Memory arbiter} sim:/top/memory_arbiter/state

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
