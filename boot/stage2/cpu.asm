bits    16


; Check whether the CPU supports the CPUID supplementary capability.
;
; Returns:
;       CF      Clear if CPUID is supported by the CPU; false if it isn't.
is_cpuid_supported:
        push    eax

        ; How this algorithm works:
        ; Attempt to flip the ID bit in the EFLAGS register. If it remains flipped
        ; after reloading the register, the CPUID is supported by the CPU.

        ; Copy EFLAGS to EAX via the stack.
        pushfd
        pop     eax

        ; Flip the ID bit.
        xor     eax, 1 << 21

        ; Copy EAX to EFLAGS via the stack.
        push    eax
        popfd

        ; Copy EFLAGS back to EAX.
        pushfd
        pop     eax

        ; Check if the ID bit remains flipped.
        and     eax, 1 << 21

        clc

        ; If the ID bit was flipped.
        jnz     .exit

        stc

.exit:
        pop     eax
        ret


is_long_mode_supported:
        push    eax
        push    ecx
        push    edx

        ; Get Highest Extended Function implemented.
        mov     eax, 0x80000000
        cpuid
        cmp     eax, 0x80000000
        jb      .not_supported

        ; Get Extended Processor Info and Feature Bits.
        mov     eax, 0x80000001
        cpuid
        test    edx, 1 << 29
        jz      .not_supported

        clc
        jmp     .exit

.not_supported:
        stc
        
.exit:
        pop     edx
        pop     ecx
        pop     eax
        ret
