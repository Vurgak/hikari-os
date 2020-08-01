bits    16


; Read the specified number of sectors from a disk into the memory.
;
; Parameters:
;       EBX:EAX First sector index.
;       CX      Number of sectors to read.
;       DS:DI   Pointer to the target buffer.
;
; Returns:
;       CF      Clear on sucess; set on error.
read_sectors_from_disk:
        push    ax
        push    si

        mov     [disk_address_packet.sector_count], cx
        mov     [disk_address_packet.buffer_offset], di
        mov     [disk_address_packet.buffer_segment], ds
        mov     [disk_address_packet.first_sector + 0], eax
        mov     [disk_address_packet.first_sector + 4], ebx

        mov     ah, 0x42
        mov     si, disk_address_packet
        int     0x13

        pop     si
        pop     ax
        ret


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


disk_address_packet:
.size:                  db      0x10
.padding:               db      0x00
.sector_count:          dw      0x0000
.buffer_offset:         dw      0x0000
.buffer_segment:        dw      0x0000
.first_sector:          dq      0x00
