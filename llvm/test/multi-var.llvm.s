	.text
	.file	"llvm/test/multi-var.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.type	a,@object               # @a
	.bss
	.globl	a
	.align	4
a:
	.size	a, 0

	.type	b,@object               # @b
	.globl	b
	.align	4
b:
	.size	b, 0

	.type	c,@object               # @c
	.globl	c
	.align	4
c:
	.size	c, 0


	.section	".note.GNU-stack","",@progbits
