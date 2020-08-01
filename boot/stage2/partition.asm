bits    16


; Read a byte value from a partition.
;
; Parameters:
;       EBX:EAX Address of the dword to read.
;       DL      Drive number.
;       DH      Partition number.
;
; Returns:
;       AL      Readen value.
;       CF      Clear on success; set on error.
read_byte_from_partition:
        push    ebx
        push    ebp
        push    esi

        ; Find the partition start sector index.
        mov     ebp, eax
        mov     esi, ebx
        push    ebx
        push    edx

        movzx   eax, dh
        mov     ebx, partition_entry_size
        mul     ebx
        add     eax, partition_table_offset + 8 ; Points to 'lba_first_sector' field.

        pop     edx
        pop     ebx
        call    read_dword_from_disk

        push    ebx
        push    edx
        
        xor     edx, edx
        mov     ebx, bytes_per_sector
        mul     ebx
        mov     ebx, edx

        pop     edx
        pop     ebx

        add     eax, ebp
        adc     ebx, esi
        call    read_byte_from_disk

        pop     esi
        pop     ebp
        pop     ebx
        ret
