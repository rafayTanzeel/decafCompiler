	.text
	.file	"llvm/dev/boolcall2.llvm.bc"
	.globl	test
	.align	16, 0x90
	.type	test,@function
test:                                   # @test
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	andl	$1, %edi
	movb	%dil, 7(%rsp)
	andl	$1, %esi
	movb	%sil, 6(%rsp)
	movl	$2, %edi
	callq	print_int
	popq	%rax
	retq
.Lfunc_end0:
	.size	test, .Lfunc_end0-test
	.cfi_endproc

	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp1:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
	xorl	%esi, %esi
	callq	test
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
