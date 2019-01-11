	.text
	.global _start
_start:
	la x1, data
	li x2, 0x11223344
	li x3, 0x55667788
	sw x2, 0(x1)
	sw x2, 4(x1)
	sw x2, 8(x1)
	sw x2, 12(x1)
	sw x2, 16(x1)
	sb x3, 0(x1)
	lh x4, 0(x1)

	nop
	nop
	nop
	nop

data:
	.word 0xAABBCCDD
