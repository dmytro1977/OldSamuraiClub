if1
%out [1;32;40mPass 1: assembling [1;31;40m8087 coprocessor 11-level test[0;37;40m
endif
if2 
%out [1;32;40mPass 2: assembling [1;34;40m8087 coprocessor 11-level test[0;37;40m
endif


cseg	segment	para 'code'
	assume	cs:cseg, ds:cseg, es:cseg, ss:cseg
	org	100h
page	,132
env87	struc
CW	dw	?	; xxxIRRPP=MxPUOZDI
SW	dw	?	; B3TTT210=IxPUOZDI
TAG	dw	?
IP	dw	?       ; 16 bit
IP_OP	dw	?
DP	dw	?
DP_H	dw	?
env87	ends

CW_INF_PROJECTIVE	EQU	0
CW_INF_AFFINE		EQU	10h
CW_RC_TONEAR	EQU	0
CW_RC_TODOWN	EQU	4h
CW_RC_TOUP	EQU	8h
CW_RC_TRUNCATE	EQU	12h
CW_PREC_24	EQU	0
CW_PREC_53	EQU	2
CW_PREC_64	EQU	3
CW_ALLI_MASK	EQU	0BFh

CW_INTR_MASK	EQU	03Fh
CW_SUMM_INTR	EQU	080h
CW_RC_MASK	EQU	0C00h
CW_PREC_MASK	EQU	0300h
CW_INF_MASK	EQU	1000h

SW_INTR_MASK	EQU	03Fh
SW_SUMM_INTR	EQU	080H
SW_ALLI_MASK	EQU	0BFh
SW_FLAG_MASK	EQU	4700H
SW_C0_MASK	EQU	0100H
SW_C1_MASK	EQU	0200H
SW_C2_MASK	EQU	0400H
SW_C3_MASK	EQU	4000H
SW_C0_BMASK	EQU	01H
SW_C1_BMASK	EQU	02H
SW_C2_BMASK	EQU	04H
SW_C3_BMASK	EQU	40H
SW_TOS_MASK	EQU	3800H
SW_TOS_BMASK	EQU	38H
SW_BUSY_MASK	EQU	8000H

AI_7B_MASK	EQU	80H
PI_5B_MASK	EQU	20H
UI_4B_MASK	EQU	10H
OI_3B_MASK	EQU	08H
ZI_2B_MASK	EQU	04H
DI_1B_MASK	EQU	02H
II_0B_MASK	EQU	01H

SGSM	struc
sam	dw	?
sag	dw	?
SGSM	ends

NO_OF_TESTS	EQU	15	

include	include/imp.asm

; options
; S - use INTR from slave intr controller
SW_SLAVE_IRQ	equ	1
SW_FPU_287	equ	2
SW_FPU_387	equ	4
SW_NUXT		equ	8

main	proc	near
        cld
	call	get_opts	
	call	init_fpu
	jnc	@F
	mov	dx,offset mess_ni
	call	mdosprn
	ret	; FPU init error
@@:
COMMENT !
	push	ds	; NMI address 
	sub	ax,ax
	mov	ds,ax
	mov	si,8
	mov	di, offset int8_store
	mov	ax, offset irq_13_fpu_inter
	xchg	ax,[si]
	stosw
	mov	ax, cs
	xchg	ax,[si+2]
	stosw
	pop	ds   !

	test	exe_switch, SW_NUXT ;SW_SLAVE_IRQ OR SW_FPU_287 OR SW_FPU_387
	jz	@F
	; NMI stuff
	mov	al, 80h
	out	0a0h, al
	jmp	$+2
	jmp	$+2
	mov	al, 01000011b
	out	63h, al
	jmp	$+2
@@:	;jmp	short set_iv
        ;mov	fpu_intr, 75h
	;mov	word ptr mess_par1, "57"
set_iv:	;call	init_stdlib
	mov	ax, exe_switch
	test	ax, SW_FPU_287 OR SW_FPU_387
	jz	no_proc_modify
	mov	intr_2, offset irq_75_fpu_inter
	sub	ax,ax
	mov	c_alli_prec, CW_INTR_MASK OR ((CW_PREC_64 OR CW_RC_TONEAR)SHL 8)
	mov	test_procs+12, ax
	mov	bx, offset mess_par2+1
	mov	dx, [bx+1] 
	mov	[bx],dx
	mov	dl,"2"
	mov	lab_cr0, 0
	test	exe_switch, SW_FPU_387
	jz	@F
	mov	cod_02+6, DI_1B_MASK
	mov	test_procs+28, ax
	inc	dx
@@:	mov	[bx+2],dl	
no_proc_modify:	
	call	set_intr_vector

	mov	dx, offset mess_welc ; welcome
	call	mdosprn
	call	m_white

	mov	cx, 2
	mov	dx, offset mess_opt1 ; options
@@:	call	mdosprn
	add	dx, 6
	push	dx
	call	m_blue
	pop	dx
	call	mdosprn
	add	dx, 4
	push	dx
	call	m_white
	pop	dx
	loop	@B
	mov	dx, offset mess_crlf
	call	mdosprn

	mov	dx, offset mess_copy ; copyright
	call	mdosprn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	main tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sub	si, si
over_tests:
	mov	dx, offset mess_test ; TEST 
	call	mdosprn
	call	m_blue
	mov	ax,si
	shr	ax,1
	inc	ax
	cwd	; clear dx
	mov	di, offset mess_digits  ; # of test
	call	i2ascc
	call	mdosprn
	mov	dx, offset mess_nmcolor
	call	mdosprn
	mov	dx, [si+nam_t_ofs];test name
	call	mdosprn
	mov	ax,[si+test_procs]
	inc	si
	inc	si
	or	ax,ax
	mov	dx,offset mess_skipped 
	jz	@F
	push	si
	call	ax
	pop	si
	mov	dx, offset mess_passed
	jnc	@F
	cbw     ; only al used
	push	ax
	mov	dx, offset mess_failed ; failed
	call	mdosprn
	pop	ax
	cwd
	mov	di, offset mess_digits ; fail code
	call	i2ascc
@@:	call	mdosprn
fin_print:
	mov	dx, offset mess_crlf ; CR LF
	call	mdosprn
	cmp	si, 2*NO_OF_TESTS
	jb	over_tests	

COMMENT !
	push	es
	sub	ax,ax	; NMI restore
	mov	es,ax
	mov	di,8
	mov	si,offset int8_store
	lodsw
	stosw
	lodsw
	stosw
	pop	es  !
	call	restore_intr_vector
	ret
main	endp

mdosprn	proc
	mov	ah,9
	int	21h
	ret
mdosprn	endp

dossym	proc
	mov	ah,2
	int	21h
	ret
dossym	endp

m_blue	proc
	mov	dx, offset mess_blue
@@:	jmp	mdosprn
m_white:mov	dx, offset mess_white
	jmp	@B
m_blue	endp

set_intr_vector	proc
	push	es
	mov	ah,35h
	mov	al,fpu_intr
	push	ax
	int	21h
	mov	int2_store,bx
	mov	int2_store+2,es
	mov	dx, intr_2 ; offset irq_13_fpu_inter
	pop	ax
	mov	ah,25h
	int	21h
	pop	es
	ret
set_intr_vector	endp

restore_intr_vector	proc
	push	ds
	mov	al, fpu_intr
	mov	ds, int2_store+2
	mov	dx, int2_store
	mov	ah, 25h
	int	21h
	pop	ds 
	ret
restore_intr_vector	endp

get_opts	proc
	mov	si,80h
	lodsb
	cbw
	xchg	ax,cx
	jcxz	sym_end
new_sym:	
	lodsb
	cmp	al, 20h
	jbe	nxt_sym
	cmp	al,'a'
	jb	@F
	cmp	al,'z'
	ja	@F
	sub	al,20h
@@:	push	cx
	mov	di, offset symbopts
	mov	cx, NUM_OPTS
	repnz	scasb
	jnz	@F
	mov	cl,[di]
	mov	bx,1
	shl	bx,cl
	or	exe_switch,bx
@@:	pop	cx
nxt_sym:loop	new_sym
sym_end:ret	
get_opts	endp

; include bn_m.asm

if2 
%out [1;32;40mPass 2: assembling [1;34;40m8087 coprocessor tests[0;37;40m
endif

NUM_OPTS	equ	8
symbopts	db	'S',0,'2',1,'3',2, 'N', 3


test_procs	dw	fpu_test_01, fpu_test_02, fpu_test_03, fpu_test_04
		dw	fpu_test_05, fpu_test_06, fpu_test_07, fpu_test_08
		dw	fpu_test_99, fpu_test_10, fpu_test_11, fpu_test_12
		dw	fpu_test_13, fpu_test_14, fpu_test_15
test_procs_end	equ	$

mess_test	db	"TEST: $"
mess_passed	db	27,"[1;32;40m PASSED$"
mess_skipped	db	27,"[1;36;40m SKIPPED$"
mess_welc	db	27,"[1;32;40m8087 MATH COPROCESSOR",27, "[1;33;40m TESTING UTILITY VER 1.0.0 $"
mess_crlf	db	13, 10 
mess_white	db	27, "[0;37;40m$"
mess_copy	db	"Original tests 1-11 reverse engineered code courtesy MPOVT ES-1842 system tests", 13, 10, "$" 
mess_failed	db	27, "[1;31;50m FAILED WITH CODE $"
mess_nmcolor	db      27, "[1;33;40m$" ; yellow
mess_blue	db	27,"[1;36;40m$" ; blue
mess_green	db	27,"[0;32;40m$"
mess_ni		db	"Coprocessor is not installed",13,10,"$"
mess_digits	db	8	dup	("-")
mess_opt1	db	"INT: $"
mess_par1	db	"02 $"
mess_opt2	db	"FPU: $"
mess_par2	db	"  8087$" 

nam_t_ofs	dw	offset nam_t1, offset nam_t2, offset nam_t3, offset nam_t4
		dw	offset nam_t5, offset nam_t6, offset nam_t7, offset nam_t8
		dw	offset nam_t9, offset nam_t10, offset nam_t11, offset nam_t12
		dw	offset nam_t13, offset nam_t14, offset nam_t15
nam_t1	db	"INIT,CONTROL,REGISTER MEMORY$"
nam_t2  db	"STATUS,EXCEPTION FLAGS$"
nam_t3	db	"ROUNDING,ARITHMETIC,POWER2,LOG2$"
nam_t4	db	"TRANSCENDENTAL PRECISION,ENVIRONMENT$"
nam_t5	db	"INTEGER OPS-1$"
nam_t6	db	"BCD OPS,STATE OPS,TAGS,STACK PTR$"
nam_t7	db	"INTERRUPT FLAGS$"
nam_t8	db	"CONSTANTS AND ARITHMETICS$"
nam_t9	db	"EXCEPTIONS HANDLING$"
nam_t10	db	"INTEGERS OPS-2$"
nam_t11	db	"OPERAND ADDRESSES$"
nam_t12	db	"FFREEP AND FSTPNCE INSTRUCTIONS$"
nam_t13	db	"PARTIAL REMINDER,SCALE$"
nam_t14	db	"SPECIAL VALUES$"
nam_t15	db	"FCOMPP HIDDEN CODES$"

; display number less than 60000
; in decimal
; di points to resulting ascii
; cf if need $ at the end
; dx:ax - word to render
; finally buffer address in dx
i2ascc proc
	pushr	di,bx,cx
	mov	bx, sp
	mov	cx, 10
	cld
	or	dx,dx
	jnz	adodivc
afchkc:	cmp	ax,cx
	jb	alastchc
adodivc:div	cx
	or	dl,30h
	push	dx
	xor	dx,dx
	jmp	afchkc
alastchc:	or	al,30h
	push	ax    ; last char
	sub	bx,sp
	shr	bx,1 ; number of digits
	mov	cx, fwidth ; field width
	sub	cx, bx
	mov	al, ' '
	jcxz	@F
	rep	stosb	
@@:	mov	cx, bx
@@:	pop	ax
	stosb
	loop	@B
	popr	cx,bx,dx
	mov   ax, '$ '
	stosw
	ret
i2ascc endp


init_fpu	proc
	FNINIT
	mov	bx,offset S_SW
	XOR     AX,AX
    	MOV	[BX+2],AX  ; all 0s control in memory
    	NOT     AX
	MOV     [BX],AX  ; all 1s status in memory
    	CLI
    	MOV     CX,15
@@:     LOOP	@B       ; wait
	FNSTCW  [BX+2];S_CW
    	MOV     CL,15
@@:	LOOP    @B
	sti
	MOV     AX,[BX+2];S_CW  ; real CW   11111   111111
    	AND     AX,CW_INTR_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ; 01f3fh	; ___IRRPP=__PUOZDI
	CMP     AX,(CW_PREC_64 SHL 8) OR CW_INTR_MASK ; 033fh 				; ___00011=__111111
    	JZ	@F
ret_with_error:	mov	al, 17
	stc
    	ret
@@:
	FSTSW   [BX];S_SW            ; real SW
    	MOV     CL,15
@@:	LOOP    @B
    	TEST    [BX], SW_ALLI_MASK OR SW_TOS_MASK OR SW_BUSY_MASK ;0b8bfh	; B3TTT210=IxPUOZDI
    	JNZ	ret_with_error  						; 10111000=10111111
    	xor	ax, ax
    	ret
init_fpu	endp

fpu_test_01	proc ; AX, BX are not saved
    	MOV	AX,CS
    	MOV	ES,AX
    	MOV     DS,AX
    	CLI
    	call	init_fpu ; sets BX
    	jnc	@F
ret_no_fpu:
	cbw
	stc
	sti
	ret
@@:
	MOV	[BX+2],CW_INTR_MASK OR CW_RC_MASK OR CW_INF_MASK ;01c3fh     ; xxxIRRPP=MxPUOZDI
    	FLDCW	[BX+2];S_CW            					   ; 00011100=00111111
    	sub	CX,CX
    	MOV     [BX+2],CX         ; 0s
    	FSTCW   [BX+2];S_CW
	wait	; 287+
    	MOV	AX,[BX+2]; S_CW 
	AND     AX,CW_INTR_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ;1f3fh 	; 00011111=00111111
	CMP	AX,CW_INTR_MASK OR CW_RC_MASK OR CW_INF_MASK ;1c3fh  			; 00011100=00111111
	mov	al, 2
    	JNZ    	ret_no_fpu
    	MOV     [BX+2],CX
	STI
    	FINIT
    	XOR     AX,AX
    	MOV     [BX+2],AX
    	FSTCW   [BX+2];S_CW
	wait ; 287+
    	OR	AX,[BX+2];S_CW
	mov	al, 3
	JZ	ret_no_fpu       ; check
    	FINIT
    	FSTCW   [BX+2];S_CW
	wait	; 287+
    	MOV     AX,[BX+2];S_CW         ; xxxIRRPP=MxPUOZDI
    	AND     AX,CW_ALLI_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ; 1fbfh	; 00011111=10111111
    	CMP	AX,c_alli_prec ; CW_ALLI_MASK OR CW_PREC_MASK ;03bfh					; 00000011=10111111
	mov	al, 4
	JNZ     ret_no_fpu
    	FSTENV	[BX+4] ; ENV_87
	inc	ax ; 5
	WAIT
    	TEST    [BX+4].SW,SW_ALLI_MASK OR SW_TOS_MASK OR SW_BUSY_MASK ; 0b8bfh	; B3TTT210=IxPUOZDI
    	JNZ	ret_no_fpu              					; 10111000=10111111
	inc	ax ; 6
    	CMP     [BX+4].TAG,0FFFFh       ; all empty
    	JNZ     ret_no_fpu
	MOV     BX,offset tbyte_FF      ; all 1s
    	MOV	AL,0ffh                 ; flag
check_0_FF_in_regs:
    	MOV	CX,8
@@:    	FLD    	tbyte ptr [BX]          ; storage test
    	LOOP    @B
    	MOV     CL,8
    	MOV	BX,offset stored_tbytes_0
@@:    	FSTP	tbyte ptr [BX]
	ADD     BX,10
	LOOP	@B                      ; stored all
	MOV     DI,offset stored_tbytes_0
	MOV	CL,80
	CLD
	rep	SCASB ; ES:DI
	jnz	ret_reg_error
	OR	AL,AL
	JZ	@F
	MOV	BX,offset tbyte_00      ; all 0s one more loop
	inc	ax
	JMP	check_0_FF_in_regs
ret_reg_error:
	mov	al, 7
	stc
@@:	ret
fpu_test_01	endp

ofs_cod_02	EQU	-$
cod_02	db	II_0B_MASK, 0ffh, DI_1B_MASK, 0ffh, ZI_2B_MASK, 5
	db	UI_4B_MASK, 0ffh, PI_5B_MASK OR OI_3B_MASK, 5
	db	PI_5B_MASK, 4

;;;;;;;;;;;;;;; test2 ;;;;2222222222222222222222222;;;;
fpu_test_02      proc
	FINIT
	mov	si, offset cod_02
	;WAIT
	FSTP	ST	; empty stack
	; MOV	AL,II_0B_MASK ;1 _______I
	;MOV	BL,0ffh ; not used
	CALL	check_87_intr_and_code
	JNC	@F
ret_2_no_fpu:
	sub	si,offset cod_02
	xchg	ax,si
	shr	ax,1
	stc
	ret
@@:
	MOV	AL,byte ptr S_SW+1	; B3TTT210=IxPUOZDI
	AND	AL,SW_C3_BMASK OR SW_C0_BMASK ; 41h	;01000001
	CMP	AL,SW_C3_BMASK OR SW_C0_BMASK ; 41h	;01000001
	JNZ	ret_2_no_fpu
	FINIT
	FLD	dword ptr f4_smallest_denorm;   = 5.877473E-39
	FSTSW	S_SW
	;MOV	AL,DI_1B_MASK ;2 ______D_
	;MOV	BL,0ffh ; no code
	CALL	check_87_intr_and_code
	JC	ret_2_no_fpu
	FINIT
	FLDPI
	FLDZ		; pi 0 ---
	FDIVR	ST,ST(1); pi/0
	;MOV	BL,5    ; c:0101
	;MOV	AL,ZI_2B_MASK ;4 _____Z__
	CALL	check_87_intr_and_code
	JC	ret_2_no_fpu
	FINIT
	FLD	f4_smallest;   = 9.403954E-38
	FSUB    f4_near_smallest; =9.403946E-38
	FST	f4_res0
	FLD	f4_res0
	;MOV	BL,0ffh ; -------
	;MOV	AL,UI_4B_MASK ;10h ___U____
	CALL	check_87_intr_and_code
	JC	ret_2_no_fpu
	FINIT
	FLD	f4_biggest ;  = 3.4028235E38
	FADD    f4_near_biggest;   = 1.7014118E38
	FST	f4_res0 
	FLD	f4_res0
	;MOV	BL,05h	; C: 0101
	;MOV	AL,PI_5B_MASK OR OI_3B_MASK ;28h  ; __P_O___
	CALL	check_87_intr_and_code
	JC	ret_2_no_fpu
	FINIT
	FLD1
	FADD	f4_biggest ;   = 3.4028235E38
	;MOV	BL,4	; c: 0100
	;MOV	AL,PI_5B_MASK ;20h ; __P_____
	CALL	check_87_intr_and_code
	jc	ret_2_no_fpu
@@:	xor	ax, ax
	ret
fpu_test_02	endp

fpu_test_03	proc
	FINIT
	FLD1
	FST	ST(1)
	FIDIV   f2_int_2	; 2
	MOV	bx,offset S_CW
	FST	ST(2)	; 1/2 1 1/2
	FRNDINT	; 1/2 1 0
	FTST
	FSTSW	[bx-2];S_SW
	MOV	AH,byte ptr [bx-1];S_SW+1 ; B3TTT210
	SAHF                       ; 
	JNZ	@F
	JC	@F
	FXCH	ST(2) 	; 0 1 1/2
	MOV     [bx],CW_ALLI_MASK OR ((CW_PREC_64 OR CW_RC_TOUP)SHL 8) 	; S_CW 0bbfh	; xxxIRRPP=MxPUOZDI
	FLDCW   [bx]									; 00001011 10111111
	FRNDINT
	FCOMP
	FSTSW	[bx-2];S_SW
	MOV     AH,byte ptr [bx-1];S_SW+1
	SAHF
	JNZ	@F
	JNC	fpu_ok_flags1
@@:	MOV	AL,1
	stc
	ret
fpu_ok_flags1:
	FINIT
	FILD	f2_int_2	; 2
	FLD     f8_0_4002	; = 0.4002  
	FYL2X
	FLD1
	FCHS     	; log -1
	FLD	ST(1)	; log -1 log
	MOV     [bx],CW_ALLI_MASK+((CW_PREC_64+CW_RC_TODOWN)SHL 8) ; 07bfh S_CW	; xxxIRRPP=MxPUOZDI
	FLDCW	[bx];S_CW            						; 00000111 10111111
	FRNDINT
	MOV	[bx],CW_ALLI_MASK+((CW_PREC_64+CW_RC_TONEAR)SHL 8) ; 03bfh S_CW	; 00000011 10111111
	FLDCW   [bx];S_CW
	FXCH    ST(2)	; int(log) -1 log
	FSUB    ST(0) ,ST(2)  ; int(log) -1 diff(log)
	FSCALE 	; int(log) -1 2^x
	F2XM1   ; int(log) -1 2^2^x
	FSUBRP	st(1),st(0) ; int(log) diff
	FMUL	ST(0),st(0) 	; int)log) diff^2
	FSCALE	; int(log) 2^2^2^x
	FSTP    stored_tbytes_0
	FLD	stored_tbytes_0
	FSTP	stored_double_0
	FLD     stored_double_0
	FLD     f8_0_4002	; = 0.4002  
	FMUL	ST(0),st(0)
	FSTP	stored_tbytes_1
	FLD	stored_tbytes_1
	FSTP	stored_double_0
	FLD	stored_double_0
	FCOM
	FSTSW	[bx-2];S_SW
	MOV     AH,byte ptr [bx-1];S_SW+1
	SAHF
	JNZ	fpu_flags_err
	JNC	@F;fpu_flags_ok_2
fpu_flags_err:
	MOV	AL,2
	stc
@@:	ret
fpu_test_03	endp

fpu_test_04	proc
	FINIT
	FLD1
	FST	ST(1)
	FST	ST(2) ; 1 1 1
	FADDP   st(1), st(0)
	mov	dl,1
	FADDP   st(1), st(0)
	mov	bx,offset S_SW
	FCHS    ; -3
	MOV	CX,12
loop_12_times:
	FLDPI
	FSCALE ; -scale pi^-3
	FLD	ST(0) ; -scale pi^-3 pi^-3
	FPTAN  ; -scale pi^-3 y x
	FLD	ST(1)  ; -scale pi^-3 y x y
	FLD	ST(1)  ; -scale pi^-3 y x y x
	FPATAN  ; -scale pi^-3 y x atan
	FSUB	ST(0),ST(3) ; -scale pi^-3 y x delta
	FABS
	FLD	f8_0_001 ; -scale pi^-3 y x delta 0.001  
	FCOM
	FSTSW	[bx];S_SW
	WAIT
	MOV	AX,[bx];S_SW
	SAHF
	JZ	fpu_flags_err_3
	JNC	@F
fpu_flags_err_3:
	xchg	ax,dx;MOV	AL,1
	stc
	ret
@@:	FSTP	ST(0)
	FSTP	ST(0)
	FSTP	ST(0)
	FSTP	ST(0)
	FSTP	ST(0)   ; -SCALE 
	FLD1
	FCHS
	FADDP 	st(1),st(0) ; -SCALE+1
	loop	loop_12_times
	FINIT
	FLD	f8_0_001 ; = 0.001
	inc	dx
	FLD1
	FCHS	; 0.001 -1
	MOV	Cl,80
big_loop_scales:
	FLD	ST(1) ; 0.001 -1 0.001
	FSCALE 		; 0.001 -1 0.001^x
	FLD	ST(0)   ; 0.001 -1 0.001^x 0.001^x
	FXTRACT		; 0.001 -1 0.001^x exp mant
	FLD1
	FSUBP	st(1),st(0) ; 0.001 -1 0.001^x exp mant-1
	FLD1
	FXCH            ; 0.001 -1 0.001^x exp 1 mant-1
	FYL2XP1		; 0.001 -1 0.001^x exp 2^mant
	FADDP	st(1),st(0)	; 0.001 -1 0.001^x exp+2^mant
	FXCH
	FLD1		; 0.001 -1 exp+2^mant 0.001^x 1	
	FXCH		; 0.001 -1 exp+2^mant 1 0.001^x
	FYL2X		; 0.001 -1 exp+2^mant log2(0.001^x)
	FLD	ST(0)	; 0.001 -1 exp+2^mant log2(0.001^x) log2(0.001^x)
	FSUB	ST(0),ST(2)	; 0.001 -1 exp+2^mant log2(0.001^x) log2(0.001^x)-exp+2^mant 
	FABS
	FLD	f8_1em6 ;  = 1.0E-6  
	FCOM	; 0.001 -1 exp+2^mant log2(0.001^x) |log2(0.001^x)-exp+2^mant| 1e-6
	FSTSW	[bx];S_SW
	WAIT
	MOV	AX,[bx];S_SW
	SAHF
	JZ	fpu_arth_err_check
	JNC	@F
	JMP     fpu_flags_err_3;fpu_arth_err_2
fpu_arth_err_check:
	adc	dx,0
	JC	fpu_flags_err_3;fpu_arth_err_1
@@:	FSTP	ST(0)
	FSTP	ST(0)
	FSTP	ST(0)
	FSTP	ST(0)	; 0.001 -1
	FLD1
	FCHS
	FADDP   st(1),st(0)	; 0.001 -1+1
	loop	big_loop_scales
	FINIT
	FILD	i2_141 ; = 8Dh
	mov	di,offset fpu_int_store_1
	FIST    dword ptr [di];fpu_int_store_1
	inc	dx
	inc	dx
	wait
	MOV	AX,[di];fpu_int_store_1
	XOR	AX,i2_141 ; = 8Dh
	JnZ	err04;fp_int_store_passed
	add	bx,4
	FSTENV	[bx];ENV_87
	inc	dx
	WAIT
	CMP     [bx].TAG, 3fffh ;ENV_87; tag word
	JnZ	err04;fpu_fstenv_status_ok
    	FISTP	word ptr [di];fpu_int_store_1
	inc	dx
	WAIT
	MOV	AX,[di];fpu_int_store_1
	XOR	AX,i2_141	; = 8Dh
	JnZ	err04;fpu_fstenv_status_ok_2
	FSTENV	[bx];ENV_87
	inc	dx
	WAIT
	MOV	BX, [bx].TAG ; ENV_87 tag word
	XOR	BX,0ffffh
	JZ	@F;fpu_fstenv_status_ok_3
err04:	xchg	ax,dx;MOV	AL,7
	stc
@@:	ret
fpu_test_04	endp

fpu_test_05	proc
	FINIT
	MOV	BX, offset ddw_6
	FILD    dword ptr [BX]		; [0]
	mov	di, offset S_SW+1
	FIMUL   dword ptr [BX + 12]	; [0]*[12]
	FIDIV   dword ptr [BX + 8]	; [0]*[12]/[8]
	FILD	dword ptr [BX + 4]	; [0]*[12]/[8] [4]
	FIMUL	dword ptr [BX + 12]	; [0]*[12]/[8] [4]*[12]
	FISTP	dword ptr [BX + 16]	; [0]*[12]/[8] [4]*[12]->[16]
	FILD	dword ptr [BX + 8]	; [0]*[12]/[8] [8]
	FIDIVR	dword ptr [BX + 16]	; [0]*[12]/[8] [16]/[8]
	FISTP	dword ptr [BX + 16]	; [0]*[12]/[8] [16]/[8]->[16]      
	FISUB	dword ptr [BX + 16]	; [0]*[12]/[8]-[16]
	FISTP	dword ptr [BX + 16]	;
	FILD	dword ptr [BX + 4]	; [4]
	FCHS
	FIADD	dword ptr [BX]		; -[4]+[0]
	FIMUL	dword ptr [BX + 12]     ; (-[4]+[0])*[12]
	FIDIV	dword ptr [BX + 8]	; (-[4]+[0])*[12]/[8]
	FIST    dword ptr [BX + 20]	; (-[4]+[0])*[12]/[8]
	FICOMP  dword ptr [BX + 16]	; (-[4]+[0])*[12]/[8]
	FSTSW	[di-1];S_SW
	WAIT                            ; B3TTT210
	AND	byte ptr [di],SW_C0_BMASK OR SW_C3_BMASK ; S_SW+1 041h	; 01000001
	XOR	byte ptr [di],SW_C3_BMASK 	; S_SW+1 040h		;X01000000 
	JZ      @F
	MOV	AL,1
	stc
@@:	ret ; NC
fpu_test_05	endp

fpu_test_06	proc
	FINIT
	MOV	DI,offset num_bcd
	FBLD	tbyte ptr [di];num_bcd
	mov	bx, offset ENV_87
	mov	al, 1
	MOV	CX,10
	MOV	SI,offset store_bcd0
	CLD
	FBSTP   tbyte ptr [si];store_bcd0
	WAIT
	REP	CMPSB
	JZ	@F
err06:	stc
	ret
@@:	FINIT
	FSAVE	[bx];ENV_87
	MOV	DX,8
	WAIT
	MOV	[bx].TAG, CX ; ENV_87,0
	MOV	DI,offset stored_tbytes_0
@@:	MOV	SI,offset stored_tbytes_1
	MOV	Cl,10
	rep	MOVSB
	DEC	DX
	JNZ	@B
	FRSTOR	[bx];ENV_87
	WAIT
	MOV	Dl,8
	inc	ax
@@:	MOV	DI,offset stored_tbytes_1
	MOV	SI,offset store_bcd0
	MOV	Cl,10
	FSTP	tbyte ptr [si];store_bcd0
	WAIT
	rep	CMPSB
	JnZ	err06
	DEC	DX
	JNZ	@B
	FINIT
	MOV	Cl,8
	inc	ax
@@:	FBLD	tbyte ptr num_bcd
	LOOP	@B
	FSTENV	[bx];ENV_87
	WAIT
	CMP	[bx].TAG,CX ;ENV_87,0
	JnZ	err06;fpu_bcd_ok_1        
	FFREE	ST(7)
	inc	ax
	FFREE	ST(5)
	FFREE	ST(3)
	FFREE	ST(1)
	FSTENV  [bx];ENV_87
	WAIT
	CMP	[bx].TAG,0cccch ;ENV_87
	JnZ	err06;fpu_tag_ok
	FINIT
	FINCSTP
	inc	ax
	FINCSTP
	dec	bx
	FINCSTP
	dec	bx
	FINCSTP
	dec	bx
	FSTSW	[bx-1];S_SW
	WAIT	; B3TTT210
	AND	byte ptr [bx],SW_TOS_BMASK; S_SW+1 038h	; 00111000 stack ptr
	CMP	byte ptr [bx],(4 SHL 3) ;S_SW+1 020h	; 00100000 "4"  
	JNZ	err06_1 ;fpu_int_ops_err
	FDECSTP
	FSTSW	[bx-1];S_SW
	inc	ax
	WAIT
	AND	byte ptr [bx],SW_TOS_BMASK; S_SW+1 38h	; B3TTT210
	CMP	byte ptr [bx],(3 SHL 3) ;S_SW+1 18h	; 00111000 stack ptr
	JZ	noerr06; fpu_int_ops_ok				; 00011000 "3"
err06_1:stc
noerr06:ret
fpu_test_06	endp

fpu_test_07	proc
	FINIT
	mov	bx,offset S_CW
	FSTCW	[bx];S_CW
	WAIT                    ; xxxIRRPP=MxPUOZDI
	AND	word ptr[bx],CW_ALLI_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ;01fbfh	; 00011111 10111111
	CMP	word ptr[bx],CW_ALLI_MASK OR CW_PREC_MASK ;003bfh				; 00000011 10111111
	JNZ	fpu_intr_mask_err
	FENI
	FSTCW	[bx];S_CW
	WAIT                  	; xxxIRRPP=MxPUOZDI
	AND	word ptr[bx],CW_ALLI_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ;01fbfh	; 00011111 10111111
	CMP     word ptr[bx],CW_INTR_MASK OR CW_PREC_MASK ;0033fh				; 00000011 00111111
	JNZ     fpu_intr_mask_err
	FDISI
	FSTCW	[bx];S_CW
	WAIT                   	; xxxIRRPP=MxPUOZDI     TODO
	AND	word ptr[bx],CW_ALLI_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ;01fbfh	; 00011111 00111111
	CMP	word ptr[bx],CW_ALLI_MASK OR CW_PREC_MASK ;003bfh				; 00000011 10111111
	JZ	fpu_intr_mask_ok
fpu_intr_mask_err:
	MOV	AL,1
	stc
fpu_intr_mask_ok:
	ret
fpu_test_07	endp

fpu_test_08	proc
	FINIT
	FLDLN2
	FLDL2E
	FMULP	st(1),st(0); ln2*log2e
	mov	bx,offset S_SW
	FLD1
	FSUBP	st(1),st(0); ln2*log2e-1
	FTST
	FSTSW	[bx];S_SW
	WAIT
	MOV	AL,byte ptr [bx+1];S_SW+1		; B3TTT210
	AND	AL,SW_C0_BMASK OR SW_C3_BMASK ;041h	; 01000001
	CMP	AL,SW_C3_BMASK ;040h			; 01000000
	JNZ	fpu_arth_err_18
	FFREE	ST(0)
	FLDLG2
	FLDL2T
	FMULP	st(1),st(0); lg2*log2_10
	FLD1
	FSUBP	st(1),st(0); lg2*log2_10-1
	FTST
	FSTSW	[bx];S_SW
	WAIT
	MOV	AL,BYTE PTR [bx+1];S_SW+1		; B3TTT210
	AND	AL,SW_C0_BMASK OR SW_C3_BMASK ;041h	; 01000001
	CMP	AL,SW_C3_BMASK ;040h			; 01000000
	JZ	@F
fpu_arth_err_18:
	MOV	AL,1
	stc
@@:	ret
fpu_test_08	endp

wt_cyc	proc
	sub	cx, cx
@@:	LOOP	@B
	sub	cx,cx
@@:	LOOP	@B
	ret
wt_cyc	endp

COMMENT !
fpu_test_09	proc
	FINIT
	FSTENV	ENV_87
	WAIT                    				; xxxIRRPP=MxPUOZDI
	MOV	ENV_87.CW,(CW_PREC_64 SHL 8) OR PI_5B_MASK ;0320h ; 00000011 00100000
	MOV     S_CW,(CW_PREC_64 SHL 8) OR PI_5B_MASK ; 0320h	; -
	FLDENV	ENV_87
	MOV	BX, offset ld_int_10
	MOV     irq13_SW_code,DI_1B_MASK;2  ; D-denormal bit
	MOV     irq13_flag,0
	CALL    compute_seg_ofs_87_env
	FINIT
	FLDCW	S_CW
ld_int_10:
	FLD	dword ptr i2_int_16
;	MOV	CX,0
;delay_0010:	LOOP	delay_0010
;	MOV	CX,0
;delay_0011:	LOOP	delay_0011
	call	wt_cyc
	CALL    check_instruction_addr
	JNC	fpu_ok_1000
	MOV	AL,1
	stc
	ret
fpu_ok_1000:
	TEST	irq13_flag,080h
	JNZ	fpu_ok_1001
	MOV	AL,01
	stc
	ret
fpu_ok_1001:
	MOV	irq13_SW_code,ZI_2B_MASK;4h ; ; xxxIRRPP=MxPUOZDI
	MOV	irq13_flag,0     ; zero div
	MOV	BX,offset fdivr_instr
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW   S_CW
	FLDPI
	FLDZ
fdivr_instr:
    	FDIVR	ST(0),ST(1)
	call	wt_cyc
    	WAIT
	CALL	check_instruction_addr
	JNC	fpu_ok_1002
fpu_err_1002:
	MOV	AL,1
	stc
	ret
fpu_ok_1002:
	TEST	irq13_flag,080h
	JZ	fpu_err_1002
	MOV	irq13_flag,0
	MOV	irq13_SW_code,UI_4B_MASK;010h ; xxxIRRPP=MxPUOZDI
	MOV	BX, offset fst_inst_addr    ; U - underflow
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW	S_CW
	FLD	dword ptr f4_smallest
	FSUB	dword ptr f4_near_smallest
fst_inst_addr:
	FST	f4_res0
	call	wt_cyc
	WAIT
	CALL	check_instruction_addr
	JNC	fpu_ok_1003
fpu_err_1003:
	MOV	AL,1
	stc
	ret
fpu_ok_1003:
	TEST	irq13_flag,080h
	JZ	fpu_err_1003
	MOV	irq13_flag,0
	MOV	irq13_SW_code,OI_3B_MASK;8 ; xxxIRRPP=MxPUOZDI          TODO
	MOV	BX, offset fp_fst_double ; O - overflow
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW	S_CW
	FLD	f4_biggest
	FADD 	f4_near_biggest
fp_fst_double:
	FST	f4_res0
	call	wt_cyc
	WAIT
	CALL	check_instruction_addr
	JNC	fpu_ok_1004
fpu_err_1004:
	MOV	AL,1
	stc
	ret

fpu_ok_1004:
	TEST	irq13_flag, 080h ; xxxIRRPP=MxPUOZDI
	JZ	fpu_err_1004
	MOV	irq13_flag,0
	MOV	irq13_SW_code,II_0B_MASK;1  ; 1 - invalid
	MOV	BX, offset fp_fstp_st0
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW	S_CW
fp_fstp_st0:
	FSTP	ST(0)
	call	wt_cyc
	WAIT
	CALL	check_instruction_addr
	JNC	fpu_ok_1005
fpu_err_1005:
	MOV	AL,1
	stc
	ret
fpu_ok_1005:
	TEST	irq13_flag,080h
	JZ	fpu_err_1005    ; xxxIRRPP=MxPUOZDI
	MOV	S_CW,(CW_PREC_64 SHL 8) OR AI_7B_MASK ;0380h	; 00000011 10000000
	MOV	irq13_SW_code ,PI_5B_MASK;020h 	; MxPUOZDI
	MOV	irq13_flag ,0		; 00100000
	MOV	BX,offset instr_sqrt
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW	S_CW
	FLD1
	FLD1
	FADDP	st(1),st(0)
instr_sqrt:
	FSQRT
	call	wt_cyc
	WAIT
	CALL	check_instruction_addr
	JC	fpu_err_1006
	MOV	AX,ENV_87.SW
	AND	AL,SW_INTR_MASK;03fh ; MxPUOZDI
	CMP	irq13_SW_code ,AL
	JZ	fpu_ok_1006
fpu_err_1006:
	MOV	AL,1
	stc
fpu_ok_1006:
	ret
fpu_test_09	endp
!
;COMMENT !

irq_prcs	dw	pld_int_10 ; 1st
	db	DI_1B_MASK;2       ; D-denormal bit
	dw	pld_int_10
	dw	pfdivr_instr ; 2nd
	db	ZI_2B_MASK;4	; zero div
	dw	lbl_pr2
	dw	pfst_inst_addr ; 3rd
	db	UI_4B_MASK;10h; xxxIRRPP=MxPUOZDI  U - underflow
	dw	lbl_pr3
	dw	pfp_fst_double ; 4th
	db	OI_3B_MASK;8 ; xxxIRRPP=MxPUOZDI  O - overflow
	dw      lbl_pr4
	dw      pfp_fstp_st0  ; 5th
	db	II_0B_MASK;1 ; I - invalid
	dw	pfp_fstp_st0
eo_irq_prcs	label	byte

noirq_prcs	dw	pinstr_sqrt  ; 6th
lab_cr0	db	PI_5B_MASK; 20H
	dw	lbl_pr5
eo_noirq_prcs	label	byte

pld_int_10:
	FLD	dword ptr i2_int_16
	MOV	CX,0
@@:	LOOP	@B
	MOV	CX,0
@@:	LOOP	@B
	ret
lbl_pr2:
	FLDPI
	FLDZ
pfdivr_instr:
    	FDIVR	ST(0),ST(1)
    	WAIT
	ret
lbl_pr3:
	FLD	dword ptr f4_smallest
	FSUB	dword ptr f4_near_smallest
pfst_inst_addr:
	FST	f4_res0
	WAIT
	ret
lbl_pr4:
	FLD	f4_biggest
	FADD 	f4_near_biggest
pfp_fst_double:
	FST	f4_res0
	WAIT
	ret
pfp_fstp_st0:
	FSTP	ST(0)
	WAIT
	ret
lbl_pr5:
	FLD1
	FLD1
 	FADDP	st(1),st(0)
pinstr_sqrt:
	FSQRT
	ret

fpu_test_99	proc
	FINIT
	mov	di, offset S_CW
	FSTENV	[di+2];ENV_87
	WAIT                    ; xxxIRRPP=MxPUOZDI
	MOV	ax, (CW_PREC_64 SHL 8) + PI_5B_MASK ;0320h ; 00000011 00100000
	MOV	[di+2].CW,AX ; ENV_87
	MOV     [di],AX ; S_CW (CW_PREC_64 SHL 8) OR PI_5B_MASK ;0320h	; -
	FLDENV	[di+2];ENV_87
	cld

	mov	si, offset irq_prcs
	mov	dx, si
irq_prcs_loop:
	lodsw
	xchg	bx,ax ;	MOV	BX,[si]
	lodsb
	cbw
	MOV     irq13_vars,ax
	CALL    compute_seg_ofs_87_env
	FINIT
	FLDCW	[di];S_CW
	lodsw
	call	ax
	call	wt_cyc
	CALL    check_instruction_addr
	JNC	@F
	inc	si ;	AL,1
	jmp	short err_99
@@:	TEST	irq13_flag,080h
	JNZ	@F
	inc	si; 	MOV	AL,2
	inc	si
	jmp	short err_99
@@:	cmp	si, offset eo_irq_prcs
	jnae	irq_prcs_loop

	MOV	word ptr[di],(CW_PREC_64 SHL 8) + CW_SUMM_INTR ; S_CW 0380h	; 00000011 10000000
	mov	si, offset noirq_prcs
	mov	dx, si
noirq_prcs_loop:
	lodsw
	xchg	bx,ax ; deed
	lodsb
	cbw
	mov	irq13_vars,ax
	CALL	compute_seg_ofs_87_env
	FINIT
	FLDCW	[di];S_CW
	lodsw
	call	ax
	CALL	check_instruction_addr
	JNC	@F
	add	si, 3 ;MOV	AL,1
	jmp	short err_99
@@:	MOV	AX,[di+2].SW  ;ENV_87
	AND	AL,CW_INTR_MASK; 03fh ; MxPUOZDI
	CMP	irq13_SW_code,AL
	JZ	@F
	add	si, 4 ;MOV	AL,2
	jmp	short err_99
@@:	cmp	si, offset eo_noirq_prcs
	jnae	noirq_prcs_loop

	xor	ax,ax
	ret ; NC
err_99:	sub	si,dx
	xchg	ax,si
	stc
	ret
fpu_test_99	endp
;!

fpu_test_10	proc
	FINIT
	FLD1
	mov	bx, offset fpu_int_store_1
	FLD1
	MOV	CX,0fffeh ; -2
@@:	FADD    ST(0) ,ST(1)
	LOOP	@B
	FIST    dword ptr [bx];fpu_int_store_1
	WAIT
	CMP	word ptr [bx],-1;fpu_int_store_1
	JZ	@F
	MOV	AL,1
	stc
@@:	ret
fpu_test_10	endp

fpu_test_11	proc
	PUSH	DS
	sub	BX,bx
	MOV	DS,BX
	FILD	word ptr [BX]
	mov	ax,bx
	mov	di,offset ENV_87
	POP	DS
	FSTENV	[di];ENV_87
	;MOV	AX,0
	WAIT
	CMP	[di].DP,AX ;  source operand offset
	JNZ	@F
	CMP	[di].DP_H,AX ; source operand segment
	JNZ	@F
	PUSH	DS
	dec	BX
	MOV	DS,BX
	MOV	BX,0fh
	FILD	word ptr [BX]
	POP	DS
	FSTENV	[di];ENV_87
	WAIT
	dec	AX;,0ffffh
	CMP	[di].DP,AX ; operand offset
	JNZ	@F
	MOV	AX,0f000h
	CMP	[di].DP_H,AX ; operand segment
	JZ	fpu_operand_no_error
;fpu_operand_address_error:
@@:	MOV	AL,1
	stc
fpu_operand_no_error:
	ret
fpu_test_11	endp

fpu_test_12	proc
	finit
	fldz
	fld1
	fldpi
	mov	bx,offset S_SW
	fldl2e	; 0 1 pi l2e
	wait
	db	0DFh, 0C2h ; undocumented ffreep(2)
	fstenv	[bx+4];env_87     ; 0 - pi
	wait
	cmp	[bx+4].tag, 0111001111111111b ; env_87
	je	@F
ffrp:	mov	al, 1
	stc
	ret
@@:	mov	al, byte ptr [bx+4].sw+1 ; env_87
	and	al, SW_TOS_BMASK ; 38h
	cmp	al, 101000b
	jne	ffrp
	finit
	db	0D9h, 0D8h ; fstpnce st(0)
	fstsw	[bx];S_SW
	wait
	mov	ax, [bx];S_SW ;
	and	al, SW_ALLI_MASK; 0BFh
	; need to check stack??
	jz	@F
fstpnce_err:	mov	al, 2
	stc
	ret
@@:	and	ah, SW_TOS_BMASK ;38h
	cmp	ah, 001000b
	jne	fstpnce_err
	ret
fpu_test_12	endp

fpu_test_13	proc
	FNINIT
	mov	S_CW, ((CW_INF_AFFINE OR CW_PREC_53)SHL 8) OR 40H OR CW_INTR_MASK ;0127Fh ; xxxIRRPP xMMMMMMM
	FLDCW	S_CW
	MOV	CX,0fff6h
	mov	i2_ten, 1
	mov	di, offset table_rem_1
prem_loop1:
	MOV	fpu_int_store_1,CX
	CALL	compute_rem
	scasb
	jnz	rem_error	
	INC	CX
	CMP	CX,10
	JNG	prem_loop1

	MOV	CX,0fff6h
	mov	i2_ten, 10
	mov	di, offset table_rem_2
prem_loop2:
	MOV	fpu_int_store_1,CX
	CALL	compute_rem
	scasb
	jnz	rem_error	
	INC	CX
	CMP	CX,10
	JNG	prem_loop2
scales:
	XOR	CX,CX
	mov	di, offset table_scale
@@:
	CALL	compute_scale
	MOV	AX, fpu_int_store_1	;; compute result
	scasb
	jnz	scale_error
	INC	CX
	CMP	CX,0fh		;; 15 times
	JLE	@B
	FLDZ
	FSTP	scale_seed	;; seed to zero
	CALL	compute_scale	;undefined compute_run()
	MOV	AX, fpu_int_store_1	;; compute result
	scasb
	jnz	scale_error
	ret	; NC
rem_error:	mov	al, 1
	stc
	ret
scale_error:	mov	al,2
	stc
	ret
fpu_test_13	endp

compute_scale	proc
	FLD	scale_seed  ;; init -2.5
	FLD1	; seed 1
	FSCALE	; scale 1 in deg
	FIMUL	i2_ten	  ;; 10
	FISTP	fpu_int_store_1 ;; as integer
	FADD	scale_coef  ; add 0.33
	FSTP	scale_seed	 ;; store degree
	RET
compute_scale	endp

scale_seed	dd	-2.5
scale_coef	dd	0.33

table_rem_1	db	2,1,0,7,6, 5,4,3,2,1, 0,1,2,3,4, 5,6,7,0,1, 2
table_rem_2	db	1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 1
table_scale	db	2,2,5,5,5, 10,10,10,10,10, 10,20,20,20,40, 40,10
table_nums_Cc	db	1,3,5,7,4, 4,0,0,0ch,0ch, 8,0ah,3,6,6, 2,2,0eh,0eh ; len = SPECIAL_NUMS

SPECIAL_NUMS	EQU	(13+6)
	even
NUMB80	LABEL	TBYTE
f80pnan	db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,0ffh ,0ffh,07fh
f80nnan	db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,0ffh ,0ffh,0ffh
f80pinf	db	000h,000h,000h,000h, 000h,000h,000h,080h ,0ffh,07fh
f80ninf	db	000h,000h,000h,000h, 000h,000h,000h,080h ,0ffh,0ffh
f80pnrm	db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,0ffh ,0feh,07fh
f80pnr2	db	000h,000h,000h,000h, 000h,000h,000h,080h ,001h,000h
f80punr db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,07fh ,0feh,07fh
f80pun2	db	000h,000h,000h,000h, 044h,000h,000h,000h ,001h,000h
f80pdnr db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,07fh ,000h,000h
f80pdn2 db	001h,000h,000h,000h, 000h,000h,000h,000h ,000h,000h
f80pzer db	000h,000h,000h,000h, 000h,000h,000h,000h ,000h,000h
f80nzer db	000h,000h,000h,000h, 000h,000h,000h,000h ,000h,080h
f80indf	db	000h,000h,000h,000h, 000h,000h,000h,0c0h ,0ffh,0ffh
f80nnrm	db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,0ffh ,0feh,0ffh
f80nnr2	db	000h,000h,000h,000h, 000h,000h,000h,080h ,001h,080h
f80nunr db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,07fh ,0feh,0ffh
f80nun2	db	000h,000h,000h,000h, 000h,000h,000h,000h ,001h,080h
f80ndnr db	0ffh,0ffh,0ffh,0ffh, 0ffh,0ffh,0ffh,07fh ,000h,080h
f80ndn2 db	001h,000h,000h,000h, 000h,000h,000h,000h ,000h,080h

fpu_test_14	proc
	finit
	mov	dx,SPECIAL_NUMS
	mov	di,offset NUMB80
	mov	si,offset table_nums_Cc
fplp0:	fld	tbyte ptr [di]
	add	di,10
	lodsb	; al is CC code
	call	check_87_code
	jc	imc_err
	fstp	st
	dec	dx
	jnz	fplp0
	ret	; NC
imc_err:
	mov	al, SPECIAL_NUMS+1
	sub	al,dl
	stc
	ret
fpu_test_14	endp

compute_rem	proc
	FILD	i2_ten ; 10.0
	mov	fpu_int_store_1,cx
	push	cx
	FILD	fpu_int_store_1	;; 1 counter
	FXAM	;; exam counter
	FABS	;; absolute value
	FPREM	;; value by 1
	FSTSW	S_SW   ;; store status to counter
	FSTP	ST(0)
	FSTP	ST(0)
	MOV	AX,S_SW
	ror	ah,1 ; 0B3TTT21
	shr	ax,1 ; _0B3TTT2|1
	mov	cl,4 
	shr	ah,cl ; _____0B3|1
	shr	ax,1  ; ______0B|31
	shr	ah,1  ; _______0|31______
	mov	cl,6
	shr	ax,cl ; _____031
	pop	cx
	RET
compute_rem	endp

vcompp	macro	num
	db	09bh, 0deh, 0d8h+num
	endm

fpu_test_15	proc
	mov	si, offset c_1st1
	mov	bx, offset c_in1
	mov	di, offset cmpp_code1
	mov	cx, 8
	call	tst_vcmpp
	jcxz	@F
pp_er_ex:	stc	
pp_er_e1:	xchg	ax, cx
	ret
@@:     mov	si, offset c_1st2
	mov	bx, offset c_in2
;	mov	di, offset cmpp_code2
	mov	cx, 8
	call	tst_vcmpp
	jcxz	@F
	jmp	pp_er_ex
@@:	mov	si, offset c_1st3
	mov	bx, offset c_in1
;	mov	di, offset cmpp_code3
	mov	cx, 8
	call	tst_vcmpp
	jcxz	pp_er_e1 ; no need in clc
	jmp	pp_er_ex
fpu_test_15	endp

tst_vcmpp	proc
	finit
	call	si ; _st_
	call	bx ; _in_
	fcompp
	call	c_tst
	vcompp	2
	call	c_tst
	vcompp	3
	call	c_tst
	vcompp	4
	call	c_tst
	vcompp	5
	call	c_tst
	vcompp	6
	call	c_tst
	vcompp	7
	call	c_tst
	vcompp	0
	call	c_tst
	nop
	ret
tst_vcmpp	endp
	
c_tst	proc
	fstsw	S_SW
	wait
	mov	ax,S_SW
	mov	al,ah
	and	al, 7 ; C2C1C0
	sahf
	jnz	@F
	or	al,8
@@:	scasb
	jnz	@F
	dec	cx
@@:	call	bx
	ret
c_tst	endp	
	
c_in2	proc
	fld1
	fldl2t
	ret
c_in2	endp

c_in1	proc
	fldlg2
	fld1
	ret
c_in1	endp
               
c_1st1	proc
	fldl2t
	fld1
c_1st3:	fldlg2
	fldl2t
	fld1 ; l(2)10 1 log2 l(2)10 1 log2 [1]
	ret
c_1st1	endp
	
c_1st2	proc
	fldlg2
	fldl2t
	fld1
	fldlg2
	fldl2t ; lg2 l(2)10 1 lg2 l2(10) 1 l2(10)
	cld
	ret
c_1st2	endp

cmpp_code1	db	0, 8, 1, 0, 8, 1, 13, 8
cmpp_code2	db	0, 8, 0, 0, 8, 0, 13, 8
cmpp_code3	db	0, 8, 1, 0, 13, 13, 13, 8


;*************************************************************
;* cs:bx converted to 87 format and stored in fp_inst_addr  ..
;* cs:bx is the pointer to only FP instruction
;*************************************************************
compute_seg_ofs_87_env	proc
	MOV	AX,CS
	MOV     fpu_int_store_1,AX
	FILD    dword ptr fpu_int_store_1 ; dword CS - unsigned
	FIMUL   word ptr i2_int_16 ; CS*10h
	MOV     fpu_int_store_1,BX
	FIADD	dword ptr fpu_int_store_1 ; CS*10h+BX
	FLD1    ; because of wait 87
	FADDP	st(1),st(0)
	FISTP   dword ptr fp_instr_addr ; cs*10h+bx+1
	WAIT
	MOV     AX,word ptr fp_instr_addr+2
	MOV     CL,12
	SHL	AX,CL
	MOV	word ptr fp_instr_addr+2,AX ; F000:0000 ->  F000
	RET
compute_seg_ofs_87_env	endp

;*************************************************************
;* if fp_instr_addr seg:ofs equals to ENV CS:IP - clear CF
;* otherwise - set CF
;* here the previously computed instruction address is compared
;* to FPUn stored instruction address
;*************************************************************
check_instruction_addr	proc
	FSTENV	ENV_87
	wait
	MOV	AX,word ptr fp_instr_addr
	CMP	ENV_87.IP,AX ; IP offset
	JNZ	this_fpu_error
	MOV	AX,word ptr fp_instr_addr+2
	AND	ENV_87.IP_OP, 0f000h; seg CS
	CMP	ENV_87.IP_OP,AX
	JZ	this_fpu_ok
this_fpu_error:
	STC
this_fpu_ok:	; alrteady NC
	RET
check_instruction_addr	endp

;*************************************************************
;* AL: 87 interrupt mask, BL - C3C2C1C0 status code           *
;* if 7th bit set in BL - BL is not used                      *
;* 8087 status word was saved to S_SW
;* CF set on error
;* changed to SI points to AL and BL codes                                            
;*************************************************************
check_87_intr_and_code	proc
	FXAM
	lodsw
	FSTSW	S_SW
	mov	bl, ah
	FCLEX
	TEST	byte ptr S_SW,AL
	JZ	err_intr_flag
	OR	BL,BL
	JS	not_use_C3C2C1C0
	MOV	AH,byte ptr S_SW+1
	call	form_c3210
	CMP	AL,BL
	JZ	not_use_C3C2C1C0
err_intr_flag:
	STC
	ret
not_use_C3C2C1C0:
	CLC
    	RET
check_87_intr_and_code	endp

; on start  AH = high part of SW
; on exit AL 3:0 = C3C2C1C0
form_C3210	proc
	AND	AH,47h;  C3-0 mask
	MOV	AL,AH ;   _3___210 _3___210
	MOV	CL,3
	SHR	AL,CL ;   _3___210 ____3___
	AND	AH,0fh;   _____210 ____3___
	OR	AL,AH ;   _____210 ____3210
	ret
form_C3210	endp

;*************************************************************
;* AL - C3C2C1C0 status code           *
;* 8087 status word was saved to S_SW
;* CF set on error                                            
;*************************************************************
check_87_code	proc
	FXAM
	xchg	ax,bx
	FSTSW	S_SW
	FCLEX
	MOV	AH,byte ptr S_SW+1
	call	form_c3210
	CMP	AL,BL
	JZ	@F
	STC
@@:	ret
check_87_code	endp

;**************************************************
; irq13_flag has flags pattern need to catch
; pattern is located in irq13_SW_code
; if flags are not equal - irq13_flag is set to 80h
;**************************************************
irq_13_fpu_inter	proc
	PUSH	DS
	PUSH	AX
	mov	ax,CS
	mov	DS,ax
	FNSTENV	ENV_87 ; wait causes NMI halt
	FNCLEX	; chech with wait
	MOV	AL,byte ptr ENV_87.SW	; SW	; B3TTT210=IxPUOZDI
	AND	AL,01fh			; 00000000 00011111
	CMP     irq13_SW_code,AL
	JNZ	no_intr_flag_set
	MOV	irq13_flag,080h
no_intr_flag_set:
	POP	AX
	POP	DS
	;MOV	AX,020h ; primary intr controller
	;OUT	20h,AX
	;JMP    short $+2
	;OUT    0a0h,AX  ; secondary intr controller
	IRET
irq_13_fpu_inter	endp

irq_75_fpu_inter	proc
	PUSH	DS
	PUSH	AX
	mov	ax,CS
	mov	DS,ax
	FNSTENV	ENV_87 ; wait causes NMI halt
	wait
	FNCLEX	; chech with wait
	MOV	AL,byte ptr ENV_87.SW	; SW	; B3TTT210=IxPUOZDI
	AND	AL,01fh			; 00000000 00011111
	CMP     irq13_SW_code,AL
	JNZ	@F
	MOV	irq13_flag,080h
@@:	
	;MOV	Al,020h ; primary intr controller
	;OUT	20h,Al
	;JMP    short $+2
	;OUT     0a0h,Al  ; secondary intr controller
	POP	AX
	POP	DS
	IRET
irq_75_fpu_inter	endp


COMMENT !
	fld	targs[di]
	wait
	mov	dx, 309h+FOPT_MANT_SIGN_W+FOPT_EXP_SIGN_W+FOPT_ALWAYS_SCI_W
	mov	di,offset alldig+2
	call	f2a
	mov	dx,offset alldig+2
	call	mdosprn
	fstp	st
!

mess_ptest	db	27,"[1;36;40m$"

fpu_intr	db	2

exe_switch	dw	0
even
int2_store	dw	0,0
; Compatibility variables
c_alli_prec 	dw 	CW_ALLI_MASK OR CW_PREC_MASK
	; Data variables
; #### S_CW = S_SW+2 #####
S_SW	dw	?	; should be the array, offset S_CW = offset S_SW+2
S_CW	dw	?
ENV_87	env87	<>  ; S_SW+4
stored_tbytes_0	dt	8 dup (0.0)
stored_tbytes_1	dt	0.0

f4_smallest		dd	9.403954E-38	;db	0ffh, 0ffh, 0ffh, 01
f4_biggest		dd	3.4028235E38	;db	0ffh, 0ffh, 07fh, 07fh
f4_near_biggest		dd	1.7014118E38	;db	0, 0, 0, 7fh
f4_near_smallest	dd	9.403946E-38	;db	0f0h, 0ffh, 0ffh, 1
f4_smallest_denorm	db	1, 0, 0, 0	;dd	5.877473E-39
f2_int_2		dw	2 ; 2
f8_0_4002		dq	0.4002
f8_0_001		dq	0.001
f8_1em6			dq	1e-6
i2_141			dw	8dh
ddw_6			dd	42h, 0b6h, 2h, 2ah, 0, 0 ; 66, 182, 2, 42
f4_res0		dd	0.0
num_bcd	db	55h, 55h, 55h, 55h, 55h, 55h, 55h, 55h, 55h, 0
tbyte_FF	db	10 dup (0FFh)
tbyte_00	db	10 dup (0)
stored_double_0	dq	0.0
fpu_int_store_1	dw	0,0
i2_int_16	dw	16, 0 ; high word
store_bcd0	dt	?
i2_ten		dw	10
fp_instr_addr	SGSM	<>

irq13_vars	label	word
irq13_SW_code	db	0
irq13_flag	db	0
; performance
intr_2	dw	offset irq_13_fpu_inter

; perf
fwidth	dw	2

if2 
%out [1;32;40mPass 2: assembled  [1;34;40m8087 coprocessor 11-level test[0;37;40m
endif

cseg	ends
	end	main

CW mask:
CW_INTR_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ; 01f3fh
CW_ALLI_MASK OR CW_RC_MASK OR CW_PREC_MASK OR CW_INF_MASK ; 1fbfh
CW_INTR_MASK

CW value:
(CW_PREC_64 SHL 8) OR CW_INTR_MASK ; 33F;
CW_INTR_MASK OR CW_RC_MASK OR CW_INF_MASK ;1c3fh
CW_ALLI_MASK OR CW_PREC_MASK ;03bfh
CW_ALLI_MASK OR ((CW_PREC_64 OR CW_RC_TOUP)SHL 8) 	; 0bbfh
CW_ALLI_MASK OR ((CW_PREC_64 OR CW_RC_TODOWN)SHL 8) ; 07bfh
CW_ALLI_MASK OR ((CW_PREC_64 OR CW_RC_TONEAR)SHL 8) ; 03bfh
CW_INTR_MASK OR CW_PREC_MASK ;0033fh
(CW_PREC_64 SHL 8) OR PI_5B_MASK
(CW_PREC_64 SHL 8) OR AI_7B_MASK
(CW_PREC_64 SHL 8) OR CW_SUMM_INTR
((CW_INF_AFFINE OR CW_PREC_53)SHL 8) OR 40H OR CW_INTR_MASK ;0127Fh

SW mask:
SW_ALLI_MASK OR SW_TOS_MASK OR SW_BUSY_MASK ;0b8bfh
SW_C3_BMASK OR SW_C0_BMASK
SW_C3_BMASK
SW_TOS_BMASK
SW_INTR_MASK;03fh
SW_ALLI_MASK

SW value:
xI_xB_MASK
SW_INTR_MASK;03fh
