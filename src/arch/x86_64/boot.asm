global start
extern long_mode_start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call set_up_page_tables
    call enable_paging
    call set_up_SSE

    ; load the 64-bit GDT
    lgdt [gdt64.pointer]

    jmp gdt64.code:long_mode_start

error:
    ; Prints 'ERR: ' and the error code to screen and then hangs
    ; parameter: error code in ascii
    mov dword [0xb8000], 0x4f524f45 ; screen char consists of 2 parts: colour code (4f) and char code (52)
    mov dword [0xb8004], 0x4f3a4f52 ; 4f is white, 52 is an 'R', and all is read right to left per row
    mov dword [0xb8008], 0x4f204f20 ; sequence, from top, is literally: {'R', 'E'}, {':', 'R'}, {' ', ' '}
    mov byte  [0xb800a], al
    hlt

; ---- Functions ----

check_multiboot:
    cmp eax, 0x36d76289 ; cmp = compare. EAX is a reserved register. The magic number 0x36d76289 must be written here before loading kernel.
    jne .no_multiboot ; jne = jump if not equal (in this case jump to .no_multiboot)
    ret
.no_multiboot:
    mov al, "0" ; moves the value "0" to the error function
    jmp error ; jmp = jump to

check_cpuid:
    ; CPUID is an instruction to get a bunch of info about the CPU
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via stack
    push eax
    popfd

    ; Copy FLAGS back to EAX again (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the 
    ; ID back if it was ever flipped)
    push ecx
    popfd

    ; Compare EAX to ECX. If they are equal it means the bit wasn't flipped
    ; and CPUID is not supported
    cmp ecx, eax
    je .no_cpuid ; je - jump if equal
    ret
.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    ; check if extended processor info is available
    mov eax, 0x80000000     ; EAX is an implicit argument to cpuid function (because it's weird)
    cpuid                   ; get highest supported argument (which is what cpuid function returns)
    cmp eax, 0x80000001     ; it needs to be at least 0x80000001 (old processors don't even know this argument)
    jb .no_long_mode        ; jb - jump if below. If it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001     ; argument for extended processor info
    cpuid                   ; returns various feature bits in ECX and EDX
    test edx, 1 << 29       ; test if the LM-bit (29) is set in the D-register (EDX)
    jz .no_long_mode        ; if it's not set then there's no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error

set_up_page_tables:
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11 ; present and writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11
    mov [p3_table], eax

    ; map each P2 entry to a huge 2MiB page
    mov ecx, 0
.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000       ; 2MiB
    mul eax                 ; start address of ecx-th page
    or eax, 0b10000011      ; present and writable and huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx                 ; increase counter
    cmp ecx, 512            ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table

    ret

enable_paging:
    ; load P4 to cr3 register (CPU uses this to access the P4 table)
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE-flag in cr4 (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

; Check for SSE and enable it. If there's no support throw the error "a"
set_up_SSE:
    ; check for SSE
    mov eax, 0x1
    cpuid
    test edx, 1<<25
    jz .no_SSE

    ; enable SSE
    mov eax, cr0
    and ax, 0xFFFB  ; clear coprocessor emulation CR0.EM
    or ax, 0x2      ; set coprocessor monitoring CR0.MP
    mov cr0, eax
    mov eax, cr4
    or ax, 3 << 9
    mov cr4, eax

    ret
.no_SSE
    mov al, "a"
    jmp error


section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64 ; new
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64


section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:

