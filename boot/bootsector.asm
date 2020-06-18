org     0x7C00
bits    16

bootsector:
        mov     ah, 0x00
        mov     al, 0x03
        int     0x10

        mov     ax, 0x1112
        int     0x10

        mov     ah, 0x0E
        mov     si, os_name_version_msg

.write_next_char:
        lodsb
        cmp     al, 0x00
        je      .exit

        int     0x10
        jmp     .write_next_char

.exit:
        cli
        hlt

os_name_version_msg     db      "Hikari OS v0.1.0-dev", 0x0A, 0x0D, 0x00

times   510 - ($ - $$)  db      0x00

bootable_signature:     db      0x55, 0xAA
