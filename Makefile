VERILATOR ?= verilator

SV_SOURCES = top.sv definitions.sv alu.sv control.sv datapath.sv \
	mem_tb.sv regfile.sv
CC_SOURCES =
TOP_MODULE = top
TB_SOURCES = tiny5_tb.cpp
VERILATOR_FLAGS = -Wno-fatal -Wall
VTOP = V$(TOP_MODULE)

all: verilate

obj_dir/$(VTOP): $(SV_SOURCES) $(TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VTOP).mk $(VTOP)

verilate: obj_dir/$(VTOP)

lint:
	$(VERILATOR) -Wall --lint-only $(SV_SOURCES)

run: obj_dir/$(VTOP) data.hex
	@obj_dir/$(VTOP)

gtkwave: dump.vcd
	@gtkwave dump.vcd &

dump.vcd: run

view: top.svg
	@inkview top.svg 2> /dev/null &

top.svg: top.json
	@node $(NETLISTSVG) top.json -o $@

top.json: $(TOP) data.hex
	@yosys -q -o top.json -p proc -p opt -p "hierarchy -auto-top -libdir ." $(TOP)

%.hex: %.bin
	@hexdump -ve '1/1 "%.2x "' $< > $@

clean:
	rm -rf obj_dir data.hex dump.vcd top.svg top.json

.PHONY:
	verilate run trace clean
