bits    32


initialize_paging_and_enable_long_mode:
        push    eax
        push    ecx

        call    initialize_page_tables

        ; Load CR3 with the address of the PML4.
        mov     eax, pml4_offset
        mov     cr3, eax

        ; Set the PAE (Physical Address Extension) the in CR0.
        mov     eax, cr4
        or      eax, 1 << 5
        mov     cr4, eax

        ; Set the LM (Long Mode) bit in EFER MSR.
        mov     ecx, 0xC0000080
        rdmsr
        or      eax, 1 << 8
        wrmsr

        ; Set the PG (Paging) bit in CR0.
        mov     eax, cr0
        or      eax, 1 << 31
        mov     cr0, eax

        pop     ecx
        pop     eax
        ret


initialize_page_tables:
        push    eax
        push    ecx

        ; Map the first PML4 entry to the PML3 table.
        mov     eax, pml3_offset
        or      eax, 0b00000011         ; Present + writable.
        mov     [pml4_offset], eax

        ; Map the first PML3 entry to the PML2 table.
        mov     eax, pml2_offset
        or      eax, 0b00000011         ; Present + writable.
        mov     [pml3_offset], eax

        ; Map each PML2 table entry to huge 2 MiB page.
        mov     ecx, 0

.map_pml2_entry:
        mov     eax, 0x200000
        mul     ecx
        or      eax, 0b10000011         ; Present + writable + huge.
        mov     [pml2_offset + ecx * 8], eax

        inc     ecx
        cmp     ecx, page_entry_count
        jne     .map_pml2_entry

        pop     ecx
        pop     eax
        ret

; Use an unused memory region instead of having to reserve 3 * 4096 of bytes
; in the image.
pml4_offset             equ     0x1000
pml3_offset             equ     0x2000
pml2_offset             equ     0x3000

page_entry_count        equ     512
