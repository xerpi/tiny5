onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /top_simple_mem/reset_i
add wave -noupdate -radix hexadecimal /top_simple_mem/clk_i
add wave -noupdate /top_simple_mem/tl_master/state
add wave -noupdate /top_simple_mem/memif_cpu_master/busy
add wave -noupdate /top_simple_mem/dp/control/halt
add wave -noupdate -radix hexadecimal /top_simple_mem/dp/pc
add wave -noupdate /top_simple_mem/dp/control/pc_we_o
add wave -noupdate -radix hexadecimal /top_simple_mem/dp/ir
add wave -noupdate /top_simple_mem/dp/control/ir_we_o
add wave -noupdate -radix hexadecimal /top_simple_mem/dp/ctrl_next_pc_sel
add wave -noupdate -radix hexadecimal /top_simple_mem/dp/ctrl_alu_in1_sel
add wave -noupdate -radix hexadecimal /top_simple_mem/dp/regfile/registers
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1 ns}
