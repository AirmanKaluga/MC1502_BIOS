;---------------------------------------------------------------------------------------------------
; Interrupt 13h - Floppydisk
;---------------------------------------------------------------------------------------------------
proc		int_13h	near
                cld
                sti
                push	bx
                push	cx
                push	dx
                push	si
                push	di
                push	ds
                push	es
                mov	si, BDAseg
                mov	ds, si
                assume ds:nothing
                call	sub_FEC85
                mov	ah, [cs:MotorOff]
                mov	[ds:dsk_motor_tmr], ah
                mov	ah, [ds:dsk_ret_code_]
                cmp	ah, 1
                cmc
                pop	es
                pop	ds
                assume ds:nothing
                pop	di
                pop	si
                pop	dx
                pop	cx
                pop	bx
                retf	2
endp		int_13h




proc		sub_FEC85 near		; ...
                push	dx
                call	sub_FECC2
                pop	dx
                mov	bx, dx
                and	bx, 1
                mov	ah, [ds:dsk_ret_code_]
                cmp	ah, 40h
                jz	short loc_FECBA
                cmp	ax, 400h
                jnz	short locret_FECC1
                call	sub_FE36C
                jz	short loc_FECBA
                mov	al, [bx+90h]
                mov	ah, 0
                test	al, 0C0h
                jnz	short loc_FECAE
                mov	ah, 80h

loc_FECAE:				; ...
                and	al, 3Fh
                or	al, ah
                mov	[bx+90h], al
                mov	al, 0
                jmp	short locret_FECC1
; ---------------------------------------------------------------------------

loc_FECBA:				; ...
                xor	[byte ptr bx+90h], 20h
                mov	al, 0

locret_FECC1:				; ...
                retn
endp		sub_FEC85





proc		sub_FECC2 near		; ...

                and	[byte ptr ds:dsk_motor_stat], 7Fh
                or	ah, ah
                jz	short loc_FED01
                dec	ah
                jz	short loc_FED31
                mov	[byte ptr ds:dsk_ret_code_], 0
                cmp	dl, 1
                ja	short loc_FECFB
                dec	ah
                jz	short loc_FED43
                dec	ah
                jz	short loc_FED3E
                dec	ah
                jz	short loc_FED35
                dec	ah
                jnz	short loc_FECEC
                jmp	loc_FEE0E
; ---------------------------------------------------------------------------

loc_FECEC:				; ...
                sub	ah, 12h
                jnz	short loc_FECF4
                jmp	loc_FEF0A
; ---------------------------------------------------------------------------

loc_FECF4:				; ...
                dec	ah
                jnz	short loc_FECFB
                jmp	loc_FEF26
; ---------------------------------------------------------------------------

loc_FECFB:				; ...
                mov	[byte ptr ds:dsk_ret_code_], 1
                retn
; ---------------------------------------------------------------------------

loc_FED01:				; ...
                mov	al, 0
                mov	[ds:3Eh], al
                mov	[ds:dsk_ret_code_], al
                mov	ah, [ds:dsk_motor_stat]
                test	ah, 3
                jz	short loc_FED1A
                mov	al, 4
                shr	ah, 1
                jb	short loc_FED1A
                mov	al, 18h

loc_FED1A:				; ...
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_2]
                out	dx, al
                inc	ax
                out	dx, al
                mov	dl, [ds:dsk_status_1]
                mov	al, 0D0h
                out	dx, al
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                retn
; ---------------------------------------------------------------------------

loc_FED31:				; ...
                mov	al, [ds:dsk_ret_code_]
                retn
; ---------------------------------------------------------------------------

loc_FED35:				; ...
                mov	bx, 0FC00h
                mov	es, bx
                assume es:nothing
                mov	bh, bl
                jmp	short loc_FED43
; ---------------------------------------------------------------------------

loc_FED3E:				; ...
                or	[byte ptr ds:dsk_motor_stat], 80h

loc_FED43:				; ...
                call	sub_FE3C3
                push	bx
                mov	bl, 15h
                call	sub_FE2EF
                pop	bx
                jnb	short loc_FED52
                xor	al, al
                retn
; ---------------------------------------------------------------------------

loc_FED52:				; ...
                call	sub_FE452
                mov	ch, al
                xor	ah, ah
                call	sub_FE2D3
                mov	cl, [ds:dsk_status_1]
                add	cl, 3
                test	[byte ptr ds:dsk_motor_stat], 80h
                jnz	short loc_FED9E

loc_FED6A:				; ...
                mov	di, bx
                mov	al, 80h
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                mov	dl, [ds:dsk_status_3]
                jmp	short loc_FED7A
; ---------------------------------------------------------------------------

loc_FED79:				; ...
                stosb

loc_FED7A:				; ...
                in	al, dx
                shr	al, 1
                xchg	dl, cl
                in	al, dx
                xchg	dl, cl
                jb	short loc_FED79
                mov	bx, di
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 1Fh
                jnz	short loc_FEDD7
                inc	ah
                call	sub_FEE04
                cmp	ch, ah
                jnz	short loc_FED6A
                mov	al, ah
                call	sub_FE483
                retn
; ---------------------------------------------------------------------------

loc_FED9E:				; ...
                push	ds
                mov	al, 0A0h
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                mov	dl, [ds:dsk_status_3]
                mov	si, es
                mov	ds, si
                assume ds:nothing
                mov	si, bx

loc_FEDB0:				; ...
                in	al, dx
                shr	al, 1
                lodsb
                xchg	dl, cl
                out	dx, al
                xchg	dl, cl
                jb	short loc_FEDB0
                dec	si
                mov	bx, si
                pop	ds
                assume ds:nothing
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 5Fh
                jnz	short loc_FEDD7
                inc	ah
                call	sub_FEE04
                cmp	ch, ah
                jnz	short loc_FED9E
                mov	al, ah
                call	sub_FE483
                retn
; ---------------------------------------------------------------------------

loc_FEDD7:				; ...
                call	sub_FE483
                mov	bh, ah
                test	[byte ptr ds:dsk_motor_stat], 80h
                jz	short loc_FEDE9
                test	al, 40h
                mov	ah, 3
                jnz	short loc_FEDFD

loc_FEDE9:				; ...
                test	al, 10h
                mov	ah, 4
                jnz	short loc_FEDFD
                test	al, 8
                mov	ah, 10h
                jnz	short loc_FEDFD
                test	al, 1
                mov	ah, 80h
                jnz	short loc_FEDFD
                mov	ah, 20h

loc_FEDFD:				; ...
                or	[ds:dsk_ret_code_], ah
                mov	al, bh
                retn
endp		sub_FECC2





proc		sub_FEE04 near		; ...
                mov	dl, [ds:dsk_status_1]
                inc	dx
                inc	dx
                in	al, dx
                inc	ax
                out	dx, al
                retn
endp		sub_FEE04

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_FECC2

loc_FEE0E:				; ...
                push	bx
                or	[byte ptr ds:dsk_motor_stat], 80h
                call	sub_FE3C3
                mov	bl, 11h
                call	sub_FE2EF
                pop	si
                jnb	short loc_FEE20
                retn
; ---------------------------------------------------------------------------

loc_FEE20:				; ...
                push	ax
                push	bp
                mov	ah, al
                xor	bx, bx
                mov	ds, bx
                lds	bx, [ds:prn_timeout_1_]
                mov	di, [bx+7]
                mov	bx, BDAseg
                mov	ds, bx
                assume ds:nothing
                call	sub_FE452
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_3]
                mov	bp, dx
                mov	dl, [ds:dsk_status_1]
                mov	al, 0F0h
                out	dx, al
                add	dl, 3
                test	[byte ptr ds:dsk_motor_stat], 20h
                jz	short loc_FEE60
                lods	[word ptr es:si]
                xchg	ax, cx

loc_FEE54:				; ...
                xchg	bp, dx
                in	al, dx
                lods	[byte ptr es:si]
                xchg	bp, dx
                out	dx, al
                loop	loc_FEE54
                jmp	short loc_FEEB1
; ---------------------------------------------------------------------------

loc_FEE60:				; ...
                mov	bx, offset unk_FEEEB
                mov	ch, 5
                call	sub_FEED3

loc_FEE68:				; ...
                mov	bx, offset unk_FEEF5
                mov	ch, 3
                call	sub_FEED3
                mov	cx, 4

loc_FEE73:				; ...
                xchg	bp, dx
                in	al, dx
                lods	[byte ptr es:si]
                xchg	bp, dx
                out	dx, al
                loop	loc_FEE73
                push	ax
                mov	ch, 5
                call	sub_FEED3
                pop	cx
                mov	bx, 80h
                shl	bx, cl
                mov	cx, bx
                mov	bx, di

loc_FEE8D:				; ...
                xchg	bp, dx
                in	al, dx
                mov	al, bh
                xchg	bp, dx
                out	dx, al
                loop	loc_FEE8D
                xchg	bp, dx
                in	al, dx
                mov	al, 0F7h
                xchg	bp, dx
                out	dx, al
                mov	cx, di
                xor	ch, ch

loc_FEEA3:				; ...
                xchg	bp, dx
                in	al, dx
                mov	al, 4Eh
                xchg	bp, dx
                out	dx, al
                loop	loc_FEEA3
                dec	ah
                jnz	short loc_FEE68

loc_FEEB1:				; ...
                xchg	bp, dx
                in	al, dx
                xchg	bp, dx
                shr	al, 1
                mov	al, 4Eh
                out	dx, al
                jb	short loc_FEEB1
                pop	bp
                pop	cx
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 47h
                jz	short loc_FEECD
                sub	ah, ah
                jmp	loc_FEDD7
; ---------------------------------------------------------------------------

loc_FEECD:				; ...
                call	sub_FE483
                mov	al, cl
                retn
; END OF FUNCTION CHUNK	FOR sub_FECC2




proc		sub_FEED3 near		; ...
                mov	cl, [cs:bx+1]

loc_FEED7:				; ...
                xchg	bp, dx
                in	al, dx
                mov	al, [cs:bx]
                xchg	bp, dx
                out	dx, al
                dec	cl
                jnz	short loc_FEED7
                inc	bx
                inc	bx
                dec	ch
                jnz	short sub_FEED3
                retn
endp		sub_FEED3

; ---------------------------------------------------------------------------
unk_FEEEB	db  4Eh	; N		; ...
                db  10h
                db    0
                db  0Ch
                db 0F6h	; ?
                db    3
                db 0FCh	; ?
                db    1
                db  4Eh	; N
                db  32h	; 2
unk_FEEF5	db    0			; ...
                db  0Ch
                db 0F5h	; ?
                db    3
                db 0FEh	; ?
                db    1
                db 0F7h	; ?
                db    1
                db  4Eh	; N
                db  16h
                db    0
                db  0Ch
                db 0F5h	; ?
                db    3
                db 0FBh	; ?
                db    1

data_37	db  93h	; ?
                db  74h	; t
                db  15h
                db  97h	; ?
                db  17h
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_FECC2

loc_FEF0A:				; ...
                dec	ax
                cmp	al, 5
                jb	short loc_FEF12
                jmp	loc_FECFB
; ---------------------------------------------------------------------------

loc_FEF12:				; ...
                mov	bx, ax
                and	bx, 7
                mov	al, data_37[bx]

loc_FEF1C:
                mov	bx, dx
                and	bx, 1
                mov	[bx+90h], al
                retn
; ---------------------------------------------------------------------------

loc_FEF26:				; ...
                mov	al, 2
                cmp	cx, 2709h
                jz	short loc_FEF12
                inc	ax
                cmp	cx, 4F0Fh
                jz	short loc_FEF12
                inc	ax
                cmp	cx, 4F09h
                jz	short loc_FEF12
                inc	ax
                cmp	cx, 4F12h
                jz	short loc_FEF12
                jmp	loc_FECFB

; ---------------------------------------------------------------------------
unk_FEF46:
                db  24h	; $		; ...
                db  78h	; x
; ---------------------------------------------------------------------------
                mov	cl, 3
                shr	al, cl
                mov	bx, offset unk_FEF97
                xlat	[byte ptr cs:bx]
                mov	ah, al
                dec	dx
                in	al, dx
                inc	dx
                mov	bl, al
                mov	al, 37h
                out	dx, al
                mov	al, bl
                jmp	loc_FE7F3




proc		sub_FEF60 near		; ...
                mov	cx, 14h

loc_FEF63:				; ...
                loop	loc_FEF63
                retn
endp		sub_FEF60

; ---------------------------------------------------------------------------

loc_FEF66:				; ...
                inc	dx
                in	al, dx
                mov	ch, al
                mov	cl, 2
                shr	ch, cl
                and	ch, 20h
                mov	bx, offset unk_FEF8F
                mov	ah, al
                and	al, 7
                xlat	[byte ptr cs:bx]
                xchg	ah, al
                mov	cl, 3
                shr	al, cl
                and	al, 0Fh
                mov	bx, offset unk_FEF97
                xlat	[byte ptr cs:bx]
                or	ah, al
                inc	dx
                mov	al, 0F0h
                jmp	loc_FE7F3
; ---------------------------------------------------------------------------
unk_FEF8F:
                db    0	;
                db  20h ;
                db    1 ;
                db  21h	;
                db  40h	;
                db  60h	;
                db  41h	;
                db  61h	;
unk_FEF97:
                db    0	;
                db    4
                db    2
                db    6
                db    8
                db  0Ch
                db  0Ah
                db  0Eh
                db  10h
                db  14h
                db  12h
                db  16h
                db  18h
                db  1Ch
                db  1Ah
                db  1Eh
                db  32 dup (0)
