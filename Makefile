VERILATOR ?= verilator

TOP_MODULE = top_tb
TRACE_FILE = trace.vcd

SV_SOURCES = definitions.sv alu.sv compare_unit.sv control.sv datapath.sv regfile.sv
SV_TB_SOURCES = tb/top_tb.sv tb/mem_tb.sv
CC_TB_SOURCES = tb/main.cpp tb/Tiny5Tb.cpp
TEST_SOURCES = test/start.s

VTOP = V$(TOP_MODULE)
CFLAGS = -DVTOP_MODULE=$(VTOP) -DTRACE_FILE="\\\"$(TRACE_FILE)\\\""
VERILATOR_FLAGS = -Wno-fatal -Wall -CFLAGS "$(CFLAGS)"
TEST_CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib

all: verilate

obj_dir/$(VTOP): $(SV_SOURCES) $(SV_TB_SOURCES) $(CC_TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VTOP).mk $(VTOP)

verilate: obj_dir/$(VTOP)

lint:
	@$(VERILATOR) -Wall --lint-only $(SV_SOURCES) $(SV_TB_SOURCES)

run: obj_dir/$(VTOP) test.bin
	@obj_dir/$(VTOP) -l addr=0x00000000,file=test.bin $(ARGS)

$(TRACE_FILE): run

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
	rm -rf obj_dir $(TRACE_FILE) test.elf test.bin top.svg top.json

.PHONY:
	verilate run trace gtkwave clean
