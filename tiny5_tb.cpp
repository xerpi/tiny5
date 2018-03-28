#include <iostream>
#include <map>
#include <verilated.h>
#include "Vtop__Dpi.h"

#if VM_TRACE
#include <verilated_vcd_c.h>
#endif

#include "Vtop.h"

#define DEFAULT_TICKS 1000

static vluint64_t main_time = 0;
static std::map<uint32_t, uint8_t> mem;

double sc_time_stamp()
{
	return main_time;
}

extern uint8_t mem_read8(uint32_t address)
{
	return mem[address];
}

extern void mem_write8(uint32_t address, uint8_t data)
{
	mem[address] = data;
}

extern uint32_t mem_read32(uint32_t address)
{
	return (mem[address + 3] << 24) | (mem[address + 2] << 16) |
		(mem[address + 1] << 8) | mem[address];
}

extern void mem_write32(uint32_t address, uint32_t data)
{
	mem[address] = data & 0xFF;
	mem[address + 1] = (data >> 8) & 0xFF;
	mem[address + 2] = (data >> 16) & 0xFF;
	mem[address + 3] = (data >> 24) & 0xFF;
}

int main(int argc, char *argv[])
{
	uint64_t max_ticks = 0;
	Vtop *top = new Vtop;

	Verilated::commandArgs(argc, argv);

	mem[0] = 0xAA;
	mem[1] = 0xBB;
	mem[2] = 0xCC;
	mem[3] = 0xDD;

	if (getenv("MAX_TICKS"))
		max_ticks = strtoull(getenv("MAX_TICKS"), NULL, 0);
	if (!max_ticks)
		max_ticks = DEFAULT_TICKS;

#if VM_TRACE
	Verilated::traceEverOn(true);
	VL_PRINTF("Tracing enabled.\n");
	VerilatedVcdC *vcd = new VerilatedVcdC;
	top->trace(vcd, 99);
	vcd->open("dump.vcd");
#endif

	top->clk_i = 1;
	top->reset_i = 1;
	top->eval();
	main_time++;
#if VM_TRACE
	vcd->dump(main_time);
#endif

	top->clk_i = 0;
	top->reset_i = 0;

	while ((main_time <= 2 * max_ticks + 1) && !Verilated::gotFinish()) {
		top->eval();
		main_time++;
#if VM_TRACE
		vcd->dump(main_time);
#endif
		top->clk_i ^= 1;
	}

#if VM_TRACE
	vcd->close();
	delete vcd;
#endif

	delete top;

	return 0;
}
