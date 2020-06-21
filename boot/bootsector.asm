org     0x7A00


bits    16


bootsector:
        ; Make sure that segment registers are all set to zero.
        mov     ax, 0x0000
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        ; Initialize the stack pointer with a memory region that we are not
        ; going to use.
        mov     sp, 0x7A00

        ; Relocate the bootsector to 0x7A00.
        mov     si, 0x7C00
        mov     di, 0x7A00
        mov     cx, 0x0100
        rep     movsw

        ; Jump to the relocated code.
        jmp     0x0000:.relocated_code

.relocated_code:
        ; Find the first active partition.
        mov     bx, partition_table.fst_status
        mov     cl, 0

.check_next_partition_entry:
        mov     al, [bx]
        and     al, 0b10000000
        jnz     .boot_active_partition

        add     bx, partition_entry_size
        inc     cl
        cmp     cl, 4
        jnz     .check_next_partition_entry

        ; No active partition found; print error.
        mov     si, no_bootable_partition_msg
        call    write_error
        cli
        hlt

.boot_active_partition:
        add     bx, 8                   ; Move the pointer to the 'first_sector' field.
        mov     eax, [bx]
        mov     [disk_address_packet.first_sector], eax
        
        mov     ah, 0x42
        mov     si, disk_address_packet
        int     0x13
        jnc     .jump_to_loaded_code

        mov     si, disk_read_failure_msg
        call    write_error
        cli
        hlt

.jump_to_loaded_code:
        jmp     0x0000:0x7C00


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
        mov     si, error_msg
        call    write_string
        pop     si

        call    write_string

        pop     si
        ret


partition_entry_size    equ     16

error_msg               db      "Error: ", 0x00
no_bootable_partition_msg db    "No bootable partition was found.", 0x00
disk_read_failure_msg   db      "Failed to load the active partition.", 0x00


disk_address_packet:
.size:                  db      0x10
.padding:               db      0x00
.sector_count:          dw      0x0001
.buffer_offset:         dw      0x7C00
.buffer_segment:        dw      0x0000
.first_sector:          dq      0x00


times   446 - ($ - $$)  db      0x00


partition_table:
.fst_status:            db      0
.fst_chs_first_sector:  db      0, 0, 0
.fst_partition_type:    db      0
.fst_chs_last_sector:   db      0, 0, 0
.fst_lba_first_sector:  dd      0
.fst_sector_count:      dd      0
.snd_status:            db      0
.snd_chs_first_sector:  db      0, 0, 0
.snd_partition_type:    db      0
.snd_chs_last_sector:   db      0, 0, 0
.snd_lba_first_sector:  dd      0
.snd_sector_count:      dd      0
.trd_status:            db      0
.trd_chs_first_sector:  db      0, 0, 0
.trd_partition_type:    db      0
.trd_chs_last_sector:   db      0, 0, 0
.trd_lba_first_sector:  dd      0
.trd_sector_count:      dd      0
.fth_status:            db      0
.fth_chs_first_sector:  db      0, 0, 0
.fth_partition_type:    db      0
.fth_chs_last_sector:   db      0, 0, 0
.fth_lba_first_sector:  dd      0
.fth_sector_count:      dd      0


bootable_signature:     db      0x55, 0xAA
