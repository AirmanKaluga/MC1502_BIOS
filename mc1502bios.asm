	Ideal
	model small ; produce .EXE file then truncate it
;---------------------------------------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------------------------------------
; Pad code to create entry point at specified address (needed for 100% IBM BIOS compatibility)
macro	jmpfar	segm, offs
        db	0EAh;
        dw	offs, segm
endm

;---------------------------------------------------------------------------------------------------
include	var.asm	;Variables
;---------------------------------------------------------------------------------------------------


; Segment type:	Pure code
segment		code byte public 'CODE'
                assume cs:code
                org 0E000h
                assume es:nothing, ss:nothing, ds:nothing


Banner:
	        db 'Elektronika MS 1502 BIOS Version 7.3 - 31/12/2017', 0

Copiright:	
		db LF, CR, 7, "Updated Airman and RUS", LF, CR, 0
empty_string:
		db LF, CR, 0
str_8088:
	 	db LF, CR, 'Intel (C) 8088 Processor 5.33Mhz Installed', LF, CR, 0
str_v20:
	   	db LF, CR, 'NEC (C) V20 Processor 5.33Mhz Installed', LF, CR, 0
TestingSystem:
		db LF, CR, '000 K System RAM Passed', 0
FailedAt:
		db 7, LF, CR, 'Failed at ', 0
SystemNotFound:
		db 7, LF, CR, 'System not found.', LF, CR, 0
str_8087:
		db LF, CR, 'Intel (C) 8087 FPU 5.33Mhz Installed', 0
str_nofpu:	db LF, CR, 'No FPU Istalled', 0
port_int_fdc:
                db  48h	 		; ...
                db  4Ch
                db  4Eh
                db  4Dh

port_ext_fdc:
                db  0Ch
                db  00h
                db  08h
                db  0Ah


baud:
		dw    470h 
                dw    341h
                dw    1A1h
                dw    0D0h
                dw    068h
                dw    034h
                dw    01Ah
                dw    00Dh
BDA:

rs232_1:	dw    3F8h
rs232_2:	dw    2F8h
rs232_3:	dw    0
rs232_4:	dw    0
lpt_1:		dw    378h
lpt_2:		dw    278h
lpt_3:		dw    0
bios_data_seg:	dw    0
equip_bit:	dw    626Dh
manufact_test:	db    0
main_ram_size:	dw    0
error_codes:	dw    40h
kb_flag_1:	db    0
kb_flag_2:	db    0
kb_alt_num:	db    0
kb_q_head:	dw  1Eh
kb_q_tail:	dw  1Eh
kb_queue:	dw  1Eh


; ---------------------------------------------------------------------------
proc		post	near
warm_boot:				; Entered by POWER_ON/RESET
                cli
                cld
@@init_PPI:
                mov	al, 88h
                out	63h, al		; PC/XT	PPI Command/Mode Register.
                                        ; Selects which	PPI ports are input or output.
                                        ; BIOS sets to 99H (Ports A and	C are input, B is output).
                mov	al, 98h
                out	6Bh, al
                mov	al, 9
                out	62h, al		; PC/XT	PPI port C. Bits:
                                        ; 0-3: values of DIP switches
                                        ; 5: 1=Timer 2 channel out
                                        ; 6: 1=I/O channel check
                                        ; 7: 1=RAM parity check	error occurred.

                mov	al, 0E0h
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
@@init_PIC:		
                mov	al, 13h
                out	20h, al		; Interrupt controller,	8259A.
                mov	al, 08h
                out	21h, al		; Interrupt controller,	8259A.
                mov	al, 9
                out	21h, al		; Interrupt controller,	8259A.
@@init_PIT:
                mov	al, 36h
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 0
                out	40h, al		; Timer	8253-5 (AT: 8254.2).
                out	40h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 50h
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 4
                out	41h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 0B6h
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                mov	al, 2
                out	42h, al		; Timer	8253-5 (AT: 8254.2).
                out	42h, al		; Timer	8253-5 (AT: 8254.2).
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	ss, ax
                mov	sp, 800h
                mov	bp, [ds:warm_boot_flag_]
                mov	di, ax
                mov	es, ax
                mov	cx, 380h
                rep stosw
                push	cs
                pop	ds
                assume ds:nothing

@@init_vec_table_1:
                mov	cx, 17h
                mov	si, offset int_vec_table_1
                mov	di, 20h

vec_table_1_loop:				; ...
                lodsw
                stosw
                mov	ax, cs
                stosw
                loop	vec_table_1_loop

@@init_dummy_int:
                mov	di, 8
                mov	ax, offset dummy_int
                stosw
                mov	ax, cs
                stosw

@@init_print_screen_int:
                mov	di, 14h
                mov	ax, offset int_05h
                stosw
                mov	ax, cs
                stosw
                mov	ax, BDAseg
                mov	es, ax
                assume es:nothing

@@init_BDA:
                mov	cx, 10h
                mov	si, offset BDA
                xor	di, di
                rep movsw
@@Test_type_fdc:
                in	al, 4Bh
                not	al
                out	4Bh, al
                mov	ah, al
                in	al, 4Bh
                mov	si, offset port_int_fdc
                cmp	al, ah
                jz	short init_fdc_BDA
                mov	si, offset port_ext_fdc

init_fdc_BDA:				; ...
                mov	di, 42h
                movsw
                movsw
                mov	di, 80h
                mov	ax, 1Eh
                stosw
                mov	ax, 3Eh
                stosw
                mov	al, 18h
                stosb
                mov	di, 90h
                xor	ax, ax
                stosw
                mov	bx, ax
                mov	cx, ax
                mov	di, ax
                mov	ds, ax
                assume ds:nothing

loc_FE12E:				; ...
                mov	ax, [bx]
                not	ax
                mov	[bx], ax
                cmp	ax, [bx]
                jnz	short Print_Startup_Information
                not	[word ptr bx]
                add	ch, 8
                mov	ds, cx
                assume ds:nothing
                add	di, 20h
                cmp	di, 2E0h
                jb	short loc_FE12E

Print_Startup_Information:				; ...
                mov	[es:13h], di
                mov	al, 0FCh
                out	21h, al		; Interrupt controller,	8259A.
                sti

                mov	ax, 3
                int	10h		; - VIDEO - SET	VIDEO MODE
                                        ; AL = mode
		call	print_title
                mov 	si, offset Copiright
		call	print_string

		cmp	bp, 1234h
                jz	short search_addinional_rom

		call	print_cpu_fpu
		
		mov	si, offset TestingSystem
                call	print_string
                mov	cx, 14h
                call	print_backspace
                mov	ax, es
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	bx, ax
                mov	dx, ax
                mov	es, ax
                assume es:nothing
                jmp	short loc_FE182
; ---------------------------------------------------------------------------

loc_FE17D:				; ...
                call	sub_FE21E
                jnz	short loc_FE1F0

loc_FE182:				; ...
                mov	ax, es
                add	ah, 8
                mov	es, ax
                assume es:nothing
                mov	ax, dx
                add	al, 32h
                daa
                adc	ah, 0
                mov	dx, ax
                mov	cx, 3
                call	print_backspace
                mov	al, dh
                call	sub_FE26B
                mov	al, dl
                call	sub_FE262
                add	bx, 20h
                cmp	bx, [ds:main_ram_size_]
                jb      short  loc_FE17D

search_addinional_rom:				; ...
                mov	ax, BDAseg
                mov	ds, ax
                mov	[word ptr ds:gen_use_ptr_], 3
                mov	[word ptr ds:gen_use_seg_], 0BE00h

search_loop:				; ...
                mov	ax, BDAseg
                mov	ds, ax
                add	[word ptr ds:gen_use_seg_+1], 2
                cmp	[word ptr ds:gen_use_seg_], 0FE00h
                jz	short no_additional_rom
                mov	es, [word ptr ds:gen_use_seg_]
                assume es:nothing
                cmp	[word ptr es:0], 0AA55h
                jnz	short search_loop
                call	[dword ptr ds:gen_use_ptr_]
                jmp	short search_loop
; ---------------------------------------------------------------------------

no_additional_rom:				; ...
                mov	si, empty_string
                call	print_string
                xor	cx, cx

loc_FE1EA:				; ...
                loop	loc_FE1EA

loc_FE1EC:				; ...
                loop	loc_FE1EC
                int	19h		; DISK BOOT
                                        ; causes reboot	of disk	system

loc_FE1F0:				; ...
                push	ax
                mov	si, offset FailedAt
                call	print_string
                dec	di
                dec	di
                mov	ax, es
                call	sub_FE25B
                mov	ax, 0E3Ah
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                mov	ax, di
                call	sub_FE25B
                mov	ax, 0E20h
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                pop	ax
                xor	ax, [es:di]
                call	sub_FE25B
                mov	[ds:main_ram_size_], bx
                xor	ax, ax
                int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
                                        ; Return: AH = scan code, AL = character
                jmp	short search_addinional_rom
endp		post

;---------------------------------------------------------------------------------------------------
;  Print cpu and fpu type
;---------------------------------------------------------------------------------------------------
proc		print_cpu_fpu near
        	xor     al, al
		mov	al, 40h				; mul on V20 does not affect the zero flag
		mul	al				;   but on an 8088 the zero flag is used
		jz	@@have_v20			; Was zero flag set?
		mov	si, offset str_8088		;   No, so we have an 8088 CPU
		call	print_string
		jmp	fpu
@@have_v20:
		mov	si, offset str_v20		;   Otherwise we have a V20 CPU
		call	print_string

fpu:		mov	ax, BDAseg
		mov 	ds, ax
		fninit					; Try to init FPU
		mov	si, 0200h
		mov	[byte si+1], 0			; Clear memory byte
		fnstcw	[word si]			; Put control word in memory
		mov	ah, [si+1]
		cmp	ah, 03h				; If ah is 03h, FPU is present
		jne	@@no_8087
		or	[byte ds:10h], 00000010b	; Set FPU in equp list
		mov	si, offset str_8087
		call 	print_string
		ret
@@no_8087:
		and	[byte ds:10h], 11111101b	; Set no FPU in equp list
		mov	si, offset str_nofpu
	        call	print_string
		ret

endp		print_cpu_fpu
;-------------------------------------------------------------------------------------------------------

proc		sub_FE21E near		; ...
                mov	ax, 0FFFFh
                call	mem_test_loop
                jnz	short sub_exit
                mov	ax, 0AAAAh
                call	mem_test_loop
                jnz	short sub_exit
                mov	ax, 5555h
                call	mem_test_loop
                jnz	short sub_exit
                xor	ax, ax
endp		sub_FE21E ; sp-analysis	failed





proc		mem_test_loop near		; ...
                mov	cx, mem_test_cicle_count
                xor	di, di
                rep stosw
                mov	cx, mem_test_cicle_count
                xor	di, di
                repe scasw
                retn
endp		mem_test_loop





proc		print_backspace near		; ...
                mov	ax, 0E08h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                loop	print_backspace

sub_exit:				; ...
                retn
endp		print_backspace




;----------------------------------------------------------------------------------------------------------
proc            print_string near               
print_string_loop:
                lods    [byte ptr cs:si]
                or      al, al
                jz      short sub_exit
                mov     ah, 0Eh
                int     10h 
                jmp     short print_string_loop
endp            print_string

;-----------------------------------------------------------------------------------------------------------


proc		sub_FE25B near		; ...
                xchg	ah, al
                call	sub_FE262
                xchg	ah, al
endp		sub_FE25B ; sp-analysis	failed





proc		sub_FE262 near		; ...
                mov	cl, 4
                rol	al, cl
                call	sub_FE26B
                rol	al, cl
endp		sub_FE262 ; sp-analysis	failed





proc		sub_FE26B near		; ...
                push	ax
                and	al, 0Fh
                add	al, 90h
                daa
                adc	al, 40h
                daa
                mov	ah, 0Eh
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                pop	ax
                retn
endp		sub_FE26B

; ---------------------------------------------------------------------------

proc		sub_FE2D3 near		; ...
                mov	dh, [ds:dsk_status_4]
                dec	dh
                and	dh, 1
                retn
endp		sub_FE2D3





proc		sub_FE2DD near		; ...
                push ax
                mov	[byte ptr ds:dsk_motor_tmr], 0FFh ; dsk_motor_tmr
                mov	[byte ptr ds:dsk_motor_tmr], 0FFh ; dsk_motor_tmr

loc_FE2E8:				; ...
                in	al, dx
                shr	al, 1
                jb	short loc_FE2E8
                pop	ax
                retn
endp		sub_FE2DD





proc		sub_FE2EF near		; ...
                push	ax
                push	cx
                mov	ax, si
                inc	ax
                mov	ah, ch
                test	[ds:dsk_recal_stat], al
                jnz	short loc_FE308
                call	sub_FE394
                jnb	short loc_FE304
                pop	cx
                jmp	short loc_FE36A
; ---------------------------------------------------------------------------
; dsk_status ?
loc_FE304:				; ...
                or	[ds:dsk_recal_stat], al

loc_FE308:				; ...
                mov	al, ah
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_1]
                inc	dx
                out	dx, al
                mov	cl, [ds:dsk_status_7]
                shl	al, cl
                cmp	al, [si+dsk_status_5]
                jz	short loc_FE360
                inc	dx
                inc	dx
                out	dx, al
                xchg al, [si+dsk_status_5]
                dec	dx
                dec	dx
                out	dx, al
                dec	dx
                mov	al, 10h
                out	dx, al
                call	sub_FE2DD
                mov	al, ah
                mov	dl, [ds:dsk_status_1]
                inc	dx
                out	dx, al
                test	[byte ptr ds:dsk_motor_stat], 80h
                jz	short loc_FE360
                inc	dx
                inc	dx
                out	dx, al
                mov	dl, [ds:dsk_status_1]
                mov	al, bl
                out	dx, al
                mov	dl, [ds:dsk_status_3]
                in	al, dx
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 19h
                jz	short loc_FE360
                or	[byte ptr ds:dsk_ret_code_], 40h
                stc
                pop	cx
                jmp	short loc_FE36A
; ---------------------------------------------------------------------------

loc_FE360:				; ...
                pop	cx
                mov	al, cl
                mov	dl, [ds:dsk_status_1]
                inc	dx
                inc	dx
                out	dx, al

loc_FE36A:				; ...
                pop	ax
                retn
endp		sub_FE2EF





proc		sub_FE36C near		; ...
                mov	al, 0D0h
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                call	sub_FE2DD
                mov	al, 0C0h
                out	dx, al
                mov	ah, 3
                add	ah, dl

loc_FE380:				; ...
                mov	dl, [ds:dsk_status_3]
                in	al, dx
                shr	al, 1
                mov	dl, ah
                in	al, dx
                jb	short loc_FE380
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 10h
                retn
endp		sub_FE36C





proc		sub_FE394 near		; ...
                push	ax
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                mov	dl, [ds:dsk_status_1]
                mov	al, 0D0h
                out	dx, al
                call	sub_FE2DD
                mov	al, 9
                out	dx, al
                call	sub_FE2DD
                in	al, dx
                and	al, 5
                cmp	al, 4
                jz	short loc_FE3B7
                or	[byte ptr ds:dsk_ret_code_], 80h
                stc

loc_FE3B7:				; ...
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                mov	[byte ptr si+0046h], 0
                pop	ax
                retn
endp		sub_FE394





proc		sub_FE3C3 near		; ...
                push	ax
                push	cx
                and	dl, 1
                mov	si, dx
                and	si, 1
                mov	cl, dl
                inc	cx
                mov	[byte ptr ds:dsk_status_7], 0
                test	[byte ptr si+90h], 10h
                jnz	short loc_FE3E1
                mov	[byte ptr si+0090h], 17h

loc_FE3E1:				; ...
                test	[byte ptr si+0090h], 20h
                jz	short loc_FE3F8
                cmp	ch, 2Ch
                jnb	short loc_FE3F3
                inc	[byte ptr ds:dsk_status_7]
                jmp	short loc_FE3F8
; ---------------------------------------------------------------------------

loc_FE3F3:				; ...
                and	[byte ptr si+90h], 0DFh

loc_FE3F8:				; ...
                mov	al, 82h
                test	[byte ptr ds:dsk_motor_stat], 40h
                jz	short loc_FE404
                xor	dl, 1

loc_FE404:				; ...
                test	dl, 1
                jz	short loc_FE40B
                mov	al, 8Ch

loc_FE40B:				; ...
                or	al, dh
                test	[byte ptr si+90h], 0C0h
                jnz	short loc_FE416
                or	al, 10h

loc_FE416:				; ...
                rol	al, 1
                call	sub_FE2D3
                mov	ah, 0FFh
                mov	[ds:dsk_motor_tmr], ah

                inc	ah
                mov	dl, [ds:dsk_status_2]
                out	dx, al
                in	al, dx
                mov	dl, [ds:dsk_status_1]
                mov	al, 0D0h
                out	dx, al
                test	[ds:dsk_motor_stat], cl
                jnz	short loc_FE446

loc_FE436:				; ...
                mov	al, [ds:dsk_motor_tmr]
                sub	al, ah
                not	al
                shr	al, 1
                cmp	al, [cs:MotorOn]
                jb	short loc_FE436

loc_FE446:				; ...
                and	[byte ptr ds:dsk_motor_stat], 0FCh
                or	[ds:dsk_motor_stat], cl
                pop	cx
                pop	ax
                retn
endp		sub_FE3C3





proc		sub_FE452 near		; ...
                cli
                push	ax
                mov	al, [ds:video_mode_reg_]
                test	al, 1
                jz	short loc_FE48C
                mov	ax, es
                push	cx
                mov	cl, 4
                push	bx
                shr	bx, cl
                add	ax, bx
                pop	bx
                pop	cx
                push	ax
                mov	ax, [ds:0013h] ; main_ram_size
                cmp	ax, 0060h  ; 96 kb
                pop	ax
                ja	short loc_FE475
                mov	al, 0
                jmp	short loc_FE488
; ---------------------------------------------------------------------------

loc_FE475:				; ...
                cmp	ax, 7EC0h
                jb	short loc_FE48C
                cmp	ax, 0C000h
                jnb	short loc_FE48C
                mov	al, 0
                jmp	short loc_FE488
endp		sub_FE452





proc		sub_FE483 near		; ...
                sti
                push	ax
                mov	al, [ds:video_mode_reg_]

loc_FE488:				; ...
                mov	dx, 3D8h
                out	dx, al

loc_FE48C:				; ...
                pop	ax
                retn
endp		sub_FE483


;--------------------------------------------------------------------------------------------------
; Print color title bar
;--------------------------------------------------------------------------------------------------
proc		print_title	near

                mov	si, Banner
		xor	dx, dx				; Cursor starts in upper left corner
		mov	cx, 1				; Character repeat count

                mov 	bl, 01Fh
@@loop_title:
		lods   [byte ptr cs:si] 		; Print zero terminated string
		or	al, al
		jz	@@done_title			; Terminator in ax?
		inc	dl				; New cursor position
		call	color_out_char			; Print character in ax and advance cursor
		jmp	@@loop_title				;   back for more

@@done_title:
		mov	cl, 14h				; Repeat trailing space 9 chars
color_out_char:
		mov	ah, 09h 			; Write character and attribute
		int	10h
		mov	ah, 02h				; Set cursor position
		int	10h
		ret

endp	print_title

;---------------------------------------------------------------------------------------------------
include int19h.asm 	; Warm Boot
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int09h.asm 	; Keyboard Services IRQ1
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int16h.asm 	; Keyboard
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int14h.asm 	; RS232 Service
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int13h.asm 	; Floppydisk
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int1Eh.asm 	; Diskette Parameter Table
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int17h.asm 	; Parallel LPT Services
;---------------------------------------------------------------------------------------------------

; --------------------------------------------------------------------------------------------------
include int10h.asm 	; Interrupt 10h handlers
; --------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int12h.asm 	; Memory Size
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int11h.asm  	; Equipment Check
;---------------------------------------------------------------------------------------------------

; --------------------------------------------------------------------------------------------------
include int1Ah.asm	; Real Time Clock Function
; --------------------------------------------------------------------------------------------------

; --------------------------------------------------------------------------------------------------
include int08h.asm	; IRQ0;
; --------------------------------------------------------------------------------------------------

; --------------------------------------------------------------------------------------------------
include dummy.asm  	;Dummy interrupt
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int05h.asm  	;Print Screen
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include vectors.asm  	;Interrupt vector tables
;---------------------------------------------------------------------------------------------------




;--------------------------------------------------------------------------------------------------
; Prints CR+LF on the printer
;--------------------------------------------------------------------------------------------------
proc    	print_cr_lf     near
                xor	dx, dx
                xor	ah, ah
                mov	al, LF
                int	17h		; PRINTER - OUTPUT CHARACTER
                                        ; AL = character, DX = printer port (0-3)
                                        ; Return: AH = status bits
                xor	ah, ah
                mov	al, CR
                int	17h		; PRINTER - OUTPUT CHARACTER
                                        ; AL = character, DX = printer port (0-3)
                                        ; Return: AH = status bits
                retn
endp		print_cr_lf

		db 635 dup (0)

;--------------------------------------------------------------------------------------------------
; Power-On Entry Point
;--------------------------------------------------------------------------------------------------
proc		power	far				;   CPU begins here on power up
                jmpfar	0F000h, warm_boot
endp 		power

;--------------------------------------------------------------------------------------------------
; BIOS Release Date and Signature
;--------------------------------------------------------------------------------------------------
date	db '12/31/17',0
		db 0FEh  ; Computer type (XT)

ends		code
end
