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

        ; Enable the A20 line.
        call    enable_a20_line
        jnc     .a20_enabled

        mov     si, a20_disabled_msg
        call    write_error
        cli
        hlt

.a20_enabled:
        mov     si, a20_enabled_msg
        call    write_string

        ; Enter the Unreal Mode.
        cli

        call    disable_nmi

        lgdt    [gdt_pointer]

        mov     eax, cr0 
        or      eax, 1
        mov     cr0, eax

        jmp     0x0008:.temporary_protected_mode

.temporary_protected_mode:
        mov     ax, 0x10
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     eax, cr0
        and     eax, ~1
        mov     cr0, eax

        jmp     0x00:.enter_unreal_mode

.enter_unreal_mode:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     si, entered_unreal_mode_msg
        call    write_string

        ; TODO: Load the rest of the bootloader.

        cli
        hlt


os_name_version_msg     db      "Hikari OS v0.1.0-dev", 0x0A, 0x0D, 0x00
a20_disabled_msg        db      "Failed to enable the A20 line.", 0x0A, 0x0D, 0x00
a20_enabled_msg         db      "Status: Enabled the A20 line.", 0x0A, 0x0D, 0x00
entered_unreal_mode_msg db      "Status: Entered the Unreal Mode.", 0x0A, 0x0D, 0x00


%include        "boot/stage1/vga.asm"
%include        "boot/stage2/a20.asm"
%include        "boot/stage2/gdt.asm"
%include        "boot/stage2/keyboard.asm"
%include        "boot/stage2/nmi.asm"


times   512 - ($ - $$)  db      0x00
