section .multiboot_header
header_start:
    dd 0xe85250d6                ; magic number
    dd 0                         ; architecture 0 (protected mode i386)
    dd header_end - header_start ; header length
    ; checksum - the 0x100000000 is apparently a compiler silencing hack
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    ; insert optional multiboot tags here (there aren't many more)

    ; required end tag
    dw 0    ; type
    dw 0    ; flags
    dw 8    ; size
header_end: