;---------------------------------------------------------------------------------------------------
; Variables
;---------------------------------------------------------------------------------------------------
LF			equ	0Ah
CR			equ	0Dh

BDAseg 			equ 	040h

equip_bits_ 		equ 	010h
main_ram_size_ 		equ 	013h
keybd_flags_1_ 		equ 	017h
keybd_flags_2_ 		equ 	018h
keybd_alt_num_ 		equ 	019h
keybd_q_head_ 		equ 	01Ah
keybd_q_tail_ 		equ 	01Ch
keybd_break_ 		equ 	071h
keybd_buffer_ 		equ 	01Eh
keybd_buffer_end	equ 	03Eh

dsk_recal_stat 		equ 	03Eh
dsk_motor_stat 		equ 	03Fh
dsk_motor_tmr 		equ 	040h
dsk_ret_code_ 		equ 	041h
dsk_status_1 		equ 	042h
dsk_status_2 		equ 	043h
dsk_status_3 		equ 	044h
dsk_status_4 		equ 	045h
dsk_status_5 		equ 	046h
dsk_status_7 		equ 	048h
dsk_motor_stat_ 	equ 	043Fh

video_mode_ 		equ 	049h
video_columns_ 		equ 	04Ah
video_buf_siz_ 		equ 	04Ch 
video_pag_off_ 		equ 	04Eh
vid_curs_pos0_ 		equ 	050h

vid_curs_mode_ 		equ 	060h
video_page_ 		equ 	062h
video_port_ 		equ 	063h
video_mode_reg_ 	equ 	065h
video_color_ 		equ 	066h

gen_use_ptr_ 		equ 	067h
gen_use_seg_ 		equ 	069h
gen_int_occurd_ 	equ 	06Bh

timer_low_ 		equ 	06Ch
timer_hi_ 		equ 	06Eh
timer_rolled_ 		equ 	070h

warm_boot_flag_ 	equ 	072h
prn_timeout_1_ 		equ 	078h
rs232_timeout1_ 	equ 	07Ch

mfg_port        	equ      80h    


mem_test_cycle_addr 	equ 	03Eh
mem_test_cycle_full 	equ    4000h
mem_test_cycle_short	equ    100h

