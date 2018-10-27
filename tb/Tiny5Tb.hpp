#ifndef TINY5TB_HPP
#define TINY5TB_HPP

#include <cstdint>
#include <map>
#include <verilated.h>
#include <verilated_fst_c.h>
#include "top_module.h"
#include VTOP_MODULE_HEADER

class Tiny5Tb {
public:
	Tiny5Tb(VTOP_MODULE *top);
	~Tiny5Tb();

	void resetTick(void);
	void tick(void);
	void enableTracing(const std::string &name, int levels = 99, int options = 0);

	uint64_t getTimeStamp(void);

private:
	VTOP_MODULE *top;
	uint64_t timeStamp;
	VerilatedFstC *fst;

	void advanceTimeStamp(void);
};

#endif
