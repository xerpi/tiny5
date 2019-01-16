OUTPUT_FORMAT("elf32-littleriscv","elf32-littleriscv","elf32-littleriscv")
OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
	. = 0x00001000;
	.text : {
		*(.text.start)
		*(.text*)
		*(.rodata*)
	}
	.data : {
		*(.data*)
		*(.sdata*)
		*(.bss*)
	}
	. = ALIGN(1024);
	_sp_start = ABSOLUTE(.);
	. += 1024;
	_sp_end = ABSOLUTE(.);
}
