bits    16

; Multiply two unsigned 64-bit numbers to obtain an unsigned 64-bit result.
;
; Note:
;       This function does not take overflows into consideration.
;
; Parameters:
;       EDX:EAX Multiplier.
;       ECX:EBX Multiplicand.
;
; Return:
;       EDX:EAX Product.
mul64:
        push    ebx
        push    ecx
        push    esi
        push    edi

        mov     esi, eax
        mov     edi, edx

        mov     eax, edi
        mul     ebx
        xchg    eax, ebx        ; Upper 32 bits of the product (partial).
        mul     esi
        xchg    esi, eax        ; Lower 32 bits of the product. 
        add     ebx, edx
        mul     ecx
        add     ebx, eax        ; Upper 32 bits of the product.

        mov     eax, esi        ; Result in EDX:EAX.
        mov     edx, ebx

        pop     edi
        pop     esi
        pop     ecx
        pop     ebx
        ret
