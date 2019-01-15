	.text
	.global _start
_start:
	li   x1, 20
	li   x2, -3
	div  x3, x1, x2

	nop
	nop
	nop



	la x1, data
	li x2, 0x11223344
	li x3, 0x55667788
	sb x2, 0(x1)
	sb x2, 1(x1)
	sb x2, 2(x1)
	sb x2, 3(x1)
	sb x2, 4(x1)
	sb x3, 5(x1)
	lh x4, 0(x1)

	nop
	nop
	nop
	nop

data:
	.word 0xAABBCCDD
