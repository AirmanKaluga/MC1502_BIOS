;---------------------------------------------------------------------------------------------------
; Interrupt 11h - Equipment Check
;---------------------------------------------------------------------------------------------------
proc		int_11h near
                sti
                push	ds
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:equip_bits_]
                pop	ds
                assume ds:nothing
                iret
endp		int_11h
