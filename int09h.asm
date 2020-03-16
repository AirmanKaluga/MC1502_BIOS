;---------------------------------------------------------------------------------------------------
; Interrupt 09h - keyaboard IRQ1
;---------------------------------------------------------------------------------------------------
proc		int_09h
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
                iret

endp		int_09h
; ---------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------------------