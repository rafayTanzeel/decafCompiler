	.text
	.file	"llvm/dev/method1.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$1, 4(%rsp)
	movl	$1, %edi
	callq	print_int
	movl	$1, %edi
	callq	test
	movl	4(%rsp), %edi
	callq	print_int
	movl	4(%rsp), %edi
	callq	test
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.globl	test
	.align	16, 0x90
	.type	test,@function
test:                                   # @test
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp1:
	.cfi_def_cfa_offset 16
	movl	%edi, 4(%rsp)
	movl	$1, (%rsp)
	movl	$1, %edi
	callq	print_int
	movl	(%rsp), %edi
	callq	print_int
	popq	%rax
	retq
.Lfunc_end1:
	.size	test, .Lfunc_end1-test
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
