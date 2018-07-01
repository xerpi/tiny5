	.text
	.global _start
_start:
	li x1, 0xAA00
	li x2, 0xBB
	add x3, x2, x1
	sub x4, x3, x2

	la x5, var
	sw x4, 0(x5)
	lw x6, 0(x5)

	.data
var:
	.word 0
