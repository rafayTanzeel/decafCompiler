	.text
	.file	"llvm/dev/boolcallcalleeexpr.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
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
	andl	$1, %edi
	movb	%dil, 7(%rsp)
	movb	7(%rsp), %al
	andb	$1, %al
	movzbl	%al, %ecx
	cmpl	$1, %ecx
	je	.LBB1_2
# BB#1:                                 # %ifright
	xorl	%eax, %eax
.LBB1_2:                                # %end
	movzbl	%al, %edi
	callq	print_int
	popq	%rax
	retq
.Lfunc_end1:
	.size	test, .Lfunc_end1-test
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
