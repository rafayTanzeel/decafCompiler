	.text
	.file	"llvm/dev/returnmismatch-intofchar-ok.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	callq	test
	movl	%eax, 4(%rsp)
	movl	%eax, %edi
	callq	print_int
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
	movl	$120, %eax
	retq
.Lfunc_end1:
	.size	test, .Lfunc_end1-test
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
