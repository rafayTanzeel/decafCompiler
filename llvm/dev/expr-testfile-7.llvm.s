	.text
	.file	"llvm/dev/expr-testfile-7.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	subq	$24, %rsp
.Ltmp0:
	.cfi_def_cfa_offset 32
	movl	$958, 20(%rsp)          # imm = 0x3BE
	movl	$-28660, 12(%rsp)       # imm = 0xFFFFFFFFFFFF900C
	movl	$28660, 20(%rsp)        # imm = 0x6FF4
	movb	$0, 19(%rsp)
	movl	20(%rsp), %edi
	callq	print_int
	xorl	%eax, %eax
	addq	$24, %rsp
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
