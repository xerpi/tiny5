#include <iostream>
#include <cstdio>
#include <getopt.h>
#include <verilated.h>
#include "Tiny5Tb.hpp"
#include "top_module.h"
#include VTOP_MODULE_HEADER
#include VTOP_MODULE_DPI_HEADER

#ifndef TRACE_FILE
#define TRACE_FILE "trace.vcd"
#endif

#define DEFAULT_TICKS 1000

static void usage(char *argv[]);

static Tiny5Tb *tiny5tb;

extern double sc_time_stamp()
{
	return tiny5tb->getTimeStamp();
}

extern uint8_t mem_read8(uint32_t address)
{
	return tiny5tb->memRead8(address);
}

extern void mem_write8(uint32_t address, uint8_t data)
{
	tiny5tb->memWrite8(address, data);
}

extern uint16_t mem_read16(uint32_t address)
{
	return tiny5tb->memRead16(address);
}

extern void mem_write16(uint32_t address, uint16_t data)
{
	tiny5tb->memWrite16(address, data);
}

extern uint32_t mem_read32(uint32_t address)
{
	return tiny5tb->memRead32(address);
}

extern void mem_write32(uint32_t address, uint32_t data)
{
	tiny5tb->memWrite32(address, data);
}

static size_t fp_get_size(FILE *fp)
{
	size_t size;

	fseek(fp, 0, SEEK_END);
	size = ftell(fp);
	rewind(fp);

	return size;
}

static int load_file_bin(const char *file, uint32_t addr)
{
	FILE *fp;
	size_t file_size;
	size_t read_size;
	uint8_t *buffer;

	if (!(fp = fopen(file, "rb"))) {
		printf("Error opening '%s': %s\n", file, strerror(errno));
		return 0;
	}

	file_size = fp_get_size(fp);
	buffer = (uint8_t *)malloc(file_size);
	if (!buffer) {
		printf("Error loading '%s': malloc()\n", file);
		fclose(fp);
		return 0;
	}

	read_size = fread(buffer, 1, file_size, fp);

	for (size_t offset = 0; offset < read_size; offset++)
		tiny5tb->memWrite8(addr + offset, buffer[offset]);

	free(buffer);
	fclose(fp);

	printf("Loaded '%s' at address 0x%08X\n", file, addr);

	return 1;
}

static int load_file_hex(const char *file, uint32_t addr)
{
	FILE *fp;
	uint32_t offset = 0;

	if (!(fp = fopen(file, "r"))) {
		printf("Error opening '%s': %s\n", file, strerror(errno));
		return 0;
	}

	while (1) {
		int ret;
		uint8_t data;

		ret = fscanf(fp, "%2hhx", &data);
		if (ret == -1) {
			if (errno != 0) {
				printf("Error loading '%s': %s\n", file,
					strerror(errno));
				fclose(fp);
				return 0;
			} else {
				break;
			}
		}

		if (ret == EOF || ret == 0)
			break;

		tiny5tb->memWrite8(addr + offset, data);
		offset++;
	}

	fclose(fp);

	printf("Loaded '%s' at address 0x%08X\n", file, addr);

	return 1;
}


static int load_file(const char *file, uint32_t addr)
{
	const char *ext = strrchr(file, '.');

	if (ext != NULL && strcmp(ext + 1, "bin") == 0) {
		return load_file_bin(file, addr);
	} else {
		return load_file_hex(file, addr);
	}
}

enum load_subopt {
	ADDR_OPT = 0,
	FILE_OPT
};

static char *const load_subopt_token[] = {
	[ADDR_OPT] = (char *)"addr",
	[FILE_OPT] = (char *)"file",
	NULL
};

static int parse_load_subopt(char *optarg)
{
	char *value;
	char *subopts = optarg;
	uint32_t load_addr = 0;
	char *load_file_name = NULL;

	while (*subopts != '\0') {
		switch (getsubopt(&subopts, load_subopt_token, &value)) {
		case ADDR_OPT:
			if (!value)
				return -1;

			load_addr = strtoul(value, NULL, 0);
			break;
		case FILE_OPT:
			if (!value)
				return -1;

			if (load_file_name)
				free(load_file_name);

			load_file_name = strdup(value);
			break;
		}
	}

	if (load_file_name) {
		if (!load_file(load_file_name, load_addr)) {
			free(load_file_name);
			return 0;
		}
		free(load_file_name);
	}

	return 1;
}

int main(int argc, char *argv[])
{
	static const struct option long_options[] = {
		{"load", required_argument, NULL, 'l'},
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
		case 'l':
			if (!parse_load_subopt(optarg)) {
				early_exit = true;
				ret = -1;
			}
			break;
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
		"  -l, --load addr=ADDR,file=FILE loads FILE to ADDR\n"
		"  -m, --max-ticks=N       maximum number of ticks before stopping\n"
		"  -h, --help              display this help and exit\n"
		, argv[0]);
}
