	.section .text.start
	.global _start
_start:
	la sp, _sp_end
	jal main
