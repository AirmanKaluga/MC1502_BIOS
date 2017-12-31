;---------------------------------------------------------------------------------------------------
; Interrupt 1Dh - Video Parameter Tables
;---------------------------------------------------------------------------------------------------
proc		int_1Dh	far

                db	38h, 28h, 2Dh, 0Ah, 1Fh, 6, 19h	; Init string for 40x25 color
                db	1Ch, 2, 7, 6, 7
                db	0, 0, 0, 0

                db	71h, 50h, 5Ah, 0Ah, 1Fh, 6, 19h	; Init string for 80x25 color
                db	1Ch, 2, 7, 6, 7
                db	0, 0, 0, 0

                db	38h, 28h, 2Dh, 0Ah, 7Fh, 6, 64h	; Init string for graphics
                db	70h, 2, 1, 6, 7
                db	0, 0, 0, 0

                db	61h, 50h, 52h, 0Fh, 19h, 6, 19h	; Init string for 80x25 b/w
                db	19h, 2, 0Dh, 0Bh, 0Ch
                db	0, 0, 0, 0

regen_len	dw	0800h			; Regen length, 40x25
                dw	1000h			;	        80x25
                dw	4000h			;	        graphics
                dw	4000h

max_cols	db	28h, 28h, 50h, 50h, 28h, 28h, 50h, 50h	; Maximum columns
video_hdwr_mode db	2Ch, 28h, 2Dh, 29h, 2Ah, 2Eh, 1Eh, 29h	; Table of mode sets
mul_lookup      db	00h, 00h, 10h, 10h, 20h, 20h, 20h, 30h	; Table lookup for multiply
endp		int_1Dh

