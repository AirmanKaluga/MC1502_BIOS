;---------------------------------------------------------------------------------------------------
; Interrupt 19h - Warm Boot
;---------------------------------------------------------------------------------------------------
proc		int_19h
                xor	dx, dx 
                mov	es, dx
                mov	dl, 80h

read_boot_sector:
				; ...
                mov	cx, 3

read_boot_sector_loop:				; ...
                push	cx
                mov	ah, dh
                int	13h		; DISK - RESET DISK SYSTEM
                                        ; DL = drive (if bit 7 is set both hard	disks and floppy disks reset)
                jb	short error_disk_system_on_boot
                mov	bx, 7C00h
                mov	cx, 1
                mov	ax, 201h
                int	13h		; DISK - READ SECTORS INTO MEMORY
                                        ; AL = number of sectors to read, CH = track, CL = sector
                                        ; DH = head, DL	= drive, ES:BX -> buffer to fill
                                        ; Return: CF set on error, AH =	status,	AL = number of sectors read
                pop	cx
                jnb	short try
                loop	read_boot_sector_loop

error_disk_system_on_boot:.
                shl	dl, 1
                jb	short read_boot_sector
                test	[byte ptr es:dsk_motor_stat_], 40h
                jnz	short System_not_found
                or	[byte ptr es:dsk_motor_stat_], 40h
                jmp	short read_boot_sector
; ---------------------------------------------------------------------------

System_not_found:				; ...
                mov	si, offset SystemNotFound
                call	print_string
                sti

		mov	si, offset str_ins_disk		; Load disk message
		call	print_string			;   and print string
		call	get_key				;   wait for keypress
		call	clear_screen
		call	int_19h
; ---------------------------------------------------------------------------

try:				; ...
                cmp	[word ptr es:7DFEh], 0AA55h
                jnz	short error_disk_system_on_boot
                jmpfar 0,7C00h

endp		int_19h
