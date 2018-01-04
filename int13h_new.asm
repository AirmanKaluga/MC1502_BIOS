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
proc		int_13h	near

;arg_B	    = byte ptr	0Fh

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
			mov	    [bp+0Fh],	ah
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
 endp		int_13h

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
			
 ; ==============================================================================
 j25:				    ; 
		    xor	    cx,	cx
 j26:				    ;
		    in	    al,	dx
		    test    al,	80h
		    jnz	    short j27
		    loop    j26
		    jmp	    short j24
 ; ==============================================================================

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
