;---------------------------------------------------------------------------------------------------
; Interrupt 16h - Keyboard
;---------------------------------------------------------------------------------------------------
proc		int_16h
                sti
                push	ds
                push	bx
                mov	bx, BDAseg
                mov	ds, bx
                assume ds:nothing
                or	ah, ah
                jz	short loc_FE845
                dec	ah
                jz	short loc_FE85E
                dec	ah
                jz	short loc_FE86F
                pop	bx
                pop	ds
                assume ds:nothing
                iret
endp		int_16h
; ---------------------------------------------------------------------------

loc_FE845:				; ...
                cli
                mov	bx, [ds:keybd_q_head_]
                cmp	bx, [ds:keybd_q_tail_]
                sti
                jz	short loc_FE845
                mov	ax, [bx]
                call	sub_FE5E8
                mov	[ds:keybd_q_head_], bx
                pop	bx
                pop	ds
                iret
; ---------------------------------------------------------------------------

loc_FE85E:				; ...
                cli
                mov	bx, [ds:keybd_q_head_]
                cmp	bx, [ds:keybd_q_tail_]
                mov	ax, [bx]
                sti
                pop	bx
                pop	ds
                retf	2
; ---------------------------------------------------------------------------

loc_FE86F:				; ...
                mov	al, [ds:keybd_flags_1_]
                pop	bx
                pop	ds
                iret



proc		sub_FE875 near		; ...
                add	bx, 2

                cmp	bx, 0x003E
                jnz	short locret_FE881
                mov	bx, 1Eh
endp		sub_FE875 ; sp-analysis	failed


locret_FE881:				; ...
                retn
; ---------------------------------------------------------------------------
unk_FE882	db  52h	; R		; ...
unk_FE883	db  3Ah	; :		; ...
                db  45h	; E
                db  46h	; F
                db  38h	; 8
                db  1Dh
                db  2Ah	; *
                db  36h	; 6
data_31		db  80h	;
                db  40h	; @
                db  20h
                db  10h
                db    8
                db    4
                db    2
                db    1
unk_FE892	db  1Bh			; ...
                db 0FFh
                db    0
                db 0FFh
                db 0FFh
                db 0FFh
                db  1Eh
                db 0FFh
                db 0FFh
                db 0FFh
                db 0FFh
                db  1Fh
                db 0FFh
                db  7Fh	;
                db 0FFh
                db  11h
                db  17h
                db    5
                db  12h
                db  14h
                db  19h
                db  15h
                db    9
                db  0Fh
                db  10h
                db  1Bh
                db  1Dh
                db  0Ah
                db 0FFh
                db    1
                db  13h
                db    4
                db    6
                db    7
                db    8
                db  0Ah
                db  0Bh
                db  0Ch
                db 0FFh
                db 0FFh
                db 0FFh
                db 0FFh
                db  1Ch
                db  1Ah
                db  18h
                db    3
                db  16h
                db    2
                db  0Eh
                db  0Dh
                db 0FFh
                db 0FFh
                db 0FFh
                db 0FFh
                db 0FFh
                db 0FFh
                db  20h
                db 0FFh
unk_FE8CC	db  5Eh	; ^		; ...
                db  5Fh	; _
                db  60h	; `
                db  61h	; a
                db  62h	; b
                db  63h	; c
                db  64h	; d
                db  65h	; e
                db  66h	; f
                db  67h	; g
                db 0FFh
                db 0FFh
                db  77h	; w
                db 0FFh
                db  84h	;
                db 0FFh
                db  73h	; s
                db 0FFh
                db  74h	; t
                db 0FFh
                db  75h	; u
                db 0FFh
                db  76h	; v
                db 0FFh
                db 0FFh
unk_FE8E5	db  1Bh			; ...
                db  31h	; 1
                db  32h	; 2
                db  33h	; 3
                db  34h	; 4
                db  35h	; 5
                db  36h	; 6
                db  37h	; 7
                db  38h	; 8
                db  39h	; 9
                db  30h	; 0
                db  2Dh	; -
                db  3Dh	; =
                db    8
                db    9
                db  71h	; q
                db  77h	; w
                db  65h	; e
                db  72h	; r
                db  74h	; t
                db  79h	; y
                db  75h	; u
                db  69h	; i
                db  6Fh	; o
                db  70h	; p
                db  5Bh	; [
                db  5Dh	; ]
                db  0Dh
                db 0FFh
                db  61h	; a
                db  73h	; s
                db  64h	; d
                db  66h	; f
                db  67h	; g
                db  68h	; h
                db  6Ah	; j
                db  6Bh	; k
                db  6Ch	; l
                db  3Bh	; ;
                db  27h	; '
                db  60h	; `
                db 0FFh
                db  5Ch	; \
                db  7Ah	; z
                db  78h	; x
                db  63h	; c
                db  76h	; v
                db  62h	; b
                db  6Eh	; n
                db  6Dh	; m
                db  2Ch	; ,
                db  2Eh	; .
                db  2Fh	; /
                db 0FFh
                db  2Ah	; *
                db 0FFh
                db  20h
                db 0FFh
unk_FE91F	db  1Bh	; ...
                db  21h	; !
                db  40h	; @
                db  23h	; #
                db  24h	; $
                db  25h	; %
                db  5Eh	; ^
                db  26h	; &
                db  2Ah	; *
                db  28h	; (
                db  29h	; )
                db  5Fh	; _
                db  2Bh	; +
                db    8
                db    0
                db  51h	; Q
                db  57h	; W
                db  45h	; E
                db  52h	; R
                db  54h	; T
                db  59h	; Y
                db  55h	; U
                db  49h	; I
                db  4Fh	; O
                db  50h	; P
                db  7Bh	; {
                db  7Dh	; }
                db  0Dh
                db 0FFh
                db  41h	; A
                db  53h	; S
                db  44h	; D
                db  46h	; F
                db  47h	; G
                db  48h	; H
                db  4Ah	; J
                db  4Bh	; K
                db  4Ch	; L
                db  3Ah	; :
                db  22h	; "
                db  7Eh	; ~
                db 0FFh
                db  7Ch	; |
                db  5Ah	; Z
                db  58h	; X
                db  43h	; C
                db  56h	; V
                db  42h	; B
                db  4Eh	; N
                db  4Dh	; M
                db  3Ch	; <
                db  3Eh	; >
                db  3Fh	; ?
                db 0FFh
                db    0
                db 0FFh
                db  20h
                db 0FFh
unk_FE959	db  54h	; T		; ...
                db  55h	; U
                db  56h	; V
                db  57h	; W
                db  58h	; X
                db  59h	; Y
                db  5Ah	; Z
                db  5Bh	; [
                db  5Ch	; \
                db  5Dh	; ]
unk_FE963	db  68h	; h		; ...
                db  69h	; i
                db  6Ah	; j
                db  6Bh	; k
                db  6Ch	; l
                db  6Dh	; m
                db  6Eh	; n
                db  6Fh	; o
                db  70h	; p
                db  71h	; q
unk_FE96D	db  37h	; 7		; ...
                db  38h	; 8
                db  39h	; 9
                db  2Dh	; -
                db  34h	; 4
                db  35h	; 5
                db  36h	; 6
                db  2Bh	; +
                db  31h	; 1
                db  32h	; 2
                db  33h	; 3
                db  30h	; 0
                db  2Eh	; .
unk_FE97A	db  47h	; G		; ...
                db  48h	; H
                db  49h	; I
                db 0FFh
                db  4Bh	; K
                db 0FFh
                db  4Dh	; M
                db 0FFh
                db  4Fh	; O
; ---------------------------------------------------------------------------
                push	ax  ; TODO Unknown PUSH
                push	cx
                push	dx
                push	bx
