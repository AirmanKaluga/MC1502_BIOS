;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Video BIOS (Mono/CGA) Main Entry
;---------------------------------------------------------------------------------------------------

video_funcs	dw	int_10_func_0		; Set mode
		dw	int_10_func_1		; Set cursor type
		dw	int_10_func_2		; Set cursor position
		dw	int_10_func_3		; Get cursor position
		dw	int_10_func_4		; Read light pen position
		dw	int_10_func_5		; Set active display page
		dw	int_10_func_6_7		; Scroll active page up
		dw	int_10_func_6_7		; Scroll active page down
		dw	int_10_func_8_9_10	; Read attribute/character
		dw	int_10_func_8_9_10	; Write attribute/character
		dw	int_10_func_8_9_10	; Write character only
		dw	int_10_func_11		; Set color
		dw	int_10_func_12		; Write pixel
		dw	int_10_func_13		; Read pixel
		dw	int_10_func_14		; Write teletype
		dw	int_10_func_15		; Return current video state

proc	int_10h	far

	sti					; Video BIOS service ah=(0-15)
	cld					;   strings auto-increment
	push	bp
	push	es
	push	ds
	push	si
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	bx, 40h
	mov	ds, bx
	mov	bl, [ds:10h]			; Get equipment byte
	and	bl, 00110000b			;   isolate video mode
	cmp	bl, 00110000b			; Check for monochrome card
	mov	bx, 0B800h
	jnz	@@dispatch			;   not there, bx --> CGA
	mov	bh, 0B0h			; Else bx --> MONO

@@dispatch:
	push	bx				; Save video buffer address
	mov	bp, sp				;   start of stack frame
	call	int_10_dispatch			;   then do the function
	pop	si
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	si
	pop	ds
	pop	es
	pop	bp
	iret

map_byte:
	push	dx				; Multiply al by bx, cx --> buffer
	mov	ah, 0
	mul	bx				; Position in ax
	pop	dx
	mov	cx, [bp+0]			; cx --> video buffer
	retn

endp	int_10h


str_last_line	db	192, 0


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function Dispatch
;---------------------------------------------------------------------------------------------------
proc    int_10_dispatch	near

	cmp	ah, 0Fh 			; Is ah a legal video command?
	jbe	@@ok

invalid:
	ret					;   error return if not

@@ok:	shl	ah, 1				; Make word value
	mov	bl, ah				;   then set up bx
	mov	bh, 0
	jmp	[word cs:bx+video_funcs]	;   vector to routines

endp	int_10_dispatch


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 0: Set mode
;---------------------------------------------------------------------------------------------------
proc	int_10_func_0	near

	mov	al, [ds:10h]			; Set mode of CRT
	mov	dx, 3B4h			;   mono port
	and	al, 00110000b			;   get display type
	cmp	al, 00110000b			;   equal if mono
	mov	al, 1				; Assume mono display
	mov	bl, 7				;   mode is 7
	jz	@@reset				;   Skip if mono, else CGA

	mov	bl, [bp+2]			; bl = mode number (user al)
	cmp	bl, 7
	ja	invalid

	mov	dl, 0D4h			; 3D4 is CGA port
	dec	al

@@reset:
	mov	[ds:63h], dx			; Save current CRT display port
	add	dl, 4
	out	dx, al				; Reset the video
	mov	[ds:49h], bl			;   save current CRT mode
	push	ds
	xor	ax, ax
	mov	ds, ax
	les	si, [dword ds:74h]		; si --> INT_1D video parameters
	pop	ds
	mov	bh, 0
	push	bx
	mov	bl, [cs:bx+mul_lookup]		; Get bl for index into INT_1D
	add	si, bx
	mov	cx, 10h 			; Sixteen values to send

@@loop:	mov	al, [es:si]			; Value to send in si
	call	send_ax				;   send it
	inc	ah				;   bump count
	inc	si				;   point to next
	loop	@@loop				;   loop until done

	mov	bx, [bp+0]			; bx --> regen buffer
	mov	es, bx				;   into es segment
	xor	di, di
	call	mode_check			; Set flags to mode
	mov	ch, 20h				;   assume CGA
	mov	ax, 0				;   and graphics
	jb	@@fill				;   do graphics fill
	jnz	@@text				;   Alphanumeric fill
	mov	ch, 8h				;   mono card
@@text:	mov	ax, 7*100h+' '			; Word for text fill
@@fill:	rep	stosw				;   fill regen buffer

	mov	dx, [ds:63h]			; Get the port
	add	dl, 4
	pop	bx
	mov	al, [cs:bx+video_hdwr_mode]		; Load data to set for mode
	out	dx, al				;   and send it
	mov	[ds:65h], al			;   then save active data
	inc	dx
	mov	al, 30h 			; Assume not 640x200 b/w
	cmp	bl, 6				;   correct?
	jnz	@@palette
	mov	al, 3Fh 			; Palette for 640x200 b/w

@@palette:
	mov	[ds:66h], al			;   save palette
	out	dx, al				;   send palette
	xor	ax, ax
	mov	[ds:4Eh], ax			; Start at beg. of 1st page
	mov	[ds:62h], al			;   active page=page 0
	mov	cl, 8				; Do 8 pages of cursor data
	mov	di, 50h 			; Page cursor data at 40:50

@@cursor:
	mov	[di], ax			; Cursor at upper left of page
	inc	di				;   next page
	loop	@@cursor

	mov	al, [cs:bx+max_cols]		; Get display width
	mov	[ds:4Ah], ax			;   save it
	and	bl, 11111110b
	mov	ax, [word cs:bx+regen_len]	; Get video regen length
	mov	[ds:4Ch], ax			;   save it
	ret

endp	int_10_func_0


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 1: Set cursor type
;---------------------------------------------------------------------------------------------------
proc	int_10_func_1	near

	mov	cx, [bp+6]			; Set cursor type, from cx
	mov	[ds:60h], cx			;   save it
	mov	ah, 0Ah 			; CRT index register 0Ah
	call	out_6845			;   send ch, cl to CRT register
	ret

endp	int_10_func_1


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 2: Set cursor position
;---------------------------------------------------------------------------------------------------
proc	int_10_func_2	near

	mov	bl, [bp+5]			; Set cursor position, page bh
	shl	bl, 1				;   (our bl)
	mov	bh, 0
	mov	ax, [bp+8]			; Position in user dx (our ax)
	mov	[bx+50h], ax			;   remember cursor position
	jmp	set_cursor			;   set 6845 cursor hardware

endp	int_10_func_2


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 3: Get cursor position
;---------------------------------------------------------------------------------------------------
proc	int_10_func_3	near

	mov	bl, [bp+5]			; Get cursor position, page bh
	shl	bl, 1
	mov	bh, 0
	mov	ax, [bx+50h]
	mov	[bp+8], ax			;   return position in user dx
	mov	ax, [ds:60h]			; Get cursor mode
	mov	[bp+6], ax			;   return in user cx
	ret

endp	int_10_func_3


pen_offset	db	3, 3, 5, 5, 3, 3, 3, 4	; Light pen offset table


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 4: Read light pen position
;---------------------------------------------------------------------------------------------------
proc	int_10_func_4	near

	mov	dx, [ds:63h]
	add	dl, 6
	mov	[byte bp+3], 0			; ah=0, assume not triggered
	in	al, dx
	test	al, 00000100b
	jz	@@reset				; Skip, reset if pen not set
	test	al, 00000010b
	jnz	@@triggered			; Skip if pen triggered
	ret					;   return, do not reset

@@triggered:
	mov	ah, 10h 			; Offset to pen port is 10h
	call	pen_pos				;   read into ch, cl
	mov	bl, [ds:49h]			; Get CRT mode data word
	mov	cl, bl
	mov	bh, 0
	mov	bl, [byte cs:bx+pen_offset]	; Load offset for subtraction
	sub	cx, bx
	jns	@@mode				;   did not overflow
	xor	ax, ax				; Else fudge a zero

@@mode:	call	mode_check			; Set flags on display type
	jnb	@@text				;   text mode, skip
	mov	ch, 28h
	div	dl
	mov	bl, ah
	mov	bh, 0
	mov	cl, 3
	shl	bx, cl
	mov	ch, al
	shl	ch, 1
	mov	dl, ah
	mov	dh, al
	shr	dh, 1
	shr	dh, 1
	cmp	[byte ds:49h], 6		; Mode 640x200 b/w?
	jnz	@@done				;   no, skip
	shl	dl, 1
	shl	bx, 1
	jmp	short @@done

@@text:	div	[byte ds:4Ah]			; Divide by columns in screen
	xchg	al, ah				;   as this is text mode
	mov	dx, ax
	mov	cl, 3
	shl	ah, cl
	mov	ch, ah
	mov	bl, al
	mov	bh, 0
	shl	bx, cl

@@done:	mov	[byte bp+3], 1			; Return ah=1, light pen read
	mov	[bp+8], dx			;   row, column in user dx
	mov	[bp+4], bx			;   pixel column in user bx
	mov	[bp+7], ch			;   raster line in user ch

@@reset:
	mov	dx, [ds:63h]			; Get port of active CRT card
	add	dx, 7
	out	dx, al				;   reset the light pen
	ret

endp	int_10_func_4


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 5: Set active display page
;---------------------------------------------------------------------------------------------------
proc	int_10_func_5	near

	mov	al, [bp+2]			; Set active display page to al
	mov	[ds:62h], al			;   save new active page
	mov	ah, 0				;   clear high order
	push	ax
	mov	bx, [ds:4Ch]			; Get size of regen buffer
	mul	bx				;   times number of pages
	mov	[ds:4Eh], ax			; Now ax = CRT offset, save
	shr	ax, 1				;   now word offset
	mov	cx, ax				;   save a copy
	mov	ah, 0Ch 			; CRT index register 0Ch
	call	out_6845			;   send ch, cl through CRT register
	pop	bx
	call	move_cursor			; Save new parameters
	ret

endp	int_10_func_5


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 6: Scroll active page up
;                 Function 7: Scroll active page down
;---------------------------------------------------------------------------------------------------
proc	int_10_func_6_7	near

	call	mode_check
	jnb	@@text
	jmp	near @@graphics			; Graphics scroll

@@text: cld					; Strings go upward
	cmp	[byte ds:49h], 2
	jb	@@get_coords			;   no retrace wait needed
	cmp	[byte ds:49h], 3
	ja	@@get_coords			;   no retrace wait needed
	mov	dx, 3DAh			; Else 80x25, do the kludge

@@wait: in	al, dx				; Read CGA status register
	test	al, 00001000b			;   vertical retrace?
	jz	@@wait				;   wait until it is
	mov	dx, 3D8h			; Then go and
	mov	al, 25h 			;   turn the display
	out	dx, al				;   off to avoid snow

@@get_coords:
	mov	ax, [bp+8]			; Get row, column of upper left
	push	ax
	cmp	[byte bp+3], 7			; Check for scroll down
	jz	@@offset			;   yes, skip if so
	mov	ax, [bp+6]			; Get row, column of lower right

@@offset:
	call	rc_to_col			; Get byte offset in CRT buffer
	add	ax, [ds:4Eh]			;   add base for CRT buffer
	mov	si, ax
	mov	di, ax
	pop	dx
	sub	dx, [bp+6]			; Subtract (row, col) lwr rhgt
	add	dx, 101h			;   width of one char
	mov	bx, [ds:4Ah]			; Get columns in display
	shl	bx, 1				;   bytes in row of display
	push	ds
	mov	al, [bp+2]			; Get scroll fill character
	call	map_byte			;   calculate offset
	mov	es, cx				; cx --> byte in buffer
	mov	ds, cx
	cmp	[byte bp+3], 6			; Scroll up?
	jz	@@count				;   skip if so
	neg	ax
	neg	bx
	std					; Else start at top of page

@@count:
	mov	cl, [bp+2]			; Get count of lines to scroll
	or	cl, cl
	jz	@@attr				;   nothing to do
	add	si, ax
	sub	dh, [bp+2]

@@scroll:
	mov	ch, 0				; Clear high order word count
	mov	cl, dl				;   load low order word count
	push	di
	push	si
	rep	movsw				; Do the scroll
	pop	si
	pop	di
	add	si, bx				; Move one line in direction
	add	di, bx				;	 ""	  ""
	dec	dh				; One less line to scroll
	jnz	@@scroll
	mov	dh, [bp+2]			; Now get number of rows

@@attr: mov	ch, 0				; Clear high order word count
	mov	ah, [bp+5]			;   get fill attribute
	mov	al, ' ' 			;   fill character

@@fill: mov	cl, dl				; Get characters to scroll
	push	di
	rep	stosw				;   store fill attr/char
	pop	di
	add	di, bx				; Show row was filled
	dec	dh
	jnz	@@fill				;   more rows are left
	pop	ds
	call	mode_check			; Check for monochrome card
	jz	@@done				;   skip if so
	mov	al, [ds:65h]			; Get the mode data byte
	mov	dx, 3D8h			;   load active CRT card port
	out	dx, al				;   and unblank the screen

@@done: ret

@@graphics:
	cld					; Assume graphics scroll up
	mov	ax, [bp+8]			; (Row, Col) of lower right
	push	ax
	cmp	[byte bp+3], 7			; Scroll down?
	jz	@@gfx_offset			;   skip if so
	mov	ax, [bp+6]			; (Row, Col) of upper left

@@gfx_offset:
	call	gfx_rc_col			; Convert (Row, Col) -> Chars
	mov	di, ax
	pop	dx
	sub	dx, [bp+6]			; Chars to copy over
	add	dx, 101h			;   width of one char
	shl	dh, 1
	shl	dh, 1
	mov	al, [bp+3]			; Get command type
	cmp	[byte ds:49h], 6		;   is this 640x200?
	jz	@@gfx_next			;   skip if so
	shl	dl, 1				; Else bigger characters
	shl	di, 1
	cmp	al, 7				; Is this scroll down?
	jnz	@@gfx_next			;   skip if not so
	inc	di

@@gfx_next:
	cmp	al, 7				; Is this scroll down?
	jnz	@@gfx_start			;   skip if not so
	add	di, 0F0h

@@gfx_start:
	mov	bl, [bp+2]			; Number of rows to blank
	shl	bl, 1
	shl	bl, 1
	push	bx
	sub	dh, bl				; Subtract from row count
	mov	al, 50h
	mul	bl
	mov	bx, 1FB0h
	cmp	[byte bp+3], 6			; Is this scroll up?
	jz	@@gfx_end			;   skip if so
	neg	ax				; Else do it
	mov	bx, 2050h
	std					;   in reverse

@@gfx_end:
	mov	si, di				; End of area
	add	si, ax				;   start
	pop	ax
	or	al, al
	mov	cx, [bp+0]
	mov	ds, cx
	mov	es, cx
	jz	@@gfx_attr			; No rows to scroll
	push	ax

@@gfx_scroll:
	mov	ch, 0				; Zero hi order byte count
	mov	cl, dl				;   bytes in row
	push	si
	push	di
	rep	movsb				; Copy one plane
	pop	di
	pop	si
	add	si, 2000h			; Load other graphics
	add	di, 2000h			;   video plane
	mov	cl, dl
	push	si
	push	di
	rep	movsb				; Copy other plane
	pop	di
	pop	si
	sub	si, bx
	sub	di, bx
	dec	dh				; One less row to scroll
	jnz	@@gfx_scroll			;   loop if more to do
	pop	ax
	mov	dh, al				; Load rows to blank

@@gfx_attr:
	mov	al, [bp+5]			; Get fill attribute
	mov	ch, 0

@@gfx_fill:
	mov	cl, dl				; Get bytes per row
	push	di
	rep	stosb				; Load row with fill attribute
	pop	di
	add	di, 2000h			; Do other graphics video plane
	mov	cl, dl
	push	di
	rep	stosb				; Load row with fill attribute
	pop	di
	sub	di, bx
	dec	dh				; Show one less row to blank
	jnz	@@gfx_fill			;   loop if more to do
	ret

endp	int_10_func_6_7


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 8: Read attribute/character
;                 Function 9: Write attribute/character
;                 Function 10: Write character only
;---------------------------------------------------------------------------------------------------
proc	int_10_func_8_9_10	near

	call	mode_check
	jb	@@graphics			; Graphics operation
	mov	bl, [bp+5]			; Get the display page
	mov	bh, 0
	push	bx
	call	text_rc_col			; Convert Row, Col, Page -> Col
	mov	di, ax				;   offset in di
	pop	ax
	mul	[word ds:4Ch]			; Page length X page number
	add	di, ax				;   current char position
	mov	si, di				;   move into si
	mov	dx, [ds:63h]			; Display port into dx
	add	dx, 6				;   get status port
	push	ds
	mov	bx, [bp+0]			; bx --> regen. buffer
	mov	ds, bx
	mov	es, bx
	mov	al, [bp+3]			; Get user (ah) function request
	cmp	al, 8
	jnz	@@write				;   skip if not read attribute

@@read:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jnz	@@read				; Yes, wait for display on
	cli					;   no interrupts now

@@read_wait:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jz	@@read_wait			;   not yet, wait for it

	lodsw					; Read character/attribute
	pop	ds
	mov	[bp+2], al			; Return character
	mov	[bp+3], ah			;   and attribute
	ret

@@write:
	mov	bl, [bp+2]			; Get character to write
	mov	bh, [bp+4]			;   attribute
	mov	cx, [bp+6]			;   character count
	cmp	al, 0Ah 			; Write character only?
	jz	@@char_write			;   skip if so

@@write_loop:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jnz	@@write_loop			; Yes, wait for display on
	cli					;   no interrupts now

@@write_wait:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jz	@@write_wait			;   not yet, wait for it

	mov	ax, bx				; Get char/attribute
	stosw					;   write it
	loop	@@write_loop			;   loop for character count
	pop	ds
	ret

@@char_write:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jnz	@@char_write			;   not yet, wait for it
	cli					;   no interrupts now

@@char_wait:
	in	al, dx				; Read CRT display status
	test	al, 00000001b			;   test for horizontal retrace
	jz	@@char_wait			;   not yet, wait for it

	mov	al, bl				; Get character
	stosb					;   write it
	inc	di				;   skip attribute
	loop	@@char_write			;   loop for character count
	pop	ds
	ret

@@graphics:
	cmp	[byte bp+3], 8			; Read graphics char/attr?
	jnz	@@gfx_write			;   no, must be write
	jmp	near @@gfx_read			; Else read char/attr

@@gfx_write:
	mov	ax, [ds:50h]			; Get cursor position
	call	gfx_rc_col			;   convert (row, col) -> col
	mov	di, ax				; Save in displacement register
	push	ds
	mov	al, [bp+2]			; Get character to write
	mov	ah, 0
	or	al, al				; Is it user character set?
	js	@@user_chars			;   skip if so
	mov	dx, cs				; Else use ROM character set
	mov	si, offset gfx_chars		;   offset gfx_chars into si
	jmp	short @@buffer

@@user_chars:
	and	al, 7Fh 			; Origin to zero
	xor	bx, bx				;   then go load
	mov	ds, bx				;   user graphics
	lds	si, [dword ds:7Ch]		;   vector, offset in si
	mov	dx, ds				;   segment into dx

@@buffer:
	pop	ds				; Restore data segment
	mov	cl, 3				;   char 8 pixels wide
	shl	ax, cl
	add	si, ax				; Add regen buffer base address
	mov	ax, [bp+0]			;   get regen buffer address
	mov	es, ax				;   into es
	mov	cx, [bp+6]			;   load character count
	cmp	[byte ds:49h], 6		; Is the mode 640x200 b/w?
	push	ds
	mov	ds, dx
	jz	@@write_640x200			;   skip if so
	shl	di, 1
	mov	al, [bp+4]			; Get character attribute
	and	ax, 3
	mov	bx, 5555h
	mul	bx
	mov	dx, ax
	mov	bl, [bp+4]

@@gfx_write_loop:
	mov	bh, 8				; Char 8 pixels wide
	push	di
	push	si

@@write_read:
	lodsb					; Read the screen
	push	cx
	push	bx
	xor	bx, bx
	mov	cx, 8

@@shift:
	shr	al, 1				; Shift bits through byte
	rcr	bx, 1
	sar	bx, 1
	loop	@@shift

	mov	ax, bx				; Result into ax
	pop	bx
	pop	cx
	and	ax, dx
	xchg	ah, al
	or	bl, bl
	jns	@@write_word
	xor	ax, [es:di]

@@write_word:
	mov	[es:di], ax			; Write new word
	xor	di, 2000h
	test	di, 2000h			; Is this other plane?
	jnz	@@write_next			;   nope
	add	di, 50h 			; Else advance character

@@write_next:
	dec	bh				; Show another char written
	jnz	@@write_read			;   more to go
	pop	si
	pop	di
	inc	di
	inc	di
	loop	@@gfx_write_loop
	pop	ds
	ret

@@write_640x200:
	mov	bl, [bp+4]			; Get display page
	mov	dx, 2000h			;   size of graphics plane

@@write_loop_640:
	mov	bh, 8				; Pixel count to write
	push	di
	push	si

@@write_read_640:
	lodsb					; Read from one plane
	or	bl, bl				;   done both planes?
	jns	@@write_byte_640		;   skip if not
	xor	al, [es:di]			; Else load attribute

@@write_byte_640:
	mov	[es:di], al			; Write out attribute
	xor	di, dx				;   get other plane
	test	di, dx				; Done both planes?
	jnz	@@write_next_640		;   skip if not
	add	di, 50h 			; Else position for now char

@@write_next_640:
	dec	bh				; Show row of pixels read
	jnz	@@write_read_640		;   not done all of them
	pop	si
	pop	di
	inc	di
	loop	@@write_loop_640
	pop	ds
	ret

@@gfx_read:
	cld					; Increment upwards
	mov	ax, [ds:50h]			;   get cursor position
	call	gfx_rc_col			; Convert (row, col) -> columns
	mov	si, ax				;   save in si
	sub	sp, 8				; Grab 8 bytes temp storage
	mov	di, sp				;   save base in di
	cmp	[byte ds:49h], 6		; Mode 640x200 b/w?
	mov	ax, [bp+0]			;   ax --> CRT regen buffer
	push	ds
	push	di
	mov	ds, ax
	jz	@@640x200			; Mode is 640x200 b/w - skip
	mov	dh, 8				; Eight pixels high/char
	shl	si, 1
	mov	bx, 2000h			; Bytes per video plane

@@read_loop:
	mov	ax, [si]			; Read existing word
	xchg	ah, al
	mov	cx, 0C000h			; Attributes to scan for
	mov	dl, 0

@@attr: test	ax, cx				; Look for attributes
	clc
	jz	@@skip				;   set, skip
	stc					; Else show not set

@@skip: rcl	dl, 1
	shr	cx, 1
	shr	cx, 1
	jnb	@@attr				;   more shifts to go
	mov	[ss:di], dl
	inc	di
	xor	si, bx				; Do other video plane
	test	si, bx				;   done both planes?
	jnz	@@row_done			;   no, skip
	add	si, 50h 			; Else advance pointer

@@row_done:
	dec	dh				; Show another pixel row done
	jnz	@@read_loop			;   more rows to do
	jmp	short @@load_chars

@@640x200:
	mov	dh, 4				; Mode 640x200 b/w - special

@@read_plane:
	mov	ah, [si]			; Read pixels from one plane
	mov	[ss:di], ah			;   save on stack
	inc	di				;   advance
	mov	ah, [si+2000h]			; Read pixels from other plane
	mov	[ss:di], ah			; Save pixels on stack
	inc	di				;   advance
	add	si, 50h 			; Total pixels in char
	dec	dh				;   another row processed
	jnz	@@read_plane			;   more to do

@@load_chars:
	mov	dx, cs				; Load segment of graphics char
	mov	di, offset gfx_chars		;   and offset
	mov	es, dx				;   save offset in es
	mov	dx, ss
	mov	ds, dx
	pop	si
	mov	al, 0

@@gfx_user_chars:
	mov	dx, 80h 			; Number of characters in graphics set

@@gfx_read_loop:
	push	si
	push	di
	mov	cx, 8				; Bytes to compare for char
	repz	cmpsb				;   do compare
	pop	di
	pop	si
	jz	@@read_done			; Found graphics character
	inc	al				;   else show another char
	add	di, 8				;   advance one row
	dec	dx				;   one less char to scan
	jnz	@@gfx_read_loop			; Loop if more char left

	or	al, al				; User graphics character set?
	jz	@@read_done			;   no, not found
	xor	bx, bx
	mov	ds, bx
	les	di, [dword ds:7Ch]		; Else load user graphics char
	mov	bx, es
	or	bx, di
	jz	@@read_done			;   not found
	jmp	@@gfx_user_chars		; Try using user graphics char

@@read_done:
	mov	[bp+2], al			; Return char in user al
	pop	ds
	add	sp, 8				;   return temp storage
	ret

endp	int_10_func_8_9_10


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 11: Set color
;---------------------------------------------------------------------------------------------------
proc	int_10_func_11	near

	mov	dx, [ds:63h]			; Set color, get CGA card port
	add	dx, 5				;   color select register
	mov	al, [ds:66h]			; Get CRT palette
	mov	ah, [bp+5]			;   new palette ID, user bh
	or	ah, ah
	mov	ah, [bp+4]			;   new palette color, user bl
	jnz	@@skip				; Palette ID specified, skip
	and	al, 0E0h
	and	ah, 1Fh 			; Null ID = ID 01Fh
	or	al, ah				;   set in color
	jmp	short @@new_palette

@@skip: and	al, 0DFh
	test	ah, 1
	jz	@@new_palette
	or	al, 20h

@@new_palette:
	mov	[ds:66h], al			; Save new palette
	out	dx, al				;   tell CGA about it
	ret

endp	int_10_func_11


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 12: Write pixel
;---------------------------------------------------------------------------------------------------
proc	int_10_func_12	near

	mov	ax, [bp+0]			; Write pixel
	mov	es, ax
	mov	dx, [bp+8]			; Load row from user dx
	mov	cx, [bp+6]			;   col from user cx
	call	dot_offset			; Find dot offset
	jnz	@@ok				;   valid
	mov	al, [bp+2]			; Load user color
	mov	bl, al
	and	al, 1
	ror	al, 1
	mov	ah, 7Fh
	jmp	short @@read

@@ok:	shl	cl, 1
	mov	al, [bp+2]
	mov	bl, al
	and	al, 3
	ror	al, 1
	ror	al, 1
	mov	ah, 3Fh

@@read:	ror	ah, cl
	shr	al, cl
	mov	cl, [es:si]			; Read the char with the dot
	or	bl, bl
	jns	@@color
	xor	cl, al				; Exclusive or existing color
	jmp	short @@write

@@color:
	and	cl, ah				; Set new color for dot
	or	cl, al

@@write:
	mov	[es:si], cl			; Write out char with the dot
	ret

endp	int_10_func_12


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 13: Read pixel
;---------------------------------------------------------------------------------------------------
proc	int_10_func_13	near

	mov	ax, [bp+0]			; ax --> video regen buffer
	mov	es, ax				;   into es segment
	mov	dx, [bp+8]			; Load row from user dx
	mov	cx, [bp+6]			;   col from user cx
	call	dot_offset			; Calculate dot offset
	mov	al, [es:si]			;   read dot
	jnz	@@offset			;   was there
	shl	al, cl
	rol	al, 1
	and	al, 1
	jmp	short @@done

@@offset:
	shl	cl, 1				; Calculate offset in char
	shl	al, cl
	rol	al, 1
	rol	al, 1
	and	al, 3

@@done:	mov	[bp+2], al			; Return dot pos in user al
	ret

endp	int_10_func_13


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 14: Write teletype
;---------------------------------------------------------------------------------------------------
proc	int_10_func_14	near

	mov	bl, [ds:62h]			; Get active video page (0-7)
	shl	bl, 1				;   as word index
	mov	bh, 0				;   clear high order
	mov	dx, [bx+50h]			; Index into cursor position

	mov	al, [bp+2]			; Get character to write
	cmp	al, 8				;   back space?
	jz	@@back_space			;   skip if so
	cmp	al, LF				; Is it a line feed?
	jz	@@line_feed			;   skip if so
	cmp	al, 7				; Print a bell?
	jz	@@beep				;   do beep
	cmp	al, CR				; Is it a carriage return?
	jz	@@carriage_return		;   skip if so
	mov	bl, [bp+4]			; Else write at cursor position
	mov	ah, 0Ah
	mov	cx, 1				;   one time
	int	10h
	inc	dl				; Advance cursor
	cmp	dl, [ds:4Ah]			;   check for line overflow
	jnz	@@position
	mov	dl, 0				; Overflowed, then fake
	jmp	short @@line_feed		;   new line

@@back_space:
	cmp	dl, 0				; At start of line?
	jz	@@position			;   skip if so
	dec	dl				; Else back up
	jmp	short @@position		;   join common code

@@beep:	mov	bl, 1				; Do a short
	call	beep				;   beep
	ret

@@carriage_return:
	mov	dl, 0				; Position to start of line

@@position:
	mov	bl, [ds:62h]			; Get active video page (0-7)
	shl	bl, 1				;   as word index
	mov	bh, 0				;   clear high order
	mov	[bx+50h], dx			; Remember the cursor position
	jmp	set_cursor			;   set 6845 cursor hardware

@@line_feed:
	cmp	dh, 18h 			; Done all 24 lines on page?
	jz	@@scroll			;   yes, scroll
	inc	dh				; Else advance line
	jnz	@@position

@@scroll:
	mov	ah, 2				; Position cursor at line start
	int	10h
	call	mode_check			; Is this text mode?
	mov	bh, 0
	jb	@@scroll_up			; Skip if text mode
	mov	ah, 8
	int	10h				;   else read attribute
	mov	bh, ah

@@scroll_up:
	mov	ah, 6				; Now prepare to
	mov	al, 1				;   scroll
	xor	cx, cx				;   the
	mov	dh, 18h 			;   page
	mov	dl, [ds:4Ah]			;   up
	dec	dl
	int	10h
	ret

endp	int_10_func_14


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 15: Return current video state
;---------------------------------------------------------------------------------------------------
proc	int_10_func_15	near

	mov	al, [ds:4Ah]			; Get current video state
	mov	[bp+3], al			;   columns
	mov	al, [ds:49h]
	mov	[bp+2], al			;   mode
	mov	al, [ds:62h]
	mov	[bp+5], al			;   page
	ret

endp	int_10_func_15


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Video mode check
;---------------------------------------------------------------------------------------------------
proc	mode_check	near

	push	ax				; Set flags to current mode
	mov	al, [ds:49h]			;   get mode
	cmp	al, 7				;   equal if mono
	jz	@@done
	cmp	al, 4
	cmc
	jnb	@@done				;   carry set on graphics
	sbb	al, al
	stc

@@done: pop	ax
	ret

endp	mode_check


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Calculate dot offset
;---------------------------------------------------------------------------------------------------
proc	dot_offset	near

	mov	al, 50h 			; Dots in character position
	xor	si, si
	shr	dl, 1				; Two bytes/char position
	jnb	@@calc				;   no overflow
	mov	si, 2000h			; Else on other video plane

@@calc: mul	dl				; Multiply position by row
	add	si, ax				;   add in column position
	mov	dx, cx				; Copy column position
	mov	cx, 302h			;   regular char size
	cmp	[byte ds:49h], 6		; Mode 640x200, b/w?
	pushf
	jnz	@@done				;   skip if not
	mov	cx, 703h			; Else special char size

@@done: and	ch, dl
	shr	dx, cl
	add	si, dx
	xchg	cl, ch
	popf
	ret

endp	dot_offset


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Read light pen position
;---------------------------------------------------------------------------------------------------
proc	pen_pos	near

	call	near @@pen_xy			; Read light pen position high
	mov	ch, al				;   save in ch
	inc	ah
	call	near @@pen_xy			; Read light pen position low
	mov	cl, al				;   save in cl
	ret

@@pen_xy:
	push	dx				; Read CRT register offset al
	mov	dx, [ds:63h]			;   get active CRT port
	xchg	al, ah
	out	dx, al				; Send initialization byte
	inc	dl				;   increment
	in	al, dx				; Read pen position byte back
	pop	dx
	ret

endp	pen_pos


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Convert (row, col) coordinates to column count for text modes
;---------------------------------------------------------------------------------------------------
proc	text_rc_col	near

	mov	bh, 0				; Convert Row, Col, Page -> Col
	shl	bx, 1				;   two bytes/column
	mov	ax, [bx+50h]			; Get page number in ax
						;   join common code
rc_to_col:
	push	bx				; Map (ah=row, al=col) to col
	mov	bl, al
	mov	al, ah
	mul	[byte ds:4Ah]			; Multiply Row x (Row/Column)
	mov	bh, 0
	add	ax, bx				;   add in existing col
	shl	ax, 1				;   times 2 because 2 bytes/col
	pop	bx
	ret

endp	text_rc_col


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Convert (row, col) coordinates to column count for graphics modes
;---------------------------------------------------------------------------------------------------
proc	gfx_rc_col	near

	push	bx				; Convert (row, col) -> col
	mov	bl, al				;   save column
	mov	al, ah				;   get row
	mul	[byte ds:4Ah]			; Multiply by columns/row
	shl	ax, 1
	shl	ax, 1
	mov	bh, 0
	add	ax, bx				; Add in columns
	pop	bx
	ret

endp	gfx_rc_col


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Internal: Set 6845 cursor position
;---------------------------------------------------------------------------------------------------
proc	set_cursor	near

	shr	bl, 1				; Sets 6845 cursor position
	cmp	[ds:62h], bl			;   is this page visible?
	jnz	@@done				; No, do nothing in hardware

move_cursor:
	call	text_rc_col			; Map row, col, page to col
	add	ax, [ds:4Eh]			;   + byte offset, regen register
	shr	ax, 1
	mov	cx, ax
	mov	ah, 0Eh 			; Tell 6845 video controller
						;   to position the cursor
out_6845:
	mov	al, ch				; Send ch, cl through CRT register ah
	call	send_ax				;   send ch
	inc	ah				;   increment
	mov	al, cl				;   send cl

send_ax:
	push	dx
	mov	dx, [ds:63h]			; Load active video port
	xchg	al, ah
	out	dx, al				; Send high order
	xchg	al, ah
	inc	dl
	out	dx, al				;   low order
	pop	dx

@@done: ret

endp	set_cursor

