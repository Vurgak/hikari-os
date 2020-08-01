bits    16


; Compares two NULL-terminated byte strings.
;
; Parameters:
;       DS:SI   Pointer to the first NULL-terminated byte string.
;       DS:DI   Pointer to the second NULL-terminated byte string.
;
; Returns:
;       CF      Clear if the string are the same; set if they are different.
str_compare:
        push    eax
        push    ebx
        push    esi
        push    edi

        call    str_length              ; Check the length of the strings; if
        mov     ebx, eax                ; they are different, then the strings
        xchg    esi, edi                ; are different too.
        call    str_length
        cmp     eax, ebx
        jne     .not_equal
        
        mov     ecx, eax                ; Preserve the length of the strings.

.loop:
        lodsb                           ; Load a character from the first string.

        mov     ah, [di]                ; Load a character from the second string.
        inc     di

        cmp     al, ah                  ; Compare characters to each other.
        jne     .not_equal

        dec     ecx                     ; Check if there are any characters left
        cmp     ecx, 0                  ; in the strings to compare.
        je      .exit

        jmp     .loop

.equal:
        clc
        jmp     .exit

.not_equal:
        stc

.exit:
        pop     edi
        pop     esi
        pop     ebx
        pop     eax
        ret


; Compares up to n characters of two possibly NULL-terminated byte strings.
;
; Parameters:
;       ECX     Maximum number of characters to compare.
;       DS:SI   Pointer to the first possibly NULL-terminated byte string.
;       DS:DI   Pointer to the second possibly NULL-terminated byte string.
;
; Returns:
;       CF      Clear if the string are the same; set if they are different.
str_n_compare:
        push    ecx
        push    si
        push    di

.loop:
        lodsb                           ; Load a character from the first string.

        mov     ah, [di]                ; Load a character from the second string.
        inc     di

        cmp     al, ah                  ; Check if the characters are equal.
        jne     .not_equal

        cmp     al, ascii_null          ; Check if the current character
        je      .equal                  ; is ASCII NULL 0x00.

        dec     ecx                     ; Check if there are any characters left
        cmp     ecx, 0                  ; to compare.
        je      .equal

        jmp     .loop

.not_equal:
        stc
        jmp     .exit

.equal:
        clc

.exit:
        pop     di
        pop     si
        pop     ecx
        ret


; Gets the length of a NULL-terminated byte string.
;
; Parameters:
;       DS:SI   Pointer to a NULL-terminated byte string.
;
; Returns:
;       EAX     Length of a NULL-terminated byte string.
str_length:
        push    ecx
        push    si

        xor     ecx, ecx

.loop:
        lodsb
        cmp     al, ascii_null
        jz      .exit

        inc     ecx
        jmp     .loop

.exit:
        mov     eax, ecx

        pop     si
        pop     ecx
        ret


ascii_null              equ     0x00
