bits    16

; Read a double-word value from a disk.
;
; Parameters:
;       EBX:EAX Address of the dword to read.
;       DL      Drive number.
;
; Returns:
;       EAX     Readen value.
;       CF      Clear on success; set on error.
read_dword_from_disk:
        push    ebx
        push    ecx
        push    ebp
        push    di

        ; Find the sector on which the value is located.
        push    edx
        mov     edx, ebx
        mov     ebx, bytes_per_sector
        div     ebx
        mov     ebp, edx                ; ECX contains the offset of the value on a sector.
        pop     edx

        xor     ebx, ebx
        mov     cx, 1
        mov     di, sector_buffer
        call    read_sectors_from_disk
        
        mov     eax, [sector_buffer + ebp]

        pop     di
        pop     ebp
        pop     ecx
        pop     ebx
        ret
