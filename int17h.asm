;---------------------------------------------------------------------------------------------------
; Interrupt 17h - Parallel LPT Services
;---------------------------------------------------------------------------------------------------
proc		int_17h	near
                push	dx
                push	cx
                push	bx
                or	ah, ah
                jz	short loc_FEFE5
                dec	ah
                jz	short loc_FF028
                dec	ah
                jz	short loc_FF00D

loc_FEFE1:				; ...
                pop	bx
                pop	cx
                pop	dx
                iret
endp		int_17h
; ---------------------------------------------------------------------------

loc_FEFE5:				; ...
                push	ax
                mov	bl, 0Ah
                xor	cx, cx
                out	60h, al		; 8042 keyboard	controller data	register.

loc_FEFEC:				; ...
                in	al, 6Ah
                mov	ah, al
                test	al, 80h
                jz	short loc_FF002
                loop	loc_FEFEC
                dec	bl
                jnz	short loc_FEFEC
                or	ah, 1
                and	ah, 0F1h
                jmp	short loc_FF015
; ---------------------------------------------------------------------------

loc_FF002:				; ...
                in	al, 61h		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                or	al, 4
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                and	al, 0FBh
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                pop	ax

loc_FF00D:				; ...
                push	ax

loc_FF00E:				; ...
                in	al, 6Ah
                mov	ah, al
                and	ah, 0D0h

loc_FF015:				; ...
                pop	dx
                mov	al, dl
                test	ah, 10h
                jnz	short loc_FF020
                or	ah, 8

loc_FF020:				; ...
                and	ah, 0E9h
                xor	ah, 0D0h
                jmp	short loc_FEFE1
; ---------------------------------------------------------------------------

loc_FF028:				; ...
                push	ax
                in	al, 61h		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                and	al, 0E3h
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                mov	cx, 4B0h

loc_FF032:				; ...
                loop	loc_FF032
                in	al, 61h		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                or	al, 10h
                out	61h, al		; PC/XT	PPI port B bits:
                                        ; 0: Tmr 2 gate	??? OR	03H=spkr ON
                                        ; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
                                        ; 3: 1=read high switches
                                        ; 4: 0=enable RAM parity checking
                                        ; 5: 0=enable I/O channel check
                                        ; 6: 0=hold keyboard clock low
                                        ; 7: 0=enable kbrd
                jmp	short loc_FF00E
