;---------------------------------------------------------------------------------------------------
; Прерывание 08h - IRQ0 (Таймер)
;---------------------------------------------------------------------------------------------------
proc        int_08h near
                push    ds                      ; Сохранить сегмент данных
                push    ax                      ; Сохранить регистры
                push    dx
                mov     ax, BDAseg              ; Сегмент области данных BIOS (0040h)
                mov     ds, ax                  ; Установить DS на BDA
                assume ds:nothing
                xor     ax, ax                  ; AX = 0
                inc     [word ptr ds:timer_low_] ; Увеличить младшее слово счетчика таймера
                jnz     short timer_low_no_overflow ; Если не переполнилось, перейти
                inc     [word ptr ds:timer_hi_] ; Увеличить старшее слово счетчика таймера

timer_low_no_overflow:
                cmp     [word ptr ds:timer_hi_], 18h ; Сравнить старшую часть с 18h (24)
                jnz     short check_motor_timer ; Если не равно, перейти к проверке мотора
                cmp     [word ptr ds:timer_low_], 0B0h ; Сравнить младшую часть с B0h (176)
                jnz     short check_motor_timer ; Если не равно, перейти к проверке мотора
                mov     [ds:timer_hi_], ax      ; Сбросить старшее слово счетчика (AX=0)
                mov     [ds:timer_low_], ax     ; Сбросить младшее слово счетчика
                mov     [byte ptr ds:timer_rolled_], 1 ; Установить флаг переполнения суток

check_motor_timer:
                inc     ax                      ; AX = 1 (для управления мотором)
                dec     [byte ptr ds:dsk_motor_tmr] ; Уменьшить таймер мотора дисковода
                jnz     short call_user_timer   ; Если не 0, перейти к пользовательскому таймеру
                and     [byte ptr ds:dsk_motor_stat], 0FCh ; Сбросить биты моторов (остановить)
                call    get_drive_and_head      ; Получить параметры для управления дисководом
                mov     dl, [ds:dsk_status_2]   ; Порт управления дисководом (3F2h)
                out     dx, al                  ; Выключить мотор (AL=1 или другая маска)

call_user_timer:
                int     1Ch                     ; Вызвать пользовательское прерывание таймера
                mov     al, 20h                 ; Команда End Of Interrupt
                out     20h, al                 ; Отправить в контроллер прерываний 8259A
                pop     dx                      ; Восстановить регистры
                pop     ax
                pop     ds
                assume ds:nothing
                iret                            ; Возврат из прерывания
endp        int_08h