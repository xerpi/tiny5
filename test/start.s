	.text
	.global _start
_start:
	li x1, 0x01
	li x2, 0x02
	add x3, x2, x1
	nop
	nop
	add x4, x3, x2

	nop
	nop
