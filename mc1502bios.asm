
	Ideal
	model small ; produce .EXE file then truncate it
;---------------------------------------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------------------------------------
; Pad code to create entry point at specified address (needed for 100% IBM BIOS compatibility)
macro	entry	addr
	pad = str_banner - $ + addr - 0E000h
	if pad lt 0
		err	'No room for ENTRY point'
	endif
	if pad gt 0
		db	pad dup(090h)
	endif
endm

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
str_banner      db ' 8088/8086/V20/V30 Modular BIOS v7.3', 0

date_full:
		db LF, CR, ' Released 12/04/2020 by Airman and RUS' , 0

enter_setup:	
		db ' Press <DEL> to Enter Setup', 0
Copyright:	
		db LF, CR, ' Copyright (C) 1989-2020, NPO "Microprocessor" 1989', LF, CR, 0
empty_string:
		db LF, CR, 0
platform_string:
		db LF, CR, ' ELECTRONIKA MC1502', 0

str_8088:
	 	db LF, CR, LF, CR,' Intel (C) 8088 at 5.33 Mhz', 0
str_v20:                                                  	
		db LF, CR, LF, CR,' NEC (C) V20 at 5.33 Mhz', 0
str_8087:
		db ' with Intel (C) 8087 FPU', 0
StrTestingSystem:
		db ' Memory testing: 000K OK', 0
StrEnteringSetup:
		db CR, LF, CR, LF, CR, LF, ' Entering Setup...', CR, LF, LF, 0
SkipMemTest:
		db ' Press <ESC> to skip memory test', 0
FailedAt:
		db  LF, CR, ' Failed at ', 0
SystemNotFound:
		db  LF, CR, ' System not found.', LF, CR, 0

str_ega_vga:
		db LF, CR, LF, CR, ' EGA/VGA Video card Installed          ', LF, CR, 0
str_cga:
		db LF, CR, LF, CR, ' CGA Video card installed              ', LF, CR, 0

str_ins_disk:	db ' Insert BOOT disk in A:', CR, LF
		db ' Press any key when ready', CR, LF, LF, 0

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
rs232_2:	dw    0
rs232_3:	dw    0
rs232_4:	dw    0
lpt_1:		dw    62h
lpt_2:		dw    0
lpt_3:		dw    0
bios_data_seg:	dw    0
equip_bit:	dw    622Dh
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
write_first_post_codes:
		mov	al, 01h
		out	mfg_port, al


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
write_ppi_post_code:
		
		mov	al, 02h
		out	mfg_port, al


@@init_PIC:		
                mov	al, 13h
                out	20h, al		; Interrupt controller,	8259A.
                mov	al, 68h
                out	21h, al		; Interrupt controller,	8259A.
                mov	al, 9
                out	21h, al		; Interrupt controller,	8259A.

write_pic_post_code:
		mov	al, 03h
		out	mfg_port, al

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

wriet_pit_post_code:
		mov	al, 04h
		out	mfg_port, al

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

write_fist_vec_table_code:
		mov	al, 05h
		out	mfg_port, al

@@init_vect_table_2:
                mov	cx, 8
                mov	si, offset int_vec_table_2
                mov	di, 1A0h

vec_table_2_loop:				; ...
                lodsw
                stosw
                mov	ax, cs
                stosw
                loop	vec_table_2_loop

write_secont_vec_table_code:
		mov	al, 06h
		out	mfg_port, al

@@init_dummy_int:
                mov	di, 8
                mov	ax, offset dummy_int
                stosw
                mov	ax, cs
                stosw

write_dummy_int_code:
		mov	al, 07h
		out	mfg_port, al


@@init_print_screen_int:
                mov	di, 14h
                mov	ax, offset int_05h
                stosw
                mov	ax, cs
                stosw
                mov	ax, BDAseg
                mov	es, ax
                assume es:nothing

write_print_screen_int_code:
		mov	al, 08h
		out	mfg_port, al


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
		call	search_rom

test_first_8K_ram:				; ...
                mov	ax, [bx]
                not	ax
                mov	[bx], ax
                cmp	ax, [bx]
                jnz	short Print_Startup_Info
                not	[word ptr bx]
                add	ch, 8
                mov	ds, cx

                assume ds:nothing
                add	di, 20h
                cmp	di, 2E0h
                jb	short test_first_8K_ram
		


Print_Startup_Info:				; ...
                mov	[es:13h], di
                mov	al, 0FCh
                out	21h, al		; Interrupt controller,	8259A.
                sti
		mov	bl ,1

		call 	beep
		call	video_init
		call	print_date
		mov	si, offset Banner
		call	print_string
                mov 	si, offset Copyright
		call	print_string
		mov 	si, offset empty_string
		call	print_string
		mov 	si, offset platform_string
		call	print_string
		call	print_cpu_fpu
	 	mov	dl, 00h
		mov	dh, 09h		
		mov	ah, 02h
		int 	10h		
		mov	si, SkipMemTest
		call 	print_string
        	mov	dl, 0h
		mov	dh, 07h		
		mov	ah, 02h
		int 	10h		
                mov	si, offset StrTestingSystem
                call	print_string
                mov	cx, 4h
                call	print_backspace
                mov	ax, es
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	bx, ax
                mov	dx, ax
                mov	es, ax
                assume es:nothing
				
				mov [ds:mem_test_cycle_addr], mem_test_cycle_full
                jmp	short Mem_test

; ---------------------------------------------------------------------------
Mem_test_loop:
                call	Mem_test_pattern
                jnz	short Test_error

 
Mem_test:				; ...
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
                call	print_AL_nibble
                mov	al, dl
                call	print_AL
                add	bx, 20h
		mov	Ah, 01h
		int	16h			; ������ ����� ������� ?
		jz	Mem_size_compare		; ���
		xor	ax, ax
		int	16h
		cmp	al, 1Bh			; ESC ?
		jne	Check_Del_Key; ClearMemEscString
		mov word ptr [ds:mem_test_cycle_addr], mem_test_cycle_short

Check_Del_Key:
		cmp ax, 5300h  ; 00 - ᪠� ���; 53h - DEL
		jne Mem_size_compare
		mov	si, offset StrEnteringSetup
		call	print_string
		cli
		hlt			; TODO - make bios Setup 
	;   jmp SetupBIOS

Mem_size_compare:
		cmp	bx, [ds:main_ram_size_]
		jb      short  Mem_test_loop

ClearMemEscString:
	 	mov	dl, 0h
		mov	dh, 7h		
		mov	ah, 02h
		int 	10h		


Print_video_type:
		call	video_type
Boot:
                mov	si, empty_string
                call	print_string
		mov	cx, 0Fh
super_delay:
		push 	cx
		mov 	cx, 0FFFFh
boot_delay:	
		loop 	boot_delay
		pop 	cx
		loop	super_delay

       		call	clear_screen
		mov	ax, 1Eh				; Flush keyboard buffer in case user
		mov	[es:1Ah], ax			;   was mashing keys during memory test
		mov	[es:1Ch], ax
                int	19h		; DISK BOOT
                                        ; causes reboot	of disk	system

Test_error:				; ...
                push	ax
                mov	si, offset FailedAt
                call	print_string
                dec	di
                dec	di
                mov	ax, es
                call	print_AX
                mov	ax, 0E3Ah
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                mov	ax, di
                call	print_AX
                mov	ax, 0E20h
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                pop	ax
                xor	ax, [es:di]
                call	print_AX
                mov	[ds:main_ram_size_], bx
                xor	ax, ax
                int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
                                        ; Return: AH = scan code, AL = character
endp		post


proc		Mem_test_pattern near		; ...
                mov	ax, 0FFFFh
                call	mem_test_cycle
                jnz	short sub_exit
                mov	ax, 0AAAAh
                call	mem_test_cycle
                jnz	short sub_exit
                mov	ax, 5555h
                call	mem_test_cycle
                jnz	short sub_exit
                xor	ax, ax
		mov	AH,1
endp		Mem_test_pattern 





proc		mem_test_cycle near		; ...
                mov     cx, [ds:mem_test_cycle_addr]
                xor	di, di
                rep stosw
                mov     cx, [ds:mem_test_cycle_addr]
                xor	di, di
                repe scasw
                retn
endp		mem_test_cycle


proc		print_backspace near		; ...
                mov	ax, 0E08h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                loop	print_backspace

sub_exit:				; ...
                retn
endp		print_backspace


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
		ret

endp		print_cpu_fpu
;-------------------------------------------------------------------------------------------------------




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
; Convert AX to ASCII and print it

proc		print_AX near		; ...
                xchg	ah, al
                call	print_AL
                xchg	ah, al
endp		print_AX 

proc		print_AL near		
                mov	cl, 4 ; To rotate the register by 4 bits
                rol	al, cl ; <- rotate left for extract high nibble
                call	print_AL_nibble
                rol	al, cl
endp		print_AL 

; Converts a binary number in AL, range 0 to 0FH
; to the appropriate ASCII character.
proc		print_AL_nibble near		; ...
                push	ax
                and	al, 0Fh
                add	al, 90h ;special hex conversion sequence
                daa         ;using ADDs and DAA's
                adc	al, 40h
                daa         ;nibble now converted to ASCII
                mov	ah, 0Eh
                int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
                                        ; AL = character, BH = display page (alpha modes)
                                        ; BL = foreground color	(graphics modes)
                pop	ax
                retn
endp		print_AL_nibble

;--------------------------------------------------------------------------------------------------
; Print date
;--------------------------------------------------------------------------------------------------
proc		print_date	near

	 	mov	dl, 0h
		mov	dh, 18h		
		mov	ah, 02h
		int 	10h		
		mov	si, enter_setup
		call 	print_string
		mov	si, date_full
		call	print_string	
		xor 	dx, dx
		mov 	ah, 02h
		int 	10h
		ret

endp		print_date
;--------------------------------------------------------------------------------------------------
; Flush string
;--------------------------------------------------------------------------------------------------
proc		flush_string	near
                mov 	cx, 50h
		mov	al, 20h
		mov	ah, 0ah
		int 	10
		ret

endp		flush_string


;---------------------------------------------------------------------------------------------------
; Clear display screen
;---------------------------------------------------------------------------------------------------
proc		clear_screen	near
	
		mov	dx, 184Fh			; Lower right corner of scroll
		xor	cx, cx				; Upper left  corner of scroll
		mov	ax, 600h			; Blank entire window
		mov	bh, 7				; Set regular cursor
		int	10h				; Call video service scroll
		mov	ah, 2				; Set cursor position
		xor	dx, dx				;   upper left corner
		mov	bh, 0				;   page 0
		int	10h				;   call video service
		mov	ax, 500h			; Set active display page zero
		int	10h
		ret

endp		clear_screen

;---------------------------------------------------------------------------------------------------
; Saerch additional rom
;---------------------------------------------------------------------------------------------------


proc		search_rom	near

                push    bx
                push    cx
                push    dx
                push	si
                push	di
                push	ds
                push	es
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
		mov	es, bx	
		mov	bl, 5 * 18		; Ticks to pause at 18.2 Hz

                jmp	short search_loop

no_additional_rom:				; ...
		pop	es
		pop	ds
		pop	di
		pop	si
                pop	dx
                pop	cx
                pop	bx
		ret
endp		search_rom	

;--------------------------------------------------------------------------------------------------
; PC speaker beep (length in bl)
;--------------------------------------------------------------------------------------------------
proc		beep	near

		push	ax
		push	cx
		mov	al, 10110110b			; Timer IC 8253 square waves
		out	43h, al 			;   channel 2, speaker
		mov	ax, 528h			; Get countdown constant word
		out	42h, al 			;   send low order
		mov	al, ah				;   load high order
		out	42h, al 			;   send high order
		in	al, 61h 			; Read IC 8255 machine status
		push	ax
		or	al, 00000011b
		out	61h, al 			; Turn speaker on
		xor	cx, cx
@@delay:
		loop	@@delay
		dec	bl
		jnz	@@delay
		pop	ax
		out	61h, al 			; Turn speaker off
		pop	cx
		pop	ax
		ret

endp	beep


;--------------------------------------------------------------------------------------------------
; Waits for a keypress and then returns it (ah=scan code, al=ASCII)
;--------------------------------------------------------------------------------------------------
proc	get_key	near

	mov	ah, 0				; Read keyboard key
	int	16h
	ret

endp	get_key

;--------------------------------------------------------------------------------------------------
; Print video type
;--------------------------------------------------------------------------------------------------

proc    	video_type	near
		mov	ah, 12h				; Test for EGA/VGA
		mov	bx, 0FF10h
		int	10h				; Video Get EGA Info
		cmp	bh, 0FFh			; If EGA or later present BH != FFh
		je	is_cga
		mov	si, offset str_ega_vga		; Otherwise we have EGA/VGA
		jmp	short display_video
is_cga:
		mov	si, offset str_cga
display_video:
		call	print_string				; Print video adapter present
		ret
endp		video_type
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
;include int13h_new.asm 	; Floppydisk
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int1Eh.asm 	; Diskette Parameter Table
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int17h.asm 	; Parallel LPT Services
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int1Dh.asm	; Video parametr Table
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
include int68h.asm  	;Second interrupt table redirect 68h to 08h
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int69h.asm  	;Second interrupt table redirect 69h to 09h and scannig keyboard key
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Ah.asm  	;Second interrupt table redirect 6Ah to 0Ah

;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Bh.asm  	;Second interrupt table redirect 6Bh to 0Bh
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Ch.asm  	;Second interrupt table redirect 6Ch to 0Ch
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Dh.asm  	;Second interrupt table redirect 6Dh to 0Dh
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Eh.asm  	;Second interrupt table redirect 6Eh to 0Eh
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include int6Fh.asm  	;Second interrupt table redirect 6Fh to 0Fh
;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------
include gfx.asm		; Grafic charapter table
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
include vectors.asm  	;Interrupt vector tables
;---------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------
; Power-On Entry Point  
;--------------------------------------------------------------------------------------------------
		entry   0FFF0h
proc		power	far				;   CPU begins here on power up
                jmpfar	0F000h, warm_boot
endp 		power

;--------------------------------------------------------------------------------------------------
; BIOS Release Date and Signature
;--------------------------------------------------------------------------------------------------
date	db '12/04/20', 0
		db 0FEh  ; Computer type (XT)

ends		code
end
