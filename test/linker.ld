OUTPUT_FORMAT("elf32-littleriscv","elf32-littleriscv","elf32-littleriscv")
OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
	. = 0x00010000;
	.text : {
		*(.text.start)
		*(.text*)
		*(.rodata*)
	}
	.data : {
		*(.data*)
		*(.bss*)
	}
}
