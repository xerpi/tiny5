VERILATOR ?= verilator

VERILATOR_TOP_MODULE = top_dpi_mem
MODELSIM_TOP_MODULE = top_simple_mem
TRACE_FILE = trace.vcd

SV_SOURCES = definitions.sv alu.sv compare_unit.sv control.sv \
	datapath.sv mem_if.sv regfile.sv
SV_DPI_MEM_SOURCES = top_dpi_mem.sv dpi_mem.sv
SV_SIMPLE_MEM_SOURCES = simple_mem.sv top_simple_mem.sv
TEST_SOURCES = test/start.s

VERILATOR_SV_TB_SOURCES = $(SV_SOURCES) $(SV_DPI_MEM_SOURCES)
MODELSIM_SV_TB_SOURCES = $(SV_SOURCES) $(SV_SIMPLE_MEM_SOURCES)
VERILATOR_CC_TB_SOURCES = tb/main.cpp tb/Tiny5Tb.cpp

VERILATOR_VTOP = V$(VERILATOR_TOP_MODULE)
CFLAGS = -DVTOP_MODULE=$(VERILATOR_VTOP) -DTRACE_FILE="\\\"$(TRACE_FILE)\\\""
VERILATOR_FLAGS = -Wno-fatal -Wall -CFLAGS "$(CFLAGS)"
TEST_CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib

all: verilate

obj_dir/$(VERILATOR_VTOP): $(VERILATOR_SV_TB_SOURCES) $(VERILATOR_CC_TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(VERILATOR_TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VERILATOR_VTOP).mk $(VERILATOR_VTOP)

verilate: obj_dir/$(VERILATOR_VTOP)

lint:
	@$(VERILATOR) -Wall --lint-only $(VERILATOR_SV_TB_SOURCES)

run: obj_dir/$(VERILATOR_VTOP) test.bin
	@obj_dir/$(VERILATOR_VTOP) -l addr=0x00000000,file=test.bin $(ARGS)

$(TRACE_FILE): run

modelsim: $(MODELSIM_SV_TB_SOURCES) test.hex.txt
	vlib work
	vlog -ccflags "-std=c++11" $(MODELSIM_SV_TB_SOURCES)
	vsim -do tb/modelsim.do $(MODELSIM_TOP_MODULE)

gtkwave: $(TRACE_FILE)
	@gtkwave $(TRACE_FILE) trace.sav

test.bin: test.elf
	riscv64-unknown-elf-objcopy -S -O binary $^ $@

test.elf: $(TEST_SOURCES)
	riscv64-unknown-elf-gcc -T test/linker.ld $(TEST_CFLAGS) $^ -o $@

disasm_test: test.elf
	@riscv64-unknown-elf-objdump -M numeric,no-aliases -D $^

view: top.svg
	@inkview top.svg 2> /dev/null &

top.svg: top.json
	@node $(NETLISTSVG) top.json -o $@

top.json: $(TOP)
	@yosys -q -o top.json -p proc -p opt -p "hierarchy -auto-top -libdir ." $(TOP)

%.hex.txt: %.bin
	@hexdump -ve '1/1 "%.2x "' $< > $@

clean:
	rm -rf obj_dir work $(TRACE_FILE) test.elf test.bin test.hex.txt top.svg top.json

.PHONY:
	verilate run trace gtkwave clean
