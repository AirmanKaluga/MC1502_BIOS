;---------------------------------------------------------------------------------------------------
; Interrupt 9h - IRQ1
;---------------------------------------------------------------------------------------------------
proc		int_09h near
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
endp 		int_09h




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
                call	int_09a		;  - IRQ1 - KEYBOARD INTERRUPT
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
                call	int_09a		;  - IRQ1 - KEYBOARD INTERRUPT
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

proc		int_09a
                sti
                push	ax
                push	bx
                push	cx
                push	dx
                push	si
                push	di
                push	ds
                push	es
                cld
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                in	al, 60h		; 8042 keyboard	controller data	register
                mov	ah, al
                cmp	al, 0FFh
                jnz	short loc_FE9A1
                jmp	loc_FEC0F
; ---------------------------------------------------------------------------

loc_FE9A1:				; ...
                and	al, 7Fh
                push	cs
                pop	es
                assume es:nothing
                mov	di, offset unk_FE882
                mov	cx, 8
                repne scasb
                mov	al, ah
                jz	short loc_FE9B4
                jmp	loc_FEA3B
; ---------------------------------------------------------------------------

loc_FE9B4:				; ...
                sub	di, offset unk_FE883
                mov	ah, cs:data_31[di]
                test	al, 80h
                jnz	short loc_FEA14
                cmp	ah, 10h
                jnb	short loc_FE9CD
                or	[ds:keybd_flags_1_], ah
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FE9CD:				; ...
                test	[byte ptr ds:keybd_flags_1_], 4
                jnz	short loc_FEA3B
                cmp	al, 52h

loc_FE9D6:
                jnz	short loc_FE9FC
                test	[byte ptr ds:keybd_flags_1_], 8
                jz	short loc_FE9E1
                jmp	short loc_FEA3B
; ---------------------------------------------------------------------------

loc_FE9E1:				; ...
                test	[byte ptr ds:keybd_flags_1_], 20h
                jnz	short loc_FE9F5
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FE9FC

loc_FE9EF:				; ...
                mov	ax, 5230h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FE9F5:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FE9EF

loc_FE9FC:				; ...
                test	[ds:keybd_flags_2_], ah
                jnz	short loc_FEA4F
                or	[ds:keybd_flags_2_], ah
                xor	[ds:keybd_flags_1_], ah
                cmp	al, 52h
                jnz	short loc_FEA4F
                mov	ax, 5200h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEA14:				; ...
                cmp	ah, 10h
                jnb	short loc_FEA33
                not	ah
                and	[ds:keybd_flags_1_], ah
                cmp	al, 0B8h
                jnz	short loc_FEA4F
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0
                mov	[ds:keybd_alt_num_], ah
                cmp	al, 0
                jz	short loc_FEA4F
                jmp	loc_FEBD0
; ---------------------------------------------------------------------------

loc_FEA33:				; ...
                not	ah
                and	[ds:keybd_flags_2_], ah
                jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEA3B:				; ...
                cmp	al, 80h
                jnb	short loc_FEA4F
                test	[byte ptr ds:keybd_flags_2_], 8
                jz	short loc_FEA59
                cmp	al, 45h
                jz	short loc_FEA4F
                and	[byte ptr ds:keybd_flags_2_], 0F7h

loc_FEA4F:				; ...
                cli

loc_FEA50:				; ...
                pop	es
                assume es:nothing
                pop	ds
                assume ds:nothing
                pop	di
                pop	si
                pop	dx
                pop	cx
                pop	bx
                pop	ax
                ret

endp		int_09a
; ---------------------------------------------------------------------------

loc_FEA59:				; ...
                test	[byte ptr ds:keybd_flags_1_], 8
                jnz	short loc_FEA63
                jmp	loc_FEAF2
; ---------------------------------------------------------------------------

loc_FEA63:				; ...
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short near ptr unk_FEA9B
                cmp	al, 53h
                jnz	short near ptr unk_FEA9B
                mov	[word ptr ds:warm_boot_flag_], 1234h
                jmp	warm_boot
; ---------------------------------------------------------------------------
unk_FEA77	db  52h	; R		; ...
unk_FEA78	db  4Fh	; O		; ...
                db  50h	; P
                db  51h	; Q
                db  4Bh	; K
                db  4Ch	; L
                db  4Dh	; M
                db  47h	; G
                db  48h	; H
                db  49h	; I
                db  10h
                db  11h
                db  12h
                db  13h
                db  14h
                db  15h
                db  16h
                db  17h
                db  18h
                db  19h
                db  1Eh
                db  1Fh
                db  20h
                db  21h	; !
                db  22h	; "
                db  23h	; #
                db  24h	; $
                db  25h	; %
                db  26h	; &
                db  2Ch	; ,
                db  2Dh	; -
                db  2Eh	; .
                db  2Fh	; /
                db  30h	; 0
                db  31h	; 1
                db  32h	; 2
; ---------------------------------------------------------------------------
unk_FEA9B:
		cmp	al,39h   ; '9'
		jne	loc_EAA4 ; Jump if not equal
                mov	al, 20h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------
loc_EAA4:
                mov	di, offset unk_FEA77
                mov	cx, 0Ah
                repne scasb
                jnz	short loc_FEAC0
                sub	di, offset unk_FEA78
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0Ah
                mul	ah
                add	ax, di
                mov	[ds:keybd_alt_num_], al
                jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEAC0:				; ...
                mov	[byte ptr ds:keybd_alt_num_], 0
                mov	cx, 1Ah
                repne scasb
                jnz	short loc_FEAD1
                mov	al, 0
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEAD1:				; ...
                cmp	al, 2
                jb	short loc_FEAE1
                cmp	al, 0Eh
                jnb	short loc_FEAE1
                add	ah, 76h
                mov	al, 0
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEAE1:				; ...
                cmp	al, 3Bh
                jnb	short loc_FEAE8

loc_FEAE5:				; ...
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEAE8:				; ...
                cmp	al, 47h
                jnb	short loc_FEAE5
                mov	bx, offset unk_FE963
                jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEAF2:				; ...
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short loc_FEB53
                cmp	al, 46h
                jnz	short loc_FEB15
                mov	bx, 1Eh
                mov	[ds:keybd_q_head_], bx
                mov	[ds:keybd_q_tail_], bx
                mov	[byte ptr ds:keybd_break_], 80h
                int	1Bh		; CTRL-BREAK KEY
                mov	ax, 0
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB15:				; ...
                cmp	al, 45h
                jnz	short loc_FEB3A
                or	[byte ptr ds:keybd_flags_2_], 8
                mov	al, 20h
                out	20h, al		; Interrupt controller,	8259A.
                cmp	[byte ptr ds:video_mode_], 7
                jz	short loc_FEB30
                mov	dx, 3D8h
                mov	al, [ds:video_mode_reg_]
                out	dx, al

loc_FEB30:				; ...
                test	[byte ptr ds:keybd_flags_2_], 8
                jnz	short loc_FEB30
                jmp	loc_FEA50
; ---------------------------------------------------------------------------

loc_FEB3A:				; ...
                cmp	al, 37h
                jnz	short loc_FEB44
                mov	ax, 7200h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB44:				; ...
                mov	bx, offset unk_FE892
                cmp	al, 3Bh
                jnb	short loc_FEB4D
                jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEB4D:				; ...
                mov	bx, offset unk_FE8CC
                jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEB53:				; ...
                cmp	al, 47h
                jnb	short loc_FEB83
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FEBB8
                cmp	al, 0Fh
                jnz	short loc_FEB67
                mov	ax, 0F00h
                jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB67:				; ...
                cmp	al, 37h
                jnz	short loc_FEB74
                mov	al, 20h
                out	20h, al		; Interrupt controller,	8259A.
                int	5		;  - PRINT-SCREEN KEY
                                        ; automatically	called by keyboard scanner when	print-screen key is pressed
                jmp	loc_FEA50
; ---------------------------------------------------------------------------

loc_FEB74:				; ...
                cmp	al, 3Bh
                jb	short loc_FEB7E
                mov	bx, offset unk_FE959
                jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEB7E:				; ...
                mov	bx, offset unk_FE91F
                jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEB83:				; ...
                test	[byte ptr ds:keybd_flags_1_], 20h
                jnz	short loc_FEBAA
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FEBB1

loc_FEB91:				; ...
                cmp	al, 4Ah
                jz	short loc_FEBA0
                cmp	al, 4Eh
                jz	short loc_FEBA5
                sub	al, 47h
                mov	bx, offset unk_FE97A
                jmp	loc_FEC17
; ---------------------------------------------------------------------------

loc_FEBA0:				; ...
                mov	ax, 4A2Dh
                jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBA5:				; ...
                mov	ax, 4E2Bh
                jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBAA:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FEB91

loc_FEBB1:				; ...
                sub	al, 46h
                mov	bx, offset unk_FE96D
                jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEBB8:				; ...
                cmp	al, 3Bh
                jb	short loc_FEBC0
                mov	al, 0
                jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBC0:				; ...
                mov	bx, offset unk_FE8E5

loc_FEBC3:				; ...
                dec	al
                xlat	[byte ptr cs:bx]

loc_FEBC7:				; ...
                cmp	al, 0FFh
                jz	short loc_FEBEA
                cmp	ah, 0FFh
                jz	short loc_FEBEA

loc_FEBD0:				; ...
                test	[byte ptr ds:keybd_flags_1_], 40h
                jz	short loc_FEBF7
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FEBED
                cmp	al, 41h
                jb	short loc_FEBF7
                cmp	al, 5Ah
                ja	short loc_FEBF7
                add	al, 20h
                jmp	short loc_FEBF7
; ---------------------------------------------------------------------------

loc_FEBEA:				; ...
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEBED:				; ...
                cmp	al, 61h
                jb	short loc_FEBF7
                cmp	al, 7Ah
                ja	short loc_FEBF7
                sub	al, 20h

loc_FEBF7:				; ...
                mov	bx, [ds:keybd_q_tail_]
                mov	si, bx
                call	sub_FE875
                cmp	bx, [ds:keybd_q_head_]
                jz	short loc_FEC0F
                mov	[si], ax
                mov	[ds:keybd_q_tail_], bx
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEC0F:				; ...
                call	loc_FEC1F
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEC15:				; ...
                sub	al, 3Bh

loc_FEC17:				; ...
                xlat	[byte ptr cs:bx]
                mov	ah, al
                mov	al, 0
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEC1F:				; ...
                push	ax
                push	bx
                push	cx
                mov	bx, 0C0h
                in	al, 61h		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                push	ax

loc_FEC28:				; ...
                and	al, 0FCh
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                mov	cx, 48h

loc_FEC2F:				; ...
                loop	loc_FEC2F
                or	al, 2
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                mov	cx, 48h

loc_FEC38:				; ...
                loop	loc_FEC38
                dec	bx
                jnz	short loc_FEC28
                pop	ax
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                pop	cx
                pop	bx
                pop	ax
                retn
