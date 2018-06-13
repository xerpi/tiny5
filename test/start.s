	.text
	.global _start
_start:
	csrr x1, cycle
	csrr x2, cycle
	csrr x3, cycle
	csrr x4, cycle
	csrr x5, cycle

	li x1, 0xAA00
	li x2, 0xBB
	add x3, x2, x1
	sub x4, x3, x2

	la x5, var
	sw x4, 0(x5)
	lw x6, 0(x5)

	nop
	nop

	.data
var:
	.word 0
