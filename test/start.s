	.text
	.global _start
_start:
	la x1, data
	li x2, 0xAABBCCDD
	sw x2, 0(x1)

	nop
	nop
	nop
	nop

data:
	.word 0xAABBCCDD
