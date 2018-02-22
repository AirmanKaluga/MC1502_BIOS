
	Ideal
	model small ; produce .EXE file then truncate it
;---------------------------------------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------------------------------------
; Pad code to create entry point at specified address (needed for 100% IBM BIOS compatibility)
macro	entry	addr
	pad = str_banner - $ + addr - 00000h
	if pad lt 0
		err	'No room for ENTRY point'
	endif
	if pad gt 0
		db	pad dup(090h)
	endif
endm

macro	jmpfar	segm, offs
        db	0EAh;
        dw	offs, segm
endm

;---------------------------------------------------------------------------------------------------

; Segment type:	Pure code
segment		code byte public 'CODE'
                assume cs:code
                org 00000h
                assume es:nothing, ss:nothing, ds:nothing

		mov	dx, 333h
		mov	al, 0C1h ; 'Á'
		out	dx, al
		cli
		mov	ax, 0
		mov	ds, ax
		mov	ss, ax
		mov	sp, 7C00h
		sti
		mov	ax, [word ptr ds:068h]
		mov	[ds:168], ax
		mov	[word ptr ds:068h],	offset loc_511
		mov	ax, [word ptr ds:06Ah]
		mov	[word ptr ds:016Ah], ax
		mov	[word ptr ds:06ah],	cs
		mov	[word ptr ds:064h],	offset loc_62
		mov	[word ptr ds:066h],	cs
		mov	ax, [word ptr ds:048h+4]
		mov	[word ptr ds:0FDh+3],	ax
		mov	ax, [word ptr ds:04Eh]
		mov	[word ptr ds:0102h], ax
		mov	[word ptr ds:048h+4], offset loc_135	
		mov	[word ptr ds:04Eh],	cs

loc_48:					; DATA XREF: seg000:0032r seg000:003Ew ...
		and	[byte ptr ds:loc_40F+1], 7Fh

loc_4D:					; DATA XREF: seg000:0038r seg000:0044w
		mov	ah, 12h

loc_4F:
		mov	[byte ptr ds:word_477],	ah

loc_53:					; CODE XREF: seg000:0108j
		mov	ax, 3
		int	10h		; - VIDEO - SET	VIDEO MODE
					; AL = mode

loc_58:					; DATA XREF: seg000:0106r
		lea	bx, [aRLinkNetworkBi] ;	"R-LINK	Network	BIOS V1.00\r\n(C) SPIKA	"...
		call	sub_10B
		mov	si, 3

loc_62:					;
		mov	ax, 0
		mov	ds, ax

loc_67:					; DATA XREF: seg000:0012r seg000:0018w ...
		mov	es, ax

		mov	ah, 10h
		int	1Ah
		jb	short loc_BA
		mov	ah, 1
		int	5Ah		; Cluster adapter BIOS entry address
		mov	ah, 17h
		int	1Ah
		jb	short loc_BA
		mov	[ds:byte_474], dl
		mov	[ds:byte_475], dh
		and	cl, 3Fh
		mov	[ds:byte_476], cl
		mov	ah, 4
		int	1Ah		; CLOCK	- READ DATE FROM REAL TIME CLOCK (AT,XT286,CONV,PS)
					; Return: DL = day in BCD
					; DH = month in	BCD
					; CL = year in BCD
					; CH = century (19h or 20h)
		jb	short loc_BA
		mov	al, dl
		call	sub_11A
		mov	ax, 0E2Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	al, dh
		call	sub_11A
		mov	ax, 0E2Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	al, ch
		call	sub_11A
		mov	al, cl
		call	sub_11A
		mov	ax, 0E20h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	ax, 0E20h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	ah, 2
		int	1Ah		; CLOCK	- READ REAL TIME CLOCK (AT,XT286,CONV,PS)
					; Return: CH = hours in	BCD
					; CL = minutes in BCD
					; DH = seconds in BCD

loc_BA:					; CODE XREF: seg000:006Dj seg000:0077j ...
		jb	short loc_F0
		mov	al, ch
		call	sub_11A
		mov	ax, 0E3Ah
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	al, cl
		call	sub_11A
		mov	bx, 7C00h
		mov	ax, 201h
		mov	cx, 1
		mov	di, 1
		mov	dx, 80h	; '€'
		int	13h		; DISK - READ SECTORS INTO MEMORY
					; AL = number of sectors to read, CH = track, CL = sector
					; DH = head, DL	= drive, ES:BX -> buffer to fill
					; Return: CF set on error, AH =	status,	AL = number of sectors read
		jb	short loc_F0
		lea	bx, [aRLinkNetworkBi+29h] ; "\r\n\r\n"
		call	sub_10B
		mov	ah, 36h	; '6'
		mov	[byte ptr ds:word_477],	ah
		jmpfar 	0, 7C00h
; ---------------------------------------------------------------------------

loc_F0:					; CODE XREF: seg000:loc_BAj
					; seg000:00DCj
		dec	si
		jz	short loc_F6
		jmp	loc_62
; ---------------------------------------------------------------------------

loc_F6:					; CODE XREF: seg000:00F1j
		lea	bx, [aRLinkNetworkBi+29h] ; "\r\n\r\n"
		call	sub_10B

loc_FD:					; DATA XREF: seg000:0035w
		lea	bx, [byte_59A]

loc_101:				; DATA XREF: seg000:003Bw
		call	sub_10B
		mov	ah, 0
		int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
					; Return: AH = scan code, AL = character
		jmp	loc_53

; =============== S U B	R O U T	I N E =======================================


proc		sub_10B	near		; CODE XREF: seg000:005Cp seg000:00E2p ...
		mov	al, [cs:bx]
		cmp	al, 0
		jz	short locret_119
		mov	ah, 0Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		inc	bx
		jmp	short sub_10B
; ---------------------------------------------------------------------------

locret_119:				; CODE XREF: sub_10B+5j
		retn
endp		sub_10B


; =============== S U B	R O U T	I N E =======================================

proc		sub_11A	near		;
		mov	bh, al
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		add	al, 30h	; '0'
		mov	ah, 0Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	al, bh
		and	al, 0Fh
		add	al, 30h	; '0'
		mov	ah, 0Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		retn
endp		sub_11A

; ---------------------------------------------------------------------------
loc_135:  
		sti
		cmp     dl, 80h ; 'À'
		jnb     short loc_140
		int     40h             ; Hard disk - Relocated Floppy Handler (original INT 13h)
		retf    2
; ---------------------------------------------------------------------------
loc_140:
		push	ds
		push	ax
		xor	ax, ax
		mov	ds, ax
		pop	ax
		cmp	ah, 2
		jz	short loc_1B4
		cmp	ah, 0Ch
		jz	short loc_1B4
		cmp	ah, 33h	; '3'
		jz	short loc_1B4
		cmp	ah, 55h	; 'U'
		jnz	short loc_15E
		jmp	loc_3DB
; ---------------------------------------------------------------------------
loc_15E:                                ; CODE XREF: seg000:0159j
		 cmp     ah, 3
		 jnz     short loc_168
		 mov     ah, 3
		 jmp     loc_2EA
; ---------------------------------------------------------------------------

loc_168:                                ; CODE XREF: seg000:0161j
								 ; DATA XREF: seg000:0015w ...
		 cmp     ah, 0
		 jz      short loc_19A
		 cmp     ah, 1
		 jnz     short loc_179
		 mov     al, [ds:byte_441]
		 clc
		 jmp     loc_2F4
; ---------------------------------------------------------------------------
loc_179:                                ; CODE XREF: seg000:0170j
		cmp	ah, 8
		jnz	short loc_19D
		cmp	dl, 80h	; '€'
		jz	short loc_18E
		mov	ah, 0
		mov	cx, 0
		mov	dx, 0
		jmp	far loc_2EA
; ---------------------------------------------------------------------------

loc_18E:				; CODE XREF: seg000:0181j
		mov	ah, 17h
		int	1Ah
		mov	dl, 1
		mov	ah, 0
		jnb	short loc_19A
		mov	ah, 80h	; '€'

loc_19A:				; CODE XREF: seg000:0196j
		jmp	far loc_2EA
; ---------------------------------------------------------------------------

loc_19D:				; CODE XREF: seg000:017Cj
		cmp	ah, 15h
		jnz	short loc_1AF
		mov	ah, 0
		cmp	dl, 80h	; '€'
		jnz	short loc_1AB
		mov	ah, 3

loc_1AB:				; CODE XREF: seg000:01A7j
		clc
		jmp	loc_2F4
; ---------------------------------------------------------------------------

loc_1AF:				; CODE XREF: seg000:01A0j
		mov	ah, 1
		jmp	loc_2EA
; ---------------------------------------------------------------------------

loc_1B4:				; CODE XREF: seg000:014Aj seg000:014Fj ...
		push	si
		push	di
		push	bp
		push	bx
		push	ax
		push	cx
		push	dx
		dec	dl
		push	bx
		push	ax
		push	cx
		push	dx
		mov	bp, sp
		mov	[byte ptr bp+0Dh], 3

loc_1C7:				; CODE XREF: seg000:0246j
		mov	di, [bp+6]
		lea	dx, [loc_238]
		push	dx

loc_1CF:				; CODE XREF: seg000:02D1j seg000:02D9j
		mov	bl, [bp+4]
		cmp	bl, [ds:byte_474]
		jbe	short loc_1DC
		mov	bl, [ds:byte_474]

loc_1DC:				; CODE XREF: seg000:01D6j
		cmp	[byte ptr bp+5], 33h ; '3'
		jnz	short loc_1E5
		jmp	loc_2F8
; ---------------------------------------------------------------------------

loc_1E5:				; CODE XREF: seg000:01E0j
		mov	bh, 5
		call	loc_420
		mov	ah, [bp+5]
		call	sub_4C9
		mov	ah, bl
		call	sub_4C9
		mov	ah, [bp+2]
		call	sub_4C9
		mov	ah, [bp+3]
		call	sub_4C9
		mov	ah, [bp+1]
		call	sub_4C9
		mov	ah, [bp+0]
		call	sub_4C9
		shl	bl, 1
		shl	bl, 1
		mov	bh, 80h	; '€'
		call	loc_420
		call	sub_4EE
		mov	ah, al
		call	sub_49B
		test	ah, 40h
		jz	short loc_233
		cmp	[byte ptr bp+5], 0Ch
		jz	short loc_24D
		test	ah, 2
		jz	short loc_259
		mov	ah, 4
		jmp	short loc_24A
; ---------------------------------------------------------------------------
		db 90h
; ---------------------------------------------------------------------------

loc_233:				; CODE XREF: seg000:0221j
		mov	ah, 20h	; ' '
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_238:				; CODE XREF: seg000:0277j seg000:034Dj
					; DATA XREF: ...
		cmp	ah, 10h
		jnz	short loc_249
		mov	dx, 330h
		in	al, dx
		dec	byte ptr [bp+0Dh]
		jz	short loc_249
		jmp	loc_1C7
; ---------------------------------------------------------------------------

loc_249:				; CODE XREF: seg000:023Bj seg000:0244j
		push	dx

loc_24A:				; CODE XREF: seg000:0230j seg000:0235j ...
		jmp	loc_2DE
; ---------------------------------------------------------------------------

loc_24D:				; CODE XREF: seg000:0227j
		test	ah, 2
		jnz	short loc_255
		jmp	loc_2DC
; ---------------------------------------------------------------------------

loc_255:				; CODE XREF: seg000:0250j
		mov	ah, 40h	; '@'
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_259:				; CODE XREF: seg000:022Cj seg000:0288j
		mov	bh, 0FFh
		call	loc_420
		mov	bh, 80h	; '€'

loc_260:				; CODE XREF: seg000:0269j seg000:0284j
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_279
		cmp	cx, [ds:word_46C]
		jns	short loc_260
		and	al, 3
		cmp	al, 1
		jz	short loc_275
		mov	ah, 80h	; '€'
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_275:				; CODE XREF: seg000:026Fj
		mov	ah, 10h
		jmp	short loc_238
; ---------------------------------------------------------------------------

loc_279:				; CODE XREF: seg000:0263j
		dec	dx
		dec	dx
		in	al, dx
		inc	dx
		inc	dx
		mov	[es:di], al
		inc	di
		dec	bh
		jnz	short loc_260
		dec	bl
		jnz	short loc_259
		call	sub_49B

loc_28D:				; CODE XREF: seg000:loc_3D8j
		mov	ah, [ds:byte_474]
		sub	[bp+4],	ah
		jbe	short loc_2DC
		mov	al, [bp+2]
		mov	bl, al
		and	al, 3Fh
		and	bl, 0C0h
		add	al, ah
		cmp	al, [ds:byte_476]
		jbe	short loc_2D4
		sub	al, [ds:byte_476]
		or	al, bl
		mov	[bp+2],	al
		inc	byte ptr [bp+1]
		mov	ah, [bp+1]
		cmp	ah, [ds:byte_475]
		jbe	short loc_2CA
		mov	[byte ptr bp+1], 0
		inc	byte ptr[bp+3]
		jnz	short loc_2CA
		add	byte ptr [bp+2], 40h ; '@'

loc_2CA:				; CODE XREF: seg000:02BBj seg000:02C4j
		mov	[bp+6],	di
		mov	[byte ptr bp+0Dh], 3
		jmp	loc_1CF
; ---------------------------------------------------------------------------

loc_2D4:				; CODE XREF: seg000:02A6j
		or	al, bl
		mov	[bp+2],	al
		jmp	loc_1CF
; ---------------------------------------------------------------------------

loc_2DC:				; CODE XREF: seg000:0252j seg000:0294j
		mov	ah, 0

loc_2DE:				; CODE XREF: seg000:loc_24Aj
		add	sp, 0Ah
		pop	dx
		pop	cx
		pop	bx
		mov	al, bl
		pop	bx
		pop	bp
		pop	di
		pop	si

loc_2EA:				; CODE XREF: seg000:0165j seg000:018Bj ...
		mov	[ds:byte_441], ah
		cmp	ah, 0
		jz	short loc_2F4
		stc

loc_2F4:				; CODE XREF: seg000:0176j seg000:01ACj ...
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_2F8:				; CODE XREF: seg000:01E2j
		mov	bh, 0
		call	loc_420
		mov	ah, [bp+14h]
		or	ah, 20h
		call	sub_4C9
		mov	bh, 80h	; '€'
		call	loc_420
		call	sub_4EE
		mov	ah, al
		call	sub_49B
		test	ah, 20h
		jnz	short loc_31D
		mov	ah, 20h	; ' '

loc_31A:				; CODE XREF: seg000:0324j seg000:0349j ...
		jmp	loc_24A
; ---------------------------------------------------------------------------

loc_31D:				; CODE XREF: seg000:0316j
		test	ah, 1
		jnz	short loc_326
		mov	ah, 0FFh
		jmp	short loc_31A
; ---------------------------------------------------------------------------

loc_326:				; CODE XREF: seg000:0320j
		mov	si, 0
		shl	bl, 1
		shl	bl, 1

loc_32D:				; CODE XREF: seg000:0361j
		mov	bh, 7Fh	; ''
		call	loc_420
		xor	ah, ah
		mov	bh, 80h	; '€'

loc_336:				; CODE XREF: seg000:033Fj seg000:035Dj
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_350
		cmp	cx, [ds:word_46C]
		jns	short loc_336
		and	al, 3
		cmp	al, 1
		jz	short loc_34B
		mov	ah, 80h	; '€'
		jmp	short loc_31A
; ---------------------------------------------------------------------------

loc_34B:				; CODE XREF: seg000:0345j
		mov	ah, 10h
		jmp	loc_238
; ---------------------------------------------------------------------------

loc_350:				; CODE XREF: seg000:0339j
		dec	dx
		dec	dx
		mov	al, [es:di]
		add	si, ax
		out	dx, al
		inc	dx
		inc	dx
		inc	di
		dec	bh
		jnz	short loc_336
		dec	bl
		jnz	short loc_32D
		mov	bh, 8
		call	loc_420
		mov	bh, 0
		mov	ah, 3
		add	bh, ah
		call	sub_4C9
		mov	ah, [bp+4]
		cmp	ah, [ds:byte_474]
		jbe	short loc_37E
		mov	ah, [ds:byte_474]

loc_37E:				; CODE XREF: seg000:0378j
		add	bh, ah
		call	sub_4C9
		mov	ah, [bp+2]
		add	bh, ah
		call	sub_4C9
		mov	ah, [bp+3]
		add	bh, ah
		call	sub_4C9
		mov	ah, [bp+1]
		add	bh, ah
		call	sub_4C9
		mov	ah, [bp+0]
		add	bh, ah
		call	sub_4C9
		mov	ax, si
		mov	ah, al
		add	bh, ah
		call	sub_4C9
		mov	ax, si
		add	bh, ah
		call	sub_4C9
		mov	ah, bh
		call	sub_4C9
		mov	bh, 80h	; '€'
		call	loc_420
		call	sub_4EE
		mov	ah, al
		call	sub_49B
		test	ah, 80h
		jnz	short loc_3CF
		mov	ah, 20h	; ' '

loc_3CC:				; CODE XREF: seg000:03D6j
		jmp	loc_31A
; ---------------------------------------------------------------------------

loc_3CF:				; CODE XREF: seg000:03C8j
		test	ah, 2
		jz	short loc_3D8
		mov	ah, 4
		jmp	short loc_3CC
; ---------------------------------------------------------------------------

loc_3D8:				; CODE XREF: seg000:03D2j
		jmp	loc_28D
; ---------------------------------------------------------------------------

loc_3DB:				; CODE XREF: seg000:015Bj
		push	bx
		push	cx
		push	dx
		lea	dx, [loc_41A]
		push	dx
		mov	bh, 0
		call	loc_420
		mov	ah, bl
		or	ah, 10h
		call	sub_4C9
		mov	bh, 80h	; '€'
		call	loc_420
		call	sub_4EE
		mov	ah, al
		call	sub_49B
		test	ah, 10h
		jnz	short loc_408
		mov	ah, 4
		stc
		jmp	short loc_412
; ---------------------------------------------------------------------------

loc_408:				; CODE XREF: seg000:0400j
		test	ah, 1
		mov	ah, 0
		jz	short loc_411

loc_40F:				; DATA XREF: seg000:loc_48w
		mov	ah, 0FFh

loc_411:				; CODE XREF: seg000:040Dj
		clc

loc_412:				; CODE XREF: seg000:0405j
		pop	dx

loc_413:				; CODE XREF: seg000:041Ej
		pop	dx
		pop	cx
		pop	bx
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_41A:				; DATA XREF: seg000:03DEo
		mov	dx, 330h
		in	al, dx
		jmp	short loc_413
; ---------------------------------------------------------------------------

loc_420:				; CODE XREF: seg000:01E7p seg000:0213p ...
		mov	dx, 332h
		mov	cx, [ds:word_46C]
		add	cx, 2

loc_42A:				; CODE XREF: seg000:0447j
		in	al, dx
		and	al, 3
		cmp	al, 0
		jz	short loc_47C
		cmp	al, 1
		jnz	short loc_443
		in	al, dx
		and	al, 3
		cmp	al, 1
		jnz	short loc_443
		mov	ah, 10h
		add	sp, 2
; ---------------------------------------------------------------------------
byte_441	db 0F9h			; DATA XREF: seg000:0172r
					; seg000:loc_2EAw
; ---------------------------------------------------------------------------
		retn
; ---------------------------------------------------------------------------

loc_443:				; CODE XREF: seg000:0433j seg000:043Aj
		cmp	cx, [ds:word_46C]
		jns	short loc_42A
		add	cx, [ds:word_477]
		in	al, dx
		mov	ah, al
		and	al, 3
		cmp	al, 0
		jz	short loc_480
		dec	dx
		dec	dx
		cmp	al, 1
		jz	short loc_462
		test	ah, 80h
		jz	short loc_462
		out	dx, al

loc_462:				; CODE XREF: seg000:045Aj seg000:045Fj
		test	ah, 20h
		jz	short loc_468
		in	al, dx

loc_468:				; CODE XREF: seg000:0465j
		inc	dx
		inc	dx
; ---------------------------------------------------------------------------
		db 0A1h, 6Ch
word_46C	dw 3B04h		; DATA XREF: seg000:0265r seg000:033Br ...
		db 6
		db 6Ch,	4, 74h,	0FAh, 3Bh
byte_474	db 0Eh			; DATA XREF: seg000:0079w seg000:01D2r ...
byte_475	db 6Ch			; DATA XREF: seg000:007Dw seg000:02B7r
byte_476	db 4			; DATA XREF: seg000:0084w seg000:02A2r ...
word_477	dw 0D479h		; DATA XREF: seg000:loc_4Fw
					; seg000:00E7w	...
; ---------------------------------------------------------------------------
		jmp	short loc_494
; ---------------------------------------------------------------------------
		;align 2

loc_47C:				; CODE XREF: seg000:042Fj
		add	cx, [ds:word_477]

loc_480:				; CODE XREF: seg000:0454j
		dec	dx
		dec	dx
		mov	al, bh
		out	dx, al
		inc	dx
		inc	dx

loc_487:				; CODE XREF: seg000:0492j
		in	al, dx
		and	al, 3
		cmp	al, 2
		jz	short locret_49A
		cmp	cx, [ds:word_46C]
		jns	short loc_487

loc_494:				; CODE XREF: seg000:0479j
		mov	ah, 80h	; '€'
		add	sp, 2
		stc

locret_49A:				; CODE XREF: seg000:048Cj
		retn

; =============== S U B	R O U T	I N E =======================================


proc		sub_49B	near		; CODE XREF: seg000:021Bp seg000:028Ap ...
		in	al, dx
		and	al, 3
		cmp	al, 0
		jz	short locret_4C8
		cmp	al, 1
		jnz	short loc_4BC
		in	al, dx
		and	al, 3
		cmp	al, 1
		jnz	short loc_4BC
		mov	ah, 10h
		jmp	short loc_4C4
; ---------------------------------------------------------------------------
		;align 2
		db 2 dup(0FFh),	81h, 85h, 89h, 91h, 88h, 8Ah, 2Dh, 8Ah
; ---------------------------------------------------------------------------

loc_4BC:				; CODE XREF: sub_49B+9j sub_49B+10j
		cmp	cx, [ds:word_46C]
		jns	short sub_49B
		mov	ah, 80h	; '€'

loc_4C4:				; CODE XREF: sub_49B+14j
		add	sp, 2
		stc

locret_4C8:				; CODE XREF: sub_49B+5j
		retn
endp		sub_49B	; sp-analysis failed


; =============== S U B	R O U T	I N E =======================================


proc		sub_4C9	near		; CODE XREF: seg000:01EDp seg000:01F2p ...
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_4E5
		cmp	cx, [ds:word_46C]
		jns	short sub_4C9
		and	al, 3
		cmp	al, 1
		jz	short loc_4E1
		mov	ah, 80h	; '€'

loc_4DC:				; CODE XREF: sub_4C9+1Aj
		add	sp, 2
		stc
		retn
; ---------------------------------------------------------------------------

loc_4E1:				; CODE XREF: sub_4C9+Fj
		mov	ah, 10h
		jmp	short loc_4DC
; ---------------------------------------------------------------------------

loc_4E5:				; CODE XREF: sub_4C9+3j
		dec	dx
		dec	dx
		mov	al, ah
		out	dx, al
		inc	dx
		inc	dx
		clc
		retn
endp		sub_4C9	; sp-analysis failed


; =============== S U B	R O U T	I N E =======================================


proc		sub_4EE	near		; CODE XREF: seg000:0216p seg000:030Bp ...
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_50A
		cmp	cx, [ds:word_46C]
		jns	short sub_4EE
		and	al, 3
		cmp	al, 1
		jz	short loc_506
		mov	ah, 80h	; '€'

loc_501:				; CODE XREF: sub_4EE+1Aj
		add	sp, 2
		stc
		retn
; ---------------------------------------------------------------------------

loc_506:				; CODE XREF: sub_4EE+Fj
		mov	ah, 10h
		jmp	short loc_501
; ---------------------------------------------------------------------------

loc_50A:				; CODE XREF: sub_4EE+3j
		dec	dx
		dec	dx
		in	al, dx
		inc	dx
		inc	dx
		clc
		retn
endp		sub_4EE	; sp-analysis failed

; ---------------------------------------------------------------------------
loc_511:
		cmp	ah, 10h
		jb	short loc_51C
		sub	ah, 10h
		jmp	short loc_52B
; ---------------------------------------------------------------------------
		;align 2

loc_51C:				; CODE XREF: seg000:0514j
		cmp	ah, 2
		jz	short loc_52B
		cmp	ah, 4
		jz	short loc_52B
		int	5Ah		; Cluster adapter BIOS entry address
		retf	2
; ---------------------------------------------------------------------------

loc_52B:				; CODE XREF: seg000:0519j seg000:051Fj ...
		sti
		push	ds
		push	bx
		lea	dx, [loc_566]
		push	dx
		xor	bx, bx
		mov	ds, bx
		mov	bl, ah
		call	loc_420
		mov	ah, bl
		or	ah, 8
		call	sub_4C9
		mov	bh, 83h	; 'ƒ'
		call	loc_420
		call	sub_4EE
		mov	ah, al
		call	sub_4EE
		mov	bx, ax
		call	sub_4EE
		mov	ah, al
		call	sub_4EE
		mov	dx, ax
		mov	cx, bx
		pop	bx
		clc

loc_561:				; CODE XREF: seg000:056Aj
		pop	bx
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_566:				; DATA XREF: seg000:052Eo
		mov	dx, 330h
		in	al, dx
		jmp	short loc_561
; ---------------------------------------------------------------------------
aRLinkNetworkBi	db 'R-LINK Network BIOS V1.00',0Dh,0Ah ; DATA XREF: seg000:loc_58o
		db '(C) SPIKA 1990',0Dh,0Ah
		db 0Dh,0Ah,0
byte_59A	db 52h			; DATA XREF: seg000:loc_FDo
aLinkBootError	db '-LINK boot error',0Dh,0Ah,0
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		
ends		code
end