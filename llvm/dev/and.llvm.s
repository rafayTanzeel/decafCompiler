	.text
	.file	"llvm/dev/and.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %end9
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
	callq	print_int
	xorl	%edi, %edi
	callq	print_int
	xorl	%edi, %edi
	callq	print_int
	xorl	%edi, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
