bits    16


; Load a file from a Hikari FS formatted partition into the specified memory address.
;
; Note:
;       Currently only loading from the main directory is supported.
;
; Note:
;       This procedure should be run only while the CPU is running in Unreal Mode.
;
; Parameters:
;       DL      Drive number.
;       DH      Partition number.
;       ESI     Pointer to the NULL-terminated file name string.
;       EDI     Destination buffer.
;
; Returns:
;       CF      Clear if the file was loaded successfully; set if there were any errors.
hkfs_load_file:
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    ebp
        push    esi
        push    edi

        mov     [.old_stack], sp
        
        mov     [.disk_and_partiton], dx

        mov     eax, .block_count_low_disk_offset
        call    read_dword_from_partition
        push    eax

        mov     eax, .block_count_high_disk_offset
        call    read_dword_from_partition
        push    eax

        mov     eax, .bytes_per_block_disk_offset
        call    read_dword_from_partition
        push    eax

        mov     eax, .reserved_blocks_disk_offset
        call    read_dword_from_partition
        push    eax

        ; Calculate the length of the file allocation table (in blocks, not bytes)
        ; using the formula:
        ; (block_count * sizeof(uint64) + bytes_per_block - 1) / bytes_per_block
        ; Result is located in the EAX register.
        mov     eax, [esp + .block_count_low_stack_offset]
        mov     edx, [esp + .block_count_high_stack_offset]
        mov     ebx, .fat_entry_size
        mul     ebx
        add     eax, [esp + .bytes_per_block_stack_offset]
        adc     edx, 0
        sub     eax, 1
        sbb     edx, 0
        mov     ebx, [esp + .bytes_per_block_stack_offset]
        div     ebx

        ; Calculate the offset of the main directory in blocks. It starts
        ; immediately after reserved sectors and file allocation table.
        add     eax, [esp + .reserved_blocks_stack_offset]
        adc     edx, 0

        ; Calculate the offset of the main directory in bytes.
        mov     ebx, [esp + .bytes_per_block_stack_offset]
        xor     ecx, ecx
        mul     ebx
        mov     ebx, edx

        ; EBX:EAX points to the first main directory entry.

.main_directory_loop:
        ; TODO: Currently we just load the first main directory entry.
        
        ; push    eax
        ; push    edi

        ; Check if the entry has correct name.
        ; mov     ebp, eax                ; Get the length of the entry.
        ; push    dx
        ; mov     dx, [.disk_and_partiton]
        ; call    read_byte_from_partition
        ; pop     dx
        ; movzx   ecx, al                 ; Get the length of the entry name in ECX.
        ; sub     ecx, 48
        ; mov     edi, eax                ; Set EDI to the 'entry.name' field.
        ; add     edi, 48
        ; call    str_n_compare

        ; pop     edi
        ; pop     edx

        clc

        jnc     .load_entry_content
        jmp     .not_loaded

.load_entry_content:
        ; TODO: Currently we only load the first block of a file. Load the rest.

        ; Read the 'first_block' field.
        add     eax, 40
        mov     ebp, eax
        mov     dx, [.disk_and_partiton]
        call    read_dword_from_partition
        mov     [.first_block_low_bytes], eax
        mov     eax, ebp
        add     eax, 4
        call    read_dword_from_partition
        mov     [.first_block_high_bytes], eax

        ; Calculate the number of sectors per block.
        xor     edx, edx
        mov     eax, [esp + .bytes_per_block_stack_offset]
        mov     ebx, bytes_per_sector
        div     ebx
        mov     ebx, eax

        mov     eax, [.first_block_low_bytes]
        mov     edx, [.first_block_high_bytes]

        xor     ecx, ecx
        call    mul64

        mov     ecx, ebx

        ; Calculate the offset of file allocation table.
        ; mov     eax, [esp + .reserved_blocks_stack_offset]
        ; mul     ebx

.load_and_relocate_sector_loop:
        push    ecx
        
        push    di

        mov     ebx, edx
        mov     cx, 1
        mov     dx, [.disk_and_partiton]
        mov     di, sector_buffer
        call    read_sectors_from_partition
        jc      .not_loaded

        pop     di

        mov     esi, sector_buffer
        mov     ecx, bytes_per_sector
        rep a32 movsb

        pop     ecx
        dec     ecx
        cmp     ecx, 0
        je      .loaded

        jmp     .load_and_relocate_sector_loop

.not_loaded:
        stc
        jmp     .exit

.loaded:
        clc

.exit:
        mov     sp, [.old_stack]

        pop     edi
        pop     esi
        pop     ebp
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret

.old_stack              dw      0
.disk_and_partiton      dw      0

.fat_offset             dq      0
.first_block_low_bytes  dd      0
.first_block_high_bytes dd      0
.sectors_per_block      dd      0

.block_count_low_disk_offset    equ     8
.block_count_high_disk_offset   equ     12
.bytes_per_block_disk_offset    equ     16
.reserved_blocks_disk_offset    equ     20

.block_count_low_stack_offset   equ     12
.block_count_high_stack_offset  equ     8
.bytes_per_block_stack_offset   equ     4
.reserved_blocks_stack_offset   equ     0

.fat_entry_size         equ     8
