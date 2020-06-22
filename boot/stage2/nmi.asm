bits    16


disable_nmi:
        push    ax
        
        in      al, 0x70
        or      al, 0x80
        out     0x70, al
        
        pop     ax
        ret
