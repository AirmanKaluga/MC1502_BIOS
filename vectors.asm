;------------------------------------------------------------------------------------------------------------
;	Interrupt vector tables
;------------------------------------------------------------------------------------------------------------
int_vec_table_1:
                dw offset int_08h         ; Offest int_08h
                dw offset int_09h         ; Offset int_09h
                dw offset dummy_int       ; Offset int_0Ah
                dw offset dummy_int       ; Ofsset int_0Bh
                dw offset dummy_int       ; Offset int_0Ch
                dw offset dummy_int       ; Offset int_0Dh
                dw offset dummy_int       ; Offset int_0Eh
                dw offset dummy_int       ; Offset int_0Fh
                dw offset int_10h         ; Offset int_10h
                dw offset int_11h         ; Ofsset int_11h
                dw offset int_12h         ; Offset int_12h
                dw offset int_13h	        ; Offset int_13h
                dw offset int_14h         ; Offset int_14h
                dw offset dummy_int       ; Offset int_15h
                dw offset int_16h         ; Offset int_16h
                dw offset int_17h         ; Offset int_17h
                dw offset dummy_int       ; Offset int_18h
                dw offset int_19h         ; Offset int_19h
                dw offset int_1Ah	        ; Offset int_1Ah
                dw offset dummy_int       ; Offset int_1Bh
                dw offset dummy_int       ; Offset int_1Ch
                dw offset int_1Dh	        ; Offset int_1Dh
                dw offset int_1Eh         ; Offset int_1Eh
                
int_vec_table_2:
                dw offset int_68h
                dw offset int_69h
                dw offset int_6Ah
                dw offset int_6Bh
                dw offset int_6Ch
                dw offset int_6Dh
                dw offset int_6Eh
                dw offset int_6Fh
                
                