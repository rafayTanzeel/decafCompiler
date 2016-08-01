	.text
	.file	"llvm/test/aqs-5.llvm.bc"
	.globl	initList
	.align	16, 0x90
	.type	initList,@function
initList:                               # @initList
	.cfi_startproc
# BB#0:                                 # %entry
	movl	%edi, -4(%rsp)
	retq
.Lfunc_end0:
	.size	initList, .Lfunc_end0-initList
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
