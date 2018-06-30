VERILATOR ?= verilator

VERILATOR_TOP_MODULE = top_dpi_mem
MODELSIM_TOP_MODULE = top_simple_mem
TRACE_FILE = trace.vcd

COMMON_SOURCES = definitions.sv alu.sv compare_unit.sv control.sv \
	datapath.sv regfile.sv csr.sv memory_array_interface.sv \
	tilelink.sv tl_memory_controller.sv

VERILATOR_SOURCES = $(COMMON_SOURCES) top_dpi_mem.sv dpi_mem.sv
VERILATOR_TB_SOURCES = tb/main.cpp tb/Tiny5Tb.cpp
MODELSIM_SOURCES = $(COMMON_SOURCES) simple_mem.sv top_simple_mem.sv
TEST_SOURCES = test/start.s

VERILATOR_VTOP = V$(VERILATOR_TOP_MODULE)
CFLAGS = -std=c++11 -DVTOP_MODULE=$(VERILATOR_VTOP) -DTRACE_FILE="\\\"$(TRACE_FILE)\\\""
VERILATOR_FLAGS = -Wno-fatal -Wall -CFLAGS "$(CFLAGS)"
TEST_CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib

all: lint

#### Verilator ####
obj_dir/$(VERILATOR_VTOP): $(VERILATOR_SOURCES) $(VERILATOR_TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(VERILATOR_TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VERILATOR_VTOP).mk $(VERILATOR_VTOP)

verilate: obj_dir/$(VERILATOR_VTOP)

lint:
	@$(VERILATOR) -Wall --lint-only $(VERILATOR_SOURCES) --top-module $(VERILATOR_TOP_MODULE)

run: obj_dir/$(VERILATOR_VTOP) test.bin
	@obj_dir/$(VERILATOR_VTOP) -l addr=0x00010000,file=test.bin $(ARGS)

$(TRACE_FILE): run

gtkwave: $(TRACE_FILE)
	@gtkwave $(TRACE_FILE) trace.sav

#### Modelsim ####
modelsim: $(MODELSIM_SOURCES) test.hex.txt
	vlib work
	vlog -ccflags "-std=c++11" $(MODELSIM_SOURCES)
	vsim -do tb/modelsim.do $(MODELSIM_TOP_MODULE)

#### Test code ####
test.bin: test.elf
	riscv64-unknown-elf-objcopy -S -O binary $^ $@

test.elf: $(TEST_SOURCES)
	riscv64-unknown-elf-gcc -T test/linker.ld $(TEST_CFLAGS) $^ -o $@

disasm_test: test.elf
	@riscv64-unknown-elf-objdump -M numeric,no-aliases -D $^

%.hex.txt: %.bin
	@hexdump -ve '1/1 "%.2x "' $< > $@

clean:
	rm -rf obj_dir work $(TRACE_FILE) test.elf test.bin test.hex.txt

.PHONY:
	verilate run trace gtkwave clean
