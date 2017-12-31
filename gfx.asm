;---------------------------------------------------------------------------------------------------
; 8x8 Graphics Character Set (chars 0-127)
;---------------------------------------------------------------------------------------------------
gfx_chars	db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;   0  nul
                db	07Eh, 081h, 0A5h, 081h, 0BDh, 099h, 081h, 07Eh		;   1  soh
                db	07Eh, 0FFh, 0DBh, 0FFh, 0C3h, 0E7h, 0FFh, 07Eh		;   2  stx
                db	06Ch, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h		;   3  etx
                db	010h, 038h, 07Ch, 0FEh,	07Ch, 038h, 010h, 000h		;   4  eot
                db	038h, 07Ch, 038h, 0FEh,	0FEh, 07Ch, 038h, 07Ch		;   5  enq
                db	010h, 010h, 038h, 07Ch,	0FEh, 07Ch, 038h, 07Ch		;   6  ack
                db	000h, 000h, 018h, 03Ch,	03Ch, 018h, 000h, 000h		;   7  bel
                db	0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh		;   8  bs
                db	000h, 03Ch, 066h, 042h, 042h, 066h, 03Ch, 000h		;   9  ht
                db	0FFh, 0C3h, 099h, 0BDh, 0BDh, 099h, 0C3h, 0FFh		;  10  lf
                db	00Fh, 007h, 00Fh, 07Dh, 0CCh, 0CCh, 0CCh, 078h		;  11  vt
                db	03Ch, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h		;  12  ff
                db	03Fh, 033h, 03Fh, 030h, 030h, 070h, 0F0h, 0E0h		;  13  cr
                db	07Fh, 063h, 07Fh, 063h, 063h, 067h, 0E6h, 0C0h		;  14  so
                db	099h, 05Ah, 03Ch, 0E7h, 0E7h, 03Ch, 05Ah, 099h		;  15  si
                db	080h, 0E0h, 0F8h, 0FEh, 0F8h, 0E0h, 080h, 000h		;  16  dle
                db	002h, 00Eh, 03Eh, 0FEh,	03Eh, 00Eh, 002h, 000h		;  17  dc1
                db	018h, 03Ch, 07Eh, 018h, 018h, 07Eh, 03Ch, 018h		;  18  dc2
                db	066h, 066h, 066h, 066h,	066h, 000h, 066h, 000h		;  19  dc3
                db	07Fh, 0DBh, 0DBh, 07Bh,	01Bh, 01Bh, 01Bh, 000h		;  20  dc4
                db	03Eh, 063h, 038h, 06Ch,	06Ch, 038h, 0CCh, 078h		;  21  nak
                db	000h, 000h, 000h, 000h,	07Eh, 07Eh, 07Eh, 000h		;  22  syn
                db	018h, 03Ch, 07Eh, 018h, 07Eh, 03Ch, 018h, 0FFh		;  23  etb
                db	018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 000h		;  24  can
                db	018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h		;  25  em
                db	000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h		;  26  sub
                db	000h, 030h, 060h, 0FEh,	060h, 030h, 000h, 000h		;  27  esc
                db	000h, 000h, 0C0h, 0C0h,	0C0h, 0FEh, 000h, 000h		;  28  fs
                db	000h, 024h, 066h, 0FFh,	066h, 024h, 000h, 000h		;  29  gs
                db	000h, 018h, 03Ch, 07Eh,	0FFh, 0FFh, 000h, 000h		;  30  rs
                db	000h, 0FFh, 0FFh, 07Eh, 03Ch, 018h, 000h, 000h		;  31  us
                db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;  32  space
                db	030h, 078h, 078h, 030h,	030h, 000h, 030h, 000h		;  33  !
                db	06Ch, 06Ch, 06Ch, 000h,	000h, 000h, 000h, 000h		;  34  "
                db	06Ch, 06Ch, 0FEh, 06Ch,	0FEh, 06Ch, 06Ch, 000h		;  35  #
                db	030h, 07Ch, 0C0h, 078h, 00Ch, 0F8h, 030h, 000h		;  36  $
                db	000h, 0C6h, 0CCh, 018h, 030h, 066h, 0C6h, 000h		;  37  %
                db	038h, 06Ch, 038h, 076h,	0DCh, 0CCh, 076h, 000h		;  38  &
                db	060h, 060h, 0C0h, 000h,	000h, 000h, 000h, 000h		;  39  '
                db	018h, 030h, 060h, 060h,	060h, 030h, 018h, 000h		;  40  (
                db	060h, 030h, 018h, 018h,	018h, 030h, 060h, 000h		;  41  )
                db	000h, 066h, 03Ch, 0FFh,	03Ch, 066h, 000h, 000h		;  42  *
                db	000h, 030h, 030h, 0FCh,	030h, 030h, 000h, 000h		;  43  +
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 060h		;  44  ,
                db	000h, 000h, 000h, 0FCh,	000h, 000h, 000h, 000h		;  45  -
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 000h		;  46  .
                db	006h, 00Ch, 018h, 030h,	060h, 0C0h, 080h, 000h		;  47  /
                db	07Ch, 0C6h, 0CEh, 0DEh,	0F6h, 0E6h, 07Ch, 000h		;  48  0
                db	030h, 070h, 030h, 030h,	030h, 030h, 0FCh, 000h		;  49  1
                db	078h, 0CCh, 00Ch, 038h,	060h, 0CCh, 0FCh, 000h		;  50  2
                db	078h, 0CCh, 00Ch, 038h,	00Ch, 0CCh, 078h, 000h		;  51  3
                db	01Ch, 03Ch, 06Ch, 0CCh,	0FEh, 00Ch, 01Eh, 000h		;  52  4
                db	0FCh, 0C0h, 0F8h, 00Ch,	00Ch, 0CCh, 078h, 000h		;  53  5
                db	038h, 060h, 0C0h, 0F8h, 0CCh, 0CCh, 078h, 000h		;  54  6
                db	0FCh, 0CCh, 00Ch, 018h,	030h, 030h, 030h, 000h		;  55  7
                db	078h, 0CCh, 0CCh, 078h,	0CCh, 0CCh, 078h, 000h		;  56  8
                db	078h, 0CCh, 0CCh, 07Ch,	00Ch, 018h, 070h, 000h		;  57  9
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 000h		;  58  :
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 060h		;  59  ;
                db	018h, 030h, 060h, 0C0h,	060h, 030h, 018h, 000h		;  60  <
                db	000h, 000h, 0FCh, 000h,	000h, 0FCh, 000h, 000h		;  61  =
                db	060h, 030h, 018h, 00Ch, 018h, 030h, 060h, 000h		;  62  >
                db	078h, 0CCh, 00Ch, 018h,	030h, 000h, 030h, 000h		;  63  ?
                db	07Ch, 0C6h, 0DEh, 0DEh,	0DEh, 0C0h, 078h, 000h		;  64  @
                db	030h, 078h, 0CCh, 0CCh, 0FCh, 0CCh, 0CCh, 000h		;  65  A
                db	0FCh, 066h, 066h, 07Ch, 066h, 066h, 0FCh, 000h		;  66  B
                db	03Ch, 066h, 0C0h, 0C0h, 0C0h, 066h, 03Ch, 000h		;  67  C
                db	0F8h, 06Ch, 066h, 066h, 066h, 06Ch, 0F8h, 000h		;  68  D
                db	0FEh, 062h, 068h, 078h,	068h, 062h, 0FEh, 000h		;  69  E
                db	0FEh, 062h, 068h, 078h,	068h, 060h, 0F0h, 000h		;  70  F
                db	03Ch, 066h, 0C0h, 0C0h, 0CEh, 066h, 03Eh, 000h		;  71  G
                db	0CCh, 0CCh, 0CCh, 0FCh,	0CCh, 0CCh, 0CCh, 000h		;  72  H
                db	078h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		;  73  I
                db	01Eh, 00Ch, 00Ch, 00Ch,	0CCh, 0CCh, 078h, 000h		;  74  J
                db	0E6h, 066h, 06Ch, 078h,	06Ch, 066h, 0E6h, 000h		;  75  K
                db	0F0h, 060h, 060h, 060h,	062h, 066h, 0FEh, 000h		;  76  L
                db	0C6h, 0EEh, 0FEh, 0FEh,	0D6h, 0C6h, 0C6h, 000h		;  77  M
                db	0C6h, 0E6h, 0F6h, 0DEh,	0CEh, 0C6h, 0C6h, 000h		;  78  N
                db	038h, 06Ch, 0C6h, 0C6h,	0C6h, 06Ch, 038h, 000h		;  79  O
                db	0FCh, 066h, 066h, 07Ch,	060h, 060h, 0F0h, 000h		;  80  P
                db	078h, 0CCh, 0CCh, 0CCh,	0DCh, 078h, 01Ch, 000h		;  81  Q
                db	0FCh, 066h, 066h, 07Ch,	06Ch, 066h, 0E6h, 000h		;  82  R   +
                db	078h, 0CCh, 0E0h, 070h,	01Ch, 0CCh, 078h, 000h		;  83  S   +
                db	0FCh, 0B4h, 030h, 030h,	030h, 030h, 078h, 000h		;  84  T   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCh, 0CCh, 0FCh, 000h		;  85  U   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCH, 078h, 030h, 000h		;  86  V   +
                db	0C6h, 0C6h, 0C6h, 0D6h,	0FEh, 0EEh, 0C6h, 000h		;  87  W   +
                db	0C6h, 0C6h, 06Ch, 038h,	038h, 06Ch, 0C6h, 000h		;  88  X   +
                db	0CCh, 0CCh, 0CCh, 078h,	030h, 030h, 078h, 000h		;  89  Y   +
                db	0FEh, 0C6h, 08Ch, 018h,	032h, 066h, 0FEh, 000h		;  90  Z   +
                db	078h, 060h, 060h, 060h,	060h, 060h, 078h, 000h		;  91  [   +
                db	0C0h, 060h, 030h, 018h,	00Ch, 006h, 002h, 000h		;  92  backslash   +
                db	078h, 018h, 018h, 018h,	018h, 018h, 078h, 000h		;  93  ]   +
                db	010h, 038h, 06Ch, 0C6h,	000h, 000h, 000h, 000h		;  94  ^   +
                db	000h, 000h, 000h, 000h,	000h, 000h, 000h, 0FFh		;  95  _   +
                db	030h, 030h, 018h, 000h,	000h, 000h, 000h, 000h		;  96  `   +
                db	000h, 000h, 078h, 00Ch,	07Ch, 0CCh, 076h, 000h		;  97  a   +
                db	0E0h, 060h, 060h, 07Ch,	066h, 066h, 0DCh, 000h		;  98  b   +
                db	000h, 000h, 078h, 0CCh,	0C0h, 0CCh, 078h, 000h		;  99  c   +
                db	01Ch, 00Ch, 00Ch, 07Ch,	0CCh, 0CCh, 076h, 000h		; 100  d   +
                db	000h, 000h, 078h, 0CCh,	0FCh, 0C0h, 078h, 000h		; 101  e   +
                db	038h, 06Ch, 060h, 0F0h,	060h, 060h, 0F0h, 000h		; 102  f   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 103  g   +
                db	0E0h, 060h, 06Ch, 076h,	066h, 066h, 0E6h, 000h		; 104  h   +
                db	030h, 000h, 070h, 030h,	030h, 030h, 078h, 000h		; 105  i   +
                db	00Ch, 000h, 00Ch, 00Ch,	00Ch, 0CCh, 0CCh, 078h		; 106  j   +
                db	0E0h, 060h, 066h, 06Ch,	078h, 06Ch, 0E6h, 000h		; 107  k   +
                db	070h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		; 108  l   +
                db	000h, 000h, 0CCh, 0FEh,	0FEh, 0D6h, 0C6h, 000h		; 109  m   +
                db	000h, 000h, 0F8h, 0CCh,	0CCh, 0CCh, 0CCh, 000h		; 110  n   +
                db	000h, 000h, 078h, 0CCh,	0CCh, 0CCh, 078h, 000h		; 111  o   +
                db	000h, 000h, 0DCh, 066h,	066h, 07Ch, 060h, 0F0h		; 112  p   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 01Eh		; 113  q   +
                db	000h, 000h, 0DCh, 076h,	066h, 060h, 0F0h, 000h		; 114  r   +
                db	000h, 000h, 07Ch, 0C0h,	078h, 00Ch, 0F8h, 000h		; 115  s   +
                db	010h, 030h, 07Ch, 030h,	030h, 034h, 018h, 000h		; 116  t   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 0CCh, 076h, 000h		; 117  u   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 078h, 030h, 000h		; 118  v   +
                db	000h, 000h, 0C6h, 0D6h, 0FEh, 0FEh, 06Ch, 000h		; 119  w   +
                db	000h, 000h, 0C6h, 06Ch,	038h, 06Ch, 0C6h, 000h		; 120  x   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 121  y   +
                db	000h, 000h, 0FCh, 098h,	030h, 064h, 0FCh, 000h		; 122  z   +
                db	01Ch, 030h, 030h, 0E0h,	030h, 030h, 01Ch, 000h		; 123  {   +
                db	018h, 018h, 018h, 000h,	018h, 018h, 018h, 000h		; 124  |   +
                db	0E0h, 030h, 030h, 01Ch,	030h, 030h, 0E0h, 000h		; 125  }   +
                db	076h, 0DCh, 000h, 000h,	000h, 000h, 000h, 000h		; 126  ~   +
                db	000h, 010h, 038h, 06Ch,	0C6h, 0C6h, 0FEh, 000h		; 127  del +
;---------------------------------------------------------------------------------------------------
