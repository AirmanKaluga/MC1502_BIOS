;---------------------------------------------------------------------------------------------------
; Interrupt 5h - Print Screen
;---------------------------------------------------------------------------------------------------
proc		int_05h	far				; Print screen service
                sti
                push	ds
                push	ax
                push	bx
                push	cx
                push	dx
                mov	ax, 50h
                mov	ds, ax
                assume ds:nothing
                cmp	[byte ptr ds:0], 1
                jz	short exit_int_05h
                mov	[byte ptr ds:0], 1
                mov	ah, 0Fh
                int	10h		; - VIDEO - GET	CURRENT	VIDEO MODE
                                        ; Return: AH = number of columns on screen
                                        ; AL = current video mode
                                        ; BH = current active display page
                mov	cl, ah
                mov	ch, 19h
                call	print_cr_lf
                push	cx
                mov	ah, 3
                int	10h		; - VIDEO - READ CURSOR	POSITION
                                        ; BH = page number
                                        ; Return: DH,DL	= row,column, CH = cursor start	line, CL = cursor end line
                pop	cx
                push	dx
                xor	dx, dx

loc_FFF7F:				; ...
                mov	ah, 2
                int	10h		; - VIDEO - SET	CURSOR POSITION
                                        ; DH,DL	= row, column (0,0 = upper left)
                                        ; BH = page number
                mov	ah, 8
                int	10h		; - VIDEO - READ ATTRIBUTES/CHARACTER AT CURSOR	POSITION
                                        ; BH = display page
                                        ; Return: AL = character
                                        ; AH = attribute of character (alpha modes)
                or	al, al
                jnz	short loc_FFF8D
                mov	al, 20h

loc_FFF8D:				; ...
                push	dx
                xor	dx, dx
                xor	ah, ah
                int	17h		; PRINTER - OUTPUT CHARACTER
                                        ; AL = character, DX = printer port (0-3)
                                        ; Return: AH = status bits
                pop	dx
                test	ah, 25h
                jnz	short loc_FFFBB
                inc	dl
                cmp	cl, dl
                jnz	short loc_FFF7F
                xor	dl, dl
                mov	ah, dl
                push	dx
                call	print_cr_lf
                pop	dx
                inc	dh
                cmp	ch, dh
                jnz	short loc_FFF7F
                pop	dx
                mov	ah, 2
                int	10h		; - VIDEO - SET	CURSOR POSITION
                                        ; DH,DL	= row, column (0,0 = upper left)
                                        ; BH = page number
                mov	[byte ptr ds:0], 0
                jmp	short exit_int_05h

loc_FFFBB:				; ...
                pop	dx
                mov	ah, 2
                int	10h		; - VIDEO - SET	CURSOR POSITION
                                        ; DH,DL	= row, column (0,0 = upper left)
                                        ; BH = page number
                mov	[byte ptr ds:0], 0FFh

exit_int_05h:				; ...
                pop	dx
                pop	cx
                pop	bx
                pop	ax
                pop	ds
                assume ds:nothing
                iret
endp		int_05h



