	.text
	.global _start
_start:
	li x1, 0xAA00
	li x2, 0xBB
	add x3, x2, x1
	sub x4, x3, x2
