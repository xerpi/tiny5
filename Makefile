VERILATOR ?= verilator

TOP_MODULE = top_tb
TRACE = trace.vcd

SV_SOURCES = definitions.sv alu.sv control.sv datapath.sv regfile.sv
SV_TB_SOURCES = tb/top_tb.sv tb/mem_tb.sv
CC_TB_SOURCES = tb/main.cpp tb/Tiny5Tb.cpp
TEST_SOURCES = test/start.s

VTOP = V$(TOP_MODULE)
CFLAGS = "-DVTOP_MODULE=$(VTOP)"
VERILATOR_FLAGS = -Wno-fatal -Wall -CFLAGS $(CFLAGS)
TEST_CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib

all: verilate

obj_dir/$(VTOP): $(SV_TB_SOURCES) $(SV_SOURCES) $(CC_TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VTOP).mk $(VTOP)

verilate: obj_dir/$(VTOP)

lint:
	@$(VERILATOR) -Wall --lint-only $(SV_TB_SOURCES) $(SV_SOURCES)

run: obj_dir/$(VTOP) test.bin
	@obj_dir/$(VTOP) -l addr=0x00000000,file=test.bin $(ARGS)

gtkwave: $(TRACE)
	@gtkwave $(TRACE) trace.sav &

$(TRACE): run

test.bin: test.elf
	@riscv64-unknown-elf-objcopy -S -O binary $^ $@

test.elf: $(TEST_SOURCES)
	@riscv64-unknown-elf-gcc -T test/linker.ld $(TEST_CFLAGS) $^ -o $@

disasm_test: test.elf
	@riscv64-unknown-elf-objdump -M numeric,no-aliases -d $^

view: top.svg
	@inkview top.svg 2> /dev/null &

top.svg: top.json
	@node $(NETLISTSVG) top.json -o $@

top.json: $(TOP)
	@yosys -q -o top.json -p proc -p opt -p "hierarchy -auto-top -libdir ." $(TOP)

%.hex.txt: %.bin
	@hexdump -ve '1/1 "%.2x "' $< > $@

clean:
	rm -rf obj_dir $(TRACE) test.elf test.bin top.svg top.json

.PHONY:
	verilate run trace clean
