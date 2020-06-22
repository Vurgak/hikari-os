bits    16


enable_a20_line:
        call    is_a20_enabled
        jc      .enable_using_bios
        ret

.enable_using_bios:
        mov     ax, 2401
        int     0x15

        call    is_a20_enabled
        jc      .enable_using_keyboard_controller
        ret

.enable_using_keyboard_controller:
        cli

        call    wait_for_keyboard_input_ready
        mov     al, 0xAD
        out     0x64, al

        call    wait_for_keyboard_output_ready
        in      al, 0x60
        push    ax

        call    wait_for_keyboard_input_ready
        mov     al, 0xD1
        out     0x64, al

        call    wait_for_keyboard_input_ready
        pop     ax
        or      al, 1 << 1
        out     0x60, al

        call    wait_for_keyboard_input_ready
        
        sti

        call    is_a20_enabled
        jc      .enable_using_fast_gate
        ret

.enable_using_fast_gate:
        in      al, 0x92
        or      al, 1 << 1
        out     0x92, al

        call    is_a20_enabled
        jc      .enable_using_port_ee
        ret

.enable_using_port_ee:
        push    ax
        in      al, 0xEE
        pop     ax

        call    is_a20_enabled
        ret


is_a20_enabled:
        push    ax
        push    ds

        mov     ax, 0xFFFF
        mov     ds, ax
        mov     byte [ds:0x0510], 0xFF

        xor     ax, ax
        mov     ds, ax
        cmp     byte [ds:0x0500], 0xFF
        
        clc

        jne     .exit

        stc

.exit:
        pop     ds
        pop     ax
        ret
