	.text
	.file	"llvm/dev/expr-testfile-2.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %end
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$958, 4(%rsp)           # imm = 0x3BE
	movl	$-958, 4(%rsp)          # imm = 0xFFFFFFFFFFFFFC42
	movb	$1, 3(%rsp)
	movb	$0, 2(%rsp)
	movb	$1, %al
	testb	%al, %al
	je	.LBB0_1
# BB#3:                                 # %ifright7
	movb	2(%rsp), %al
	jmp	.LBB0_2
.LBB0_1:
	xorl	%eax, %eax
.LBB0_2:                                # %end6
	andb	$1, %al
	movb	%al, 3(%rsp)
	movl	4(%rsp), %edi
	negl	%edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
