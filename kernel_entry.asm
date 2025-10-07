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
    
    ; Write "ADA!" to VGA as early boot indicator
    mov eax, 0xb8000
    mov byte [eax], 'A'
    mov byte [eax+1], 0x0F
    mov byte [eax+2], 'D'
    mov byte [eax+3], 0x0F
    mov byte [eax+4], 'A'
    mov byte [eax+5], 0x0F
    mov byte [eax+6], '!'
    mov byte [eax+7], 0x0F
    
    ; Jump to Ada kernel
    call _ada_boot
    
    ; Hang if Ada returns
hang:
    cli
    hlt
    jmp hang