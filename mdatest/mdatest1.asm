.186
SEG_A		SEGMENT
		ASSUME CS:SEG_A, DS:SEG_A
		ORG	100H

SCR_ADDR	equ	50*2
SRC_ATTR	equ	19h
KBD_ADDR	equ	80*2*2
ACS_ATTR	equ	17h
SCD_ATTR	equ	1Eh

ADRB0	equ	0b0h
ADRB8	equ	0b8h

COMY	PROC
	START:
	call	get_opts
	mov	di,KBD_ADDR
	mov	es,disp_segm
	mov	ds,test_segm
	mov	si,cs:start_mem
	cmp	cs:maintest,0
	je	addr_test

	mov	dx,32*1024
@@:	mov	ax,si
	mov	al,ah ; high byte of SI
	push	di
	call	store_screen
	mov	ax,si
	call	store_screen ; low byte
	call	mem_check
	jz	no_prn_err
	call	prn_err
	jz	texit
no_prn_err: 	pop	di
	add	si, cs:inc_mem
	cmp	si,dx
	jb	@B

	call	end_mem
addr_test:
	add	di,80*2

	mov	dx,32*1024
	mov	al,0
	mov	si,cs:start_mem
@@:	mov	[si],al
	add	si,cs:inc_mem
	add	al,13
	cmp	si,dx
	jb	@B

	mov	dx,32*1024
	mov	bl,0
	mov	si,cs:start_mem

@@:	mov	ax,si
	mov	al,ah
	push	di
	call	store_screen
	mov	ax,si
	call	store_screen

	mov	ah,[si]
	cmp	ah,bl
	jz	addr_ok
	mov	al,bl
	call	prn_err
	je	texit
addr_ok:pop	di
	add	si,cs:inc_mem
	add	bl,13
	cmp	si,dx
	jb	@B	

	call	end_mem
texit:
	int	20h

COMY	ENDP

prn_err	proc
	push	ax
	push	ax
	inc	di ; position change
	inc	di
	call	store_screen ; one value
	pop	ax
	mov	al,ah
	call	store_screen ; another value
	inc	di ; +col
	inc	di
	pop	ax
	xor	al,ah
	call	store_screen
	mov	ah,0
	int	16h
	cmp	al,'q'
	ret
prn_err	endp

end_mem	proc
	push	di
	mov	ax,(ACS_ATTR SHL 8)+'-'
	stosw
	stosw
	stosw
	stosw
	pop	di
	ret
end_mem	endp

; DS:SI = checked cell
; NZ on fail, ZR if OK
mem_check	proc
	mov	al,1
mem_str:mov	cx,8
@@:	mov	[si],al
	push	ax
	pop	ax
	mov	ah,[si]
	cmp	al,ah
	jnz	mem_ex
	rol	al,1
	loop	@B
	not	al
	test	al,1
	jz	mem_str
	sub	al,al
mem_ex:	ret

mem_check	endp

get_opts	proc
	cld
	mov	si,80h
	mov	ax,ADRB0 SHL 8
	cmp	byte ptr [si+2],'8'
	jne	@F
	mov	ah,ADRB8
@@:	mov	test_segm,ax
	mov	ah,ADRB0
	cmp	byte ptr [si+3],'8'
	jne	@F
	mov	ah,ADRB8
@@:	mov	disp_segm,ax
	mov	ax,1
	cmp	byte ptr [si+4],'2'
	jne	@F
	inc	ax
@@:	mov	inc_mem,ax
	xor	ax,ax
	cmp	byte ptr [si+5],'1'
	jne	@F
	inc	ax
@@:	mov	start_mem,ax
	or	al,1
	cmp	byte ptr [si+6],'0'
	jne	@F
	dec	ax
@@:	mov	maintest,ax
	ret
get_opts	endp
; render AL as 2 hex digits at address
; ES:DI = screen address, is propagated
; AL = number
store_screen	proc
	mov	ah,SCD_ATTR
	push	ax
	mov	cl,4
	shr	al,cl
	add	al,90h
	daa
	adc	al,40h
	daa
	stosw
	pop	ax
	and	al,0fh
	add	al,90h
	daa
	adc	al,40h
	daa
	stosw
	ret
store_screen	endp

options	db	"<0|8>testseg<0|8>dispseg<1|2>incmem<0|1>ofsmem<0|1>onlyadr"

test_segm	dw	0b000h
disp_segm	dw	0b800h
inc_mem		dw	1
start_mem	dw	0
maintest	dw	1

SEG_A	ENDS
	END	COMY
