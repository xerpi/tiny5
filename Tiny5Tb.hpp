#ifndef TINY5TB_HPP
#define TINY5TB_HPP

#include <cstdint>
#include <map>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

class Tiny5Tb {
public:
	Tiny5Tb(Vtop *top);
	~Tiny5Tb();

	void resetTick(void);
	void tick(void);
	void enableTracing(const std::string &name, int levels = 99, int options = 0);

	uint64_t getTimeStamp(void);

	uint8_t memRead8(uint32_t address);
	void memWrite8(uint32_t address, uint8_t data);
	uint16_t memRead16(uint32_t address);
	void memWrite16(uint32_t address, uint16_t data);
	uint32_t memRead32(uint32_t address);
	void memWrite32(uint32_t address, uint32_t data);

private:
	Vtop *top;
	uint64_t timeStamp;
	std::map<uint32_t, uint8_t> mem;
	VerilatedVcdC *vcd;

	void advanceTimeStamp(void);
};

#endif
