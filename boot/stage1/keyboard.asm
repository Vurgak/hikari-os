wait_for_keyboard_input_ready:
        push    ax
        
        in      al, 0x64
        test    al, 1 << 1
        jnz     wait_for_keyboard_input_ready
        
        pop    ax
        ret

wait_for_keyboard_output_ready:
        push    ax
        
        in      al, 0x64
        test    al, 1
        jnz     wait_for_keyboard_output_ready
        
        pop    ax
        ret
