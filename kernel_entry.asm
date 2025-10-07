; kernel_entry.asm - Entry point for Pure Ada Kernel
[bits 32]
[global _start]
[extern _ada_boot]

section .text
_start:
    ; Set up stack
    mov esp, 0x90000
    mov ebp, esp
    
    ; Clear direction flag
    cld
    
    ; Write "STEP 1" to VGA
    mov edi, 0xb8000
    mov esi, step1_msg
    call print_string
    
    ; Call Ada kernel
    call _ada_boot
    
    ; If we get here, Ada returned
    mov edi, 0xb8000 + 160  ; Second line
    mov esi, ada_returned_msg
    call print_string
    
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

step1_msg: db 'STEP 1: Assembly Entry Reached', 0
ada_returned_msg: db 'ERROR: Ada returned!', 0
