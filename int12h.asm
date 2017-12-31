;------------------------------------------------------------------------------------
; Interrupt 12h -- Memory size
;------------------------------------------------------------------------------------
proc		int_12h near
                sti
                push	ds
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:main_ram_size_]
                pop	ds
                assume ds:nothing
                iret
endp		int_12h
