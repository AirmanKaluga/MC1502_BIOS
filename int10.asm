; ---------------------------------------------------------------------------
video_funcs:
                dw offset int_10_func_0 ; Set mode
                dw offset int_10_func_1 ; Set cursor type
                dw offset int_10_func_2 ; Set cursor position
                dw offset int_10_func_3 ; Get cursor position
                dw offset int10_end ; Read light pen position - not supported now
                dw offset int_10_func_5 ; Set active display page
                dw offset int_10_func_6 ; Scroll active page up
                dw offset int_10_func_7 ; Scroll active page down
                dw offset int_10_func_8 ; Read attribute/character
                dw offset int_10_func_9 ; Write attribute/character
                dw offset int_10_func_0A ; Write character only
                dw offset int_10_func_0B ; Set color
                dw offset int_10_func_0C ; Write pixel
                dw offset int_10_func_0D ; Read pixel
                dw offset int_10_func_0E ; Write teletype
                dw offset int_10_func_0F ; Return current video state
;---------------------------------------------------------------------------------------------------
; Interrupt 1Dh - Video Parameter Tables
;---------------------------------------------------------------------------------------------------
proc		int_1Dh	far

                db	38h, 28h, 2Dh, 0Ah, 1Fh, 6, 19h	; Init string for 40x25 color
                db	1Ch, 2, 7, 6, 7
                db	0, 0, 0, 0

                db	71h, 50h, 5Ah, 0Ah, 1Fh, 6, 19h	; Init string for 80x25 color
                db	1Ch, 2, 7, 6, 7
                db	0, 0, 0, 0

                db	38h, 28h, 2Dh, 0Ah, 7Fh, 6, 64h	; Init string for graphics
                db	70h, 2, 1, 6, 7
                db	0, 0, 0, 0

                db	61h, 50h, 52h, 0Fh, 19h, 6, 19h	; Init string for 80x25 b/w
                db	19h, 2, 0Dh, 0Bh, 0Ch
                db	0, 0, 0, 0

regen_len	dw	0800h			; Regen length, 40x25
                dw	1000h			;	        80x25
                dw	4000h			;	        graphics
                dw	4000h

max_cols	db	28h, 28h, 50h, 50h, 28h, 28h, 50h, 50h	; Maximum columns
video_hdwr_mode db	2Ch, 28h, 2Dh, 29h, 2Ah, 2Eh, 1Eh, 29h	; Table of mode sets
mul_lookup      db	00h, 00h, 10h, 10h, 20h, 20h, 20h, 30h	; Table lookup for multiply
endp		int_1Dh

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Video BIOS (Mono/CGA) Main Entry
;---------------------------------------------------------------------------------------------------
proc		int_10h near
                push	ax
                push	bx
                push	cx
                push	dx
                push	bp
                push	si
                push	di
                push	ds
                push	es
                mov	bp, ax
                mov	al, ah
                cmp	al, 10h ; Is ah a legal video command?
                jb	short loc_FF07B
                jmp	int10_end ;   error return if not
; ---------------------------------------------------------------------------

loc_FF07B:				; ...
                xor	ah, ah
                shl	ax, 1  ; Make word value
                xchg	ax, bp
                mov	si, BDAseg
                mov	ds, si
                mov	si, 0B800h
                mov	es, si
                assume es:nothing
                jmp	[cs:video_funcs+bp] ;   vector to routines
				
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 0: Set mode
;---------------------------------------------------------------------------------------------------
int_10_func_0:				; int 10 function 0: Set video mode
                push	ax
                and	al, 7Fh
                cmp	al, 7
                pop	ax
                jb	short loc_FF107
                jmp	int10_end
; ---------------------------------------------------------------------------

loc_FF107:				; ...
                push	es
                push	ax
                push	ds
                pop	es
                assume es:nothing
                mov	di, 49h
                stosb
                mov	bx, 28h
                test	al, 2
                jz	short loc_FF118
                shl	bx, 1

loc_FF118:				; ...
                xchg	ax, bx
                stosw
                mov	ax, 4000h
                cmp	bl, 4
                jnb	short loc_FF12B
                mov	ah, 8
                test	bl, 2
                jz	short loc_FF12B
                shl	ah, 1

loc_FF12B:				; ...
                stosw
                xor	ax, ax
                stosw
                mov	cx, 8
                rep stosw
                mov	ax, 607h
                stosw
                xor	ax, ax
                stosb
                mov	ax, 3D4h
                stosw
                xchg	ax, dx
                xor	ax, ax
                add	dx, 4
                out	dx, al
                sub	dx, 4
                mov	al, video_hdwr_mode[bx]
                cmp	bl, 4
                jb	short loc_FF15C
                mov	ah, 30h
                cmp	bl, 6
                jb	short loc_FF15C
                mov	ah, 0Fh

loc_FF15C:				; ...
                stosw
                mov	ax, 409h
                cmp	bl, 4
                jb	short loc_FF167
                mov	ah, 1

loc_FF167:				; ...
                out	dx, ax
                mov	ax, 60Ah
                out	dx, ax
                mov	ax, 70Bh
                out	dx, ax
                mov	ax, 0Ch
                out	dx, ax
                inc	ax
                out	dx, ax
                inc	ax
                out	dx, ax
                inc	ax
                out	dx, ax
                pop	ax
                pop	es
                assume es:nothing
                shl	al, 1
                jb	short loc_FF191
                xor	ax, ax
                cmp	bl, 4
                jnb	short loc_FF18A
                mov	ax, 720h

loc_FF18A:				; ...
                mov	cx, 2000h
                xor	di, di
                rep stosw

loc_FF191:				; ...
                mov	ax, [ds:video_mode_reg_]
                add	dx, 4
                out	dx, ax

int10_end:				; ...
                pop	es
                pop	ds
                assume ds:nothing
                pop	di
                pop	si
                pop	bp
                pop	dx
                pop	cx
                pop	bx
                pop	ax
                iret
endp		int_10h

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 1: Set cursor type
;---------------------------------------------------------------------------------------------------
int_10_func_1:				; ...
                mov	[ds:vid_curs_mode_], cx ; Save cursor type, from CX
                mov	dx, [ds:video_port_] ; Get the port
                mov	al, 0Ah  ; CRT index register 0Ah
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax
                jmp	short int10_end
				
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 2: Set cursor position
;---------------------------------------------------------------------------------------------------
int_10_func_2:				; ...
                and	bh, 7
                xor	ax, ax
                mov	al, bh
                shl	ax, 1
                xchg	ax, si
                mov	[si+vid_curs_pos0_], dx
                cmp	[byte ptr ds:video_mode_], 4
                jnb	short loc_FF1EF
                cmp	bh, [ds:video_page_]
                jnz	short loc_FF1EF
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	cx, cx
                mov	cl, dl
                add	cx, ax
                mov	ax, [ds:video_pag_off_]
                shr	ax, 1
                add	cx, ax
                mov	dx, [ds:video_port_]
                mov	al, 0Eh
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax

loc_FF1EF:				; ...
                jmp	short int10_end
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 3: Get cursor position
;---------------------------------------------------------------------------------------------------
int_10_func_3:				; ...
                and	bh, 7
                mov	bl, bh
                xor	bh, bh
                shl	bx, 1
                mov	dx, [bx+50h]
                mov	cx, [ds:vid_curs_mode_]
                pop	es
                pop	ds
                pop	di
                pop	si
                pop	bp
                pop	bx
                pop	bx
                pop	bx
                pop	ax
                iret
; ---------------------------------------------------------------------------

int_10_func_5:			; Set active display page
                and	ax, 7
                mov	[ds:video_page_], al
                mov	bh, al
                mul	[word ptr ds:video_buf_siz_]
                mov	[ds:video_pag_off_], ax
                shr	ax, 1
                xchg	ax, cx
                mov	dx, [ds:video_port_]
                mov	al, 0Ch
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax
                xor	ax, ax
                mov	al, bh
                shl	ax, 1
                xchg	ax, si
                mov	bx, [si+50h]
                mov	ax, [ds:video_columns_]
                mul	bh
                add	cx, ax
                xor	bh, bh
                add	cx, bx
                mov	al, 0Eh
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax
                jmp	int10_end
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 6: Scroll active page up
;---------------------------------------------------------------------------------------------------
int_10_func_6:
                mov	bl, al
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF259
                jmp	loc_FF543
; ---------------------------------------------------------------------------

loc_FF259:				; ...
                sub	dl, cl
                inc	dl
                sub	dh, ch
                inc	dh
                mov	bp, [ds:video_columns_]
                mov	ax, bp
                mul	ch
                xor	ch, ch
                add	ax, cx
                shl	ax, 1
                add	ax, [ds:video_pag_off_]
                xchg	ax, di
                xor	ax, ax
                mov	al, dl
                sub	bp, ax
                shl	bp, 1
                mov	al, bl
                dec	al
                mov	ah, dh
                dec	ah
                sub	ah, al
                jbe	short loc_FF2A7
                xchg	ax, cx
                mov	ax, [ds:video_columns_]
                shl	ax, 1
                mul	bl
                mov	si, ax
                add	si, di
                xchg	ax, cx
                xor	cx, cx
                push	es
                pop	ds

loc_FF299:				; ...
                mov	cl, dl
                rep movsw
                add	si, bp
                add	di, bp
                dec	dh
                dec	ah
                jnz	short loc_FF299

loc_FF2A7:				; ...
                mov	ah, bh
                mov	al, 20h

loc_FF2AB:				; ...
                mov	cl, dl
                rep stosw
                add	di, bp
                dec	dh
                jnz	short loc_FF2AB

loc_FF2B5:				; ...
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:video_mode_reg_]
                mov	dx, [ds:video_port_]
                add	dx, 4
                out	dx, ax
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
;                 Function 7: Scroll active page down
;---------------------------------------------------------------------------------------------------
int_10_func_7:				; ...
                std
                mov	bl, al
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF2D5
                jmp	loc_FF5CD
; ---------------------------------------------------------------------------

loc_FF2D5:				; ...
                push	dx
                sub	dl, cl
                inc	dl
                sub	dh, ch
                inc	dh
                pop	cx
                mov	bp, [ds:video_columns_]
                mov	ax, bp
                mul	ch
                xor	ch, ch
                add	ax, cx
                shl	ax, 1
                add	ax, [ds:video_pag_off_]
                xchg	ax, di
                xor	ax, ax
                mov	al, dl
                sub	bp, ax
                shl	bp, 1
                mov	al, bl
                dec	al
                mov	ah, dh
                dec	ah
                sub	ah, al
                jbe	short loc_FF325
                xchg	ax, cx
                mov	ax, [ds:video_columns_]
                shl	ax, 1
                mul	bl
                mov	si, di
                sub	si, ax
                xchg	ax, cx
                xor	cx, cx
                push	es
                pop	ds
                assume ds:nothing

loc_FF317:				; ...
                mov	cl, dl
                rep movsw
                sub	si, bp
                sub	di, bp
                dec	dh
                dec	ah
                jnz	short loc_FF317

loc_FF325:				; ...
                mov	ah, bh
                mov	al, 20h

loc_FF329:				; ...
                mov	cl, dl
                rep stosw
                sub	di, bp
                dec	dh
                jnz	short loc_FF329
                jmp	short loc_FF2B5

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 8: Read attribute/character
;---------------------------------------------------------------------------------------------------
int_10_func_8:				; ...
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF33F
                jmp	loc_FF65C
; ---------------------------------------------------------------------------

loc_FF33F:				; ...
                and	bh, 7
                xor	ax, ax
                mov	al, bh
                mov	bx, ax
                shl	ax, 1
                xchg	ax, si
                mov	cx, [si+50h]
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	dh, dh
                add	ax, dx
                shl	ax, 1
                add	ax, cx
                xchg	ax, bx
                mov	ax, [es:bx]

loc_FF367:				; ...
                pop	es
                pop	ds
                pop	di
                pop	si
                pop	bp
                pop	dx
                pop	cx
                pop	bx
                inc	sp
                inc	sp
                iret
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 9: Write attribute/character
;---------------------------------------------------------------------------------------------------
int_10_func_9:				; ...
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF37C
                jmp	loc_FF6FC
; ---------------------------------------------------------------------------

loc_FF37C:				; ...
                mov	ah, bl
                push	ax
                push	cx
                and	bh, 7
                xor	ax, ax
                mov	al, bh
                mov	bx, ax
                shl	ax, 1
                xchg	ax, si
                mov	cx, [si+50h]
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	dh, dh
                add	ax, dx
                shl	ax, 1
                add	ax, cx
                xchg	ax, di
                pop	cx
                pop	ax
                rep stosw
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 10: Write character only
;---------------------------------------------------------------------------------------------------
int_10_func_0A:
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF3B6
                jmp	loc_FF6FC
; ---------------------------------------------------------------------------

loc_FF3B6:				; ...
                push	ax
                push	cx
                and	bh, 7
                xor	ax, ax
                mov	al, bh
                mov	bx, ax
                shl	ax, 1
                xchg	ax, si
                mov	cx, [si+50h]
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	dh, dh
                add	ax, dx
                shl	ax, 1
                add	ax, cx
                xchg	ax, di
                pop	cx
                pop	ax

loc_FF3DF:				; ...
                stosb
                inc	di
                loop	loc_FF3DF
                jmp	int10_end


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 11: Set color
;---------------------------------------------------------------------------------------------------
int_10_func_0B:				; ...
                mov	dx, [ds:video_port_]
                add	dx, 5
                mov	al, [ds:video_color_]
                or	bh, bh
                jnz	short loc_FF3FD
                and	al, 20h
                and	bl, 1Fh
                or	al, bl
                jmp	short loc_FF405
; ---------------------------------------------------------------------------

loc_FF3FD:				; ...
                and	al, 1Fh
                shr	bl, 1
                jnb	short loc_FF405
                or	al, 20h

loc_FF405:				; ...
                out	dx, al
                mov	[ds:video_color_], al
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 12: Write pixel
;---------------------------------------------------------------------------------------------------
int_10_func_0C:
                xor	bx, bx
                mov	dh, al
                shr	dl, 1
                jnb	short loc_FF416
                mov	bh, 20h

loc_FF416:				; ...
                mov	al, 50h
                mul	dl
                mov	dl, cl
                and	dl, 7
                shr	cx, 1
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF42D
                and	dl, 3
                shl	cx, 1

loc_FF42D:				; ...
                shr	cx, 1
                shr	cx, 1
                add	ax, cx
                add	bx, ax
                mov	al, [es:bx]
                mov	ah, 80h
                mov	cl, dl
                mov	dl, dh
                ror	dh, 1
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF44D
                mov	ah, 0C0h
                shl	cl, 1
                ror	dh, 1

loc_FF44D:				; ...
                and	dh, ah
                shr	ah, cl
                shr	dh, cl
                shl	dl, 1
                jb	short loc_FF45B
                or	al, ah
                xor	al, ah

loc_FF45B:				; ...
                xor	al, dh
                mov	[es:bx], al
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 13: Read pixel
;---------------------------------------------------------------------------------------------------
int_10_func_0D:				; ...
                xor	bx, bx
                shr	dl, 1
                jnb	short loc_FF46B
                mov	bh, 20h

loc_FF46B:				; ...
                mov	al, 50h
                mul	dl
                mov	dl, cl
                and	dl, 7
                shr	cx, 1
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF482
                and	dl, 3
                shl	cx, 1

loc_FF482:				; ...
                shr	cx, 1
                shr	cx, 1
                add	ax, cx
                add	bx, ax
                mov	al, [es:bx]
                mov	ah, 80h
                mov	cl, dl
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF49C
                mov	ah, 0C0h
                shl	cl, 1

loc_FF49C:				; ...
                shl	al, cl
                and	al, ah
                rol	al, 1
                rol	al, 1
                pop	es
                pop	ds
                pop	di
                pop	si
                pop	bp
                pop	dx
                pop	cx
                pop	bx
                inc	sp
                inc	sp
                iret

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 14: Write teletype
;---------------------------------------------------------------------------------------------------
int_10_func_0E:				; ...
                mov	bh, [ds:video_page_]
                xor	cx, cx
                mov	cl, bh
                shl	cx, 1
                mov	si, cx
                mov	dx, [si+vid_curs_pos0_]
                cmp	al, 7
                jz	short loc_FF512
                cmp	al, 8
                jz	short loc_FF52F
                cmp	al, 0Ah
                jz	short loc_FF538
                cmp	al, 0Dh
                jz	short loc_FF53F
                mov	ah, 0Ah
                mov	cx, 1
                int	10h		; - VIDEO -
                inc	dl
                mov	ax, [ds:video_columns_]
                cmp	dl, al
                jb	short loc_FF50E
                xor	dl, dl
                cmp	dh, 18h
                jb	short loc_FF50C

loc_FF4E6:				; ...
                mov	ah, 2
                int	10h		; - VIDEO - SET	CURSOR POSITION
                                        ; DH,DL	= row, column (0,0 = upper left)
                                        ; BH = page number
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF4F5
                mov	bh, 0
                jmp	short loc_FF4FB
; ---------------------------------------------------------------------------

loc_FF4F5:				; ...
                mov	ah, 8
                int	10h		; - VIDEO - READ ATTRIBUTES/CHARACTER AT CURSOR	POSITION
                                        ; BH = display page
                                        ; Return: AL = character
                                        ; AH = attribute of character (alpha modes)
                mov	bh, ah

loc_FF4FB:				; ...
                mov	ax, 601h
                xor	cx, cx
                mov	dx, [ds:video_columns_]
                dec	dx
                mov	dh, 18h

loc_FF507:				; ...
                int	10h		; - VIDEO - SCROLL PAGE	UP
                                        ; AL = number of lines to scroll window	(0 = blank whole window)
                                        ; BH = attributes to be	used on	blanked	lines
                                        ; CH,CL	= row,column of	upper left corner of window to scroll
                                        ; DH,DL	= row,column of	lower right corner of window
                jmp	int10_end
; ---------------------------------------------------------------------------

loc_FF50C:				; ...
                inc	dh

loc_FF50E:				; ...
                mov	ah, 2
                jmp	short loc_FF507
				
				loc_FF512:				; ...
                mov	al, 0B6h
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 50h
                out	42h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 2
                out	42h, al		; Timer	8253-5 (AT: 8254.2).
                in	al, 61h		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                or	al, 3
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                xor	cx, cx

loc_FF526:				; ...
                loop	loc_FF526
                xor	al, 3
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                jmp	int10_end
; ---------------------------------------------------------------------------

loc_FF52F:				; ...
                cmp	dl, 0
                jz	short loc_FF50E
                dec	dl
                jmp	short loc_FF50E
; ---------------------------------------------------------------------------

loc_FF538:				; ...
                cmp	dh, 18h
                jnz	short loc_FF50C
                jmp	short loc_FF4E6
; ---------------------------------------------------------------------------

loc_FF53F:				; ...
                xor	dl, dl
                jmp	short loc_FF50E
; ---------------------------------------------------------------------------

loc_FF543:				; ...
                sub	dl, cl
                inc	dl
                sub	dh, ch
                inc	dh
                mov	al, 0A0h
                mul	ch
                shl	ax, 1
                xor	ch, ch
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF55E
                shl	cl, 1
                shl	dl, 1

loc_FF55E:				; ...
                add	ax, cx
                xchg	ax, di
                xor	ax, ax
                mov	al, dl
                mov	bp, ax
                mov	al, bl
                dec	al
                mov	ah, dh
                dec	ah
                shl	dh, 1
                shl	dh, 1
                shl	dh, 1
                sub	ah, al
                jbe	short loc_FF5B2
                shl	ah, 1
                shl	ah, 1
                shl	ah, 1
                xchg	ax, cx
                mov	al, 0A0h
                mul	bl
                shl	ax, 1
                mov	si, ax
                add	si, di
                xchg	ax, cx
                mov	cx, es
                mov	ds, cx
                xor	cx, cx

loc_FF591:				; ...
                mov	cl, dl
                rep movsb
                sub	si, bp
                sub	di, bp
                xor	si, 2000h
                xor	di, 2000h
                test	ah, 1
                jz	short loc_FF5AC
                add	si, 50h
                add	di, 50h

loc_FF5AC:				; ...
                dec	dh
                dec	ah
                jnz	short loc_FF591

loc_FF5B2:				; ...
                mov	al, bh

loc_FF5B4:				; ...
                mov	cl, dl
                rep stosb
                sub	di, bp
                xor	di, 2000h
                test	dh, 1
                jz	short loc_FF5C6
                add	di, 50h

loc_FF5C6:				; ...
                dec	dh
                jnz	short loc_FF5B4
                jmp	int10_end
; ---------------------------------------------------------------------------

loc_FF5CD:				; ...
                push	dx
                sub	dl, cl
                inc	dl
                sub	dh, ch
                inc	dh
                pop	cx
                mov	al, 0A0h
                mul	ch
                shl	ax, 1
                xor	ch, ch
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF5EA
                shl	cl, 1
                shl	dl, 1

loc_FF5EA:				; ...
                add	ax, cx
                add	ax, 20F0h
                xchg	ax, di
                xor	ax, ax
                mov	al, dl
                mov	bp, ax
                mov	al, bl
                dec	al
                mov	ah, dh
                dec	ah
                shl	dh, 1
                shl	dh, 1
                shl	dh, 1
                sub	ah, al
                jbe	short loc_FF641
                shl	ah, 1
                shl	ah, 1
                shl	ah, 1
                xchg	ax, cx
                mov	al, 0A0h
                mul	bl
                shl	ax, 1
                mov	si, di
                sub	si, ax
                xchg	ax, cx
                mov	cx, es
                mov	ds, cx
                xor	cx, cx

loc_FF620:				; ...
                mov	cl, dl
                rep movsb
                add	si, bp
                add	di, bp
                xor	si, 2000h
                xor	di, 2000h
                test	ah, 1
                jz	short loc_FF63B
                sub	si, 50h
                sub	di, 50h

loc_FF63B:				; ...
                dec	dh
                dec	ah
                jnz	short loc_FF620

loc_FF641:				; ...
                mov	al, bh
                mov	cl, dl
                rep stosb
                add	di, bp
                xor	di, 2000h
                test	dh, 1
                jz	short loc_FF655
                sub	di, 50h

loc_FF655:				; ...
                dec	dh
                jnz	short loc_FF641
                jmp	int10_end
; ---------------------------------------------------------------------------


loc_FF65C:				; ...
                sub	sp, 8
                mov	bp, sp
                mov	dx, [ds:vid_curs_pos0_]
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF66E
                shl	dl, 1

loc_FF66E:				; ...
                mov	al, 0A0h
                mul	dh
                shl	ax, 1
                xor	dh, dh
                add	ax, dx
                xchg	ax, si
                mov	dl, [ds:video_mode_]
                mov	ax, es
                mov	ds, ax
                mov	ax, ss
                mov	es, ax
                mov	di, bp
                mov	cx, 8

loc_FF68A:				; ...
                mov	al, [si]
                test	dl, 2
                jnz	short loc_FF6A9
                mov	ah, al
                mov	al, [si+1]
                mov	bx, ax
                shl	bx, 1
                or	bx, ax
                push	cx
                mov	cx, 8

loc_FF6A0:				; ...
                shr	bx, 1
                shr	bx, 1
                rcr	al, 1
                loop	loc_FF6A0
                pop	cx

loc_FF6A9:				; ...
                stosb
                xor	si, 2000h
                test	cl, 1
                jz	short loc_FF6B6
                add	si, 50h

loc_FF6B6:				; ...
                loop	loc_FF68A
                mov	ax, cs
                mov	es, ax
                assume es:nothing
                mov	ax, ss
                mov	ds, ax
                mov	al, [bp+0]
                mov	di, offset gfx_chars
                xor	bx, bx

loc_FF6C8:				; ...
                scasb
                jz	short loc_FF6E6

loc_FF6CB:				; ...
                add	di, 7
                inc	bl
                jns	short loc_FF6C8
                shl	bh, 1
                jb	short loc_FF6F2
                xchg	bh, bl
                xor	cx, cx
                mov	ds, cx
                les	di, [ds:rs232_timeout1_]
                assume es:nothing
                mov	cx, ss
                mov	ds, cx
                jmp	short loc_FF6C8
; ---------------------------------------------------------------------------


loc_FF6E6:				; ...
                mov	cx, 7
                mov	si, bp
                inc	si
                push	di
                repe cmpsb
                pop	di
                jnz	short loc_FF6CB

loc_FF6F2:				; ...
                mov	al, bl
                add	al, bh
                add	sp, 8
                jmp	loc_FF367
; ---------------------------------------------------------------------------

loc_FF6FC:				; ...
                mov	bh, al
                mov	dx, [ds:vid_curs_pos0_]
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF70B
                shl	dl, 1

loc_FF70B:				; ...
                mov	al, 0A0h
                mul	dh
                shl	ax, 1
                xor	dh, dh
                add	ax, dx
                xchg	ax, di
                mov	dl, [ds:video_mode_]
                mov	ax, cs
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	si, 0FA6Eh
                test	bh, 80h
                jz	short loc_FF731
                mov	ds, ax
                assume ds:nothing
                lds	si, [ds:rs232_timeout1_]
                and	bh, 7Fh

loc_FF731:				; ...
                mov	al, bh
                shl	ax, 1
                shl	ax, 1
                shl	ax, 1
                add	si, ax
                mov	dh, 8

loc_FF73D:				; ...
                lodsb
                test	dl, 2
                jnz	short loc_FF78B
                xor	bp, bp
                push	cx
                mov	cx, 8

loc_FF749:				; ...
                shl	al, 1
                rcl	bp, 1
                rol	bp, 1
                loop	loc_FF749
                mov	ax, bp
                shr	ax, 1
                or	bp, ax
                mov	al, bl
                and	al, 3
                mov	ah, al
                mov	cl, 3

loc_FF75F:				; ...
                shl	ah, 1
                shl	ah, 1
                or	al, ah
                loop	loc_FF75F
                pop	cx
                mov	ah, al
                and	ax, bp
                xchg	al, ah
                test	bl, 80h
                jz	short loc_FF783
                push	cx
                push	di

loc_FF775:				; ...
                xor	[es:di], al
                inc	di
                xor	[es:di], ah
                inc	di
                loop	loc_FF775
                pop	di
                pop	cx
                jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF783:				; ...
                push	cx
                push	di
                rep stosw
                pop	di
                pop	cx
                jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF78B:				; ...
                test	bl, 80h
                jz	short loc_FF79C
                push	cx
                push	di

loc_FF792:				; ...
                xor	[es:di], al
                inc	di
                loop	loc_FF792
                pop	di
                pop	cx
                jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF79C:				; ...
                push	cx
                push	di
                rep stosb
                pop	di
                pop	cx

loc_FF7A2:				; ...
                xor	di, 2000h
                test	dh, 1
                jz	short loc_FF7AE
                add	di, 50h

loc_FF7AE:				; ...
                dec	dh
                jnz	short loc_FF73D
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 15: Return current video state
;---------------------------------------------------------------------------------------------------
int_10_func_0F:				; ...
                mov	ax, [ds:video_mode_]
                mov	bh, [ds:video_page_]
                pop	es
                pop	ds
                pop	di
                pop	si
                pop	bp
                pop	dx
                pop	cx
                add	sp, 4
                iret

;---------------------------------------------------------------------------------------------------
; 8x8 Graphics Character Set (chars 0-127)
;---------------------------------------------------------------------------------------------------
gfx_chars	db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;   0  nul
                db	07Eh, 081h, 0A5h, 081h, 0BDh, 099h, 081h, 07Eh		;   1  soh
                db	07Eh, 0FFh, 0DBh, 0FFh, 0C3h, 0E7h, 0FFh, 07Eh		;   2  stx
                db	06Ch, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h		;   3  etx
                db	010h, 038h, 07Ch, 0FEh,	07Ch, 038h, 010h, 000h		;   4  eot
                db	038h, 07Ch, 038h, 0FEh,	0FEh, 07Ch, 038h, 07Ch		;   5  enq
                db	010h, 010h, 038h, 07Ch,	0FEh, 07Ch, 038h, 07Ch		;   6  ack
                db	000h, 000h, 018h, 03Ch,	03Ch, 018h, 000h, 000h		;   7  bel
                db	0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh		;   8  bs
                db	000h, 03Ch, 066h, 042h, 042h, 066h, 03Ch, 000h		;   9  ht
                db	0FFh, 0C3h, 099h, 0BDh, 0BDh, 099h, 0C3h, 0FFh		;  10  lf
                db	00Fh, 007h, 00Fh, 07Dh, 0CCh, 0CCh, 0CCh, 078h		;  11  vt
                db	03Ch, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h		;  12  ff
                db	03Fh, 033h, 03Fh, 030h, 030h, 070h, 0F0h, 0E0h		;  13  cr
                db	07Fh, 063h, 07Fh, 063h, 063h, 067h, 0E6h, 0C0h		;  14  so
                db	099h, 05Ah, 03Ch, 0E7h, 0E7h, 03Ch, 05Ah, 099h		;  15  si
                db	080h, 0E0h, 0F8h, 0FEh, 0F8h, 0E0h, 080h, 000h		;  16  dle
                db	002h, 00Eh, 03Eh, 0FEh,	03Eh, 00Eh, 002h, 000h		;  17  dc1
                db	018h, 03Ch, 07Eh, 018h, 018h, 07Eh, 03Ch, 018h		;  18  dc2
                db	066h, 066h, 066h, 066h,	066h, 000h, 066h, 000h		;  19  dc3
                db	07Fh, 0DBh, 0DBh, 07Bh,	01Bh, 01Bh, 01Bh, 000h		;  20  dc4
                db	03Eh, 063h, 038h, 06Ch,	06Ch, 038h, 0CCh, 078h		;  21  nak
                db	000h, 000h, 000h, 000h,	07Eh, 07Eh, 07Eh, 000h		;  22  syn
                db	018h, 03Ch, 07Eh, 018h, 07Eh, 03Ch, 018h, 0FFh		;  23  etb
                db	018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 000h		;  24  can
                db	018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h		;  25  em
                db	000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h		;  26  sub
                db	000h, 030h, 060h, 0FEh,	060h, 030h, 000h, 000h		;  27  esc
                db	000h, 000h, 0C0h, 0C0h,	0C0h, 0FEh, 000h, 000h		;  28  fs
                db	000h, 024h, 066h, 0FFh,	066h, 024h, 000h, 000h		;  29  gs
                db	000h, 018h, 03Ch, 07Eh,	0FFh, 0FFh, 000h, 000h		;  30  rs
                db	000h, 0FFh, 0FFh, 07Eh, 03Ch, 018h, 000h, 000h		;  31  us
                db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;  32  space
                db	030h, 078h, 078h, 030h,	030h, 000h, 030h, 000h		;  33  !
                db	06Ch, 06Ch, 06Ch, 000h,	000h, 000h, 000h, 000h		;  34  "
                db	06Ch, 06Ch, 0FEh, 06Ch,	0FEh, 06Ch, 06Ch, 000h		;  35  #
                db	030h, 07Ch, 0C0h, 078h, 00Ch, 0F8h, 030h, 000h		;  36  $
                db	000h, 0C6h, 0CCh, 018h, 030h, 066h, 0C6h, 000h		;  37  %
                db	038h, 06Ch, 038h, 076h,	0DCh, 0CCh, 076h, 000h		;  38  &
                db	060h, 060h, 0C0h, 000h,	000h, 000h, 000h, 000h		;  39  '
                db	018h, 030h, 060h, 060h,	060h, 030h, 018h, 000h		;  40  (
                db	060h, 030h, 018h, 018h,	018h, 030h, 060h, 000h		;  41  )
                db	000h, 066h, 03Ch, 0FFh,	03Ch, 066h, 000h, 000h		;  42  *
                db	000h, 030h, 030h, 0FCh,	030h, 030h, 000h, 000h		;  43  +
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 060h		;  44  ,
                db	000h, 000h, 000h, 0FCh,	000h, 000h, 000h, 000h		;  45  -
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 000h		;  46  .
                db	006h, 00Ch, 018h, 030h,	060h, 0C0h, 080h, 000h		;  47  /
                db	07Ch, 0C6h, 0CEh, 0DEh,	0F6h, 0E6h, 07Ch, 000h		;  48  0
                db	030h, 070h, 030h, 030h,	030h, 030h, 0FCh, 000h		;  49  1
                db	078h, 0CCh, 00Ch, 038h,	060h, 0CCh, 0FCh, 000h		;  50  2
                db	078h, 0CCh, 00Ch, 038h,	00Ch, 0CCh, 078h, 000h		;  51  3
                db	01Ch, 03Ch, 06Ch, 0CCh,	0FEh, 00Ch, 01Eh, 000h		;  52  4
                db	0FCh, 0C0h, 0F8h, 00Ch,	00Ch, 0CCh, 078h, 000h		;  53  5
                db	038h, 060h, 0C0h, 0F8h, 0CCh, 0CCh, 078h, 000h		;  54  6
                db	0FCh, 0CCh, 00Ch, 018h,	030h, 030h, 030h, 000h		;  55  7
                db	078h, 0CCh, 0CCh, 078h,	0CCh, 0CCh, 078h, 000h		;  56  8
                db	078h, 0CCh, 0CCh, 07Ch,	00Ch, 018h, 070h, 000h		;  57  9
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 000h		;  58  :
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 060h		;  59  ;
                db	018h, 030h, 060h, 0C0h,	060h, 030h, 018h, 000h		;  60  <
                db	000h, 000h, 0FCh, 000h,	000h, 0FCh, 000h, 000h		;  61  =
                db	060h, 030h, 018h, 00Ch, 018h, 030h, 060h, 000h		;  62  >
                db	078h, 0CCh, 00Ch, 018h,	030h, 000h, 030h, 000h		;  63  ?
                db	07Ch, 0C6h, 0DEh, 0DEh,	0DEh, 0C0h, 078h, 000h		;  64  @
                db	030h, 078h, 0CCh, 0CCh, 0FCh, 0CCh, 0CCh, 000h		;  65  A
                db	0FCh, 066h, 066h, 07Ch, 066h, 066h, 0FCh, 000h		;  66  B
                db	03Ch, 066h, 0C0h, 0C0h, 0C0h, 066h, 03Ch, 000h		;  67  C
                db	0F8h, 06Ch, 066h, 066h, 066h, 06Ch, 0F8h, 000h		;  68  D
                db	0FEh, 062h, 068h, 078h,	068h, 062h, 0FEh, 000h		;  69  E
                db	0FEh, 062h, 068h, 078h,	068h, 060h, 0F0h, 000h		;  70  F
                db	03Ch, 066h, 0C0h, 0C0h, 0CEh, 066h, 03Eh, 000h		;  71  G
                db	0CCh, 0CCh, 0CCh, 0FCh,	0CCh, 0CCh, 0CCh, 000h		;  72  H
                db	078h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		;  73  I
                db	01Eh, 00Ch, 00Ch, 00Ch,	0CCh, 0CCh, 078h, 000h		;  74  J
                db	0E6h, 066h, 06Ch, 078h,	06Ch, 066h, 0E6h, 000h		;  75  K
                db	0F0h, 060h, 060h, 060h,	062h, 066h, 0FEh, 000h		;  76  L
                db	0C6h, 0EEh, 0FEh, 0FEh,	0D6h, 0C6h, 0C6h, 000h		;  77  M
                db	0C6h, 0E6h, 0F6h, 0DEh,	0CEh, 0C6h, 0C6h, 000h		;  78  N
                db	038h, 06Ch, 0C6h, 0C6h,	0C6h, 06Ch, 038h, 000h		;  79  O
                db	0FCh, 066h, 066h, 07Ch,	060h, 060h, 0F0h, 000h		;  80  P
                db	078h, 0CCh, 0CCh, 0CCh,	0DCh, 078h, 01Ch, 000h		;  81  Q
                db	0FCh, 066h, 066h, 07Ch,	06Ch, 066h, 0E6h, 000h		;  82  R   +
                db	078h, 0CCh, 0E0h, 070h,	01Ch, 0CCh, 078h, 000h		;  83  S   +
                db	0FCh, 0B4h, 030h, 030h,	030h, 030h, 078h, 000h		;  84  T   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCh, 0CCh, 0FCh, 000h		;  85  U   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCH, 078h, 030h, 000h		;  86  V   +
                db	0C6h, 0C6h, 0C6h, 0D6h,	0FEh, 0EEh, 0C6h, 000h		;  87  W   +
                db	0C6h, 0C6h, 06Ch, 038h,	038h, 06Ch, 0C6h, 000h		;  88  X   +
                db	0CCh, 0CCh, 0CCh, 078h,	030h, 030h, 078h, 000h		;  89  Y   +
                db	0FEh, 0C6h, 08Ch, 018h,	032h, 066h, 0FEh, 000h		;  90  Z   +
                db	078h, 060h, 060h, 060h,	060h, 060h, 078h, 000h		;  91  [   +
                db	0C0h, 060h, 030h, 018h,	00Ch, 006h, 002h, 000h		;  92  backslash   +
                db	078h, 018h, 018h, 018h,	018h, 018h, 078h, 000h		;  93  ]   +
                db	010h, 038h, 06Ch, 0C6h,	000h, 000h, 000h, 000h		;  94  ^   +
                db	000h, 000h, 000h, 000h,	000h, 000h, 000h, 0FFh		;  95  _   +
                db	030h, 030h, 018h, 000h,	000h, 000h, 000h, 000h		;  96  `   +
                db	000h, 000h, 078h, 00Ch,	07Ch, 0CCh, 076h, 000h		;  97  a   +
                db	0E0h, 060h, 060h, 07Ch,	066h, 066h, 0DCh, 000h		;  98  b   +
                db	000h, 000h, 078h, 0CCh,	0C0h, 0CCh, 078h, 000h		;  99  c   +
                db	01Ch, 00Ch, 00Ch, 07Ch,	0CCh, 0CCh, 076h, 000h		; 100  d   +
                db	000h, 000h, 078h, 0CCh,	0FCh, 0C0h, 078h, 000h		; 101  e   +
                db	038h, 06Ch, 060h, 0F0h,	060h, 060h, 0F0h, 000h		; 102  f   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 103  g   +
                db	0E0h, 060h, 06Ch, 076h,	066h, 066h, 0E6h, 000h		; 104  h   +
                db	030h, 000h, 070h, 030h,	030h, 030h, 078h, 000h		; 105  i   +
                db	00Ch, 000h, 00Ch, 00Ch,	00Ch, 0CCh, 0CCh, 078h		; 106  j   +
                db	0E0h, 060h, 066h, 06Ch,	078h, 06Ch, 0E6h, 000h		; 107  k   +
                db	070h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		; 108  l   +
                db	000h, 000h, 0CCh, 0FEh,	0FEh, 0D6h, 0C6h, 000h		; 109  m   +
                db	000h, 000h, 0F8h, 0CCh,	0CCh, 0CCh, 0CCh, 000h		; 110  n   +
                db	000h, 000h, 078h, 0CCh,	0CCh, 0CCh, 078h, 000h		; 111  o   +
                db	000h, 000h, 0DCh, 066h,	066h, 07Ch, 060h, 0F0h		; 112  p   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 01Eh		; 113  q   +
                db	000h, 000h, 0DCh, 076h,	066h, 060h, 0F0h, 000h		; 114  r   +
                db	000h, 000h, 07Ch, 0C0h,	078h, 00Ch, 0F8h, 000h		; 115  s   +
                db	010h, 030h, 07Ch, 030h,	030h, 034h, 018h, 000h		; 116  t   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 0CCh, 076h, 000h		; 117  u   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 078h, 030h, 000h		; 118  v   +
                db	000h, 000h, 0C6h, 0D6h, 0FEh, 0FEh, 06Ch, 000h		; 119  w   +
                db	000h, 000h, 0C6h, 06Ch,	038h, 06Ch, 0C6h, 000h		; 120  x   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 121  y   +
                db	000h, 000h, 0FCh, 098h,	030h, 064h, 0FCh, 000h		; 122  z   +
                db	01Ch, 030h, 030h, 0E0h,	030h, 030h, 01Ch, 000h		; 123  {   +
                db	018h, 018h, 018h, 000h,	018h, 018h, 018h, 000h		; 124  |   +
                db	0E0h, 030h, 030h, 01Ch,	030h, 030h, 0E0h, 000h		; 125  }   +
                db	076h, 0DCh, 000h, 000h,	000h, 000h, 000h, 000h		; 126  ~   +
                db	000h, 010h, 038h, 06Ch,	0C6h, 0C6h, 0FEh, 000h		; 127  del +
;---------------------------------------------------------------------------------------------------
