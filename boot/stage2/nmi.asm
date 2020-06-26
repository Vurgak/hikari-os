bits    16


enable_nmi:
        push    ax

        in      al, 0x70
        and     al, 0b01111111
        out     0x70, al

        pop     ax
        ret


disable_nmi:
        push    ax
        
        in      al, 0x70
        or      al, 0b10000000
        out     0x70, al
        
        pop     ax
        ret
