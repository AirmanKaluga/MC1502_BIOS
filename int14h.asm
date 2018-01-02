;---------------------------------------------------------------------------------------------------
; Interrupt 14h - RS232
;---------------------------------------------------------------------------------------------------
proc		int_14h
                sti
                push	bx
                push	cx
                push	dx
                mov	dx, 28h
                or	ah, ah
                jnz	short loc_FE7BA
                push	ax
                mov	ah, al
                mov	al, 76h
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                xor	bx, bx
                mov	bl, ah
                mov	cl, 4
                rol	bl, cl
                and	bl, 0Eh
                mov	ax, cs:baud[bx]
                out	41h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, ah
                out	41h, al		; Timer	8253-5 (AT: 8254.2).
                inc	dx
                mov	al, 65h
                out	dx, al
                call	sub_FEF60
                mov	al, 5
                out	dx, al
                call	sub_FEF60
                mov	al, 65h
                out	dx, al
                call	sub_FEF60
                pop	ax
                or	ah, 4Ah
                test	al, 1
                jz	short loc_FE798
                or	ah, 4

loc_FE798:				; ...
                test	al, 4
                jz	short loc_FE79F
                or	ah, 80h

loc_FE79F:				; ...
                test	al, 8
                jz	short loc_FE7AD
                or	ah, 10h
                test	al, 10h
                jz	short loc_FE7AD
                or	ah, 20h

loc_FE7AD:				; ...
                mov	al, ah
                out	dx, al
                call	sub_FEF60
                mov	al, 27h
                out	dx, al
                dec	dx
                jmp	loc_FEF66
; ---------------------------------------------------------------------------

loc_FE7BA:				; ...
                dec	ah
                jz	short loc_FE7CC
                dec	ah
                jz	short loc_FE7F7
                dec	ah
                jnz	short loc_FE7C9
                jmp	loc_FEF66
; ---------------------------------------------------------------------------

loc_FE7C9:				; ...
                jmp	short loc_FE7F3
; ---------------------------------------------------------------------------
loc_FE7CC:				; ...
                mov	ah, 0
                push	ax
                inc	dx
                mov	al, 27h
                out	dx, al
                xor	cx, cx

loc_FE7D5:				; ...
                in	al, dx
                test	al, 80h
                jnz	short loc_FE7DF
                loop	loc_FE7D5
                pop	ax
                jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE7DF:				; ...
                xor	cx, cx

loc_FE7E1:				; ...
                in	al, dx
                test	al, 1
                jnz	short loc_FE7EB
                loop	loc_FE7E1
                pop	ax
                jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE7EB:				; ...
                dec	dx
                pop	ax
                out	dx, al
                jmp	short loc_FE7F3
; ---------------------------------------------------------------------------

loc_FE7F0:				; ...
                or	ah, 80h

loc_FE7F3:				; ...
                pop	dx
                pop	cx
                pop	bx
                iret
endp		int_14h
; ---------------------------------------------------------------------------

loc_FE7F7:				; ...
                mov	ah, 0
                xor	cx, cx
                inc	dx

loc_FE7FC:				; ...
                in	al, dx
                test	al, 4
                jnz	short loc_FE805
                loop	loc_FE7FC
                jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE805:				; ...
                mov	al, 27h
                out	dx, al
                xor	cx, cx

loc_FE80A:				; ...
                in	al, dx
                test	al, 80h
                jnz	short loc_FE813
                loop	loc_FE80A
                jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE813:				; ...
                xor	cx, cx

loc_FE815:				; ...
                in	al, dx
                test	al, 2
                jz	short loc_FE81D
                jmp	near  ptr loc_FEF46
; ---------------------------------------------------------------------------

loc_FE81D:				; ...
                loop	loc_FE815
                jmp	short loc_FE7F0

; ---------------------------------------------------------------------------
loc_FEF46:
                and	al, 78h		; ...
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
