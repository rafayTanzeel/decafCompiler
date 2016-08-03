	.text
	.file	"llvm/test/gcd2.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	a(%rip), %edi
	movl	b(%rip), %esi
	callq	gcd
	movl	%eax, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.globl	gcd
	.align	16, 0x90
	.type	gcd,@function
gcd:                                    # @gcd
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp1:
	.cfi_def_cfa_offset 16
	movl	%edi, 4(%rsp)
	movl	%esi, (%rsp)
	movl	4(%rsp), %edi
	callq	iszero
	andb	$1, %al
	movzbl	%al, %eax
	popq	%rcx
	retq
.Lfunc_end1:
	.size	gcd, .Lfunc_end1-gcd
	.cfi_endproc

	.globl	iszero
	.align	16, 0x90
	.type	iszero,@function
iszero:                                 # @iszero
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp2:
	.cfi_def_cfa_offset 16
	movl	%edi, 4(%rsp)
	movl	%esi, (%rsp)
	cmpl	$0, (%rsp)
	je	.LBB2_2
# BB#1:                                 # %iffalse
	movl	(%rsp), %edi
	movl	4(%rsp), %eax
	cltd
	idivl	%edi
	movl	%edx, %esi
	callq	gcd
.LBB2_2:                                # %iftrue
	movb	$1, %al
	popq	%rcx
	retq
.Lfunc_end2:
	.size	iszero, .Lfunc_end2-iszero
	.cfi_endproc

	.type	a,@object               # @a
	.data
	.align	4
a:
	.long	10                      # 0xa
	.size	a, 4

	.type	b,@object               # @b
	.align	4
b:
	.long	20                      # 0x14
	.size	b, 4


	.section	".note.GNU-stack","",@progbits
