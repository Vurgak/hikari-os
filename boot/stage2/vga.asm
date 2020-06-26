bits    16


write_status:
        push    si

        push    si
        mov     si, .msg
        call    write_string
        pop     si

        call    write_string

        pop     si
        ret

.msg            db      "[  STATUS ] ", 0x00


write_warning:
        push    si

        push    si
        mov     si, .msg
        call    write_string
        pop     si

        call    write_string

        pop     si
        ret

.msg            db      "[ WARNING ] ", 0x00
