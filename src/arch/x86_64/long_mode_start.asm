global long_mode_start

section .text
bits 64
long_mode_start:
	; this file takes advantage of 64 bit code - much cleaner and terser

	; load 0 into all data segment registers
	; ensures that there's valid data in these segments
	mov ax, 0
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; print "OKAY" to the screen
	mov rax, 0x2f592f412f4b2f4f
	mov qword [0xb8000], rax
	hlt