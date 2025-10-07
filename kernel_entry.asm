; kernel_entry.asm - Minimal Entry Point
[bits 32]
[global _start]
[extern _ada_boot]

section .text
_start:
    mov esp, 0x90000
    mov ebp, esp
    cld
    
    ; Write simple boot marker
    mov eax, 0xb8000
    mov byte [eax], 'A'
    mov byte [eax+1], 0x0F
    mov byte [eax+2], 'D'
    mov byte [eax+3], 0x0F
    mov byte [eax+4], 'A'
    mov byte [eax+5], 0x0F
    
    call _ada_boot
    
hang:
    cli
    hlt
    jmp hang
