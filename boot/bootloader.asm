org     0x7C00


hikari_fs_header:
.jump_to_code:          db      0xEB, 0x1A
.signature:             db      "HkFS"
.version:               dw      0x0001
.block_count:           dq      0
.bytes_per_block:       dd      0
.reserved_blocks:       dd      0
.main_directory_blocks: dd      0


stage1:
        mov     [drive_number], dl
        mov     [partition_number], dh

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

        ; Load the Stage2 of the bootloader.

        ; Calculate the number of sectors per block.
        xor     edx, edx
        mov     eax, [hikari_fs_header.bytes_per_block]
        mov     ebx, bytes_per_sector
        div     ebx

        ; Calculate the amount of reserved sectors.
        mov     ebx, [hikari_fs_header.reserved_blocks]
        mul     ebx

        ; First sector is already loaded, so skip it.
        dec     eax

        ; Load the rest of reserved sectors.
        mov     ebx, edx
        mov     cx, ax
        mov     eax, 1
        mov     dl, [drive_number]
        mov     dh, [partition_number]
        mov     di, stage2
        xchg    bx, bx
        call    read_sectors_from_partition

        mov     eax, 0x12345678

        jmp     stage2


bytes_per_sector        equ     512

os_name_version_msg     db      "Hikari OS v0.1.0-dev", 0x0A, 0x0A, 0x0D, 0x00


drive_number            db      0x00
partition_number        db      0x00


%include        "boot/stage1/vga.asm"
%include        "boot/stage1/disk.asm"
%include        "boot/stage2/disk.asm"
%include        "boot/stage2/gdt.asm"
%include        "boot/stage2/keyboard.asm"
%include        "boot/stage2/nmi.asm"
%include        "boot/stage2/partition.asm"


times   512 - ($ - $$)  db      0x00


stage2:
        mov     si, loaded_stage2_msg
        call    write_status

        ; Enable the A20 line.
        call    enable_a20_line
        jnc     .a20_enabled

        mov     si, a20_disabled_msg
        call    write_error
        cli
        hlt

.a20_enabled:
        mov     si, a20_enabled_msg
        call    write_status

        mov     si, everything_works_msg
        call    write_status

        cli
        hlt


loaded_stage2_msg       db      "Loaded the Stage2.", 0x0A, 0x0D, 0x00
a20_enabled_msg         db      "Enabled the A20 line.", 0x0A, 0x0D, 0x00
a20_disabled_msg        db      "Failed to enable the A20 line.", 0x0A, 0x0D, 0x00
everything_works_msg    db      "Everything works!", 0x0A, 0x0D, 0x00


%include        "boot/stage2/a20.asm"
%include        "boot/stage2/vga.asm"


align   4, db 0x00
sector_buffer:          times   512     db      0x00


times   4096 * 4        db      0x00
