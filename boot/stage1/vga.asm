bits    16


; Parameters:
;       DS:SI   Pointer to the string to be printed.
write_string:
        push    ax
        push    si

        mov     ah, 0x0E

.write_next_char:
        lodsb
        cmp     al, 0x00
        je      .exit

        int     0x10
        jmp     .write_next_char

.exit:
        pop     si
        pop     ax
        ret


; Parameters:
;       DS:SI   Pointer to the error message string to be printed.
write_error:
        push    si

        push    si
        mov     si, .error_msg
        call    write_string
        pop     si

        call    write_string

        pop     si
        ret

.error_msg:             db      "Error: ", 0x00
