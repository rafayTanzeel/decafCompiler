	.text
	.file	"llvm/dev/stringescapes.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$.Lglobalstring, %edi
	callq	print_string
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.type	.Lglobalstring,@object  # @globalstring
	.section	.rodata.str1.16,"aMS",@progbits,1
	.align	16
.Lglobalstring:
	.asciz	"1\t2v3r4n5a6f7b89\"10"
	.size	.Lglobalstring, 20


	.section	".note.GNU-stack","",@progbits
