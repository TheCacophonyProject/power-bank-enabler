; macro.asm

; author	Ewen Fraser, ArchEng Designs Ltd.
; original	11 August 2000
; 20/8/2001	added missing endm after jumpto macro
;		defined more 16 bit macros
; 14/1/2005	defined swapwf
; 22/11/2006	changed code for add16 and sub16 so C is valid
;		for multi-byte maths (in particular for 24/16 division routine)
; 14 Jan 2007	added beq16k, seq16k, bne16k, sne16k
; 28 May 2008	fgoto, fcall use pagesel and turn off warning 306
; 13 Jun 2008	renamed swapwf to xchgwf to avoid confusion
;		defined xchgf
; 11 Aug 2013	fixed bug in bne16 macro
; 28 Jul 2018	removed non-PIC10 stuff

; Some useful macros for PIC10xxx

;	fgoto	fcall
;	xchgwf	xchgf
; 8-bit branch
;	fbz	fsz
;	fbnz	fsnz
;	beq	seq	beqk	seqk
;	bne	sne	bnek	snek
;	blt	slt	bltk	sltk
;	bge	sge	bgek	sgek
; 16-bit
;	bz16	sz16
;	bnz16	snz16
;	beq16	seq16	beq16k	seq16k
;	bne16	sne16	bne16k	sne16k
;	bge16	sge16	bge16k	sge16k
;	blt16	slt16	blt16k	slt16k
;	inc16	dec16
;	add16	add16k
;	sub16	sub16k
;	mov16	mov16k
;	clr16	neg16	(negf)

;****************************************************************************

; NB. pagesel doesn't generate code if PIC has only 1 bank of ROM
; Also these macros cannot be used to to set PCLATH for a jump table since
; at best the pagesel directive will only set bits 3,4 of PCLATH
; A computed goto requires all 5 bits of PCLATH to be loaded
; The directive pageselw uses w to load value into PCLATH

; Goto anywhere in code space

fgoto	macro	address
	ERRORLEVEL -306			; suppress warning about crossing page
	pagesel	address			; change bits PCLATH[4:3]
	goto	address
	ERRORLEVEL +306			; re-enable warning
	endm

; Call anywhere in code space

fcall	macro	address
	ERRORLEVEL -306			; suppress warning about crossing page
	pagesel	address			; change bits PCLATH[4:3]
	call	address
	pagesel	$			; change bits PCLATH[4:3]
	ERRORLEVEL +306			; re-enable warning
	endm

;----------------------------------------------------------------------------

; Exchange w and file without using intermediate storage

xchgwf	macro	var
	xorwf	var, self
	xorwf	var, w
	xorwf	var, self
	endm

; Exchange 2 files using only w as intermediate storage

xchgf	macro	op1,op2
	movf	op1, w
	xchgwf	op2
	movwf	op1
	endm

;----------------------------------------------------------------------------

; Conditional branch and skip macros

; NB. mpasm already recognises bz and bnz as follows
; bz	adr
;	btfsc	STATUS, Z
;	goto	adr
;
; bnz	adr
;	btfss	STATUS, Z
;	goto	adr

; Branch to address (adr) if variable (file) = 0
; w not used

fbz	macro	var,adr
	movf	var, self
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var (file) = 0
; w not used

fsz	macro	var
	movf	var, self
	btfss	STATUS, Z
	endm

; Branch to address (adr) if variable (file) != 0
; w not used

fbnz	macro	var,adr
	movf	var, self
	btfss	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var (file) != 0
; w not used

fsnz	macro	var
	movf	var, self
	btfsc	STATUS, Z
	endm

; Branch to address (adr) if op1 = op2

beq	macro	op1,op2,adr
	movf	op2, w
	subwf	op1, w
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if op1 = op2

seq	macro	op1,op2
	movf	op2, w
	subwf	op1, w
	btfss	STATUS, Z
	endm

; Branch to address (adr) if variable (var) = constant (const)

beqk	macro	var,const,adr
	movlw	const
	subwf	var, w
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var = constant

seqk	macro	var,const
	movlw	const
	subwf	var, w
	btfss	STATUS, Z	; if var = const then skip next instruction
	endm

; Branch to address (adr) if op1 != op2

bne	macro	op1,op2,adr
	movf	op2, w
	subwf	op1, w
	btfss	STATUS, Z
	goto	adr
	endm

; Skip next instruction if op1 != op2

sne	macro	op1,op2
	movf	op2, w
	subwf	op1, w
	btfsc	STATUS, Z
	endm

; Branch to address (adr) if variable (var) != constant (const)

bnek	macro	var,const,adr
	movlw	const
	subwf	var, w
	btfss	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var != constant

snek	macro	var,const
	movlw	const
	subwf	var, w
	btfsc	STATUS, Z	; if var != const then skip next instruction
	endm

; Branch to address (adr) if op1 < op2

blt	macro	op1,op2,adr
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2 (c = 0 if op1 < op2)
	btfss	STATUS, C	; if op1 < op2 then
	goto	adr		; branch
	endm

; Skip next instruction if op1 < op2

slt	macro	op1,op2
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2 (c = 0 if op1 < op2)
	btfsc	STATUS, C	; if op1 < op2 then skip next instruction
	endm

; Branch to address (adr) if variable (var) < constant (const)

bltk	macro	var,const,adr
	movlw	const		; w = const
	subwf	var, w		; w = var - const (c = 0 if var < const)
	btfss	STATUS, C	; if var < const then
	goto	adr		; branch
	endm

; Skip next instruction if var < constant

sltk	macro	var,const
	movlw	const		; w = const
	subwf	var, w		; w = var - const (c = 0 if var < const)
	btfsc	STATUS, C	; if var < const then skip next instruction
	endm

; Branch to address (adr) if op1 >= op2

bge	macro	op1,op2,adr
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2 (c = 0 if op1 < op2)
	btfsc	STATUS, C	; if op1 >= op2 then
	goto	adr		; branch 
	endm

; Skip next instruction if op1 >= op2

sge	macro	op1,op2
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2 (c = 0 if op1 < op2)
	btfss	STATUS, C	; if op1 >= op2 then skip next instruction
	endm

; Branch to address (adr) if variable (var) >= constant (const)

bgek	macro	var,const,adr
	movlw	const		; w = const
	subwf	var, w		; w = var - const (c = 0 if var < const)
	btfsc	STATUS, C	; if var >= const then
	goto	adr		; branch
	endm

; Skip next instruction if var >= constant

sgek	macro	var,const
	movlw	const		; w = const
	subwf	var, w		; w = var - const (c = 0 if var < const)
	btfss	STATUS, C	; if var >= const then skip next instruction
	endm

; 16 bit macros

; Branch to address (adr) if var == 0
; uses w

bz16	macro	var,adr
	movf	var, w
	iorwf	var+1, w
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var == 0
; uses w

sz16	macro	var
	movf	var, w
	iorwf	var+1, w
	btfss	STATUS, Z
	endm

; Branch to address (adr) if var != 0
; uses w

bnz16	macro	var,adr
	movf	var, w
	iorwf	var+1, w
	btfss	STATUS, Z
	goto	adr
	endm

; Skip next instruction if var != 0
; uses w

snz16	macro	var
	movf	var, w
	iorwf	var+1, w
	btfsc	STATUS, Z
	endm

; Branch to address (adr) if 16 bit op1 == 16 bit op2

beq16	macro	op1,op2,adr
	movf	op1, w
	subwf	op2, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+5		; do not branch
	movf	op1+1, w
	subwf	op2+1, w
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if 16 bit op1 == 16 bit op2
seq16	macro	op1,op2
	movf	op1, w
	subwf	op2, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+4		; do not skip
	movf	op1+1, w
	subwf	op2+1, w
	btfss	STATUS, Z	; if low bytes equal then skip
	endm

; Branch to address (adr) if 16 bit var == 16 bit constant (const)

beq16k	macro	var,const,adr
	movlw	high const	; compare high bytes
	subwf	var, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+5		; do not branch
	movlw	low const	; compare low bytes
	subwf	var+1, w
	btfsc	STATUS, Z
	goto	adr
	endm

; Skip next instruction if 16 bit var == 16 bit constant (const)

seq16k	macro	var,const
	movlw	high const	; compare high bytes
	subwf	var, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+4		; do not skip
	movlw	low const	; compare low bytes
	subwf	var+1, w
	btfss	STATUS, Z	; if low bytes equal then skip
	endm

; Branch to address (adr) if 16 bit op1 != 16 bit op2
bne16	macro	op1,op2,adr
	movf	op1, w
	subwf	op2, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	adr		; then branch
	movf	op1+1, w
	subwf	op2+1, w
	btfss	STATUS, Z	; if low bytes not equal
	goto	adr		; then branch
	endm

; Skip next instruction if 16 bit op1 != 16 bit op2
sne16	macro	op1,op2
	movf	op1, w
	subwf	op2, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+5		; then skip
	movf	op1+1, w
	subwf	op2+1, w
	btfsc	STATUS, Z	; if low bytes not equal then skip
	endm

; Branch to address (adr) if 16 bit var != 16 bit constant (const)

bne16k	macro	var,const,adr
	movlw	high const	; compare high bytes
	subwf	var, w
	btfss	STATUS, Z
	goto	adr
	movlw	low const	; compare low bytes
	subwf	var+1, w
	btfss	STATUS, Z
	goto	adr
	endm

; Skip next instruction if 16 bit var != 16 bit constant (const)

sne16k	macro	var,const
	movlw	high const	; compare high bytes
	subwf	var, w
	btfss	STATUS, Z	; if high bytes not equal
	goto	$+5		; then skip
	movlw	low const	; compare low bytes
	subwf	var+1, w
	btfsc	STATUS, Z	; if low bytes not equal then skip
	endm

; Branch to address (adr) if 16 bit op1 >= 16 bit op2

bge16	macro	op1,op2,adr
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movf	op2+1, w	; compare low bytes
	subwf	op1+1, w	; (c = 0 if op1 < op2)
	btfsc	STATUS, C	; if op1 >= op2 then
	goto	adr		; branch
	endm

; Skip next instruction if 16 bit op1 >= 16 bit op2

sge16	macro	op1,op2
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movf	op2+1, w	; compare low bytes
	subwf	op1+1, w	; (c = 0 if op1 < op2)
	btfss	STATUS, C	; if op1 >= op2 then skip next instruction
	endm

; Branch to address (adr) if 16 bit var >= 16 bit constant

bge16k	macro	var,const,adr
	movlw	high const
	subwf	var, w		; w = var - const
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movlw	low const	; compare low bytes
	subwf	var+1, w	; (c = 0 if var < const)
	btfsc	STATUS, C	; if var >= const then
	goto	adr		; branch
	endm

; Skip next instruction if 16 bit var >= 16 bit constant

sge16k	macro	var,const
	movlw	high const
	subwf	var, w		; var - const (c = 0 if var < const)
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movlw	low const	; compare low bytes
	subwf	var+1, w	; var - const (c = 0 if var < const)
	btfss	STATUS, C	; if var >= const then skip next instruction
	endm

; Branch to address (adr) if 16 bit op1 < 16 bit op2

blt16	macro	op1,op2,adr
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movf	op2+1, w	; compare low bytes
	subwf	op1+1, w	; (c = 0 if op1 < op2)
	btfss	STATUS, C	; if op1 < op2 then
	goto	adr		; branch
	endm

; Skip next instruction if 16 bit op1 < 16 bit op2

slt16	macro	op1,op2
	movf	op2, w		; w = op2
	subwf	op1, w		; w = op1 - op2
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movf	op2+1, w	; compare low bytes
	subwf	op1+1, w	; (c = 0 if op1 < op2)
	btfsc	STATUS, C	; if op1 < op2 then skip next instruction
	endm

; Branch to address (adr) if 16 bit var < 16 bit constant

blt16k	macro	var,const,adr
	movlw	high const
	subwf	var, w		; w = var - const
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movlw	low const	; compare low bytes
	subwf	var+1, w	; (c = 0 if var < const)
	btfss	STATUS, C	; if var < const then
	goto	adr		; branch
	endm

; Skip next instruction if 16 bit var < 16 bit constant

slt16k	macro	var,const
	movlw	high const
	subwf	var, w		; var - const (c = 0 if var < const)
	btfss	STATUS, Z	; if high bytes equal then
	goto	$+3
	movlw	low const	; compare low bytes
	subwf	var+1, w	; var - const (c = 0 if var < const)
	btfsc	STATUS, C	; if var < const then skip next instruction
	endm


; 16 bit increment, var16++

inc16	macro	var
	incf	var+1, self	; increment low byte
	btfsc	STATUS, Z	; on roll over
	incf	var, self	; increment high byte
	endm

; 16 bit decrement, var16--

dec16	macro	var
	movlw	-1
	addwf	var+1, self	; decrement low byte
	btfss	STATUS, C
	decf	var, self	; decrement high byte
	endm

; 16 bit addition, op1 += op2

;add16	macro	op1,op2
;	movf	op2+1, w
;	addwf	op1+1, self
;	btfsc	STATUS, C	; check for carry
;	incf 	op1, self
;	movf	op2, w
;	addwf	op1, self
;	endm

; This alternative gives correct carry for multi-byte maths
add16	macro	op1,op2
	movf	op2+1, w
	addwf	op1+1, self
	movf	op2, w
	btfsc	STATUS, C	; check for carry
	incfsz 	op2, w
	addwf	op1, self
	endm

; 16 bit addition, var += k

add16k	macro	var,k
	if low k
	movlw	low k
	addwf	var+1, self
	btfsc	STATUS, C	; check for carry
	incf 	var, self
	endif
	if high k
	movlw	high k
	addwf	var, self
	endif
	endm

; 16 bit subtraction, op1 -= op2

;sub16	macro	op1,op2
;	movf	op2+1, w
;	subwf	op1+1, self	; (c = 0 if op1 < op2)
;	btfss	STATUS, C	; check for NOT(borrow)
;	decf 	op1, self
;	movf	op2, w
;	subwf	op1, self
;	endm

; alternative gives correct carry for multi-byte maths
sub16	macro	op1,op2
	movf	op2+1, w
	subwf	op1+1, self
	movf	op2, w
	btfss	STATUS, C	; check for NOT(borrow)
	incfsz 	op2, w
	subwf	op1, self
	endm

; 16 bit subtraction, var -= k

sub16k	macro	var,k
	if low k
	movlw	low k
	subwf	var+1, self	; (c = 0 if op1 < op2)
	btfss	STATUS, C	; check for NOT(borrow)
	decf 	var, self
	endif
	if high k
	movlw	high k
	subwf	var, self
	endif
	endm

; 16 bit move, op1 = op2

mov16	macro	op1,op2
	movf	op2, w
	movwf	op1
	movf	op2+1, w
	movwf	op1+1
	endm

; Load 16 bit constant, var = k

mov16k	macro	var,k
	if high k
	movlw	high k
	movwf	var
	else
	clrf	var
	endif
	if low k
	movlw	low k
	movwf	var+1
	else
	clrf	var+1
	endif
	endm
	
; 16 bit clear, var = 0

clr16	macro	var
	clrf	var
	clrf	var+1
	endm

; Negate (8 bit)
; NB. mpasm already recognises negf as follows
;
;negf	macro	var, d
;	comf	var, self
;	incf	var, d
;	endm

; Negate (16 bit)

neg16	macro	var
	comf	var+1, w
	addlw	1		; negate low byte
	movwf	var+1
	comf	var, self
	btfsc	STATUS, C
	incf	var, self
	endm

