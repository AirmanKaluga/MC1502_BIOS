;---------------------------------------------------------------------------------------------------
; Обработчик прерывания 16h - Сервис клавиатуры
; Функции:
;   AH = 00h - Чтение следующего символа из буфера клавиатуры (с ожиданием)
;   AH = 01h - Проверка наличия символа в буфере (без ожидания)
;   AH = 02h - Получение состояния флагов клавиатуры
;---------------------------------------------------------------------------------------------------
proc		int_16h	near
                sti					; Разрешаем прерывания
                push	ds				; Сохраняем регистры
                push	bx
                mov	bx, BDAseg			; Загружаем сегмент BDA
                mov	ds, bx
                assume ds:nothing
                
                ; Проверяем запрошенную функцию по значению в AH
                or	ah, ah			; AH = 00h?
                jz	short read_key_with_wait	; Да - чтение с ожиданием
                dec	ah				; AH = 01h?
                jz	short check_key_available	; Да - проверка наличия символа
                dec	ah				; AH = 02h?
                jz	short get_keyboard_status	; Да - получение состояния флагов
                
                ; Неизвестная функция - возврат без изменений
                pop	bx
                pop	ds
                assume ds:nothing
                iret

endp		int_16h

; ---------------------------------------------------------------------------
; Функция 00h: Чтение символа из буфера клавиатуры с ожиданием
; Возвращает: AH = скан-код, AL = ASCII символ
; ---------------------------------------------------------------------------
read_key_with_wait:				; ...
                cli					; Запрещаем прерывания для атомарной работы
                mov	bx, [ds:keybd_q_head_]	; Получаем указатель головы буфера
                
wait_for_key:					; Цикл ожидания появления символа
                cmp	bx, [ds:keybd_q_tail_]	; Сравниваем голову и хвост
                sti					; Разрешаем прерывания (на время ожидания)
                jz	short wait_for_key	; Если равны - буфер пуст, ждем дальше
                
                ; Символ доступен
                cli					; Снова запрещаем прерывания для чтения
                mov	ax, [bx]		; Загружаем символ (AH=скан-код, AL=ASCII)
                call	advance_buffer_pointer_16h	; Продвигаем указатель головы
                mov	[ds:keybd_q_head_], bx	; Сохраняем новый указатель
                sti					; Разрешаем прерывания
                
                pop	bx
                pop	ds
                iret				; Возврат из прерывания

; ---------------------------------------------------------------------------
; Функция 01h: Проверка наличия символа в буфере (без ожидания)
; Возвращает: ZF = 1 если буфер пуст, ZF = 0 если символ доступен
;             Если символ доступен, AH = скан-код, AL = ASCII символ
; ---------------------------------------------------------------------------
check_key_available:				; ...
                cli					; Запрещаем прерывания
                mov	bx, [ds:keybd_q_head_]	; Получаем указатель головы
                cmp	bx, [ds:keybd_q_tail_]	; Сравниваем с хвостом
                mov	ax, [bx]		; Загружаем символ (даже если его нет)
                sti					; Разрешаем прерывания
                
                ; Восстанавливаем регистры и возвращаем управление
                ; (ZF уже установлен сравнением cmp)
                pop	bx
                pop	ds
                retf	2			; Возврат с удалением флагов из стека

; ---------------------------------------------------------------------------
; Функция 02h: Получение состояния флагов клавиатуры
; Возвращает: AL = байт состояния флагов клавиатуры (keybd_flags_1_)
; ---------------------------------------------------------------------------
get_keyboard_status:				; ...
                mov	al, [ds:keybd_flags_1_]	; Загружаем байт флагов
                pop	bx
                pop	ds
                iret

; ---------------------------------------------------------------------------
; Вспомогательная процедура: Продвижение указателя буфера клавиатуры
; Вход: BX - текущий указатель
; Выход: BX - новый указатель (продвинутый на 2 байта, с учетом закольцовывания)
; ---------------------------------------------------------------------------
proc		advance_buffer_pointer_16h near
                add	bx, 2			; Переходим к следующему элементу (слово)
                cmp	bx, 0x003E		; Достигли конца буфера?
                jnz	short pointer_ok_16h	; Нет - возвращаем как есть
                mov	bx, 0x001E		; Да - переходим к началу буфера
pointer_ok_16h:				; ...
                retn
endp		advance_buffer_pointer_16h

; ---------------------------------------------------------------------------
; Таблицы преобразования скан-кодов для клавиатуры
; ---------------------------------------------------------------------------

; Таблица специальных клавиш (управляющие клавиши)
special_keys_table:
                db  52h	; Insert
                db  3Ah	; Caps Lock
                db  45h	; Num Lock
                db  46h	; Scroll Lock
                db  38h	; Left Alt
                db  1Dh	; Left Ctrl
                db  2Ah	; Left Shift
                db  36h	; Right Shift

; Флаги для специальных клавиш (битовые маски)
special_key_flags:
                db  80h	; Insert
                db  40h	; Caps Lock
                db  20h	; Num Lock
                db  10h	; Scroll Lock
                db  08h	; Left Alt
                db  04h	; Left Ctrl
                db  02h	; Left Shift
                db  01h	; Right Shift

; Таблица преобразования скан-кодов при нажатом Ctrl
ctrl_keys_table:
                db  1Bh	; Escape
                db 0FFh	; (не используется)
                db  00h	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db  1Eh	; Ctrl+A
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db  1Fh	; Ctrl+B
                db 0FFh	; 
                db  7Fh	; Ctrl+Backspace? (DEL)
                db 0FFh	; 
                db  11h	; Ctrl+Q
                db  17h	; Ctrl+W
                db  05h	; Ctrl+E
                db  12h	; Ctrl+R
                db  14h	; Ctrl+T
                db  19h	; Ctrl+Y
                db  15h	; Ctrl+U
                db  09h	; Ctrl+I
                db  0Fh	; Ctrl+O
                db  10h	; Ctrl+P
                db  1Bh	; Ctrl+[
                db  1Dh	; Ctrl+]
                db  0Ah	; Ctrl+Enter
                db 0FFh	; 
                db  01h	; Ctrl+A (другой код?)
                db  13h	; Ctrl+S
                db  04h	; Ctrl+D
                db  06h	; Ctrl+F
                db  07h	; Ctrl+G
                db  08h	; Ctrl+H
                db  0Ah	; Ctrl+J
                db  0Bh	; Ctrl+K
                db  0Ch	; Ctrl+L
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db  1Ch	; Ctrl+\
                db  1Ah	; Ctrl+Z
                db  18h	; Ctrl+X
                db  03h	; Ctrl+C
                db  16h	; Ctrl+V
                db  02h	; Ctrl+B
                db  0Eh	; Ctrl+N
                db  0Dh	; Ctrl+M
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db 0FFh	; 
                db  20h	; Пробел
                db 0FFh	; 

; Таблица для функциональных клавиш с Ctrl
ctrl_function_keys_table:
                db  5Eh	; Ctrl+F1
                db  5Fh	; Ctrl+F2
                db  60h	; Ctrl+F3
                db  61h	; Ctrl+F4
                db  62h	; Ctrl+F5
                db  63h	; Ctrl+F6
                db  64h	; Ctrl+F7
                db  65h	; Ctrl+F8
                db  66h	; Ctrl+F9
                db  67h	; Ctrl+F10
                db 0FFh	; 
                db 0FFh	; 
                db  77h	; (дополнительный код)
                db 0FFh	; 
                db  84h	; (дополнительный код)
                db 0FFh	; 
                db  73h	; (дополнительный код)
                db 0FFh	; 
                db  74h	; (дополнительный код)
                db 0FFh	; 
                db  75h	; (дополнительный код)
                db 0FFh	; 
                db  76h	; (дополнительный код)
                db 0FFh	; 
                db 0FFh	; 

; Таблица преобразования для обычных клавиш (без модификаторов)
normal_keys_table:
                db  1Bh	; Escape
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
                db  08h	; Backspace
                db  09h	; Tab
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
                db  0Dh	; Enter
                db 0FFh	; 
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
                db 0FFh	; 
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
                db 0FFh	; 
                db  2Ah	; * (на цифровом блоке)
                db 0FFh	; 
                db  20h	; Пробел
                db 0FFh	; 

; Таблица преобразования для клавиш с Shift
shift_keys_table:
                db  1Bh	; Escape
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
                db  08h	; Backspace
                db  00h	; (особый случай для Shift+Tab?)
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
                db  0Dh	; Enter
                db 0FFh	; 
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
                db 0FFh	; 
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
                db 0FFh	; 
                db  00h	; (особый случай)
                db 0FFh	; 
                db  20h	; Пробел
                db 0FFh	; 

; Таблица для функциональных клавиш с Shift
shift_function_keys_table:
                db  54h	; Shift+F1
                db  55h	; Shift+F2
                db  56h	; Shift+F3
                db  57h	; Shift+F4
                db  58h	; Shift+F5
                db  59h	; Shift+F6
                db  5Ah	; Shift+F7
                db  5Bh	; Shift+F8
                db  5Ch	; Shift+F9
                db  5Dh	; Shift+F10

; Таблица для функциональных клавиш с Alt
alt_function_keys_table:
                db  68h	; Alt+F1
                db  69h	; Alt+F2
                db  6Ah	; Alt+F3
                db  6Bh	; Alt+F4
                db  6Ch	; Alt+F5
                db  6Dh	; Alt+F6
                db  6Eh	; Alt+F7
                db  6Fh	; Alt+F8
                db  70h	; Alt+F9
                db  71h	; Alt+F10

; Таблица для цифрового блока с Shift
numpad_shift_table:
                db  37h	; 7 (Home)
                db  38h	; 8 (Up arrow)
                db  39h	; 9 (PgUp)
                db  2Dh	; - (на цифровом блоке)
                db  34h	; 4 (Left arrow)
                db  35h	; 5 (на цифровом блоке)
                db  36h	; 6 (Right arrow)
                db  2Bh	; + (на цифровом блоке)
                db  31h	; 1 (End)
                db  32h	; 2 (Down arrow)
                db  33h	; 3 (PgDn)
                db  30h	; 0 (Ins)
                db  2Eh	; . (Del)

; Таблица для цифрового блока без Shift/NumLock
numpad_normal_table:
                db  47h	; 7 (Home) или 7 при выключенном NumLock
                db  48h	; 8 (Up arrow) или 8
                db  49h	; 9 (PgUp) или 9
                db 0FFh	; 
                db  4Bh	; 4 (Left arrow) или 4
                db 0FFh	; 
                db  4Dh	; 6 (Right arrow) или 6
                db 0FFh	; 
                db  4Fh	; 1 (End) или 1

; ---------------------------------------------------------------------------
; Ниже следует код, который, похоже, не принадлежит к этой процедуре.
; Возможно, это часть другой процедуры или ошибочно включенный код.
; Оставим без изменений с комментарием.
; ---------------------------------------------------------------------------
                push	ax  ; TODO: Проверить принадлежность этого кода
                push	cx
                push	dx
                push	bx