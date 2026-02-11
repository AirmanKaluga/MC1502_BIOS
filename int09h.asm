;---------------------------------------------------------------------------------------------------
; Interrupt 09h - keyaboard IRQ1
;---------------------------------------------------------------------------------------------------
proc		int_09h
                sti				; Разрешить прерывания
                push	ax			; Сохранить AX
                push	bx			; Сохранить BX
                push	cx			; Сохранить CX
                push	dx			; Сохранить DX
                push	si			; Сохранить SI
                push	di			; Сохранить DI
                push	ds			; Сохранить DS
                push	es			; Сохранить ES
                cld				; Сбросить флаг направления
                mov	ax, BDAseg		; AX = сегмент BDA (40h)
                mov	ds, ax			; DS = сегмент BDA
                assume ds:nothing
                in	al, 60h			; Прочитать скан-код из порта 60h
                mov	ah, al			; Сохранить копию скан-кода в AH
                cmp	al, 0FFh		; Скан-код равен FFh (ошибка/переполнение)?
                jnz	short scan_code_ok	; Нет – нормальная обработка
                jmp	queue_full		; Да – звуковой сигнал и выход
; ---------------------------------------------------------------------------

scan_code_ok:
                and	al, 7Fh			; Сбросить бит отпускания (оставить код нажатия)
                push	cs			; CS в стек
                pop	es			; ES = CS для доступа к таблицам
                assume es:nothing
                mov	di, offset special_scancodes ; DI = начало таблицы спец.скан-кодов
                mov	cx, 8			; В таблице 8 элементов
                repne scasb			; Искать AL в таблице
                mov	al, ah			; Восстановить полный скан-код (с битом отпускания)
                jz	short handle_special_key ; Найден – обработать специальную клавишу
                jmp	regular_key_processing  ; Не найден – обработать как обычную
; ---------------------------------------------------------------------------

handle_special_key:
                sub	di, offset special_scancodes_end ; DI = индекс (0-7) в таблице масок
                mov	ah, cs:special_key_masks[di] ; AH = битовая маска клавиши
                test	al, 80h			; Проверить бит отпускания
                jnz	short special_key_release ; Установлен – клавиша отпущена
                cmp	ah, 10h			; Маска >= 10h (клавиша-переключатель)?
                jnb	short handle_toggle_key ; Да – обработка переключателя
                or	[ds:keybd_flags_1_], ah ; Нет – установить бит модификатора
                jmp	int09_exit		; Выйти из обработчика
; ---------------------------------------------------------------------------

handle_toggle_key:
                test	[byte ptr ds:keybd_flags_1_], 4 ; Клавиатура заблокирована?
                jnz	short regular_key_processing ; Да – игнорировать
                cmp	al, 52h			; Скан-код 52h = Insert?

check_insert:
                jnz	short set_toggle_flags	; Не Insert – обычный переключатель
                test	[byte ptr ds:keybd_flags_1_], 8 ; Insert уже активен?
                jz	short insert_not_active ; Нет – можно переключать
                jmp	short regular_key_processing ; Да – игнорировать
; ---------------------------------------------------------------------------

insert_not_active:
                test	[byte ptr ds:keybd_flags_1_], 20h ; Бит 5 (CapsLock/рус/лат)?
                jnz	short insert_with_shift_check ; Да – особая обработка
                test	[byte ptr ds:keybd_flags_1_], 3 ; Проверить нажатие Shift
                jz	short set_toggle_flags	; Shift не нажат – переключить Insert

insert_shift_pressed:
                mov	ax, 5230h		; Insert+Shift → код 5230h (ASCII 0, скан 30h?)
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

insert_with_shift_check:
                test	[byte ptr ds:keybd_flags_1_], 3 ; Проверить Shift ещё раз
                jz	short set_toggle_flags	; Shift не нажат – переключить Insert
                jmp	short insert_shift_pressed ; Shift нажат – код 5230h
; ---------------------------------------------------------------------------

set_toggle_flags:
                test	[ds:keybd_flags_2_], ah ; Флаг дребезга уже установлен?
                jnz	short int09_exit	; Да – игнорировать повтор
                or	[ds:keybd_flags_2_], ah ; Установить флаг обработки
                xor	[ds:keybd_flags_1_], ah ; Переключить состояние клавиши
                cmp	al, 52h			; Insert?
                jnz	short int09_exit	; Нет – выход
                mov	ax, 5200h		; Insert без Shift → код 5200h
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

special_key_release:
                cmp	ah, 10h			; Клавиша-переключатель?
                jnb	short release_toggle_key ; Да – сбросить флаг дребезга
                not	ah			; Инвертировать маску
                and	[ds:keybd_flags_1_], ah ; Сбросить бит модификатора
                cmp	al, 0B8h		; Код отпускания левого Alt (B8h)?
                jnz	short int09_exit	; Нет – выход
                mov	al, [ds:keybd_alt_num_] ; Прочитать счётчик Alt-цифр
                mov	ah, 0			; Обнулить AH
                mov	[ds:keybd_alt_num_], ah ; Сбросить счётчик
                cmp	al, 0			; Было набрано число?
                jz	short int09_exit	; Нет – выход
                jmp	caps_check		; Да – поместить символ в очередь
; ---------------------------------------------------------------------------

release_toggle_key:
                not	ah			; Инвертировать маску
                and	[ds:keybd_flags_2_], ah ; Сбросить флаг дребезга переключателя
                jmp	short int09_exit	; Выйти
; ---------------------------------------------------------------------------

regular_key_processing:
                cmp	al, 80h			; Код отпускания (≥80h)?
                jnb	short int09_exit	; Да – игнорировать отпускание
                test	[byte ptr ds:keybd_flags_2_], 8 ; Флаг Pause/Break?
                jz	short check_keyboard_lock ; Нет – проверить блокировку
                cmp	al, 45h			; Num Lock?
                jz	short int09_exit	; Да – игнорировать при Pause
                and	[byte ptr ds:keybd_flags_2_], 0F7h ; Сбросить флаг Pause

int09_exit:
                cli				; Запретить прерывания

int09_exit_without_sti:
                pop	es			; Восстановить ES
                assume es:nothing
                pop	ds			; Восстановить DS
                assume ds:nothing
                pop	di			; Восстановить DI
                pop	si			; Восстановить SI
                pop	dx			; Восстановить DX
                pop	cx			; Восстановить CX
                pop	bx			; Восстановить BX
                pop	ax			; Восстановить AX
                iret				; Возврат из прерывания

endp		int_09h
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------

check_keyboard_lock:
                test	[byte ptr ds:keybd_flags_1_], 8 ; Проверить бит блокировки клавиатуры
                jnz	short keyboard_locked	; Установлен – клавиатура заблокирована
                jmp	keyboard_unlocked	; Сброшен – клавиатура разблокирована
; ---------------------------------------------------------------------------

keyboard_locked:
                test	[byte ptr ds:keybd_flags_1_], 4 ; Scroll Lock активен?
                jz	short locked_space_check ; Нет – обычная блокировка
                cmp	al, 53h			; Скан-код 53h = Del?
                jnz	short locked_space_check ; Нет – не перезагрузка
                mov	[word ptr ds:warm_boot_flag_], 1234h ; Установить флаг теплой перезагрузки
                jmp	warm_boot		; Перезагрузить систему
; ---------------------------------------------------------------------------
alt_digit_table	db  52h	; R			; Таблица скан-кодов Alt-цифр (начинается с 52h)
alt_digit_offset db  4Fh	; O			; Смещение для вычисления цифры (используется в sub di,offset)
                db  50h	; P
                db  51h	; Q
                db  4Bh	; K
                db  4Ch	; L
                db  4Dh	; M
                db  47h	; G
                db  48h	; H
                db  49h	; I
                db  10h
                db  11h
                db  12h
                db  13h
                db  14h
                db  15h
                db  16h
                db  17h
                db  18h
                db  19h
                db  1Eh
                db  1Fh
                db  20h
                db  21h	; !
                db  22h	; "
                db  23h	; #
                db  24h	; $
                db  25h	; %
                db  26h	; &
                db  2Ch	; ,
                db  2Dh	; -
                db  2Eh	; .
                db  2Fh	; /
                db  30h	; 0
                db  31h	; 1
                db  32h	; 2
; ---------------------------------------------------------------------------
locked_space_check:
		cmp	al, 39h			; Скан-код 39h – пробел?
		jne	alt_digit_search	; Нет – искать Alt-цифры
                mov	al, 20h			; Да – ASCII-код пробела
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------
alt_digit_search:
                mov	di, offset alt_digit_table ; DI = начало таблицы Alt-цифр
                mov	cx, 0Ah			; Искать 10 цифр
                repne scasb			; Поиск скан-кода в таблице
                jnz	short alt_letter_search ; Не цифра – искать букву
                sub	di, offset alt_digit_offset ; DI = номер цифры (1-10?)
                mov	al, [ds:keybd_alt_num_] ; Текущее накопленное число
                mov	ah, 0Ah			; Умножить на 10
                mul	ah			; AX = AL * 10
                add	ax, di			; Добавить новую цифру
                mov	[ds:keybd_alt_num_], al ; Сохранить
                jmp	short int09_exit	; Выйти
; ---------------------------------------------------------------------------

alt_letter_search:
                mov	[byte ptr ds:keybd_alt_num_], 0 ; Сбросить счётчик Alt-цифр
                mov	cx, 1Ah			; Искать 26 букв
                repne scasb			; Поиск скан-кода в таблице
                jnz	short other_locked_keys ; Не буква – другие клавиши
                mov	al, 0			; Код Alt-буквы (0 – расширенный)
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

other_locked_keys:
                cmp	al, 2			; Скан-код меньше 2?
                jb	short func_keys_locked_skip ; Да – пропустить
                cmp	al, 0Eh			; Скан-код меньше 0Eh?
                jnb	short func_keys_locked_skip ; Нет – пропустить
                add	ah, 76h			; Преобразовать в расширенный код
                mov	al, 0			; AL = 0 (расширенный)
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

func_keys_locked_skip:
                cmp	al, 3Bh			; Скан-код >= 3Bh (F1)?
                jnb	short func_keys_locked_ext ; Да – расширенные функциональные

func_keys_locked_ignore:
                jmp	int09_exit		; Игнорировать
; ---------------------------------------------------------------------------

func_keys_locked_ext:
                cmp	al, 47h			; Скан-код >= 47h (цифровая клавиатура)?
                jnb	short func_keys_locked_ignore ; Да – игнорировать
                mov	bx, offset func_table_locked ; BX = таблица функц. клавиш при блокировке
                jmp	extended_key_convert	; Преобразовать и поместить в очередь
; ---------------------------------------------------------------------------

keyboard_unlocked:
                test	[byte ptr ds:keybd_flags_1_], 4 ; Scroll Lock активен?
                jz	short unlocked_normal	; Нет – обычный режим
                cmp	al, 46h			; Скан-код 46h = Break (Ctrl+Scroll Lock)?
                jnz	short not_break		; Нет – не Break
                mov	bx, 1Eh			; Начало буфера клавиатуры (40:1Eh)
                mov	[ds:keybd_q_head_], bx	; Сбросить голову очереди
                mov	[ds:keybd_q_tail_], bx	; Сбросить хвост очереди
                mov	[byte ptr ds:keybd_break_], 80h ; Установить флаг Break
                int	1Bh			; Вызвать пользовательский обработчик Break
                mov	ax, 0			; Пустой код
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

not_break:
                cmp	al, 45h			; Num Lock?
                jnz	short not_numlock	; Нет
                or	[byte ptr ds:keybd_flags_2_], 8 ; Установить флаг Pause
                mov	al, 20h			; EOI – конец прерывания
                out	20h, al			; Послать контроллеру прерываний
                cmp	[byte ptr ds:video_mode_], 7 ; Монохромный режим?
                jz	short wait_pause_release ; Да – пропустить восстановление видео
                mov	dx, 3D8h		; Порт управления CGA
                mov	al, [ds:video_mode_reg_] ; Текущий регистр видеорежима
                out	dx, al			; Восстановить (убрать мерцание)

wait_pause_release:
                test	[byte ptr ds:keybd_flags_2_], 8 ; Pause ещё нажат?
                jnz	short wait_pause_release ; Да – ждём отпускания
                jmp	int09_exit_without_sti	; Выход без CLI
; ---------------------------------------------------------------------------

not_numlock:
                cmp	al, 37h			; Print Screen?
                jnz	short not_printscreen	; Нет
                mov	ax, 7200h		; Расширенный код Print Screen
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

not_printscreen:
                mov	bx, offset scroll_off_table ; BX = таблица при Scroll Lock выкл
                cmp	al, 3Bh			; Функциональные клавиши?
                jnb	short scroll_func_keys	; Да – отдельная таблица
                jmp	short convert_with_table ; Нет – преобразовать по таблице
; ---------------------------------------------------------------------------

scroll_func_keys:
                mov	bx, offset scroll_func_table ; BX = таблица функц. клавиш при Scroll Lock
                jmp	extended_key_convert	; Преобразовать в расширенный код
; ---------------------------------------------------------------------------

unlocked_normal:
                cmp	al, 47h			; Скан-код >= 47h (цифровая клавиатура)?
                jnb	short numeric_keypad	; Да – обработка цифровой клавиатуры
                test	[byte ptr ds:keybd_flags_1_], 3 ; Shift нажат?
                jz	short no_shift_normal	; Нет – без Shift
                cmp	al, 0Fh			; Tab?
                jnz	short not_tab_shift	; Нет – может быть Print Screen?
                mov	ax, 0F00h		; Расширенный код Tab (Shift+Tab)
                jmp	short enqueue_check	; Поместить в очередь
; ---------------------------------------------------------------------------

not_tab_shift:
                cmp	al, 37h			; Print Screen?
                jnz	short not_ps_shift	; Нет
                mov	al, 20h			; EOI
                out	20h, al			; Послать контроллеру прерываний
                int	5			; Вызвать обработчик Print Screen (int 5)
                jmp	int09_exit_without_sti	; Выход без CLI
; ---------------------------------------------------------------------------

not_ps_shift:
                cmp	al, 3Bh			; Функциональные клавиши (F1-F10)?
                jb	short shift_function_key ; Да – с Shift
                mov	bx, offset shift_func_table ; BX = таблица Shift+функц. клавиши
                jmp	extended_key_convert	; Преобразовать в расширенный код
; ---------------------------------------------------------------------------

shift_function_key:
                mov	bx, offset shift_regular_table ; BX = таблица обычных клавиш с Shift
                jmp	short convert_with_table ; Преобразовать в ASCII
; ---------------------------------------------------------------------------

numeric_keypad:
                test	[byte ptr ds:keybd_flags_1_], 20h ; Num Lock?
                jnz	short shift_on_numlock_off ; Да – перейти к проверке NumLock
                test	[byte ptr ds:keybd_flags_1_], 3 ; Shift?
                jnz	short shift_on_numlock_off_sub ; Да – временная инверсия (цифры)
; ---------------------------------------------------------------------------
numlock_off_no_shift:
                cmp	al, 4Ah			; Minus на цифровой клавиатуре?
                jz	short keypad_minus	; Да – обработать '-'
                cmp	al, 4Eh			; Plus?
                jz	short keypad_plus	; Да – обработать '+'
                sub	al, 47h			; Индекс клавиши (0-11)
                mov	bx, offset numlock_off_table ; Таблица скан-кодов курсора
                jmp	extended_key_convert_common ; Преобразовать в расширенный код
; ---------------------------------------------------------------------------

keypad_minus:
                mov	ax, 4A2Dh		; AL = 2Dh ('-'), AH = 4Ah
                jmp	short enqueue_check	; Поместить в очередь
; ---------------------------------------------------------------------------

keypad_plus:
                mov	ax, 4E2Bh		; AL = 2Bh ('+'), AH = 4Eh
                jmp	short enqueue_check	; Поместить в очередь
; ---------------------------------------------------------------------------

shift_on_numlock_off:
                test	[byte ptr ds:keybd_flags_1_], 3 ; Shift?
                jnz	short numlock_off_no_shift ; Да – курсорные клавиши (ориг. loc_FEB91)
; ---------------------------------------------------------------------------
shift_on_numlock_off_sub:
                sub	al, 46h			; Индекс для цифр (46h, а не 47h!)
                mov	bx, offset numlock_on_shift_table ; Таблица ASCII цифр
                jmp	short convert_with_table ; Преобразовать в ASCII
; ---------------------------------------------------------------------------

no_shift_normal:
                cmp	al, 3Bh			; Функциональные клавиши без Shift?
                jb	short regular_key_no_shift ; Нет – обычная клавиша
                mov	al, 0			; Да – игнорировать (код 0)
                jmp	short enqueue_check	; Поместить в очередь (пустой код)
; ---------------------------------------------------------------------------

regular_key_no_shift:
                mov	bx, offset regular_table ; BX = таблица обычных клавиш без Shift

convert_with_table:
                dec	al			; Индекс = скан-код - 1
                xlat	[byte ptr cs:bx]	; Преобразовать через таблицу

enqueue_check:
                cmp	al, 0FFh		; Код FFh (игнорировать)?
                jz	short ignore_key	; Да – пропустить
                cmp	ah, 0FFh		; Расширенный код FFh?
                jz	short ignore_key	; Да – пропустить

caps_check:
                test	[byte ptr ds:keybd_flags_1_], 40h ; Caps Lock?
                jz	short put_in_queue	; Нет – сразу в очередь
                test	[byte ptr ds:keybd_flags_1_], 3 ; Shift нажат?
                jz	short caps_uppercase	; Нет – инвертировать регистр
                cmp	al, 41h			; Код меньше 'A'?
                jb	short put_in_queue	; Да – не буква
                cmp	al, 5Ah			; Код больше 'Z'?
                ja	short put_in_queue	; Да – не буква
                add	al, 20h			; Преобразовать в нижний регистр
                jmp	short put_in_queue	; Поместить в очередь
; ---------------------------------------------------------------------------

ignore_key:
                jmp	int09_exit		; Игнорировать код, выйти
; ---------------------------------------------------------------------------

caps_uppercase:
                cmp	al, 61h			; Код меньше 'a'?
                jb	short put_in_queue	; Да – не буква
                cmp	al, 7Ah			; Код больше 'z'?
                ja	short put_in_queue	; Да – не буква
                sub	al, 20h			; Преобразовать в верхний регистр

put_in_queue:
                mov	bx, [ds:keybd_q_tail_] ; Текущий хвост очереди
                mov	si, bx			; SI = указатель на свободную ячейку
                call	update_queue_pointer	; Обновить указатель (циклически +2)
                cmp	bx, [ds:keybd_q_head_] ; Очередь полна (хвост догнал голову)?
                jz	short queue_full	; Да – потеря символа, звуковой сигнал
                mov	[si], ax		; Поместить слово в буфер
                mov	[ds:keybd_q_tail_], bx ; Обновить хвост
                jmp	int09_exit		; Выйти
; ---------------------------------------------------------------------------

queue_full:
                call	keyboard_beep		; Звуковой сигнал (переполнение)
                jmp	int09_exit		; Выйти
; ---------------------------------------------------------------------------

extended_key_convert:
                sub	al, 3Bh			; Преобразовать индекс для функц. клавиш (3Bh = F1)

extended_key_convert_common:
                xlat	[byte ptr cs:bx]	; Получить скан-код из таблицы
                mov	ah, al			; AH = скан-код
                mov	al, 0			; AL = 0 (расширенный ASCII)
                jmp	enqueue_check		; Поместить в очередь
; ---------------------------------------------------------------------------

keyboard_beep:
                push	ax			; Сохранить AX
                push	bx			; Сохранить BX
                push	cx			; Сохранить CX
                mov	bx, 0C0h		; Счётчик длительности сигнала
                in	al, 61h			; Прочитать порт B PPI (динамик)
                push	ax			; Сохранить исходное состояние

beep_loop:
                and	al, 0FCh		; Сбросить биты 0 и 1 (выкл. динамик)
                out	61h, al			; Записать в порт
                mov	cx, 48h			; Задержка

beep_delay_off:
                loop	beep_delay_off		; Цикл задержки
                or	al, 2			; Установить бит 1 (вкл. динамик)
                out	61h, al			; Записать в порт
                mov	cx, 48h			; Задержка

beep_delay_on:
                loop	beep_delay_on		; Цикл задержки
                dec	bx			; Уменьшить счётчик
                jnz	short beep_loop		; Повторить BX раз
                pop	ax			; Восстановить исходное состояние
                out	61h, al			; Записать в порт
                pop	cx			; Восстановить CX
                pop	bx			; Восстановить BX
                pop	ax			; Восстановить AX
                retn				; Возврат из подпрограммы
;-------------------------------------------------------------------------------------------