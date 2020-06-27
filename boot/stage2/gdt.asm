bits    16


align   8, db 0x00
gdt:
.null_descriptor        dq      0x0000000000000000
.unreal_code_descriptor dq      0x008F9A000000FFFF
.unreal_data_descriptor dq      0x008F92000000FFFF
.prot32_code_descriptor dq      0x00CF9A000000FFFF
.prot32_data_descriptor dq      0x00CF92000000FFFF
.long64_code_descriptor dq      0x00209A0000000000
.long64_data_descriptor dq      0x0000920000000000
.end:


align   8, db 0x00
gdt_pointer:
.size:                  dw      gdt.end - gdt
.address:               dq      gdt
