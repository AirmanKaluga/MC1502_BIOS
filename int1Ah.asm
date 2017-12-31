;------------------------------------------------------------------------------------
; Interrupt 1Ah -- Real time Clock Function
;------------------------------------------------------------------------------------
proc 		int_1Ah near
                push	ds
                push	ax
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                pop	ax
                or	ah, ah
                jz	short Read_Clock
                dec	ah
                jz	short Set_Clock

exit_int_1a:				; ...
                pop	ds
                assume ds:nothing
                iret
endp		int_1Ah

Read_Clock:				; ...
                mov	al, [ds:timer_rolled_]
                mov	[byte ptr ds:timer_rolled_], 0
                mov	cx, [ds:timer_hi_]
                mov	dx, [ds:timer_low_]
                jmp	short exit_int_1a
; ---------------------------------------------------------------------------

Set_Clock:				; ...
                mov	[ds:timer_low_], dx
                mov	[ds:timer_hi_], cx
                mov	[byte ptr ds:timer_rolled_], 0
                jmp	short exit_int_1a
