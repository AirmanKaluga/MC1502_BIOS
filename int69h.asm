;---------------------------------------------------------------------------------------------------
; Interrupt 69h - Keyboard scan
;---------------------------------------------------------------------------------------------------
proc		int_69h near
                sti
                push	ax
                push	bx
                push	cx
                push	dx
                push	di
                push	bp
                push	ds
                mov	ax, BDAseg
                mov	ds, ax
                mov	bx, offset unk_FE58C
                mov	di, 0
                mov	bp, 0FFFEh

loc_FE4A4:				; ...
                mov	ax, bp
                out	69h, ax
                in	al, 68h
                mov	ah, al
                or	al, [di+93h]
                inc	al
                jz	short loc_FE4D2
                neg	al
                or	[di+93h], al
                call	sub_FE51F
                mov	[ds:0A0h], di
                mov	dl, 80h

loc_FE4C3:				; ...
                rol	dl, 1
                test	al, dl
                jz	short loc_FE4C3
                mov	[ds:0A2h], dl
                mov	[byte ptr ds:9Eh], 9

loc_FE4D2:				; ...
                mov	al, ah
                and	al, [di+93h]
                jz	short loc_FE4E1
                xor	[di+93h], al
                call	sub_FE54B

loc_FE4E1:				; ...
                inc	di
                rol	bp, 1
                test	bp, 800h
                jnz	short loc_FE4A4
                mov	di, [ds:0A0h]
                mov	al, [ds:0A2h]
                test	[di+93h], al
                jz	short loc_FE50F
                dec	[byte ptr ds:9Eh]
                jnz	short loc_FE50F
                mov	[byte ptr ds:9Eh], 1
                mov	dx, [ds:keybd_q_head_]
                cmp	dx, [ds:keybd_q_tail_]
                jnz	short loc_FE50F
                call	sub_FE51F

loc_FE50F:				; ...
                xor	ax, ax
                out	69h, ax
                mov	al, 20h
                out	20h, al		; Interrupt controller,	8259A.
                pop	ds
                assume ds:nothing
                pop	bp
                pop	di
                pop	dx
                pop	cx
                pop	bx
                pop	ax
                iret
endp 		int_69h




proc		sub_FE51F near		; ...
                push	ax
                mov	dx, di
                mov	cx, 803h
                mov	dh, al
                shl	dl, cl

loc_FE529:				; ...
                rcl	dh, 1
                jnb	short loc_FE545
                call	sub_FE571
                or	al, al
                jnz	short loc_FE541
                test	[byte ptr ds:9Fh], 80h
                jnz	short loc_FE545
                not	[byte ptr ds:9Fh]
                jmp	short loc_FE545
; ---------------------------------------------------------------------------

loc_FE541:				; ...
                out	60h, al		; 8042 keyboard	controller data	register.
                int	9		;  - IRQ1 - KEYBOARD INTERRUPT
                                        ; Generated when data is received from the keyboard.

loc_FE545:				; ...
                dec	ch
                jnz	short loc_FE529
                pop	ax
                retn
endp		sub_FE51F





proc		sub_FE54B near		; ...
                mov	dx, di
                mov	cx, 803h
                mov	dh, al
                shl	dl, cl

loc_FE554:				; ...
                rcl	dh, 1
                jnb	short loc_FE56C
                call	sub_FE571
                or	al, al
                jnz	short loc_FE566
                and	[byte ptr ds:9Fh], 7Fh
                jmp	short loc_FE56C
; ---------------------------------------------------------------------------

loc_FE566:				; ...
                or	al, 80h
                out	60h, al		; 8042 keyboard	controller data	register.
                int	9		;  - IRQ1 - KEYBOARD INTERRUPT
                                        ; Generated when data is received from the keyboard.

loc_FE56C:				; ...
                dec	ch
                jnz	short loc_FE554
                retn
endp		sub_FE54B





proc		sub_FE571 near		; ...
                mov	al, ch
                dec	al
                or	al, dl
                xlat	[byte ptr cs:bx]
                cmp	al, 55h
                jb	short locret_FE58B
                and	[byte ptr ds:keybd_flags_1_], 0DFh
                push	bx
                mov	bx, offset unk_FE5E4
                sub	al, 55h
                xlat	[byte ptr cs:bx]
                pop	bx

locret_FE58B:				; ...
                retn
endp		sub_FE571

; ---------------------------------------------------------------------------
unk_FE58C:
                db  4Ah	; J		; ...
                db  46h	; F
                db  44h	; D
                db  36h	; 6
                db  2Ah	; *
                db  47h	; G
                db  48h	; H
                db  49h	; I
                db    1
                db  0Fh
                db  1Dh
                db  38h	; 8
                db    0
                db  52h	; R
                db  53h	; S
                db  4Eh	; N
                db    2
                db  10h
                db  1Eh
                db  2Ch	; ,
                db  3Ah	; :
                db  4Fh	; O
                db  50h	; P
                db  51h	; Q
                db  3Bh	; ;
                db    3
                db  11h
                db  1Fh
                db  2Dh	; -
                db  4Bh	; K
                db  4Ch	; L
                db  4Dh	; M
                db  3Ch	; <
                db    4
                db  12h
                db  20h
                db  2Eh	; .
                db  45h	; E
                db  42h	; B
                db  43h	; C
                db  3Dh	; =
                db    5
                db  13h
                db  21h	; !
                db  2Fh	; /
                db  0Eh
                db  41h	; A
                db  40h	; @
                db    6
                db  14h
                db  22h	; "
                db  30h	; 0
                db  39h	; 9
                db  55h	; U
                db  1Ch
                db  37h	; 7
                db  3Eh	; >
                db    7
                db  15h
                db  23h	; #
                db  31h	; 1
                db  57h	; W
                db  58h	; X
                db  2Bh	; +
                db  3Fh	; ?
                db    8
                db  16h
                db  24h	; $
                db  32h	; 2
                db  29h	; )
                db  1Bh
                db  0Dh
                db    9
                db  17h
                db  25h	; %
                db  33h	; 3
                db  56h	; V
                db  28h	; (
                db  1Ah
                db  0Ch
                db  0Ah
                db  18h
                db  26h	; &
                db  34h	; 4
                db  35h	; 5
                db  27h	; '
                db  19h
                db  0Bh
unk_FE5E4:
                db  4Dh	; M		; ...
                db  4Bh	; K
                db  50h	; P
                db  48h	; H




proc		sub_FE5E8 near		; ...
                call	sub_FE875
                test	[byte ptr ds:9Fh], 7Fh
                jz	short locret_FE655
                test	[byte ptr ds:keybd_flags_1_], 4
                jnz	short locret_FE655
                push	bx
                cmp	ah, 2
                jb	short loc_FE654
                cmp	ah, 0Ch
                jb	short loc_FE644
                cmp	ah, 10h
                jb	short loc_FE654
                cmp	ah, 1Ch
                jb	short loc_FE61D
                cmp	ah, 1Eh
                jb	short loc_FE654
                cmp	ah, 2Ah
                jz	short loc_FE654
                cmp	ah, 35h
                jge	short loc_FE654

loc_FE61D:				; ...
                mov	al, ah
                sub	al, 10h
                test	[byte ptr ds:keybd_flags_1_], 40h
                jnz	short loc_FE636
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FE63D

loc_FE62F:				; ...
                mov	bx, offset unk_FE656
                xlat	[byte ptr cs:bx]
                jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE636:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FE62F

loc_FE63D:				; ...
                mov	bx, offset unk_FE689
                xlat	[byte ptr cs:bx]
                jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE644:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FE654
                mov	al, ah
                sub	al, 2
                mov	bx, offset unk_FE67B
                xlat	[byte ptr cs:bx]

loc_FE654:				; ...
                pop	bx

locret_FE655:				; ...
                retn
endp		sub_FE5E8

; ---------------------------------------------------------------------------
unk_FE656	db 0A9h	; ©		; ...
                db 0E6h	; ?
                db 0E3h	; ?
                db 0AAh	; ?
                db 0A5h	; ?
                db 0ADh	; ­
                db 0A3h	; ?
                db 0E8h	; ?
                db 0E9h	; ?
                db 0A7h	; §
                db 0E5h	; ?
                db 0EAh	; ?
                db    0
                db    0
                db 0E4h	; ?
                db 0EBh	; ?
                db 0A2h	; ?
                db 0A0h	;
                db 0AFh	; ?
                db 0E0h	; ?
                db 0AEh	; ®
                db 0ABh	; «
                db 0A4h	; ?
                db 0A6h	; ¦
                db 0EDh	; ?
                db 0F1h	; ?
                db    0
                db  5Bh	; [
                db 0EFh	; ?
                db 0E7h	; ?
                db 0E1h	; ?
                db 0ACh	; ¬
                db 0A8h	; ?
                db 0E2h	; ?
                db 0ECh	; ?
                db 0A1h	; ?
                db 0EEh	; ?
unk_FE67B	db  21h	; !		; ...
                db  22h	; "
                db  23h	; #
                db  3Bh	; ;
                db  3Ah	; :
                db  2Ch	; ,
                db  2Eh	; .
                db  2Ah	; *
                db  28h	; (
                db  29h	; )
                db    0
                db    0
                db    0
                db    0
unk_FE689	db  89h	; ?		; ...
                db  96h	; ?
                db  93h	; ?
                db  8Ah	; ?
                db  85h	; ?
                db  8Dh	; ?
                db  83h	; ?
                db  98h	; ?
                db  99h	; ?
                db  87h	; ?
                db  95h	; ?
                db  9Ah	; ?
                db    0
                db    0
                db  94h	; ?
                db  9Bh	; ?
                db  82h	; ?
                db  80h	; ?
                db  8Fh	; ?
                db  90h	; ?
                db  8Eh	; ?
                db  8Bh	; ?
                db  84h	; ?
                db  86h	; ?
                db  9Dh	; ?
                db 0F0h	; ?
                db    0
                db  5Dh	; ]
                db  9Fh	; ?
                db  97h	; ?
                db  91h	; ?
                db  8Ch	; ?
                db  88h	; ?
                db  92h	; ?
                db  9Ch	; ?
                db  81h	; ?
                db  9Eh	; ?
; ---------------------------------------------------------------------------