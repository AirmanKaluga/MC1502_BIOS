;---------------------------------------------------------------------------------------------------
; Interrupt 1Eh - Diskette Parameter Table
;---------------------------------------------------------------------------------------------------
proc    	int_1Eh  far

SrtHdUnld       db      0CFh                       ; Disk parameter table
DmaHdLd        	db      2
MotorOff        db      25h
SectSize        db      2
LastTrack       db      9
GapLen          db      2Ah
DTL             db      0FFh
GapFMT          db      50h
FullChar        db      0F6h
HDSettle        db      19h
MotorOn         db      4

endp    	int_1Eh

