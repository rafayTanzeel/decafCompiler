	.text
	.file	"llvm/test/3int-blocks.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	subq	$24, %rsp
.Ltmp0:
	.cfi_def_cfa_offset 32
	movl	$1, 20(%rsp)
	movl	$1, 4(%rsp)
	movl	20(%rsp), %edi
	callq	print_int
	movl	4(%rsp), %edi
	callq	print_int
	movl	$1, 12(%rsp)
	movl	$1, (%rsp)
	movl	$1, 4(%rsp)
	movl	12(%rsp), %edi
	callq	print_int
	movl	(%rsp), %edi
	callq	print_int
	movl	4(%rsp), %edi
	callq	print_int
	xorl	%eax, %eax
	addq	$24, %rsp
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
