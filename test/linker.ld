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
		*(.bss*)
	}
	. = ALIGN(1024);
	_sp_start = .;
	. += 1024;
	_sp_end = .;
}
