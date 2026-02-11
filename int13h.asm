;---------------------------------------------------------------------------------------------------
; Interrupt 13h - Floppydisk
;---------------------------------------------------------------------------------------------------
proc		int_13h	near
                cld				; Сбросить флаг направления
                sti				; Разрешить прерывания
                push	bx			; Сохранить BX
                push	cx			; Сохранить CX
                push	dx			; Сохранить DX
                push	si			; Сохранить SI
                push	di			; Сохранить DI
                push	ds			; Сохранить DS
                push	es			; Сохранить ES
                mov	si, BDAseg		; SI = сегмент BDA (40h)
                mov	ds, si			; DS = сегмент BDA
                assume ds:nothing
                call	floppy_command_processor ; Вызвать основной обработчик команд диска
                mov	ah, [cs:MotorOff]	; Время выключения мотора
                mov	[ds:dsk_motor_tmr], ah	; Установить таймер мотора
                mov	ah, [ds:dsk_ret_code_]	; Получить код возврата
                cmp	ah, 1			; Сравнить с 1 (успешно?)
                cmc				; Дополнить флаг переноса (инверсия)
                pop	es			; Восстановить ES
                pop	ds			; Восстановить DS
                assume ds:nothing
                pop	di			; Восстановить DI
                pop	si			; Восстановить SI
                pop	dx			; Восстановить DX
                pop	cx			; Восстановить CX
                pop	bx			; Восстановить BX
                retf	2			; Возврат из прерывания, очистка флагов
endp		int_13h




proc		floppy_command_processor near ; Обработчик команд диска (вызывается из int_13h)
                push	dx			; Сохранить DX
                call	dispatch_ah_command	; Диспетчеризация по значению AH
                pop	dx			; Восстановить DX
                mov	bx, dx			; BX = номер дисковода
                and	bx, 1			; Только младший бит (дисковод 0/1)
                mov	ah, [ds:dsk_ret_code_]	; Получить код возврата
                cmp	ah, 40h			; 40h = ошибка?
                jz	short toggle_media_flag	; Да – переключить флаг носителя
                cmp	ax, 400h		; Проверка на команду 04h (верификация)?
                jnz	short command_done	; Нет – выход
                call	verify_diskette_status	; Проверка статуса диска
                jz	short toggle_media_flag	; ZF=1 – успешно, переключить флаг
                mov	al, [bx+90h]		; Получить байт состояния привода
                mov	ah, 0			; AH = 0
                test	al, 0C0h		; Проверить биты 6-7
                jnz	short update_drive_status ; Установлены – обновить статус
                mov	ah, 80h			; Нет – установить бит 7

update_drive_status:
                and	al, 3Fh			; Сбросить биты 6-7
                or	al, ah			; Установить новые биты
                mov	[bx+90h], al		; Сохранить статус
                mov	al, 0			; AL = 0 (успешно)
                jmp	short command_done	; Выход
; ---------------------------------------------------------------------------

toggle_media_flag:
                xor	[byte ptr bx+90h], 20h	; Инвертировать бит 5 (флаг смены носителя)
                mov	al, 0			; AL = 0

command_done:
                retn				; Возврат
endp		floppy_command_processor





proc		dispatch_ah_command near	; Диспетчер команд дисковода (по AH)

                and	[byte ptr ds:dsk_motor_stat], 7Fh ; Сбросить бит 7 (флаг записи)
                or	ah, ah			; AH = 0?
                jz	short reset_disk_system	; Да – сброс дисковода
                dec	ah			; AH = 1?
                jz	short get_last_status	; Да – получить статус
                mov	[byte ptr ds:dsk_ret_code_], 0 ; Сбросить код ошибки
                cmp	dl, 1			; Проверить номер дисковода
                ja	short invalid_command	; Номер > 1 – неверная команда
                dec	ah			; AH = 2?
                jz	short read_sectors	; Да – чтение секторов
                dec	ah			; AH = 3?
                jz	short write_setup	; Да – запись секторов
                dec	ah			; AH = 4?
                jz	short verify_setup	; Да – верификация
                dec	ah			; AH = 5?
                jnz	short check_extended_cmds ; Нет – проверить расширенные
                jmp	format_track		; Да – форматирование дорожки
; ---------------------------------------------------------------------------

check_extended_cmds:
                sub	ah, 12h			; AH = 15h?
                jnz	short check_drive_type_cmd ; Нет
                jmp	get_drive_type		; Да – получить тип привода
; ---------------------------------------------------------------------------

check_drive_type_cmd:
                dec	ah			; AH = 16h?
                jnz	short invalid_command	; Нет – неверная команда
                jmp	set_diskette_change_status ; Да – установить статус смены дискеты
; ---------------------------------------------------------------------------

invalid_command:
                mov	[byte ptr ds:dsk_ret_code_], 1 ; Код ошибки 1 (неверная команда)
                retn				; Возврат
; ---------------------------------------------------------------------------

reset_disk_system:
                mov	al, 0			; AL = 0
                mov	[ds:3Eh], al		; Сбросить таймер мотора
                mov	[ds:dsk_ret_code_], al	; Сбросить код возврата
                mov	ah, [ds:dsk_motor_stat]	; Текущий статус моторов
                test	ah, 3			; Моторы работают?
                jz	short send_reset_cmd	; Нет – сразу сброс
                mov	al, 4			; Команда сброса для дисковода 0
                shr	ah, 1			; Проверить бит 0 (дисковод 0)
                jb	short send_reset_cmd	; Бит установлен – оставить AL=4
                mov	al, 18h			; Команда сброса для дисковода 1

send_reset_cmd:
                call	get_drive_head_params	; Получить параметры головки
                mov	dl, [ds:dsk_status_2]	; Порт цифрового вывода (3F2h)
                out	dx, al			; Послать команду сброса
                inc	ax			; Снять сигнал сброса
                out	dx, al			; Послать повторно
                mov	dl, [ds:dsk_status_1]	; Порт основного статуса (3F4h)
                mov	al, 0D0h		; Команда принудительного прерывания
                out	dx, al			; Выполнить
                mov	dl, [ds:dsk_status_2]	; Порт цифрового вывода
                in	al, dx			; Прочитать состояние
                retn				; Возврат
; ---------------------------------------------------------------------------

get_last_status:
                mov	al, [ds:dsk_ret_code_]	; Вернуть код возврата
                retn				; Возврат
; ---------------------------------------------------------------------------

verify_setup:
                mov	bx, 0FC00h		; Сегмент для верификации (область данных)
                mov	es, bx			; ES = FC00h
                assume es:nothing
                mov	bh, bl			; BH = 0
                jmp	short read_sectors	; Перейти к общему коду чтения/записи
; ---------------------------------------------------------------------------

write_setup:
                or	[byte ptr ds:dsk_motor_stat], 80h ; Установить флаг записи

read_sectors:
                call	drive_motor_control	; Включить мотор и выбрать привод
                push	bx			; Сохранить BX
                mov	bl, 15h			; Код команды (15h – чтение/запись)
                call	seek_track		; Позиционировать головку
                pop	bx			; Восстановить BX
                jnb	short transfer_start	; Успешно – начать передачу
                xor	al, al			; Ошибка – вернуть 0 секторов
                retn				; Возврат
; ---------------------------------------------------------------------------

transfer_start:
                call	video_access_optimize	; Оптимизировать доступ к видеопамяти
                mov	ch, al			; CH = количество секторов
                xor	ah, ah			; AH = 0 (счетчик секторов)
                call	get_drive_head_params	; Получить параметры головки
                mov	cl, [ds:dsk_status_1]	; Базовый порт (3F4h)
                add	cl, 3			; Порт данных (3F7h)
                test	[byte ptr ds:dsk_motor_stat], 80h ; Проверить флаг записи
                jnz	short write_sector_data	; Установлен – запись
; ---------------------------------------------------------------------------

read_loop:
                mov	di, bx			; DI = текущий указатель буфера
                mov	al, 80h			; Команда чтения сектора
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                out	dx, al			; Послать команду
                mov	dl, [ds:dsk_status_3]	; Порт данных
                jmp	short read_data_byte	; Начать чтение
; ---------------------------------------------------------------------------

store_byte:
                stosb				; [ES:DI] = AL, DI++

read_data_byte:
                in	al, dx			; Прочитать статус контроллера
                shr	al, 1			; Проверить бит DRQ (готовность данных)
                xchg	dl, cl			; Переключиться на порт данных
                in	al, dx			; Прочитать байт данных
                xchg	dl, cl			; Вернуть порт статуса
                jb	short store_byte	; Если DRQ=1 – сохранить байт
                mov	bx, di			; Обновить указатель буфера
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                in	al, dx			; Прочитать статус команды
                and	al, 1Fh			; Маска битов ошибок
                jnz	short handle_transfer_error ; Ошибка – обработка
                inc	ah			; Увеличить счетчик секторов
                call	increment_sector	; Инкремент номера сектора
                cmp	ch, ah			; Все секторы обработаны?
                jnz	short read_loop		; Нет – следующий сектор
                mov	al, ah			; Вернуть количество секторов
                call	video_restore		; Восстановить видеорежим
                retn				; Возврат
; ---------------------------------------------------------------------------

write_sector_data:
                push	ds			; Сохранить DS
                mov	al, 0A0h		; Команда записи сектора
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                out	dx, al			; Послать команду
                mov	dl, [ds:dsk_status_3]	; Порт данных
                mov	si, es			; SI = сегмент данных
                mov	ds, si			; DS = сегмент источника
                assume ds:nothing
                mov	si, bx			; SI = смещение в буфере

write_byte_loop:
                in	al, dx			; Прочитать статус
                shr	al, 1			; Проверить DRQ
                lodsb				; AL = [DS:SI], SI++
                xchg	dl, cl			; Переключиться на порт данных
                out	dx, al			; Записать байт
                xchg	dl, cl			; Вернуть порт статуса
                jb	short write_byte_loop	; Пока DRQ=1 – продолжать
                dec	si			; SI = последний записанный адрес
                mov	bx, si			; BX = указатель буфера
                pop	ds			; Восстановить DS
                assume ds:nothing
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                in	al, dx			; Прочитать статус команды
                and	al, 5Fh			; Маска битов ошибок
                jnz	short handle_transfer_error ; Ошибка – обработка
                inc	ah			; Увеличить счетчик секторов
                call	increment_sector	; Инкремент номера сектора
                cmp	ch, ah			; Все секторы обработаны?
                jnz	short write_sector_data	; Нет – следующий сектор
                mov	al, ah			; Вернуть количество секторов
                call	video_restore		; Восстановить видеорежим
                retn				; Возврат
; ---------------------------------------------------------------------------

handle_transfer_error:
                call	video_restore		; Восстановить видеорежим
                mov	bh, ah			; Сохранить счетчик секторов
                test	[byte ptr ds:dsk_motor_stat], 80h ; Проверить флаг записи
                jz	short check_read_errors	; Нет – ошибка чтения
                test	al, 40h			; Бит 6 = защита от записи?
                mov	ah, 3			; Код ошибки 3 (защита от записи)
                jnz	short set_error_code	; Да – установить код

check_read_errors:
                test	al, 10h			; Бит 4 = сектор не найден?
                mov	ah, 4			; Код ошибки 4
                jnz	short set_error_code
                test	al, 8			; Бит 3 = ошибка CRC?
                mov	ah, 10h			; Код ошибки 10h
                jnz	short set_error_code
                test	al, 1			; Бит 0 = ошибка команды?
                mov	ah, 80h			; Код ошибки 80h
                jnz	short set_error_code
                mov	ah, 20h			; Общая ошибка контроллера

set_error_code:
                or	[ds:dsk_ret_code_], ah	; Установить код ошибки
                mov	al, bh			; Вернуть количество обработанных секторов
                retn				; Возврат
endp		dispatch_ah_command





proc		increment_sector near		; Инкремент номера текущего сектора
                mov	dl, [ds:dsk_status_1]	; Базовый порт
                inc	dx			; +1 (регистр номера сектора?)
                inc	dx			; +2 (возможно, порт 3F6h)
                in	al, dx			; Прочитать текущий сектор
                inc	ax			; Увеличить
                out	dx, al			; Записать обратно
                retn				; Возврат
endp		increment_sector

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR dispatch_ah_command

format_track:
                push	bx			; Сохранить BX
                or	[byte ptr ds:dsk_motor_stat], 80h ; Установить флаг записи
                call	drive_motor_control	; Включить мотор и выбрать привод
                mov	bl, 11h			; Код команды форматирования
                call	seek_track		; Позиционировать головку
                pop	si			; SI = указатель на таблицу форматирования
                jnb	short format_start	; Успешно – начать форматирование
                retn				; Возврат (ошибка)
; ---------------------------------------------------------------------------

format_start:
                push	ax			; Сохранить AX
                push	bp			; Сохранить BP
                mov	ah, al			; AH = номер головки
                xor	bx, bx			; BX = 0
                mov	ds, bx			; DS = 0 (доступ к таблице прерываний)
                lds	bx, [ds:prn_timeout_1_]	; Получить вектор принтера/таймаута
                mov	di, [bx+7]		; DI = смещение из вектора (для заполнения)
                mov	bx, BDAseg		; BX = сегмент BDA
                mov	ds, bx			; DS = BDA
                assume ds:nothing
                call	video_access_optimize	; Оптимизировать видеодоступ
                call	get_drive_head_params	; Получить параметры головки
                mov	dl, [ds:dsk_status_3]	; Порт данных
                mov	bp, dx			; BP = порт данных (сохранить)
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                mov	al, 0F0h		; Команда форматирования дорожки
                out	dx, al			; Послать команду
                add	dl, 3			; Переключиться на порт данных
                test	[byte ptr ds:dsk_motor_stat], 20h ; Проверить бит двойного шага?
                jz	short format_with_gaps	; Нет – обычное форматирование
                lods	[word ptr es:si]	; Загрузить слово из таблицы форматирования
                xchg	ax, cx			; CX = счетчик

format_data_word:
                xchg	bp, dx			; Переключиться на порт данных
                in	al, dx			; Ждать готовности
                lods	[byte ptr es:si]	; Загрузить байт данных
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Отправить байт
                loop	format_data_word	; Повторить CX раз
                jmp	short format_complete	; Завершить форматирование
; ---------------------------------------------------------------------------

format_with_gaps:
                mov	bx, offset format_gap1	; Адрес таблицы первого промежутка
                mov	ch, 5			; 5 байт
                call	send_format_bytes	; Отправить байты

format_sector_loop:
                mov	bx, offset format_sector_data ; Адрес таблицы заголовка сектора
                mov	ch, 3			; 3 байта
                call	send_format_bytes	; Отправить байты
                mov	cx, 4			; 4 байта информации сектора

write_sector_info:
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                lods	[byte ptr es:si]	; Загрузить информацию сектора
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Отправить байт
                loop	write_sector_info	; Повторить 4 раза
                push	ax			; Сохранить AX
                mov	ch, 5			; 5 байт промежутка
                call	send_format_bytes	; Отправить байты
                pop	cx			; CX = сохраненное значение (номер сектора?)
                mov	bx, 80h			; Размер сектора (128 байт * 2^CL)
                shl	bx, cl			; BX = количество байт на сектор
                mov	cx, bx			; CX = размер сектора
                mov	bx, di			; BX = значение для заполнения

fill_sector:
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                mov	al, bh			; Байт заполнения (старший байт DI)
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Записать байт
                loop	fill_sector		; Повторить CX раз
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                mov	al, 0F7h		; Маркер конца сектора
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Записать маркер
                mov	cx, di			; CX = значение для послесекторного промежутка
                xor	ch, ch			; CH = 0

write_post_gap:
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                mov	al, 4Eh			; Байт заполнения промежутка
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Записать байт
                loop	write_post_gap		; Повторить CX раз
                dec	ah			; Уменьшить номер головки
                jnz	short format_sector_loop ; Если не 0 – следующий сектор

format_complete:
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                xchg	bp, dx			; Вернуть порт статуса
                shr	al, 1			; Проверить DRQ
                mov	al, 4Eh			; Байт завершения
                out	dx, al			; Записать
                jb	short format_complete	; Пока DRQ=1 – продолжать
                pop	bp			; Восстановить BP
                pop	cx			; Восстановить CX
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                in	al, dx			; Прочитать статус
                and	al, 47h			; Маска битов ошибок
                jz	short format_success	; Нет ошибок – успех
                sub	ah, ah			; AH = 0 (количество секторов)
                jmp	handle_transfer_error	; Обработать ошибку
; ---------------------------------------------------------------------------

format_success:
                call	video_restore		; Восстановить видеорежим
                mov	al, cl			; Вернуть исходное значение AL
                retn				; Возврат
; END OF FUNCTION CHUNK	FOR dispatch_ah_command




proc		send_format_bytes near		; Отправить группу байт форматирования
                mov	cl, [cs:bx+1]		; CL = счетчик повторов (из таблицы)

send_byte_loop:
                xchg	bp, dx			; Порт данных
                in	al, dx			; Ждать готовности
                mov	al, [cs:bx]		; AL = байт из таблицы
                xchg	bp, dx			; Вернуть порт статуса
                out	dx, al			; Отправить байт
                dec	cl			; Уменьшить счетчик
                jnz	short send_byte_loop	; Повторить
                inc	bx			; Перейти к следующему байту в таблице
                inc	bx
                dec	ch			; Уменьшить счетчик блоков
                jnz	short send_format_bytes	; Если не 0 – следующий блок
                retn				; Возврат
endp		send_format_bytes

; ---------------------------------------------------------------------------
format_gap1		db  4Eh	; N		; Данные первого промежутка при форматировании
                db  10h
                db    0
                db  0Ch
                db 0F6h	; ?
                db    3
                db 0FCh	; ?
                db    1
                db  4Eh	; N
                db  32h	; 2
format_sector_data	db    0			; Данные заголовка сектора
                db  0Ch
                db 0F5h	; ?
                db    3
                db 0FEh	; ?
                db    1
                db 0F7h	; ?
                db    1
                db  4Eh	; N
                db  16h
                db    0
                db  0Ch
                db 0F5h	; ?
                db    3
                db 0FBh	; ?
                db    1

drive_type_table	db  93h	; ?		; Таблица кодов типов дисководов
                db  74h	; t
                db  15h
                db  97h	; ?
                db  17h
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR dispatch_ah_command

get_drive_type:
                dec	ax			; AL = AL - 1
                cmp	al, 5			; Проверить допустимый диапазон
                jb	short get_drive_type_code ; <5 – нормально
                jmp	invalid_command		; Иначе – ошибка
; ---------------------------------------------------------------------------

get_drive_type_code:
                mov	bx, ax			; BX = AL
                and	bx, 7			; Индекс в таблице (0-7)
                mov	al, drive_type_table[bx] ; Получить код типа

store_drive_type:
                mov	bx, dx			; BX = номер дисковода
                and	bx, 1			; Только младший бит
                mov	[bx+90h], al		; Сохранить в области привода
                retn				; Возврат
; ---------------------------------------------------------------------------

set_diskette_change_status:
                mov	al, 2			; Предположить 360K
                cmp	cx, 2709h		; 39 дорожек, 9 секторов (360K)
                jz	short get_drive_type_code ; Совпало – код 2
                inc	ax			; AL = 3
                cmp	cx, 4F0Fh		; 79 дорожек, 15 секторов (1.2M)
                jz	short get_drive_type_code ; Совпало – код 3
                inc	ax			; AL = 4
                cmp	cx, 4F09h		; 79 дорожек, 9 секторов (720K)
                jz	short get_drive_type_code ; Совпало – код 4
                inc	ax			; AL = 5
                cmp	cx, 4F12h		; 79 дорожек, 18 секторов (1.44M)
                jz	short get_drive_type_code ; Совпало – код 5
                jmp	invalid_command		; Неизвестный формат – ошибка

; ---------------------------------------------------------------------------

proc		seek_track near		; Поиск дорожки
                push	ax			; Сохранить AX
                push	cx			; Сохранить CX
                mov	ax, si			; AX = индекс дисковода
                inc	ax			; Преобразовать в маску
                mov	ah, ch			; AH = номер дорожки
                test	[ds:dsk_recal_stat], al ; Привод уже откалиброван?
                jnz	short skip_recalibrate	; Да – пропустить калибровку
                call	recalibrate_drive	; Выполнить калибровку
                jnb	short set_recalibrated	; Успешно – установить флаг
                pop	cx			; Ошибка – восстановить CX
                jmp	short seek_exit		; Выход с ошибкой
; ---------------------------------------------------------------------------
; dsk_status ?
set_recalibrated:
                or	[ds:dsk_recal_stat], al	; Установить флаг калибровки

skip_recalibrate:
                mov	al, ah			; AL = номер дорожки
                call	get_drive_head_params	; Получить параметры
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                inc	dx			; Порт дорожки (3F5h)
                out	dx, al			; Установить номер дорожки
                mov	cl, [ds:dsk_status_7]	; Сдвиг для выбора головки
                shl	al, cl			; Сдвинуть бит головки
                cmp	al, [si+dsk_status_5]	; Совпадает с текущим состоянием?
                jz	short set_sector_number	; Да – пропустить установку головки
                inc	dx			; Следующий порт (3F6h?)
                inc	dx
                out	dx, al			; Установить новое состояние головки
                xchg	al, [si+dsk_status_5]	; Обменять с сохранённым
                dec	dx			; Вернуться к порту дорожки
                dec	dx
                out	dx, al			; Восстановить старое значение
                dec	dx			; Порт статуса
                mov	al, 10h			; Команда поиска
                out	dx, al			; Выполнить
                call	wait_controller_ready	; Ждать готовности контроллера
                mov	al, ah			; AL = номер дорожки
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                inc	dx			; Порт дорожки
                out	dx, al			; Установить номер дорожки
                test	[byte ptr ds:dsk_motor_stat], 80h ; Проверить флаг записи
                jz	short set_sector_number	; Нет – не проверять
                inc	dx			; Порт головки
                inc	dx
                out	dx, al			; Установить головку
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                mov	al, bl			; AL = код команды (15h/11h)
                out	dx, al			; Послать команду
                mov	dl, [ds:dsk_status_3]	; Порт данных
                in	al, dx			; Прочитать статус
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                in	al, dx			; Прочитать статус
                and	al, 19h			; Маска ошибок
                jz	short set_sector_number	; Ошибок нет – нормально
                or	[byte ptr ds:dsk_ret_code_], 40h ; Установить бит ошибки поиска
                stc				; Установить флаг переноса (ошибка)
                pop	cx			; Восстановить CX
                jmp	short seek_exit		; Выход

set_sector_number:
                pop	cx			; Восстановить CX
                mov	al, cl			; AL = номер сектора
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                inc	dx			; Порт сектора (3F6h?)
                inc	dx
                out	dx, al			; Установить номер сектора

seek_exit:
                pop	ax			; Восстановить AX
                retn				; Возврат
endp		seek_track

proc		drive_motor_control near	; Управление мотором и выбор привода
                push	ax			; Сохранить AX
                push	cx			; Сохранить CX
                and	dl, 1			; DL = номер привода (0/1)
                mov	si, dx			; SI = номер привода
                and	si, 1			; Маска 0/1
                mov	cl, dl			; CL = номер привода
                inc	cx			; CX = маска мотора (1<<привод)
                mov	[byte ptr ds:dsk_status_7], 0 ; Сбросить флаг сдвига головки
                test	[byte ptr si+90h], 10h	; Проверить бит двойного шага?
                jnz	short check_high_track	; Да – проверить высокие дорожки
                mov	[byte ptr si+0090h], 17h ; Установить значение по умолчанию

check_high_track:
                test	[byte ptr si+0090h], 20h ; Проверить флаг дорожки >43
                jz	short prepare_motor_cmd	; Нет – подготовить команду
                cmp	ch, 2Ch			; Номер дорожки >= 44?
                jnb	short clear_high_track_flag ; Да – сбросить флаг
                inc	[byte ptr ds:dsk_status_7] ; Установить сдвиг головки для высоких дорожек
                jmp	short prepare_motor_cmd
; ---------------------------------------------------------------------------

clear_high_track_flag:
                and	[byte ptr si+90h], 0DFh	; Сбросить бит 5 (дорожка >43)

prepare_motor_cmd:
                mov	al, 82h			; Команда управления для привода 0
                test	[byte ptr ds:dsk_motor_stat], 40h ; Проверить бит смены привода?
                jz	short select_drive	; Нет – выбрать привод
                xor	dl, 1			; Инвертировать номер привода

select_drive:
                test	dl, 1			; Привод 1?
                jz	short set_motor_bits	; Нет – оставить AL=82h
                mov	al, 8Ch			; Команда управления для привода 1

set_motor_bits:
                or	al, dh			; Добавить бит выбора головки (DH)
                test	[byte ptr si+90h], 0C0h ; Проверить биты типа привода
                jnz	short send_motor_cmd	; Установлены – не менять
                or	al, 10h			; Установить бит двойной плотности

send_motor_cmd:
                rol	al, 1			; Сдвинуть для правильного формата
                call	get_drive_head_params	; Получить параметры
                mov	ah, 0FFh		; Начальное значение таймера
                mov	[ds:dsk_motor_tmr], ah	; Установить таймер мотора
                inc	ah			; AH = 0
                mov	dl, [ds:dsk_status_2]	; Порт цифрового вывода
                out	dx, al			; Отправить команду управления
                in	al, dx			; Прочитать состояние
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                mov	al, 0D0h		; Принудительное прерывание
                out	dx, al			; Выполнить
                test	[ds:dsk_motor_stat], cl ; Мотор уже включён?
                jnz	short motor_ready	; Да – пропустить ожидание

spinup_wait:
                mov	al, [ds:dsk_motor_tmr]	; Текущее значение таймера
                sub	al, ah			; Вычесть 0 (не меняется?)
                not	al			; Инвертировать
                shr	al, 1			; Поделить на 2
                cmp	al, [cs:MotorOn]	; Сравнить с константой раскрутки
                jb	short spinup_wait	; Меньше – ждать

motor_ready:
                and	[byte ptr ds:dsk_motor_stat], 0FCh ; Сбросить биты текущего привода
                or	[ds:dsk_motor_stat], cl ; Установить бит текущего привода
                pop	cx			; Восстановить CX
                pop	ax			; Восстановить AX
                retn				; Возврат
endp		drive_motor_control

proc		get_drive_head_params near	; Получить параметры привода и головки
                mov	dh, [ds:dsk_status_4]	; Получить значение (номер головки?)
                dec	dh			; Уменьшить
                and	dh, 1			; Только младший бит (0/1)
                retn				; Возврат
endp		get_drive_head_params





proc		wait_controller_ready near	; Ожидание готовности контроллера
                push	ax			; Сохранить AX
                mov	[byte ptr ds:dsk_motor_tmr], 0FFh ; Установить таймер

wait_ready_loop:
                in	al, dx			; Прочитать порт статуса
                shr	al, 1			; Проверить бит готовности
                jb	short wait_ready_loop	; Не готов – ждать
                pop	ax			; Восстановить AX
                retn				; Возврат
endp		wait_controller_ready









proc		verify_diskette_status near	; Проверка статуса диска (верификация)
                mov	al, 0D0h		; Принудительное прерывание
                call	get_drive_head_params	; Получить параметры
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                out	dx, al			; Отправить команду
                call	wait_controller_ready	; Ожидать готовности
                mov	al, 0C0h		; Запрос статуса прерывания
                out	dx, al			; Отправить
                mov	ah, 3			; Смещение для порта данных?
                add	ah, dl			; AH = порт данных (3F4h+3 = 3F7h)

read_id_loop:
                mov	dl, [ds:dsk_status_3]	; Порт данных
                in	al, dx			; Прочитать статус
                shr	al, 1			; Проверить DRQ
                mov	dl, ah			; Переключиться на порт данных
                in	al, dx			; Прочитать байт ID
                jb	short read_id_loop	; Если DRQ=1 – продолжать
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                in	al, dx			; Прочитать финальный статус
                and	al, 10h			; Проверить бит ошибки
                retn				; Возврат (ZF=1 если ошибки нет)
endp		verify_diskette_status





proc		recalibrate_drive near		; Калибровка привода (возврат на 0 дорожку)
                push	ax			; Сохранить AX
                mov	dl, [ds:dsk_status_2]	; Порт цифрового вывода
                in	al, dx			; Прочитать состояние
                mov	dl, [ds:dsk_status_1]	; Порт статуса
                mov	al, 0D0h		; Принудительное прерывание
                out	dx, al			; Отправить
                call	wait_controller_ready	; Ожидать готовности
                mov	al, 9			; Команда калибровки
                out	dx, al			; Отправить
                call	wait_controller_ready	; Ожидать завершения
                in	al, dx			; Прочитать статус
                and	al, 5			; Маска битов 0 и 2
                cmp	al, 4			; Проверить бит 2 (успех)
                jz	short recalibrate_ok	; Успешно
                or	[byte ptr ds:dsk_ret_code_], 80h ; Ошибка таймаута
                stc				; Установить флаг ошибки

recalibrate_ok:
                mov	dl, [ds:dsk_status_2]	; Порт цифрового вывода
                in	al, dx			; Прочитать состояние
                mov	[byte ptr si+0046h], 0	; Сбросить счётчик повторов?
                pop	ax			; Восстановить AX
                retn				; Возврат
endp		recalibrate_drive

proc		video_access_optimize near	; Оптимизация видеодоступа (временно отключить видео)
                cli				; Запретить прерывания
                push	ax			; Сохранить AX
                mov	al, [ds:video_mode_reg_] ; Текущий видеорежим
                test	al, 1			; Проверить бит 0 (цветной режим?)
                jz	short video_check_done	; Нет – пропустить
                mov	ax, es			; AX = сегмент буфера
                push	cx			; Сохранить CX
                mov	cl, 4			; Сдвиг на 4 (параграфы)
                push	bx			; Сохранить BX
                shr	bx, cl			; BX = смещение в параграфах
                add	ax, bx			; AX = полный сегмент буфера
                pop	bx			; Восстановить BX
                pop	cx			; Восстановить CX
                push	ax			; Сохранить AX
                mov	ax, [ds:0013h]		; Размер основной памяти в КБ
                cmp	ax, 0060h		; Меньше 96K?
                pop	ax			; Восстановить AX
                ja	short check_buffer_addr	; Больше – проверить адрес
                mov	al, 0			; AL = 0 (не отключать видео)
                jmp	short set_video_state	; Установить состояние
; ---------------------------------------------------------------------------

check_buffer_addr:
                cmp	ax, 7EC0h		; Адрес меньше 7EC0h?
                jb	short video_check_done	; Да – оставить видео
                cmp	ax, 0C000h		; Адрес выше видеопамяти?
                jnb	short video_check_done	; Да – оставить видео
                mov	al, 0			; Буфер в области видео – отключить
                jmp	short set_video_state
endp		video_access_optimize





proc		video_restore near		; Восстановление видеорежима
                sti				; Разрешить прерывания
                push	ax			; Сохранить AX
                mov	al, [ds:video_mode_reg_] ; Текущий видеорежим

set_video_state:
                mov	dx, 3D8h		; Порт управления CGA
                out	dx, al			; Установить режим

video_check_done:
                pop	ax			; Восстановить AX
                retn				; Возврат
endp		video_restore