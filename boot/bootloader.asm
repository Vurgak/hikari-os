org     0x7C00

stage1:
        ; Clear the screen by setting the 80x25 text mode.
        mov     ah, 0x00
        mov     al, 0x03
        int     0x10

        ; Load the 8x8 font (this gives us the 80x50 text mode).
        mov     ax, 0x1112
        mov     bl, 0x00
        int     0x10

        mov     si, os_name_version_msg
        call    write_string

        cli
        hlt

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

os_name_version_msg     db      "Hikari OS v0.1.0-dev", 0x0A, 0x0D, 0x00

times   512 - ($ - $$)  db      0x00
