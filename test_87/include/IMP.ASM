; important macro definitions
mfwait	macro
	ifdef I8087
	fwait
	endif
	endm

pushr	macro	reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8
	ifnb	<reg1>
	push	reg1
	pushr	reg2,reg3,reg4,reg5,reg6,reg7,reg8
	endif
	endm
	
popr	macro	reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8
	ifnb	<reg1>
	pop	reg1
	popr	reg2,reg3,reg4,reg5,reg6,reg7,reg8
	endif
	endm

incs	macro	reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8
	ifnb	<reg1>
	inc	reg1
	incs	reg2,reg3,reg4,reg5,reg6,reg7,reg8
	endif
	endm

decs	macro	reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8
	ifnb	<reg1>
	dec	reg1
	decs	reg2,reg3,reg4,reg5,reg6,reg7,reg8
	endif
	endm

dosprn	macro	adddr
	mov	dx, offset adddr
	mov	ah, 9
	int	21h
	endm
