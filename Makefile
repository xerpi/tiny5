VERILATOR ?= verilator

SV_SOURCES = top.sv definitions.sv alu.sv control.sv datapath.sv \
	mem_tb.sv regfile.sv
TOP_MODULE = top
TB_SOURCES = main.cpp Tiny5Tb.cpp
TRACE = trace.vcd

VERILATOR_FLAGS = -Wno-fatal -Wall
VTOP = V$(TOP_MODULE)

all: verilate

obj_dir/$(VTOP): $(SV_SOURCES) $(TB_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace --cc --exe $^ --top-module $(TOP_MODULE)
	make -j4 -k -C obj_dir -f $(VTOP).mk $(VTOP)

verilate: obj_dir/$(VTOP)

lint:
	@$(VERILATOR) -Wall --lint-only $(SV_SOURCES)

run: obj_dir/$(VTOP)
	@obj_dir/$(VTOP) $(ARGS)

gtkwave: $(TRACE)
	@gtkwave $(TRACE) trace.sav &

$(TRACE): run

view: top.svg
	@inkview top.svg 2> /dev/null &

top.svg: top.json
	@node $(NETLISTSVG) top.json -o $@

top.json: $(TOP)
	@yosys -q -o top.json -p proc -p opt -p "hierarchy -auto-top -libdir ." $(TOP)

%.hex: %.bin
	@hexdump -ve '1/1 "%.2x "' $< > $@

clean:
	rm -rf obj_dir $(TRACE) top.svg top.json

.PHONY:
	verilate run trace clean
