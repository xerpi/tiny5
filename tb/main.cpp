#include <iostream>
#include <cstdio>
#include <getopt.h>
#include <verilated.h>
#include "Tiny5Tb.hpp"
#include "top_module.h"
#include VTOP_MODULE_HEADER

#ifndef TRACE_FILE
#define TRACE_FILE "trace.fst"
#endif

#define DEFAULT_TICKS 2000

static void usage(char *argv[]);

static Tiny5Tb *tiny5tb;

extern double sc_time_stamp()
{
	return tiny5tb->getTimeStamp();
}

int main(int argc, char *argv[])
{
	static const struct option long_options[] = {
		{"max-ticks", required_argument, NULL, 'm'},
		{"help", no_argument, NULL, 'h'},
		{NULL, 0, NULL, 0}
	};

	int opt;
	VTOP_MODULE *top;
	int ret = 0;
	uint64_t max_ticks = DEFAULT_TICKS;
	bool early_exit = false;

	top = new VTOP_MODULE;
	if (!top)
		return -1;

	tiny5tb = new Tiny5Tb(top);
	if (!tiny5tb) {
		top->final();
		delete top;
	}

	while ((opt = getopt_long(argc, argv, "l:m:h", long_options, NULL)) != -1) {
		if (optopt != 0) {
			usage(argv);
			early_exit = true;
			ret = -1;
			break;
		}

		switch (opt) {
		case 'm':
			max_ticks = strtoull(optarg, NULL, 0);
			break;
		case 'h':
			usage(argv);
			early_exit = true;
			break;
		}
	}

	if (early_exit) {
		top->final();
		delete tiny5tb;
		delete top;
		return ret;
	}

	argc -= optind;
	argv += optind;

	Verilated::commandArgs(argc, argv);

	tiny5tb->enableTracing(TRACE_FILE);
	tiny5tb->resetTick();

	while ((tiny5tb->getTimeStamp() < 2 * max_ticks) && !Verilated::gotFinish()) {
		tiny5tb->tick();
	}

	top->final();
	delete tiny5tb;
	delete top;

	return ret;
}

static void usage(char *argv[])
{
	printf("Source code: https://github.com/xerpi/tiny5\n"
		"Usage: %s [OPTIONS]\n"
		"Options:\n"
		"  -m, --max-ticks=N       maximum number of ticks before stopping\n"
		"  -h, --help              display this help and exit\n"
		, argv[0]);
}
