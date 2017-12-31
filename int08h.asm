;---------------------------------------------------------------------------------------------------
; Interrupt 08h - IRQ0
;---------------------------------------------------------------------------------------------------
proc		int_08h near
                push	ds
                push	ax
                push	dx
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                inc	[word ptr ds:timer_low_]
                jnz	short loc_FFEB9
                inc	[word ptr ds:timer_hi_]

loc_FFEB9:				; ...
                cmp	[word ptr ds:timer_hi_], 18h
                jnz	short loc_FFED3
                cmp	[word ptr ds:timer_low_], 0B0h
                jnz	short loc_FFED3
                mov	[ds:timer_hi_], ax
                mov	[ds:timer_low_], ax
                mov	[byte ptr ds:timer_rolled_], 1

loc_FFED3:				; ...
                inc	ax
                dec	[byte ptr ds:dsk_motor_tmr]
                jnz	short loc_FFEE7
                and	[byte ptr ds:dsk_motor_stat], 0FCh
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_2]
                out	dx, al

loc_FFEE7:				; ...
                int	1Ch		; CLOCK	TICK
                mov	al, 20h
                out	20h, al		; Interrupt controller,	8259A.
                pop	dx
                pop	ax
                pop	ds
                assume ds:nothing
                iret
endp		int_08h
