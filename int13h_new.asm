;-- INT 13 ----------------------------------
;DISKETTE I/O
;	THIS INTERFACE PROVIDES ACCESS TO THE 5 1/4" DISKETTE DRIVES
;INPUT
;	(AH)=0	RESET DISKETTE SYSTEM
;		HARD RESET TO NEC, PREPARE COMMAND, RECAL REQD ON ALL DRIVES
;	(AH)=1	READ THE STATUS OF THE SYSTEM INTO (AL)
;		DISKETTE_STATUS FROM LAST OP'N IS USED
;	REGISTERS FOR READ/WRITE/VERIFY/FORMAT
;	(DL) - DRIVE NUMBER (0-3 ALLOWED, VALUE CHECKED)
;	(DH) - HEAD NUMBER (0-1 ALLOWED, NOT VALUE CHECKED)
;	(CH) - TRACK NUMBER (0-39, NOT VALUE CHECKED)
;	(CL) - SECTOR NUMBER (1-8, NOT VALUE CHECKED)
;	(AL) - NUMBER OF SECTORS ( MAX = 8, NOT VALUE CHECKED)
;
;	(ES:BX) - ADDRESS OF BUFFER ( NOT REQUIRED FOR VERIFY)
;
;	(AH)=2	READ THE DESIRED SECTORS INTO MEMORY
;	(AH)=3	WRITE THE DESIRED SECTORS FROM MEMORY
;	(AH)=4	VERIFY THE DESIRED SECTORS
;	(AH)=5	FORMAT THE DESIRED TRACKS
;		FOR THE FORMAT OPERATION, THE BUFFER POINTER (ES,BX) MUST
;		POINT TO THE COLLECTION OF DESIRED ADDRESS FIELDS FOR THE
;		TRACK. EACH FIELD IS COMPOSED OF 4 BYTES, (C,H,R,N), WHERE
;		C = TRACK NUMBER, H=HEAD NUMBER, R = SECTOR NUMBER, N= NUMBER
;		OF BYTES PER SECTOR (00=128, 01=256, 02=512, 03=1024,)
;		THERE MUST BE ONE ENTRY FOR EVERY SECTOR ON THE TRACK.
;		THIS INFORMATION IS USED TO FIND THE REQUESTED SECTOR DURING
;		READ/WRITE ACCESS.
; DATA VARIABLE -- DISK_POINTER
;	DOUBLE WORD POINTER TO THE CURRENT SET OF DISKETTE PARAMETERS
; OUTPUT
;	AH = STATUS OF OPERATION
;		STATUS BITS ARE DEFINED IN THE EQUATES FOR DISKETTE_STATUS
;		VARIABLE IN THE DATA SEGMENT OF THIS MODULE
;	CY = 0	SUCCESSFUL OPERATION (AH=0 ON RETURN)
;	CY = 1	FAILED OPERATION (AH HAS ERROR REASON)
;	FOR READ/WRITE/VERIFY
;		DS,BX,DX,CH,CL PRESERVED
;		AL = NUMBER OF SECTORS ACTUALLY READ
;		***** AL MAY NOT BE CORRECT IF TIME OUT ERROR OCCURS
;	NOTE: IF AN ERROR IS REPORTED BY THE DISKETTE CODE, THE APPROPRIATE
;		ACTION IS TO RESET THE DISKETTE, THEN RETRY THE OPERATION.
;		ON READ ACCESSES, NO MOTOR START DELAY IS TAKEN, SO THAT
;		THREE RETRIES ARE REQUIRED ON READS TO ENSURE THAT THE
;		PROBLEM IS NOT DUE TO MOTOR START-UP.
;--------------------------------------------
proc	int_13h	near

arg_B	    = byte ptr	0Fh

		sti
		push    es
		push    ax
		push    ax
		push    ax
		push    bx
		push    cx
		push    ds
		push    si
		push    di
		push    bp
		push    dx
		mov	    bp,	sp
		call    dss
		call    j1
		mov	    bl,	4
		call    get_parm
		mov	    [ds:dsk_motor_tmr], ah
		mov	    ah,	[ds:dsk_ret_code_]
		mov	    [bp+arg_B],	ah
		pop	    dx
		pop	    bp
		pop	    di
		pop	    si
		pop	    ds
		pop	    cx
		pop	    bx
		pop	    ax
		add	    sp,	4
		pop	    es
		assume es:nothing
		cmp	    ah,	1
		cmc
		retf    2
endp	int_13h

;=======================================
proc	j1	near
		mov	    dh,	al
		and	    byte ptr ds:3Fh, 7Fh
		or	    ah,	ah
		jz	    short disk_reset
		dec	    ah
		jz	    short disk_status
		mov	    byte ptr [ds:dsk_ret_code_], 0
		cmp	    dl,	2
		ja	    short j3
		dec	    ah
		jz	    short disk_read
		dec	    ah
		jnz	    short j2
		jmp	    disk_write

j2:			
		dec	    ah
		jz	    short disk_read
		dec	    ah
		jz	    short disk_format

j3:					    
		mov	    byte ptr [ds:dsk_ret_code_], 1
		retn
endp	j1
;=======================================

proc	disk_status near	
		mov	    al,	 [ds:dsk_ret_code_]
		mov	    [bp+0Eh], al
		retn
endp	disk_status

;=======================================
proc disk_reset near		   

		mov	    dx,	0F2h 
		cli
		mov	    al,	ds:3Fh
		and	    al,	7
		out	    dx,	al
		mov	    byte ptr ds:3Eh, 0
		mov	    byte ptr ds:41h, 0
		or	    al,	80h
		out	    dx,	al
		sti
		mov	    si,	offset j4_2 
		push    si
		mov	    cx,	10h

j4_0:				    
		  
		mov	    ah,	8
		call    nec_output
		call    results
		mov	    al,	ds:42h
		cmp	    al,	0C0h ; 'А'
		jz	    short j7
		loop    j4_0

j4_1:				  
		or	    byte ptr ds:41h, 20h
		pop	    si
		jmp	    short j8

j4_2:				   
		mov	    si,	offset j4_2
		push    si
		loop    j4_0
		jmp	    short j4_1

j7:					    
		pop	    si
		mov	    ah,	3
		call    nec_output
		mov	    bl,	1
		call    get_parm
		mov	    bl,	3
		call    get_parm
j8:
		retn

endp	disk_reset
;=======================================
proc disk_read near
		mov     ah,	46h 
		jmp     short rw_opn
endp disk_read
;=======================================
proc disk_format near	
		or	    byte ptr ds:3Fh, 80h
		mov	    ah,	4Dh
		jmp	    short rw_opn
endp disk_format
;=======================================
 j10:				    
		mov	    bl,	7
		call    get_parm
		mov	    bl,	9
		call    get_parm
		mov	    bl,	0Fh
		call    get_parm
		mov	    bx,	11h
		push    bx
		jmp	    j16
;=======================================
proc disk_write near		    
		or	    byte ptr ds:3Fh, 80h
		mov	    ah,	45h
endp disk_write

;=======================================

proc rw_opn near

		push    ax
		push    cx
		cli
		mov	    byte ptr [ds:dsk_motor_tmr], 0FFh
		call    get_drive
		test    [ds:dsk_ret_code_], al
		jnz	    short j14
		and	    byte ptr [ds:dsk_ret_code_], 0F0h
		or	    [ds:dsk_ret_code_], al
		sti
		or	    al,	80h
		out	    0F2h, al
		mov	    bl,	14h
		call    get_parm
		or	    ah,	ah

j12:
		jz	    short j14
		sub	    cx,	cx

j13:
		loop    j13
		dec	    ah
		jmp	    short j12
;=======================================
 j14:				   
		sti
		pop	    cx
		call    seek
		pop	    ax
		mov	    bh,	ah
		mov	    dh,	0
		jnb	    short j14_1
		jmp	    j17
;=======================================
 j14_1:	
		mov	    si,	0EED7h ;; offset!
		push    si
		call    nec_output
		mov	    ah,	[bp+1]
		shl	    ah,	1
		shl	    ah,	1
		and	    ah,	4
		or	    ah,	dl
		call    nec_output
		cmp	    bh,	4Dh
		jnz	    short j15
		jmp	    short j10
;=======================================
 j15:
		mov	    ah,	ch
		call    nec_output
		mov	    ah,	[bp+1]
		call    nec_output
		mov	    ah,	cl
		call    nec_output
		mov	    bl,	7
		call    get_parm
		mov	    bl,	8
		call    get_parm
		add	    cl,	[bp+0Eh]
		dec	    cl
		mov	    ah,	cl
		call    nec_output
		mov	    bl,	0Bh
		call    get_parm
		mov	    bx,	0Dh
		push    bx

 j16:	
		cld
		mov	    al,	1110000b
		out	    43h, al	    ; Timer 8253-5 (AT:	8254.2).
		push    ax
		pop	    ax
		mov	    al,	0FFh
		out	    41h, al	    ; Timer 8253-5 (AT:	8254.2).
		push    ax
		pop	    ax
		out	    41h, al	    ; Timer 8253-5 (AT:	8254.2).
		mov	    al,	[bp+0Fh]
		test    al,	1
		jz	    short j16_1
		mov	    cx,	offset write_loop
		jmp	    short j16_3
;=======================================

 j16_1:				   
		cmp	    al,	2
		jnz	    short j16_2
		mov	    cx,	offset read_loop
		jmp	    short j16_3
;=======================================

 j16_2:				   
		mov	    cx,	offset verify_loop

 j16_3:				    
		mov	    al,	10h
		out	    0A0h, al	    ; PIC 2  same as 0020 for PIC 1
		call    clock_wait
		call    get_drive
		mov	    dx,	0F2h ; 'т'
		or	    al,	0E0h
		out	    dx,	al
		and	    al,	0A7h
		out	    dx,	al
		mov	    dx,	0F4h ; 'ф'
		mov	    al,	20h ; ' '
		out	    0A0h, al	    ; PIC 2  same as 0020 for PIC 1
		call    read_time
		mov	    [bp+12h], ax
		call    disable
		pop	    bx
		call    get_parm
		pop	    ax
		push    es
		pop	    ds
		jmp	    cx
;=======================================

 verify_loop:			    
		in	    al,	dx
		test    al,	20h
		jz	    short verify_loop

 j22_2:				    
		test    al,	80h
		jnz	    short j22_4
		in	    al,	dx
		test    al,	20h
		jnz	    short j22_2
		jmp	    short op_end
;=======================================

 j22_4:	
		inc	    dx
		in	    al,	dx
		dec	    dx
		in	    al,	dx
		test    al,	20h
		jnz	    short j22_2
		jmp	    short op_end
;=======================================

 read_loop:				   
		in	    al,	dx
		test    al,	20h
		jz	    short read_loop

 j22_5:				   
		in	    al,	dx
		test    al,	20h
		jz	    short op_end
		test    al,	80h
		jz	    short j22_5
		inc	    dx
		in	    al,	dx
		stosb
		dec	    dx
		jmp	    short j22_5
;=======================================

 write_loop:				    
		in	    al,	dx
		test    al,	20h
		jz	    short write_loop
		mov	    cx,	2080h

 j22_7:				    
		in	    al,	dx
		test    al,	ch
		jz	    short op_end
		test    al,	cl
		jz	    short j22_7
		inc	    dx
		lodsb
		out	    dx,	al
		dec	    dx
		jmp	    short j22_7
 ;=======================================

 op_end:				    
		pushf
		call    get_drive
		or	    al,	80h
		mov	    dx,	0F2h ; 'т'
		out	    dx,	al
		call    dss
		call    clock_wait
		call    read_time
		mov	    bx,	[bp+12h]
		sub	    ax,	bx
		neg	    ax
		push    ax
		add	    ds:seg40.timer_low,	ax
		jnb	    short j16_4
		inc	    word ptr ds:seg40.timer_high

 j16_4:			
		cmp	    word ptr ds:seg40.timer_high, 18h
		jnz	    short j16_5
		cmp	    word ptr ds:seg40.timer_low, 0B0h ;	'°'
		jl	    short j16_5
		mov	    word ptr ds:seg40.timer_high, 0
		sub	    word ptr ds:seg40.timer_low, 0B0h ;	'°'
		mov	    byte ptr ds:seg40.timer_ofl, 1

 j16_5:	
		call    enable
		pop	    cx
		jcxz    short j16_7
		push    ds
		push    ax
		push    dx

 j16_6:				    
		int	    1Ch		    ; CLOCK TICK
		loop    j16_6
		pop	    dx
		pop	    ax
		pop	    ds
		or	    al,	al
		jz	    short j16_7
		mov	    bx,	80h ; 'Ђ'
		mov	    cx,	48h ; 'H'
		call    kb_noise
		and	    byte ptr ds:seg40.kb_flag, 0F0h
		and	    byte ptr ds:seg40.kb_flag_1, 0Fh
		and	    byte ptr ds:seg40.kb_flag_2, 1Fh

 j16_7:				    
		popf

 j17:				
		jb	    short j20
		call    results
		jb	    short j20
		cld
		mov	    si,	42h ; 'B'
		lodsb
		and	    al,	0C0h
		jz	    short j22
		cmp	    al,	40h ; '@'
		jnz	    short j18
		lodsb
		cmp	    al,	80h ; 'Ђ'
		jz	    short j21_1
		shl	    al,	1
		shl	    al,	1
		shl	    al,	1
		mov	    ah,	10h
		jb	    short j19
		shl	    al,	1
		mov	    ah,	8
		jb	    short j19
		shl	    al,	1
		shl	    al,	1
		mov	    ah,	4
		jb	    short j19
		shl	    al,	1
		shl	    al,	1
		mov	    ah,	2
		jb	    short j19

 j18:				   
		mov	    ah,	20h ; ' '

 j19:				    
		or	    ds:seg40.diskette_status, ah
		call    num_trans

 j20:				    
		retn
 ;=======================================
 j21_1:	
		mov	    bl,	[bp+0Eh]
		call    num_trans
		cmp	    bl,	al
		jz	    short j21_2
		or	    byte ptr ds:seg40.diskette_status, 4
		mov	    byte ptr ds:seg40.nec_status+1, 80h	; 'Ђ'
		stc
		retn
 ;=======================================

 j21_2:				 
		xor	    ax,	ax
		xor	    si,	si
		mov	    [si+42h], al
		inc	    si
		mov	    [si+42h], al
		jmp	    short j21_3
 ;=======================================
 j22:
		call    num_trans

 j21_3:
		xor	    ah,	ah
		retn
		
endp rw_opn ; sp =	-6

 ;=======================================
		    db 12h dup(0)

 ;=======================================

proc disk_int far

 arg_0	    = word ptr	0Ch

		push    ds
		push    ax
		push    dx
		push    bp
		call    dss
		mov	    bp,	sp
		push    cs
		pop	    ax
		cmp	    ax,	[bp+0Ah]
		jnz	    short loc_FEFAF
		mov	    ax,	[bp+8]
		cmp	    ax,	0EE20h
		jl	    short loc_FEFAF
		cmp	    ax,	0EE66h
		jge	    short loc_FEFAF
		mov	    word ptr [bp+8], 0EE65h
		or	    [bp+arg_0],	1
		mov	    dx,	0F4h ; 'ф'
		in	    al,	dx
		and	    al,	0F0h
		cmp	    al,	0D0h ; 'Р'
		jnz	    short loc_FEF9C
		call    results
		mov	    si,	42h ; 'B'
		mov	    al,	[si+1]
		test    al,	2
		jz	    short loc_FEF9C
		or	    byte ptr ds:41h, 3
		jmp	    short loc_FEFAF

 loc_FEF9C:		
		or	    byte ptr ds:41h, 80h
		mov	    byte ptr ds:3Eh, 0
		mov	    dx,	0F2h ; 'т'
		pop	    bp
		call    get_drive
		push    bp
		out	    dx,	al

 loc_FEFAF:				    
		mov	    al,	20h ; ' '
		out	    20h, al	    ; Interrupt	controller, 8259A.
		pop	    bp
		pop	    dx
		pop	    ax
		pop	    ds
		iret
		
 endp disk_int

;=======================================
 proc 	dss	near		    
		push    ax
		mov	    ax,	BDAseg
		mov	    ds,	ax
		pop	    ax
		retn
 endp	dss		    
;=======================================

proc	nec_output	near		
   
		push    dx
		push    cx
		mov	    dx,	0F4h ;
		xor	    cx,	cx

 j23:				    ; 
		in	    al,	dx
		test    al,	40h
		jz	    short j25
		loop    j23

 j24:				    ;
		or	    byte ptr ds:41h, 80h
		pop	    cx
		pop	    dx
		pop	    ax
		stc
		retn
			
;=======================================
 j25:				    ; 
		xor	    cx,	cx
 j26:				    ;
		in	    al,	dx
		test    al,	80h
		jnz	    short j27
		loop    j26
		jmp	    short j24
;=======================================

 j27:				   
		mov	    al,	ah
		inc	    dx
		out	    dx,	al
		pop	    cx
		pop	    dx
		retn
 endp	nec_output	    
 
 ;=======================================
 
proc	get_parm	near		    ;

	    push    ds
	    push    si
	    sub	    ax,	ax
	    xor	    bh,	bh
	    mov	    ds,	ax
	    lds	    si,	ds:78h
	    shr	    bx,	1
	    pushf
	    mov	    ah,	[bx+si]
	    cmp	    bx,	1
	    jnz	    short j27_1
	    or	    ah,	1
	    jmp	    short j27_2
j27_1:				    ;
	    cmp	    bx,	0Ah
	    jnz	    short j27_2
	    cmp	    ah,	4
	    jge	    short j27_2
	    mov	    ah,	4

j27_2:				    
	    popf
	    pop	    si
	    pop	    ds
	    jb	    short nec_output
	    retn
endp	get_parm	  
  
 ;=======================================
 
proc disk_write near
		or	    byte ptr ds:3Fh, 80h
		mov	    ah,	45h 
endp disk_write

 ;=======================================
proc clock_wait near		    
 
		xor	    al,	al
		out	    43h, al	    ; Timer 8253-5 (AT:	8254.2).
		push    ax
		pop	    ax
		in	    al,	40h	    ; Timer 8253-5 (AT:	8254.2).
		xchg    al,	ah
		in	    al,	40h	    ; Timer 8253-5 (AT:	8254.2).
		xchg    al,	ah
		cmp	    ax,	12Ch	    ; is timer 0 close to wrapping?
		jb	    short clock_wait
		retn
		
endp clock_wait

;=======================================

proc get_drive near
		push    cx
		mov	    cl,	[bp+0]
		mov	    al,	1
		shl	    al,	cl
		and	    al,	7
		pop	    cx
		retn
		
endp get_drive

;=======================================
 
proc num_trans near		    
 
		mov	    al,	ds:seg40.nec_status+3
		cmp	    al,	[bp+0Bh]
		mov	    al,	ds:seg40.nec_status+5
		jz	    short j45
		mov	    bl,	8
		call    get_parm
		mov	    al,	ah

 j45:				 
		inc	    al
		sub	    al,	[bp+0Ah]
		mov	    [bp+0Eh], al

		retn
			
endp num_trans
 ;=======================================
 
proc disable near	

	    push    ax
	    in	    al,	21h	    ; Interrupt	controller, 8259A.
	    mov	    [bp+10h], ax
	    mov	    al,	0BFh ;
	    out	    21h, al	    ; Interrupt	controller, 8259A.
	    call    bound_setup
	    pop	    ax
	    retn
		
endp disable

;=======================================
proc enable near

		push    dx
		mov	    al,	1110110b
		out	    43h, al	    ; Timer 8253-5 (AT:	8254.2).
		push    ax
		pop	    ax
		mov	    al,	0FFh
		out	    41h, al	    ; Timer 8253-5 (AT:	8254.2).
		push    ax
		pop	    ax
		out	    41h, al	    ; Timer 8253-5 (AT:	8254.2).
		mov	    es,	word ptr [bp+10h]
		in	    al,	62h	    ; PC/XT PPI	port C.	Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check error occurred.
		and	    al,	1
		push    ax
		in	    al,	0A0h	    ; PIC 2  same as 0020 for PIC 1
		mov	    al,	80h ; 'Ђ'
		out	    0A0h, al	    ; PIC 2  same as 0020 for PIC 1
		mov	    ax,	[bp+10h]
		out	    21h, al	    ; Interrupt	controller, 8259A.
		pop	    ax
		pop	    dx
		sti
		retn
		
endp enable

;=======================================
proc bound_setup near	
	  
		push    cx
		mov	    bx,	[bp+0Ch]
		push    bx
		mov	    cl,	4
		shr	    bx,	cl
		mov	    cx,	es
		add	    cx,	bx
		mov	    es,	cx
		pop	    bx
		and	    bx,	0Fh
		mov	    si,	bx
		mov	    di,	bx
		pop	    cx
		retn
	
endp bound_setup

;=======================================
   
proc seek near		    
 
		push    si
		push    bx
		push    cx
		mov	    si,	seg40.track_0
		mov	    al,	1
		mov	    cl,	dl
		and	    cx,	0FFh
		add	    si,	cx
		rol	    al,	cl
		pop	    cx
		mov	    bx,	offset j32
		push    bx
		test    ds:seg40.seek_status, al
		jnz	    short j28
		or	    ds:seg40.seek_status, al
		cmp	    byte ptr [si], 0
		jz	    short j28
		mov	    ah,	7
		call    nec_output
		mov	    ah,	dl
		call    nec_output
		call    chk_stat_2
		jb	    short j32_2
		mov	    byte ptr [si], 0

 j28:				    
		mov	    al,	[si]
		sub	    al,	ch
		jz	    short j31_1
		mov	    ah,	0Fh
		call    nec_output
		mov	    ah,	dl
		call    nec_output
		mov	    ah,	ch
		call    nec_output
		call    chk_stat_2
		pushf
		push    cx
		mov	    bl,	12h
		call    get_parm

 j29:				    
		mov	    cx,	550	    ; 1	ms loop
		or	    ah,	ah	    ; test for time expired
		jz	    short j31

 j30:				    
		loop    j30		    ; delay for	1 ms
		dec	    ah
		jmp	    short j29
;=======================================
 j31:				    
		pop	    cx
		popf
		jb	    short j32_2
		mov	    [si], ch

 j31_1:				    
		pop	    bx

 j32:				    
		pop	    bx
		pop	    si
		retn
;=======================================

 j32_2:				   
		mov	    byte ptr [si], 0FFh
		pop	    bx
		jmp	    short j32
		
endp seek
 
 ;=======================================