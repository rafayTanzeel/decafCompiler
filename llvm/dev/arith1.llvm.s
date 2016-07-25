	.text
	.file	"llvm/dev/arith1.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movb	$1, 6(%rsp)
	movb	$0, 5(%rsp)
	movb	$1, 4(%rsp)
	movb	5(%rsp), %al
	andb	$1, %al
	movzbl	%al, %ecx
	cmpl	$1, %ecx
	jne	.LBB0_2
# BB#1:
	xorl	%eax, %eax
.LBB0_2:                                # %end
	movb	6(%rsp), %cl
	movb	%cl, %dl
	notb	%dl
	testb	$1, %dl
	je	.LBB0_4
# BB#3:                                 # %ifright7
	movb	%al, %cl
.LBB0_4:                                # %end6
	andb	$1, %cl
	movb	%cl, 7(%rsp)
	movl	$0, (%rsp)
	xorl	%edi, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
