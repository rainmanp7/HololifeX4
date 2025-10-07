[org 0x7c00]
[bits 16]
start:
    mov ax, 0
    mov ds, ax
    mov es, ax 
    mov ss, ax
    mov sp, 0x7c00
    
    ; Print boot message
    mov si, msg
print_loop:
    lodsb
    test al, al
    jz hang
    mov ah, 0x0e
    int 0x10
    jmp print_loop

hang:
    jmp hang

msg: db 'BOOTED!', 0

times 510-($-$$) db 0
dw 0xaa55
