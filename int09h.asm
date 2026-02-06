;---------------------------------------------------------------------------------------------------
; Обработчик прерывания 09h - клавиатура (IRQ1)
;---------------------------------------------------------------------------------------------------
proc		int_09h	near
                sti					; Разрешаем прерывания
                push	ax				; Сохраняем регистры
                push	bx
                push	cx
                push	dx
                push	si
                push	di
                push	ds
                push	es
                cld					; Направление строковых операций - вперед
                
                ; Устанавливаем сегмент данных BDA (область данных BIOS)
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                
                ; Читаем скан-код из контроллера клавиатуры (порт 60h)
                in	al, 60h		; 8042 - контроллер клавиатуры, регистр данных
                mov	ah, al		; Сохраняем скан-код в AH
                
                ; Проверяем на сбой клавиатуры (код FFh)
                cmp	al, 0FFh
                jnz	short normal_key	; Если не FFh - нормальная клавиша
                jmp	keyboard_error		; Обработка ошибки клавиатуры
                
; ---------------------------------------------------------------------------
; Обработка нормальной клавиши
; ---------------------------------------------------------------------------
normal_key:				; ...
                ; Маскируем бит отпускания (7-й бит) для поиска в таблице
                and	al, 7Fh
                
                ; Устанавливаем ES на сегмент кода для доступа к таблицам
                push	cs
                pop	es
                assume es:nothing
                
                ; Ищем скан-код в таблице специальных клавиш
                mov	di, offset special_keys_table
                mov	cx, 8
                repne scasb		; Ищем AL в таблице
                mov	al, ah		; Восстанавливаем полный скан-код
                jz	short is_special_key	; Нашли в таблице специальных клавиш
                jmp	process_normal_key	; Не нашли - обычная клавиша
                
; ---------------------------------------------------------------------------
; Обработка специальной клавиши (управляющие клавиши)
; ---------------------------------------------------------------------------
is_special_key:				; ...
                ; Вычисляем индекс в таблице флагов специальных клавиш
                sub	di, offset special_keys_table + 1
                mov	ah, cs:special_key_flags[di]
                
                ; Проверяем, отпускание или нажатие клавиши (бит 7)
                test	al, 80h
                jnz	short key_released	; Клавиша отпущена
                
                ; Клавиша нажата - обработка в зависимости от типа
                cmp	ah, 10h			; Проверяем тип клавиши
                jnb	short toggle_key	; Если >= 10h - переключаемая клавиша
                
                ; Обычная управляющая клавиша (Shift, Ctrl, Alt)
                or	[ds:keybd_flags_1_], ah	; Устанавливаем соответствующий флаг
                jmp	process_key_complete	; Завершаем обработку
                
; ---------------------------------------------------------------------------
; Обработка переключаемых клавиш (Caps Lock, Num Lock, Scroll Lock)
; ---------------------------------------------------------------------------
toggle_key:				; ...
                ; Проверяем, не нажат ли Ctrl (флаг 04h)
                test	[byte ptr ds:keybd_flags_1_], 4
                jnz	short process_normal_key	; Если Ctrl нажат, обрабатываем как обычную
                
                ; Проверяем, не клавиша ли Insert (скан-код 52h)
                cmp	al, 52h
                jnz	short check_toggle_state
                
                ; Проверяем, не нажат ли Alt (флаг 08h)
                test	[byte ptr ds:keybd_flags_1_], 8
                jz	short check_toggle_state	; Alt не нажат
                jmp	process_normal_key		; Alt нажат - обычная обработка
                
; ---------------------------------------------------------------------------
check_toggle_state:				; ...
                ; Проверяем, не нажат ли Caps Lock (флаг 20h)
                test	[byte ptr ds:keybd_flags_1_], 20h
                jnz	short check_shift_for_toggle
                
                ; Проверяем, нажат ли Shift (любой из двух)
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short toggle_key_action
                
; Обработка комбинации Shift + переключаемая клавиша
shift_with_toggle:				; ...
                mov	ax, 5230h		; Код для Shift + Insert
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_shift_for_toggle:				; ...
                ; Caps Lock нажат, проверяем Shift
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short shift_with_toggle	; Shift не нажат
                
; ---------------------------------------------------------------------------
toggle_key_action:				; ...
                ; Проверяем, не установлен ли уже флаг переключаемой клавиши
                test	[ds:keybd_flags_2_], ah
                jnz	short process_key_complete	; Уже установлен
                
                ; Переключаем состояние клавиши
                or	[ds:keybd_flags_2_], ah	; Устанавливаем флаг
                xor	[ds:keybd_flags_1_], ah	; Инвертируем флаг в основном байте
                
                ; Для клавиши Insert отправляем специальный код
                cmp	al, 52h
                jnz	short process_key_complete
                mov	ax, 5200h		; Код для Insert
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
; Обработка отпускания клавиши
; ---------------------------------------------------------------------------
key_released:				; ...
                cmp	ah, 10h			; Проверяем тип клавиши
                jnb	short toggle_key_released
                
                ; Обычная управляющая клавиша отпущена
                not	ah			; Инвертируем маску
                and	[ds:keybd_flags_1_], ah	; Сбрасываем флаг
                
                ; Проверяем, не клавиша ли Alt
                cmp	al, 0B8h		; Скан-код отпускания левого Alt
                jnz	short process_key_complete
                
                ; Обработка альтернативного числового ввода (Alt-цифры)
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0
                mov	[ds:keybd_alt_num_], ah	; Сбрасываем сохраненное число
                cmp	al, 0			; Проверяем, было ли что-то сохранено
                jz	short process_key_complete
                jmp	put_to_buffer		; Помещаем символ в буфер
                
; ---------------------------------------------------------------------------
toggle_key_released:				; ...
                ; Переключаемая клавиша отпущена
                not	ah
                and	[ds:keybd_flags_2_], ah	; Сбрасываем флаг в байте 2
                jmp	short process_key_complete
                
; ---------------------------------------------------------------------------
; Обработка обычной клавиши (не специальной)
; ---------------------------------------------------------------------------
process_normal_key:				; ...
                ; Проверяем, не отпускание ли это (бит 7 установлен)
                cmp	al, 80h
                jnb	short process_key_complete	; Отпускание - игнорируем
                
                ; Проверяем, не установлен ли флаг "удержание" (флаг 08h в байте 2)
                test	[byte ptr ds:keybd_flags_2_], 8
                jz	short check_alt		; Флаг не установлен
                
                ; Проверяем, не клавиша ли NumLock (скан-код 45h)
                cmp	al, 45h
                jz	short process_key_complete	; NumLock - пропускаем
                
                ; Сбрасываем флаг удержания
                and	[byte ptr ds:keybd_flags_2_], 0F7h
                
; ---------------------------------------------------------------------------
process_key_complete:				; ...
                cli				; Запрещаем прерывания перед выходом

; Восстановление регистров и возврат из прерывания
restore_and_exit:				; ...
                pop	es
                assume es:nothing
                pop	ds
                assume ds:nothing
                pop	di
                pop	si
                pop	dx
                pop	cx
                pop	bx
                pop	ax
                iret

endp		int_09h
; ---------------------------------------------------------------------------
; Проверка состояния клавиши Alt
; ---------------------------------------------------------------------------
check_alt:				; ...
                test	[byte ptr ds:keybd_flags_1_], 8	; Проверяем Alt
                jnz	short alt_pressed		; Alt нажат
                jmp	no_alt_pressed			; Alt не нажат
                
; ---------------------------------------------------------------------------
; Обработка при нажатом Alt
; ---------------------------------------------------------------------------
alt_pressed:				; ...
                ; Проверяем, не нажат ли Ctrl
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short other_ctrl_alt_combo
                
                ; Ctrl+Alt нажаты - проверяем дополнительные комбинации
                cmp	al, 53h		; Скан-код клавиши Del
                jnz	short other_ctrl_alt_combo
                
                ; Ctrl+Alt+Del - теплый перезапуск
                mov	[word ptr ds:warm_boot_flag_], 1234h
                jmp	warm_boot	; Переход к перезагрузке
                
; ---------------------------------------------------------------------------
; Таблица скан-кодов для альтернативного числового ввода (Alt+цифры)
; ---------------------------------------------------------------------------
alt_numpad_table	db  52h	; R - Insert?		; ...
			db  4Fh	; O
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
other_ctrl_alt_combo:
		cmp	al,39h   ; '9' - проверка на цифру 9
		jne	check_alt_numpad ; Если не 9, проверяем другие цифры
                mov	al, 20h	; Пробел для Ctrl+Alt+9?
                jmp	put_to_buffer
; ---------------------------------------------------------------------------
check_alt_numpad:
                ; Ищем скан-код в таблице цифрового блока при Alt
                mov	di, offset alt_numpad_table
                mov	cx, 0Ah		; Длина таблицы - 10 элементов
                repne scasb		; Ищем скан-код
                jnz	short check_alt_function_keys	; Не нашли
                
                ; Нашли - обрабатываем Alt+цифра (накопление кода)
                sub	di, offset alt_numpad_table + 1
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0Ah		; Умножаем на 10 (десятичная система)
                mul	ah
                add	ax, di		; Добавляем новую цифру
                mov	[ds:keybd_alt_num_], al	; Сохраняем накопленное значение
                jmp	short process_key_complete
                
; ---------------------------------------------------------------------------
check_alt_function_keys:				; ...
                ; Сбрасываем накопленное значение Alt-цифр
                mov	[byte ptr ds:keybd_alt_num_], 0
                
                ; Проверяем функциональные клавиши при Alt
                mov	cx, 1Ah		; Длина таблицы функциональных клавиш
                repne scasb		; Ищем скан-код
                jnz	short check_extended_codes
                
                ; Нашли функциональную клавишу с Alt
                mov	al, 0		; Базовый код для Alt+F1..F10
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_extended_codes:				; ...
                ; Проверяем расширенные коды
                cmp	al, 2		; Нижняя граница
                jb	short check_function_keys_range
                cmp	al, 0Eh		; Верхняя граница
                jnb	short check_function_keys_range
                
                ; Расширенный код найден
                add	ah, 76h		; Смещение для расширенных кодов
                mov	al, 0
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_function_keys_range:				; ...
                ; Проверяем диапазон функциональных клавиш F1..F10
                cmp	al, 3Bh		; F1
                jnb	short check_is_function_key

skip_key:				; ...
                jmp	process_key_complete	; Пропускаем эту клавишу
                
; ---------------------------------------------------------------------------
check_is_function_key:				; ...
                cmp	al, 47h		; Проверяем верхнюю границу
                jnb	short skip_key	; Если >= 47h, это не F1..F10
                
                ; Это функциональная клавиша F1..F10
                mov	bx, offset alt_function_keys_table
                jmp	convert_and_store
                
; ---------------------------------------------------------------------------
; Обработка при ненажатом Alt
; ---------------------------------------------------------------------------
no_alt_pressed:				; ...
                ; Проверяем, нажат ли Ctrl
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short check_ctrl_combinations
                
                ; Ctrl нажат
                cmp	al, 46h		; Скан-код Scroll Lock
                jnz	short check_ctrl_scroll
                
                ; Ctrl+Scroll Lock = Break
                mov	bx, 1Eh		; Сбрасываем указатели буфера клавиатуры
                mov	[ds:keybd_q_head_], bx
                mov	[ds:keybd_q_tail_], bx
                mov	[byte ptr ds:keybd_break_], 80h	; Устанавливаем флаг Break
                int	1Bh		; Вызываем обработчик Ctrl-Break
                mov	ax, 0		; Пустой код
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_ctrl_scroll:				; ...
                ; Проверяем Ctrl+NumLock (приостановка)
                cmp	al, 45h		; NumLock
                jnz	short check_ctrl_print
                
                ; Ctrl+NumLock - приостановка системы
                or	[byte ptr ds:keybd_flags_2_], 8	; Устанавливаем флаг паузы
                mov	al, 20h
                out	20h, al		; Посылаем EOI контроллеру прерываний
                
                ; Проверяем видео режим (возможно, для отключения видео)
                cmp	[byte ptr ds:video_mode_], 7
                jz	short pause_loop
                
                ; Для цветного видео - дополнительные действия
                mov	dx, 3D8h	; Порт управления видеоадаптером CGA
                mov	al, [ds:video_mode_reg_]
                out	dx, al
                
pause_loop:				; ...
                ; Цикл ожидания снятия паузы
                test	[byte ptr ds:keybd_flags_2_], 8
                jnz	short pause_loop
                jmp	restore_and_exit
                
; ---------------------------------------------------------------------------
check_ctrl_print:				; ...
                ; Проверяем Ctrl+PrtSc (печать экрана)
                cmp	al, 37h		; PrtSc
                jnz	short check_ctrl_other
                
                ; Ctrl+PrtSc
                mov	ax, 7200h	; Специальный код
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_ctrl_other:				; ...
                ; Проверяем другие комбинации с Ctrl
                mov	bx, offset ctrl_keys_table
                cmp	al, 3Bh		; F1
                jnb	short check_ctrl_function_keys
                jmp	convert_scan_code
                
; ---------------------------------------------------------------------------
check_ctrl_function_keys:				; ...
                ; Ctrl+функциональные клавиши
                mov	bx, offset ctrl_function_keys_table
                jmp	convert_and_store
                
; ---------------------------------------------------------------------------
check_ctrl_combinations:				; ...
                ; Проверяем обычные клавиши с Ctrl
                cmp	al, 47h		; Проверяем Home (начало цифрового блока)
                jnb	short numeric_keypad
                
                ; Проверяем, нажат ли Shift
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short check_normal_function_keys
                
                ; Shift нажат
                cmp	al, 0Fh		; Tab
                jnz	short check_shift_tab
                
                ; Shift+Tab
                mov	ax, 0F00h
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
check_shift_tab:				; ...
                cmp	al, 37h		; PrtSc
                jnz	short check_shift_function_keys
                
                ; Shift+PrtSc - вызов обработчика печати экрана
                mov	al, 20h
                out	20h, al		; EOI
                int	5		; Вызов обработчика печати экрана
                jmp	restore_and_exit
                
; ---------------------------------------------------------------------------
check_shift_function_keys:				; ...
                cmp	al, 3Bh		; F1
                jb	short shift_normal_key
                
                ; Shift+функциональные клавиши
                mov	bx, offset shift_function_keys_table
                jmp	convert_and_store
                
; ---------------------------------------------------------------------------
shift_normal_key:				; ...
                ; Обычные клавиши с Shift
                mov	bx, offset shift_keys_table
                jmp	short convert_scan_code
                
; ---------------------------------------------------------------------------
numeric_keypad:				; ...
                ; Обработка цифрового блока клавиатуры
                test	[byte ptr ds:keybd_flags_1_], 20h	; Caps Lock
                jnz	short caps_lock_numeric
                
                ; Проверяем Shift для цифрового блока
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short shift_numeric
                
; Обработка цифрового блока без Shift
normal_numeric:				; ...
                cmp	al, 4Ah		; Минус на цифровом блоке
                jz	short numpad_minus
                cmp	al, 4Eh		; Плюс на цифровом блоке
                jz	short numpad_plus
                
                ; Обычные цифры на цифровом блоке
                sub	al, 47h		; Преобразуем скан-код в индекс (0-9)
                mov	bx, offset numpad_normal_table
                jmp	convert_and_store
                
numpad_minus:				; ...
                mov	ax, 4A2Dh	; Код для минуса
                jmp	short put_to_buffer
                
numpad_plus:				; ...
                mov	ax, 4E2Bh	; Код для плюса
                jmp	short put_to_buffer
                
; ---------------------------------------------------------------------------
caps_lock_numeric:				; ...
                ; Caps Lock включен - проверяем Shift
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short normal_numeric	; Shift нажат - как обычно
                
; ---------------------------------------------------------------------------
shift_numeric:				; ...
                ; Shift нажат на цифровом блоке
                sub	al, 46h		; Преобразуем скан-код
                mov	bx, offset numpad_shift_table
                jmp	short convert_scan_code
                
; ---------------------------------------------------------------------------
check_normal_function_keys:				; ...
                ; Обычные клавиши без управляющих
                cmp	al, 3Bh		; F1
                jb	short normal_key_processing
                
                ; Функциональные клавиши без модификаторов
                mov	al, 0		; Базовый код для F1..F10
                jmp	short put_to_buffer
                
; ---------------------------------------------------------------------------
normal_key_processing:				; ...
                ; Обычные алфавитно-цифровые клавиши
                mov	bx, offset normal_keys_table
                
; ---------------------------------------------------------------------------
convert_scan_code:				; ...
                ; Преобразование скан-кода в ASCII
                dec	al		; Индексы в таблице начинаются с 0
                xlat	[byte ptr cs:bx]	; Преобразуем через таблицу
                
; ---------------------------------------------------------------------------
put_to_buffer:				; ...
                ; Проверяем, не пустой ли код (FFh)
                cmp	al, 0FFh
                jz	skip_key	; Пустой код - пропускаем
                cmp	ah, 0FFh
                jz	skip_key
                
; ---------------------------------------------------------------------------
store_char:				; ...
                ; Проверяем состояние Caps Lock
                test	[byte ptr ds:keybd_flags_1_], 40h	; Caps Lock
                jz	short check_shift_for_case
                
                ; Caps Lock включен - проверяем Shift для определения регистра
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short caps_lock_no_shift
                
                ; Caps Lock + Shift = строчные буквы
                cmp	al, 41h		; 'A'
                jb	short add_to_buffer
                cmp	al, 5Ah		; 'Z'
                ja	short add_to_buffer
                add	al, 20h		; Преобразуем в строчные
                jmp	short add_to_buffer
                
; ---------------------------------------------------------------------------
caps_lock_no_shift:				; ...
                ; Только Caps Lock (без Shift)
                cmp	al, 61h		; 'a'
                jb	short add_to_buffer
                cmp	al, 7Ah		; 'z'
                ja	short add_to_buffer
                sub	al, 20h		; Преобразуем в заглавные
                jmp	short add_to_buffer
                
; ---------------------------------------------------------------------------
check_shift_for_case:				; ...
                ; Caps Lock выключен - проверяем Shift
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short add_to_buffer	; Shift не нажат - оставляем как есть
                
                ; Shift нажат - меняем регистр
                cmp	al, 61h		; 'a'
                jb	short add_to_buffer
                cmp	al, 7Ah		; 'z'
                ja	short add_to_buffer
                sub	al, 20h		; Преобразуем в заглавные
                
; ---------------------------------------------------------------------------
add_to_buffer:				; ...
                ; Помещаем символ в буфер клавиатуры
                mov	bx, [ds:keybd_q_tail_]	; Получаем указатель хвоста
                mov	si, bx
                call	advance_buffer_pointer	; Переходим к следующей позиции
                
                ; Проверяем, не переполнен ли буфер
                cmp	bx, [ds:keybd_q_head_]
                jz	short buffer_full	; Буфер полон
                
                ; Сохраняем символ в буфер
                mov	[si], ax
                mov	[ds:keybd_q_tail_], bx	; Обновляем указатель хвоста
                jmp	process_key_complete
                
; ---------------------------------------------------------------------------
buffer_full:				; ...
                ; Буфер клавиатуры переполнен - звуковой сигнал
                call	sound_beep
                jmp	process_key_complete
                
; ---------------------------------------------------------------------------
convert_and_store:				; ...
                ; Преобразование функциональных клавиш
                sub	al, 3Bh		; Начинаем с F1
                
convert_from_table:				; ...
                xlat	[byte ptr cs:bx]	; Преобразуем через таблицу
                mov	ah, al		; Сохраняем в AH (скан-код)
                mov	al, 0		; AL=0 для функциональных клавиш
                jmp	put_to_buffer
                
; ---------------------------------------------------------------------------
; Процедура звукового сигнала (пищалка) при переполнении буфера
; ---------------------------------------------------------------------------
sound_beep:				; ...
                push	ax
                push	bx
                push	cx
                mov	bx, 0C0h	; Длительность звука
                
                ; Читаем текущее состояние порта B
                in	al, 61h		; Порт B контроллера 8255
                push	ax		; Сохраняем
                
beep_loop:				; ...
                ; Выключаем динамик (сбрасываем биты 0 и 1)
                and	al, 0FCh
                out	61h, al
                
                ; Пауза
                mov	cx, 48h
delay_off:				; ...
                loop	delay_off
                
                ; Включаем динамик (устанавливаем бит 1)
                or	al, 2
                out	61h, al
                
                ; Пауза
                mov	cx, 48h
delay_on:				; ...
                loop	delay_on
                
                ; Уменьшаем счетчик и повторяем
                dec	bx
                jnz	short beep_loop
                
                ; Восстанавливаем исходное состояние порта
                pop	ax
                out	61h, al
                
                pop	cx
                pop	bx
                pop	ax
                retn
                
; ---------------------------------------------------------------------------
; Процедура продвижения указателя буфера клавиатуры
; ---------------------------------------------------------------------------
advance_buffer_pointer:				; ...
                ; BX - текущий указатель, на выходе - новый указатель в BX
                ; SI остается исходным указателем
                add	bx, 2		; Каждый элемент - слово
                cmp	bx, offset keybd_buffer_end
                jb	short pointer_ok
                mov	bx, offset keybd_buffer_	; Циклический буфер
pointer_ok:
                retn

; ---------------------------------------------------------------------------
; Обработка ошибки клавиатуры
; ---------------------------------------------------------------------------
keyboard_error:				; ...
                ; Сбрасываем контроллер клавиатуры
                mov	al, 20h
                out	20h, al		; Посылаем EOI
                jmp	process_key_complete

;-------------------------------------------------------------------------------------------