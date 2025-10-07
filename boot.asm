; MINIMAL WORKING BOOTLOADER
[org 0x7c00]
[bits 16]

start:
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    ; Print 'X' to confirm boot
    mov ah, 0x0e
    mov al, 'X'
    int 0x10

hang:
    jmp hang

; Boot signature
times 510-($-$$) db 0
dw 0xaa55
