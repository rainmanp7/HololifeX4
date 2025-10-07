; test_entry.asm - Pure assembly test (no Ada)
[bits 32]
[global _start]

section .text
_start:
    ; Set up stack
    mov esp, 0x90000
    mov ebp, esp
    cld
    
    ; Clear screen
    mov edi, 0xb8000
    mov ecx, 80*25
    mov ax, 0x0F20  ; White space on black
    rep stosw
    
    ; Write success message
    mov edi, 0xb8000
    mov esi, success_msg
    call print_string
    
    ; Hang
hang:
    cli
    hlt
    jmp hang

print_string:
    mov ah, 0x0F  ; White on black
.print_loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .print_loop
.done:
    ret

success_msg: db 'BOOTLOADER OK - Assembly Entry Reached!', 0