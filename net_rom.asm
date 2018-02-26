
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
		mov	[ds:0168h], ax
		mov	[word ptr ds:068h],	offset loc_511
		mov	ax, [word ptr ds:06Ah]
		mov	[word ptr ds:016Ah], ax
		mov	[word ptr ds:06Ah],	cs
		mov	[word ptr ds:064h],	offset loc_62
		mov	[word ptr ds:066h],	cs
		mov	ax, [word ptr ds:04Ch]
		mov	[word ptr ds:0100h],	ax
		mov	ax, [word ptr ds:04Eh]
		mov	[word ptr ds:0102h], ax
		mov	[word ptr ds:04Ch], offset loc_135	
		mov	[word ptr ds:04Eh],	cs

loc_48:					
		and	[byte ptr ds:0410h], 7Fh

loc_4D:	
		mov	ah, 12h

loc_4F:
		mov	[byte ptr ds:0477h],	ah

loc_53:
		mov	ax, 3
		int	10h		; - VIDEO - SET	VIDEO MODE
					; AL = mode

loc_58:
		lea	bx, [aRLinkNetworkBi] ;	"R-LINK	Network	BIOS V1.00\r\n(C) SPIKA	"...
		call	sub_10B
		mov	si, 3

loc_62:					;
		mov	ax, 0
		mov	ds, ax

loc_67:
		mov	es, ax

		mov	ah, 10h
		int	1Ah
		jb	short loc_BA
		mov	ah, 1
		int	5Ah		; Cluster adapter BIOS entry address
		mov	ah, 17h
		int	1Ah
		jb	short loc_BA
		mov	[ds:0474h], dl
		mov	[ds:0475h], dh
		and	cl, 3Fh
		mov	[ds:0476h], cl
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
		lea	bx, [newline] ; "\r\n\r\n"
		call	sub_10B
		mov	ah, 36h	; '6'
		mov	[byte ptr ds:0477h],	ah
		jmpfar 	0, 7C00h
; ---------------------------------------------------------------------------

loc_F0:					
		dec	si
		jz	short loc_F6
		jmp	loc_62
; ---------------------------------------------------------------------------

loc_F6:					
		lea	bx, [newline] ; "\r\n\r\n"
		call	sub_10B

loc_FD:					
		lea	bx, [byte_59A]

loc_101:				
		call	sub_10B
		mov	ah, 0
		int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
					; Return: AH = scan code, AL = character
		jmp	loc_53

; =============== S U B	R O U T	I N E =======================================


proc		sub_10B	near
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

locret_119:	
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
loc_15E:
		 cmp     ah, 3
		 jnz     short loc_168
		 mov     ah, 3
		 jmp     loc_2EA
; ---------------------------------------------------------------------------

loc_168:
		 cmp     ah, 0
		 jz      short loc_19A
		 cmp     ah, 1
		 jnz     short loc_179
		 mov     al, [ds:0441h]
		 clc
		 jmp     loc_2F4
; ---------------------------------------------------------------------------
loc_179:
		cmp	ah, 8
		jnz	short loc_19D
		cmp	dl, 80h	; '€'
		jz	short loc_18E
		mov	ah, 0
		mov	cx, 0
		mov	dx, 0
		jmp	far loc_2EA
; ---------------------------------------------------------------------------
loc_18E:
		mov	ah, 17h
		int	1Ah
		mov	dl, 1
		mov	ah, 0
		jnb	short loc_19A
		mov	ah, 80h	; '€'

loc_19A:
		jmp	far loc_2EA
; ---------------------------------------------------------------------------

loc_19D:
		cmp	ah, 15h
		jnz	short loc_1AF
		mov	ah, 0
		cmp	dl, 80h	; '€'
		jnz	short loc_1AB
		mov	ah, 3

loc_1AB:
		clc
		jmp	loc_2F4
; ---------------------------------------------------------------------------

loc_1AF:
		mov	ah, 1
		jmp	loc_2EA
; ---------------------------------------------------------------------------

loc_1B4:
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

loc_1C7:
		mov	di, [bp+6]
		lea	dx, [loc_238]
		push	dx

loc_1CF:
		mov	bl, [bp+4]
		cmp	bl, [ds:0474h]
		jbe	short loc_1DC
		mov	bl, [ds:0474h]

loc_1DC:
		cmp	[byte ptr bp+5], 33h ; '3'
		jnz	short loc_1E5
		jmp	loc_2F8
; ---------------------------------------------------------------------------

loc_1E5:
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

loc_233:
		mov	ah, 20h	; ' '
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_238:
		cmp	ah, 10h
		jnz	short loc_249
		mov	dx, 330h
		in	al, dx
		dec	byte ptr [bp+0Dh]
		jz	short loc_249
		jmp	loc_1C7
; ---------------------------------------------------------------------------

loc_249:
		push	dx

loc_24A:
		jmp	loc_2DE
; ---------------------------------------------------------------------------

loc_24D:
		test	ah, 2
		jnz	short loc_255
		jmp	loc_2DC
; ---------------------------------------------------------------------------

loc_255:
		mov	ah, 40h	; '@'
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_259:
		mov	bh, 0FFh
		call	loc_420
		mov	bh, 80h	; '€'

loc_260:
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_279
		cmp	cx, [ds:046Ch]
		jns	short loc_260
		and	al, 3
		cmp	al, 1
		jz	short loc_275
		mov	ah, 80h	; '€'
		jmp	short loc_24A
; ---------------------------------------------------------------------------

loc_275:
		mov	ah, 10h
		jmp	short loc_238
; ---------------------------------------------------------------------------

loc_279:
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

loc_28D:
		mov	ah, [ds:0474h]
		sub	[bp+4],	ah
		jbe	short loc_2DC
		mov	al, [bp+2]
		mov	bl, al
		and	al, 3Fh
		and	bl, 0C0h
		add	al, ah
		cmp	al, [ds:0476h]
		jbe	short loc_2D4
		sub	al, [ds:0476h]
		or	al, bl
		mov	[bp+2],	al
		inc	byte ptr [bp+1]
		mov	ah, [bp+1]
		cmp	ah, [ds:0475h]
		jbe	short loc_2CA
		mov	[byte ptr bp+1], 0
		inc	byte ptr[bp+3]
		jnz	short loc_2CA
		add	byte ptr [bp+2], 40h ; '@'

loc_2CA:
		mov	[bp+6],	di
		mov	[byte ptr bp+0Dh], 3
		jmp	loc_1CF
; ---------------------------------------------------------------------------

loc_2D4:
		or	al, bl
		mov	[bp+2],	al
		jmp	loc_1CF
; ---------------------------------------------------------------------------

loc_2DC:
		mov	ah, 0

loc_2DE:
		add	sp, 0Ah
		pop	dx
		pop	cx
		pop	bx
		mov	al, bl
		pop	bx
		pop	bp
		pop	di
		pop	si

loc_2EA:
		mov	[ds:0441h], ah
		cmp	ah, 0
		jz	short loc_2F4
		stc

loc_2F4:				
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_2F8:				
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

loc_31A:				
		jmp	loc_24A
; ---------------------------------------------------------------------------

loc_31D:				
		test	ah, 1
		jnz	short loc_326
		mov	ah, 0FFh
		jmp	short loc_31A
; ---------------------------------------------------------------------------

loc_326:				
		mov	si, 0
		shl	bl, 1
		shl	bl, 1

loc_32D:				
		mov	bh, 7Fh	; ''
		call	loc_420
		xor	ah, ah
		mov	bh, 80h	; '€'

loc_336:	
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_350
		cmp	cx, [ds:046Ch]
		jns	short loc_336
		and	al, 3
		cmp	al, 1
		jz	short loc_34B
		mov	ah, 80h	; '€'
		jmp	short loc_31A
; ---------------------------------------------------------------------------

loc_34B:
		mov	ah, 10h
		jmp	loc_238
; ---------------------------------------------------------------------------

loc_350:
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
		cmp	ah, [ds:0474h]
		jbe	short loc_37E
		mov	ah, [ds:0474h]

loc_37E:
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

loc_3CC:
		jmp	loc_31A
; ---------------------------------------------------------------------------

loc_3CF:
		test	ah, 2
		jz	short loc_3D8
		mov	ah, 4
		jmp	short loc_3CC
; ---------------------------------------------------------------------------

loc_3D8:
		jmp	loc_28D
; ---------------------------------------------------------------------------

loc_3DB:
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

loc_408:
		test	ah, 1
		mov	ah, 0
		jz	short loc_411

loc_40F:
		mov	ah, 0FFh

loc_411:
		clc

loc_412:
		pop	dx

loc_413:
		pop	dx
		pop	cx
		pop	bx
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_41A:
		mov	dx, 330h
		in	al, dx
		jmp	short loc_413
; ---------------------------------------------------------------------------

loc_420:
		mov	dx, 332h
		mov	cx, [ds:046Ch]
		add	cx, 2

loc_42A:
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
		stc
		retn
; ---------------------------------------------------------------------------

loc_443:
		cmp	cx, [ds:046Ch]
		jns	short loc_42A
		add	cx, [ds:0477h]
		
loc_44D:
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

loc_462:
		test	ah, 20h
		jz	short loc_468
		in	al, dx

loc_468:	
		inc	dx
		inc	dx
                                
		mov     ax, [word ptr ds:046Ch]

loc_46D:                            
		 cmp     ax, [word ptr ds:046Ch]
		 jz      short loc_46D

loc_473:                                
		 cmp     cx, [word ptr ds:046Ch]

loc_477:                                
		 jns     short loc_44D
		 jmp     short loc_494
		 
 ; ---------------------------------------------------------------------------

loc_47C:			
		add	cx, [ds:0477h]

loc_480:		
		dec	dx
		dec	dx
		mov	al, bh
		out	dx, al
		inc	dx
		inc	dx

loc_487:			
		in	al, dx
		and	al, 3
		cmp	al, 2
		jz	short locret_49A
		cmp	cx, [ds:046Ch]
		jns	short loc_487

loc_494:			
		mov	ah, 80h	; '€'
		add	sp, 2
		stc

locret_49A:			
		retn

; =============== S U B	R O U T	I N E =======================================


proc		sub_49B	near	
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
;04B2 
		db 0FFh
		db 0FFh
		db  81h ; Á
		db  85h ; Å
		db  89h ; É
		db  91h ; Ñ
		db  88h ; È
		db  8Ah ; Ê
		db  2Dh ; -
		db  8Ah ; Ê
; ---------------------------------------------------------------------------

loc_4BC:	
		cmp	cx, [ds:046Ch]
		jns	short sub_49B
		mov	ah, 80h	; '€'

loc_4C4:	
		add	sp, 2
		stc

locret_4C8:	
		retn
endp		sub_49B	; sp-analysis failed


; =============== S U B	R O U T	I N E =======================================


proc		sub_4C9	near
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_4E5
		cmp	cx, [ds:046Ch]
		jns	short sub_4C9
		and	al, 3
		cmp	al, 1
		jz	short loc_4E1
		mov	ah, 80h	; '€'

loc_4DC:
		add	sp, 2
		stc
		retn
; ---------------------------------------------------------------------------

loc_4E1:				
		mov	ah, 10h
		jmp	short loc_4DC
; ---------------------------------------------------------------------------

loc_4E5:
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


proc		sub_4EE	near
		in	al, dx
		cmp	al, 0A2h ; '¢'
		jz	short loc_50A
		cmp	cx, [ds:046Ch]
		jns	short sub_4EE
		and	al, 3
		cmp	al, 1
		jz	short loc_506
		mov	ah, 80h	; '€'

loc_501:
		add	sp, 2
		stc
		retn
; ---------------------------------------------------------------------------

loc_506:
		mov	ah, 10h
		jmp	short loc_501
; ---------------------------------------------------------------------------

loc_50A:
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

loc_51C:
		cmp	ah, 2
		jz	short loc_52B
		cmp	ah, 4
		jz	short loc_52B
		int	5Ah		; Cluster adapter BIOS entry address
		retf	2
; ---------------------------------------------------------------------------

loc_52B:
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

loc_561:
		pop	bx
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_566:
		mov	dx, 330h
		in	al, dx
		jmp	short loc_561
; ---------------------------------------------------------------------------
aRLinkNetworkBi	db 'R-LINK Network BIOS V1.00',0Dh,0Ah ; DATA XREF: seg000:loc_58o
		db '(C) SPIKA 1990'
newline	db 0Dh,0Ah
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
