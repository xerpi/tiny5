	.text
	.global _start
_start:
	la x1, data
	lb x2, 0(x1)
	lbu x3, 1(x1)
	lh x4, 0(x1)
	lhu x5, 2(x1)

	nop
	nop
	nop
	nop

data:
	.word 0xAABBCCDD
