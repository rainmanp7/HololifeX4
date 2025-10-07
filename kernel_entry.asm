; kernel_entry.asm - Entry point for Pure Ada Kernel
[bits 32]
[global _start]
[extern _ada_boot]  ; This matches your pragma Export

section .text
_start:
    ; Set up stack
    mov esp, 0x90000
    mov ebp, esp
    
    ; Clear direction flag
    cld
    
    ; Write "ADA ENTRY" to VGA for better visibility
    mov edi, 0xb8000
    mov esi, boot_msg
    call print_string
    
    ; Jump to Ada kernel - THIS MUST MATCH THE EXPORT
    call _ada_boot
    
    ; If we get here, Ada returned (shouldn't happen)
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

boot_msg: db 'ADA ENTRY POINT REACHED', 0
ada_returned_msg: db 'ERROR: Ada returned!', 0
