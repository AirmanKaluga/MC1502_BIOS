; =================================================================
; МС-1502: Setup BIOS (CMOS/Setup Utility)
; Адреса: FC000h - FDFFFh (F000:C000 - F000:DFFF)
; Содержит: Программа настройки BIOS с русским интерфейсом
; =================================================================

; -----------------------------------------------------------------
; Константы и макроопределения
; -----------------------------------------------------------------
                org     0C000h          ; Смещение в сегменте F000

; Коды клавиш
KEY_UP          equ     4800h
KEY_DOWN        equ     5000h
KEY_LEFT        equ     4B00h
KEY_RIGHT       equ     4D00h
KEY_ENTER       equ     1C0Dh
KEY_ESC         equ     011Bh
KEY_F1          equ     3B00h
KEY_F2          equ     3C00h
KEY_F5          equ     3F00h
KEY_F6          equ     4000h
KEY_F10         equ     4400h
KEY_PLUS        equ     4E2Bh
KEY_MINUS       equ     4A2Dh

; Цвета текстового режима
COLOR_BG        equ     10h             ; Синий фон
COLOR_FG        equ     0Fh             ; Белый текст
COLOR_HIGHLIGHT equ     30h             ; Черный на голубом
COLOR_TITLE     equ     1Eh             ; Желтый на синем
COLOR_WARNING   equ     4Eh             ; Красный на желтом
COLOR_DISABLED  equ     07h             ; Серый на черном

; -----------------------------------------------------------------
; Точка входа в Setup
; -----------------------------------------------------------------
setup_entry:
                ; Сохранение состояния
                pusha
                push    ds
                push    es
                
                ; Установка сегмента данных
                mov     ax, 40h
                mov     ds, ax
                
                ; Очистка экрана и установка режима
                call    clear_screen
                
                ; Вывод главного экрана Setup
                call    draw_main_screen
                
                ; Основной цикл обработки
                call    main_loop
                
                ; Восстановление и возврат
                pop     es
                pop     ds
                popa
                retf

; -----------------------------------------------------------------
; Главный цикл Setup
; -----------------------------------------------------------------
main_loop:
                ; Обновление отображаемых значений
                call    update_displayed_values
                
                ; Ожидание нажатия клавиши
                call    wait_key
                
                ; Обработка клавиши
                call    process_key
                
                ; Проверка на выход
                cmp     byte [exit_flag], 1
                jne     main_loop
                
                ret

; -----------------------------------------------------------------
; Ожидание нажатия клавиши
; -----------------------------------------------------------------
wait_key:
                mov     ah, 00h
                int     16h
                ret

; -----------------------------------------------------------------
; Обработка нажатой клавиши
; -----------------------------------------------------------------
process_key:
                ; Проверка специальных клавиш
                cmp     ax, KEY_F1
                je      key_f1
                cmp     ax, KEY_F2
                je      key_f2
                cmp     ax, KEY_F5
                je      key_f5
                cmp     ax, KEY_F6
                je      key_f6
                cmp     ax, KEY_F10
                je      key_f10
                cmp     ax, KEY_ESC
                je      key_esc
                
                ; Проверка стрелок
                cmp     ax, KEY_UP
                je      key_up
                cmp     ax, KEY_DOWN
                je      key_down
                cmp     ax, KEY_LEFT
                je      key_left
                cmp     ax, KEY_RIGHT
                je      key_right
                cmp     ax, KEY_ENTER
                je      key_enter
                
                ; Другие клавиши
                cmp     al, '+'
                je      key_plus
                cmp     al, '-'
                je      key_minus
                
                ret

key_f1:
                ; Помощь
                call    show_help
                ret

key_f2:
                ; Переключение цветовой схемы
                call    toggle_color_scheme
                ret

key_f5:
                ; Загрузить настройки по умолчанию
                call    load_defaults
                ret

key_f6:
                ; Оптимизированные настройки
                call    load_optimized
                ret

key_f10:
                ; Сохранить и выйти
                call    save_and_exit
                ret

key_esc:
                ; Выйти без сохранения
                call    exit_without_save
                ret

key_up:
                ; Перемещение вверх по меню
                call    menu_move_up
                ret

key_down:
                ; Перемещение вниз по меню
                call    menu_move_down
                ret

key_left:
                ; Уменьшение значения
                call    decrease_value
                ret

key_right:
                ; Увеличение значения
                call    increase_value
                ret

key_enter:
                ; Вход в подменю
                call    enter_submenu
                ret

key_plus:
                ; Увеличение (альтернативная клавиша)
                call    increase_value
                ret

key_minus:
                ; Уменьшение (альтернативная клавиша)
                call    decrease_value
                ret

; -----------------------------------------------------------------
; Очистка экрана
; -----------------------------------------------------------------
clear_screen:
                ; Установка видеорежима 80x25, 16 цветов
                mov     ax, 0003h
                int     10h
                
                ; Установка цвета фона
                mov     ah, 0Bh
                mov     bh, 0
                mov     bl, COLOR_BG
                int     10h
                
                ; Очистка экрана синим цветом
                mov     ax, 0600h
                mov     bh, COLOR_BG
                xor     cx, cx
                mov     dx, 184Fh
                int     10h
                
                ; Скрытие курсора
                mov     ah, 01h
                mov     cx, 2000h
                int     10h
                
                ret

; -----------------------------------------------------------------
; Рисование главного экрана Setup
; -----------------------------------------------------------------
draw_main_screen:
                ; Верхняя рамка
                mov     dh, 0
                mov     dl, 0
                call    set_cursor
                mov     si, border_top
                call    print_string_color
                
                ; Заголовок
                mov     dh, 1
                mov     dl, 25
                call    set_cursor
                mov     si, title_line1
                call    print_string_color
                
                mov     dh, 2
                mov     dl, 26
                call    set_cursor
                mov     si, title_line2
                call    print_string_color
                
                ; Информация о версии
                mov     dh, 4
                mov     dl, 28
                call    set_cursor
                mov     si, version_info
                call    print_string
                
                ; Основное меню
                mov     dh, 6
                mov     dl, 2
                call    set_cursor
                mov     si, menu_standard
                call    print_string
                
                mov     dh, 8
                mov     dl, 2
                call    set_cursor
                mov     si, menu_advanced
                call    print_string
                
                mov     dh, 10
                mov     dl, 2
                call    set_cursor
                mov     si, menu_security
                call    print_string
                
                mov     dh, 12
                mov     dl, 2
                call    set_cursor
                mov     si, menu_power
                call    print_string
                
                mov     dh, 14
                mov     dl, 2
                call    set_cursor
                mov     si, menu_exit
                call    print_string
                
                ; Панель информации о системе (справа)
                mov     dh, 6
                mov     dl, 50
                call    set_cursor
                mov     si, sysinfo_title
                call    print_string_color
                
                ; Информация о процессоре
                mov     dh, 8
                mov     dl, 50
                call    set_cursor
                mov     si, cpu_info
                call    print_string
                
                ; Информация о памяти
                mov     dh, 10
                mov     dl, 50
                call    set_cursor
                mov     si, mem_info
                call    print_string
                
                ; Информация о дисках
                mov     dh, 12
                mov     dl, 50
                call    set_cursor
                mov     si, disk_info
                call    print_string
                
                ; Информация о видео
                mov     dh, 14
                mov     dl, 50
                call    set_cursor
                mov     si, video_info
                call    print_string
                
                ; Нижняя панель помощи
                mov     dh, 22
                mov     dl, 0
                call    set_cursor
                mov     si, help_line
                call    print_string_color
                
                ; Подсказки внизу
                mov     dh, 23
                mov     dl, 0
                call    set_cursor
                mov     si, shortcuts
                call    print_string
                
                ; Выделение текущего пункта меню
                call    highlight_current_item
                
                ret

; -----------------------------------------------------------------
; Установка курсора
; -----------------------------------------------------------------
set_cursor:
                push    ax
                push    bx
                push    dx
                mov     ah, 02h
                xor     bh, bh
                int     10h
                pop     dx
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Печать строки с цветом
; -----------------------------------------------------------------
print_string_color:
                push    ax
                push    bx
                push    si
                
print_char_color_loop:
                lodsb
                or      al, al
                jz      print_color_done
                
                ; Сохранение цвета в BL
                mov     bl, COLOR_TITLE
                call    print_char_with_color
                
                jmp     print_char_color_loop
                
print_color_done:
                pop     si
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Печать символа с цветом
; -----------------------------------------------------------------
print_char_with_color:
                push    ax
                push    bx
                push    cx
                
                mov     ah, 09h
                mov     bh, 0
                mov     cx, 1
                int     10h
                
                ; Перемещение курсора вперед
                mov     ah, 03h
                int     10h
                inc     dl
                mov     ah, 02h
                int     10h
                
                pop     cx
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Печать строки (обычный цвет)
; -----------------------------------------------------------------
print_string:
                push    ax
                push    bx
                push    si
                
print_char_loop:
                lodsb
                or      al, al
                jz      print_done
                
                mov     ah, 0Eh
                mov     bx, 0007h
                int     10h
                
                jmp     print_char_loop
                
print_done:
                pop     si
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Подсветка текущего пункта меню
; -----------------------------------------------------------------
highlight_current_item:
                ; Сначала очистим все подсветки
                mov     byte [menu_item], 0
                call    redraw_menu_items
                
                ; Подсветим выбранный пункт
                mov     al, [current_selection]
                mov     [menu_item], al
                call    redraw_menu_items
                
                ret

; -----------------------------------------------------------------
; Перерисовка пунктов меню
; -----------------------------------------------------------------
redraw_menu_items:
                ; Пункт 1: Standard CMOS Features
                mov     dh, 6
                mov     dl, 2
                call    set_cursor
                
                cmp     byte [menu_item], 1
                jne     item1_normal
                mov     si, menu_standard_sel
                jmp     item1_draw
item1_normal:
                mov     si, menu_standard
item1_draw:
                call    print_menu_item
                
                ; Пункт 2: Advanced BIOS Features
                mov     dh, 8
                mov     dl, 2
                call    set_cursor
                
                cmp     byte [menu_item], 2
                jne     item2_normal
                mov     si, menu_advanced_sel
                jmp     item2_draw
item2_normal:
                mov     si, menu_advanced
item2_draw:
                call    print_menu_item
                
                ; Пункт 3: Security
                mov     dh, 10
                mov     dl, 2
                call    set_cursor
                
                cmp     byte [menu_item], 3
                jne     item3_normal
                mov     si, menu_security_sel
                jmp     item3_draw
item3_normal:
                mov     si, menu_security
item3_draw:
                call    print_menu_item
                
                ; Пункт 4: Power Management
                mov     dh, 12
                mov     dl, 2
                call    set_cursor
                
                cmp     byte [menu_item], 4
                jne     item4_normal
                mov     si, menu_power_sel
                jmp     item4_draw
item4_normal:
                mov     si, menu_power
item4_draw:
                call    print_menu_item
                
                ; Пункт 5: Exit
                mov     dh, 14
                mov     dl, 2
                call    set_cursor
                
                cmp     byte [menu_item], 5
                jne     item5_normal
                mov     si, menu_exit_sel
                jmp     item5_draw
item5_normal:
                mov     si, menu_exit
item5_draw:
                call    print_menu_item
                
                ret

; -----------------------------------------------------------------
; Печать пункта меню с правильным цветом
; -----------------------------------------------------------------
print_menu_item:
                push    ax
                push    bx
                push    cx
                push    si
                
                ; Определяем цвет
                cmp     byte [menu_item], 0
                je      print_normal_color
                
                ; Проверяем, это ли активный пункт
                mov     al, [current_selection]
                cmp     al, [menu_item]
                jne     print_normal_color
                
                ; Подсветка активного пункта
                mov     bl, COLOR_HIGHLIGHT
                jmp     print_with_color
                
print_normal_color:
                mov     bl, COLOR_FG
                
print_with_color:
                ; Печатаем каждый символ с цветом
print_menu_char:
                lodsb
                or      al, al
                jz      print_menu_done
                
                mov     ah, 09h
                mov     bh, 0
                mov     cx, 1
                int     10h
                
                ; Перемещаем курсор
                mov     ah, 03h
                int     10h
                inc     dl
                mov     ah, 02h
                int     10h
                
                jmp     print_menu_char
                
print_menu_done:
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Обновление отображаемых значений
; -----------------------------------------------------------------
update_displayed_values:
                ; Обновление времени
                call    update_time_display
                
                ; Обновление даты
                call    update_date_display
                
                ; Обновление информации о системе
                call    update_system_info
                
                ret

; -----------------------------------------------------------------
; Обновление отображения времени
; -----------------------------------------------------------------
update_time_display:
                ; Получение текущего времени от BIOS
                mov     ah, 02h
                int     1Ah
                jc      time_error
                
                ; Преобразование часов
                mov     al, ch
                call    bcd_to_ascii
                mov     [time_hours], ax
                
                ; Преобразование минут
                mov     al, cl
                call    bcd_to_ascii
                mov     [time_minutes], ax
                
                ; Преобразование секунд
                mov     al, dh
                call    bcd_to_ascii
                mov     [time_seconds], ax
                
                ; Отображение времени
                mov     dh, 7
                mov     dl, 20
                call    set_cursor
                
                mov     si, time_prefix
                call    print_string
                
                mov     si, time_hours
                call    print_string
                
                mov     al, ':'
                call    print_char
                
                mov     si, time_minutes
                call    print_string
                
                mov     al, ':'
                call    print_char
                
                mov     si, time_seconds
                call    print_string
                
                ret
                
time_error:
                ; Ошибка чтения времени
                mov     dh, 7
                mov     dl, 20
                call    set_cursor
                mov     si, time_error_msg
                call    print_string
                ret

; -----------------------------------------------------------------
; Обновление отображения даты
; -----------------------------------------------------------------
update_date_display:
                ; Получение текущей даты от BIOS
                mov     ah, 04h
                int     1Ah
                jc      date_error
                
                ; Преобразование века
                mov     al, ch
                call    bcd_to_ascii
                mov     [date_century], ax
                
                ; Преобразование года
                mov     al, cl
                call    bcd_to_ascii
                mov     [date_year], ax
                
                ; Преобразование месяца
                mov     al, dh
                call    bcd_to_ascii
                mov     [date_month], ax
                
                ; Преобразование дня
                mov     al, dl
                call    bcd_to_ascii
                mov     [date_day], ax
                
                ; Отображение даты
                mov     dh, 9
                mov     dl, 20
                call    set_cursor
                
                mov     si, date_prefix
                call    print_string
                
                mov     si, date_day
                call    print_string
                
                mov     al, '/'
                call    print_char
                
                mov     si, date_month
                call    print_string
                
                mov     al, '/'
                call    print_char
                
                mov     si, date_century
                call    print_string
                
                mov     si, date_year
                call    print_string
                
                ret
                
date_error:
                ; Ошибка чтения даты
                mov     dh, 9
                mov     dl, 20
                call    set_cursor
                mov     si, date_error_msg
                call    print_string
                ret

; -----------------------------------------------------------------
; Преобразование BCD в ASCII
; -----------------------------------------------------------------
bcd_to_ascii:
                push    cx
                mov     ah, al
                and     al, 0Fh
                shr     ah, 4
                add     ax, '00'
                xchg    al, ah
                pop     cx
                ret

; -----------------------------------------------------------------
; Обновление информации о системе
; -----------------------------------------------------------------
update_system_info:
                ; Определение типа процессора
                call    detect_cpu
                
                ; Определение объема памяти
                call    detect_memory
                
                ; Определение типа видеоадаптера
                call    detect_video
                
                ; Определение дисководов
                call    detect_disks
                
                ret

; -----------------------------------------------------------------
; Определение типа процессора
; -----------------------------------------------------------------
detect_cpu:
                ; Проверка на 8088/8086
                pushf
                pop     ax
                and     ax, 0FFFh
                push    ax
                popf
                pushf
                pop     ax
                and     ax, 0F000h
                cmp     ax, 0F000h
                jne     not_8088
                
                ; Это 8088/8086
                mov     si, cpu_8088
                jmp     cpu_detected
                
not_8088:
                ; Проверка на 80286
                pushf
                mov     ax, 0F000h
                push    ax
                popf
                pushf
                pop     ax
                popf
                test    ax, 0F000h
                jnz     is_286
                
                ; Это 80186/80188
                mov     si, cpu_186
                jmp     cpu_detected
                
is_286:
                ; Проверка на 80386
                pushfd
                pop     eax
                mov     ebx, eax
                xor     eax, 40000h
                push    eax
                popfd
                pushfd
                pop     eax
                push    ebx
                popfd
                cmp     eax, ebx
                je      is_286_real
                
                ; Это 80386 или выше
                mov     si, cpu_386
                jmp     cpu_detected
                
is_286_real:
                ; Это 80286
                mov     si, cpu_286
                
cpu_detected:
                ; Отображение информации о процессоре
                mov     dh, 8
                mov     dl, 65
                call    set_cursor
                call    print_string
                
                ret

; -----------------------------------------------------------------
; Определение объема памяти
; -----------------------------------------------------------------
detect_memory:
                ; Получение объема памяти от BIOS
                mov     ah, 88h
                int     15h
                
                ; AX содержит количество КБ после первого мегабайта
                add     ax, 1024        ; Добавляем первый мегабайт
                
                ; Преобразование в строку
                xor     dx, dx
                mov     cx, 1024
                div     cx              ; AX = мегабайты
                
                ; Преобразование в ASCII
                mov     di, memory_size_str
                call    word_to_ascii
                
                ; Добавляем " MB"
                mov     si, memory_mb
                call    strcat
                
                ; Отображение
                mov     dh, 10
                mov     dl, 65
                call    set_cursor
                mov     si, memory_size_str
                call    print_string
                
                ret

; -----------------------------------------------------------------
; Определение типа видеоадаптера
; -----------------------------------------------------------------
detect_video:
                ; Проверка текущего видеорежима
                mov     ah, 0Fh
                int     10h
                
                cmp     al, 7
                je      is_mono
                
                ; Цветной адаптер (CGA/EGA/VGA)
                mov     si, video_color
                jmp     video_detected
                
is_mono:
                ; Монохромный адаптер (MDA)
                mov     si, video_mono
                
video_detected:
                ; Отображение
                mov     dh, 14
                mov     dl, 65
                call    set_cursor
                call    print_string
                
                ret

; -----------------------------------------------------------------
; Определение дисководов
; -----------------------------------------------------------------
detect_disks:
                ; Получение количества дисководов от BIOS
                mov     ax, 40h
                mov     es, ax
                mov     al, [es:10h]
                and     al, 0C0h
                shr     al, 6
                inc     al              ; AL = количество дисководов
                
                ; Преобразование в ASCII
                add     al, '0'
                mov     [disk_count], al
                
                ; Отображение
                mov     dh, 12
                mov     dl, 65
                call    set_cursor
                
                mov     si, disk_prefix
                call    print_string
                
                mov     al, [disk_count]
                call    print_char
                
                mov     si, disk_360k
                call    print_string
                
                ret

; -----------------------------------------------------------------
; Преобразование слова в ASCII
; -----------------------------------------------------------------
word_to_ascii:
                push    ax
                push    bx
                push    cx
                push    dx
                
                mov     cx, 10
                xor     bx, bx
                
                ; Счетчик цифр
                mov     byte [digit_count], 0
                
                ; Проверка на ноль
                test    ax, ax
                jnz     convert_loop
                
                mov     byte [di], '0'
                inc     di
                jmp     conversion_done
                
convert_loop:
                xor     dx, dx
                div     cx
                add     dl, '0'
                push    dx
                inc     byte [digit_count]
                test    ax, ax
                jnz     convert_loop
                
                ; Извлечение цифр в правильном порядке
                mov     cl, [digit_count]
pop_digits:
                pop     ax
                stosb
                loop    pop_digits
                
conversion_done:
                ; Завершающий ноль
                mov     byte [di], 0
                
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Конкатенация строк
; -----------------------------------------------------------------
strcat:
                push    di
                
                ; Поиск конца первой строки
find_end:
                cmp     byte [di], 0
                je      copy_second
                inc     di
                jmp     find_end
                
copy_second:
                ; Копирование второй строки
                lodsb
                stosb
                test    al, al
                jnz     copy_second
                
                pop     di
                ret

; -----------------------------------------------------------------
; Перемещение по меню вверх
; -----------------------------------------------------------------
menu_move_up:
                cmp     byte [current_selection], 1
                jle     move_up_top
                dec     byte [current_selection]
                jmp     move_up_done
move_up_top:
                mov     byte [current_selection], 5
move_up_done:
                call    highlight_current_item
                ret

; -----------------------------------------------------------------
; Перемещение по меню вниз
; -----------------------------------------------------------------
menu_move_down:
                cmp     byte [current_selection], 5
                jge     move_down_bottom
                inc     byte [current_selection]
                jmp     move_down_done
move_down_bottom:
                mov     byte [current_selection], 1
move_down_done:
                call    highlight_current_item
                ret

; -----------------------------------------------------------------
; Увеличение значения
; -----------------------------------------------------------------
increase_value:
                ; Проверяем, какой пункт активен
                cmp     byte [current_selection], 1
                je      inc_time
                cmp     byte [current_selection], 2
                je      inc_advanced
                cmp     byte [current_selection], 3
                je      inc_security
                cmp     byte [current_selection], 4
                je      inc_power
                
                ret

inc_time:
                ; Увеличение времени (заглушка)
                mov     si, inc_time_msg
                call    show_temp_message
                ret

inc_advanced:
                mov     si, inc_advanced_msg
                call    show_temp_message
                ret

inc_security:
                mov     si, inc_security_msg
                call    show_temp_message
                ret

inc_power:
                mov     si, inc_power_msg
                call    show_temp_message
                ret

; -----------------------------------------------------------------
; Уменьшение значения
; -----------------------------------------------------------------
decrease_value:
                ; Аналогично увеличению
                cmp     byte [current_selection], 1
                je      dec_time
                cmp     byte [current_selection], 2
                je      dec_advanced
                cmp     byte [current_selection], 3
                je      dec_security
                cmp     byte [current_selection], 4
                je      dec_power
                
                ret

dec_time:
                mov     si, dec_time_msg
                call    show_temp_message
                ret

dec_advanced:
                mov     si, dec_advanced_msg
                call    show_temp_message
                ret

dec_security:
                mov     si, dec_security_msg
                call    show_temp_message
                ret

dec_power:
                mov     si, dec_power_msg
                call    show_temp_message
                ret

; -----------------------------------------------------------------
; Вход в подменю
; -----------------------------------------------------------------
enter_submenu:
                ; Проверяем активный пункт
                cmp     byte [current_selection], 1
                je      enter_cmos_menu
                cmp     byte [current_selection], 2
                je      enter_advanced_menu
                cmp     byte [current_selection], 3
                je      enter_security_menu
                cmp     byte [current_selection], 4
                je      enter_power_menu
                cmp     byte [current_selection], 5
                je      enter_exit_menu
                
                ret

enter_cmos_menu:
                call    show_cmos_menu
                ret

enter_advanced_menu:
                call    show_advanced_menu
                ret

enter_security_menu:
                call    show_security_menu
                ret

enter_power_menu:
                call    show_power_menu
                ret

enter_exit_menu:
                call    show_exit_menu
                ret

; -----------------------------------------------------------------
; Показ меню CMOS Setup
; -----------------------------------------------------------------
show_cmos_menu:
                ; Сохраняем экран
                call    save_screen
                
                ; Очищаем область меню
                call    clear_menu_area
                
                ; Рисуем подменю
                mov     dh, 6
                mov     dl, 20
                call    set_cursor
                mov     si, cmos_menu_title
                call    print_string_color
                
                ; Пункты подменю
                mov     dh, 8
                mov     dl, 22
                call    set_cursor
                mov     si, cmos_date
                call    print_string
                
                mov     dh, 10
                mov     dl, 22
                call    set_cursor
                mov     si, cmos_time
                call    print_string
                
                mov     dh, 12
                mov     dl, 22
                call    set_cursor
                mov     si, cmos_disk
                call    print_string
                
                mov     dh, 14
                mov     dl, 22
                call    set_cursor
                mov     si, cmos_video
                call    print_string
                
                ; Кнопка возврата
                mov     dh, 16
                mov     dl, 22
                call    set_cursor
                mov     si, cmos_back
                call    print_string
                
                ; Ожидание Esc
                call    wait_for_esc
                
                ; Восстановление экрана
                call    restore_screen
                
                ret

; -----------------------------------------------------------------
; Сохранение экрана в буфер
; -----------------------------------------------------------------
save_screen:
                push    es
                push    di
                push    si
                push    cx
                
                ; Копируем видеопамять в буфер
                mov     ax, 0B800h
                mov     es, ax
                xor     di, di
                mov     si, screen_buffer
                mov     cx, 80*25
                
save_screen_loop:
                mov     ax, es:[di]
                mov     [si], ax
                add     di, 2
                add     si, 2
                loop    save_screen_loop
                
                pop     cx
                pop     si
                pop     di
                pop     es
                ret

; -----------------------------------------------------------------
; Восстановление экрана из буфера
; -----------------------------------------------------------------
restore_screen:
                push    es
                push    di
                push    si
                push    cx
                
                ; Копируем из буфера в видеопамять
                mov     ax, 0B800h
                mov     es, ax
                xor     di, di
                mov     si, screen_buffer
                mov     cx, 80*25
                
restore_screen_loop:
                mov     ax, [si]
                mov     es:[di], ax
                add     di, 2
                add     si, 2
                loop    restore_screen_loop
                
                pop     cx
                pop     si
                pop     di
                pop     es
                ret

; -----------------------------------------------------------------
; Очистка области меню
; -----------------------------------------------------------------
clear_menu_area:
                push    ax
                push    bx
                push    cx
                push    dx
                
                mov     ax, 0600h
                mov     bh, COLOR_BG
                mov     ch, 6
                mov     cl, 20
                mov     dh, 18
                mov     dl, 60
                int     10h
                
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; -----------------------------------------------------------------
; Ожидание нажатия Esc
; -----------------------------------------------------------------
wait_for_esc:
                mov     ah, 00h
                int     16h
                cmp     al, 1Bh
                jne     wait_for_esc
                ret

; -----------------------------------------------------------------
; Показ временного сообщения
; -----------------------------------------------------------------
show_temp_message:
                push    si
                push    dx
                
                ; Сохраняем позицию курсора
                mov     ah, 03h
                int     10h
                push    dx
                
                ; Показываем сообщение
                mov     dh, 20
                mov     dl, 10
                call    set_cursor
                pop     si
                call    print_string
                
                ; Ждем немного
                mov     cx, 0FFFFh
delay_loop:
                loop    delay_loop
                
                ; Восстанавливаем позицию курсора
                pop     dx
                push    dx
                call    set_cursor
                
                ; Очищаем сообщение
                mov     ax, 0600h
                mov     bh, COLOR_BG
                mov     ch, 20
                mov     cl, 10
                mov     dh, 20
                mov     dl, 70
                int     10h
                
                pop     dx
                pop     si
                ret

; -----------------------------------------------------------------
; Показ справки
; -----------------------------------------------------------------
show_help:
                call    save_screen
                call    clear_menu_area
                
                mov     dh, 6
                mov     dl, 25
                call    set_cursor
                mov     si, help_title
                call    print_string_color
                
                ; Текст справки
                mov     dh, 8
                mov     dl, 22
                call    set_cursor
                mov     si, help_text1
                call    print_string
                
                mov     dh, 10
                mov     dl, 22
                call    set_cursor
                mov     si, help_text2
                call    print_string
                
                mov     dh, 12
                mov     dl, 22
                call    set_cursor
                mov     si, help_text3
                call    print_string
                
                mov     dh, 14
                mov     dl, 22
                call    set_cursor
                mov     si, help_text4
                call    print_string
                
                mov     dh, 16
                mov     dl, 22
                call    set_cursor
                mov     si, help_text5
                call    print_string
                
                call    wait_for_esc
                call    restore_screen
                ret

; -----------------------------------------------------------------
; Переключение цветовой схемы
; -----------------------------------------------------------------
toggle_color_scheme:
                ; Переключение между синей и серой схемой
                cmp     byte [color_scheme], 0
                je      set_gray_scheme
                
                ; Устанавливаем синюю схему
                mov     byte [color_scheme], 0
                mov     bl, 10h
                jmp     apply_scheme
                
set_gray_scheme:
                ; Устанавливаем серую схему
                mov     byte [color_scheme], 1
                mov     bl, 70h
                
apply_scheme:
                ; Применяем цвет фона
                mov     ah, 0Bh
                mov     bh, 0
                int     10h
                
                ; Перерисовываем экран
                call    draw_main_screen
                
                ret

; -----------------------------------------------------------------
; Загрузка настроек по умолчанию
; -----------------------------------------------------------------
load_defaults:
                mov     si, defaults_msg
                call    show_temp_message
                ret

; -----------------------------------------------------------------
; Загрузка оптимизированных настроек
; -----------------------------------------------------------------
load_optimized:
                mov     si, optimized_msg
                call    show_temp_message
                ret

; -----------------------------------------------------------------
; Сохранение и выход
; -----------------------------------------------------------------
save_and_exit:
                ; Сохраняем изменения (заглушка)
                mov     si, save_msg
                call    show_temp_message
                
                ; Устанавливаем флаг выхода
                mov     byte [exit_flag], 1
                ret

; -----------------------------------------------------------------
; Выход без сохранения
; -----------------------------------------------------------------
exit_without_save:
                ; Подтверждение
                call    save_screen
                call    clear_menu_area
                
                mov     dh, 10
                mov     dl, 25
                call    set_cursor
                mov     si, exit_confirm
                call    print_string_color
                
                mov     dh, 12
                mov     dl, 30
                call    set_cursor
                mov     si, exit_prompt
                call    print_string
                
                ; Ожидание ответа
                mov     ah, 00h
                int     16h
                
                cmp     al, 'Y'
                je      do_exit
                cmp     al, 'y'
                je      do_exit
                
                ; Отмена
                call    restore_screen
                ret
                
do_exit:
                mov     byte [exit_flag], 1
                call    restore_screen
                ret

; -----------------------------------------------------------------
; Остальные подменю (заглушки)
; -----------------------------------------------------------------
show_advanced_menu:
show_security_menu:
show_power_menu:
show_exit_menu:
                ; Просто показываем сообщение
                mov     si, coming_soon
                call    show_temp_message
                ret

; -----------------------------------------------------------------
; Данные и строки
; -----------------------------------------------------------------

; Границы и заголовки
border_top      db      'г==============================================================================¬', 0
title_line1     db      '¦                     МС-1502 BIOS SETUP UTILITY                        ¦', 0
title_line2     db      '¦                      (C) 1991 НПО "Электронмаш"                        ¦', 0
version_info    db      'Версия 1.00', 0

; Главное меню
menu_standard   db      '   Standard CMOS Features', 0
menu_advanced   db      '   Advanced BIOS Features', 0
menu_security   db      '   Security', 0
menu_power      db      '   Power Management Setup', 0
menu_exit       db      '   Exit Setup', 0

; Выделенные пункты меню
menu_standard_sel db    ' ? Standard CMOS Features', 0
menu_advanced_sel db    ' ? Advanced BIOS Features', 0
menu_security_sel db    ' ? Security', 0
menu_power_sel   db     ' ? Power Management Setup', 0
menu_exit_sel    db     ' ? Exit Setup', 0

; Информация о системе
sysinfo_title   db      'г===================¬', 0
cpu_info        db      'CPU:               ', 0
mem_info        db      'Memory:            ', 0
disk_info       db      'Disk Drives:       ', 0
video_info      db      'Video:             ', 0

; Нижняя панель
help_line       db      '================================================================================', 0
shortcuts       db      'F1=Help  F2=Color  F5=Defaults  F6