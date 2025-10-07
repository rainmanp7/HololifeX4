; boot.asm - HoloXlife Ada Bootloader (Protected Mode)
[org 0x7c00]
[bits 16]

; Define kernel sectors (passed from Makefile or use default)
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 64
%endif

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    sti

    mov si, boot_msg
    call print_string

    ; Load kernel to 0x1000:0x0000 (linear 0x10000)
    mov ah, 0x02                        ; BIOS read sectors
    mov al, HOLOGRAPHIC_KERNEL_SECTORS  ; Number of sectors to load
    mov ch, 0                           ; Cylinder 0
    mov cl, 2                           ; Sector 2 (after bootloader)
    mov dh, 0                           ; Head 0
    mov dl, 0x80                        ; First hard disk
    mov bx, 0x0000
    mov ax, 0x1000
    mov es, ax
    int 0x13
    jc disk_error

    ; Success message
    mov si, load_msg
    call print_string

    ; Enter protected mode
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    
    ; Jump to Ada kernel at 0x10000
    jmp 0x10000

[bits 16]
print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

boot_msg:   db 'HoloXlife OS Booting...', 13, 10, 0
load_msg:   db 'Kernel loaded! Entering protected mode...', 13, 10, 0
error_msg:  db 'Disk Read Error!', 13, 10, 0

; GDT (Global Descriptor Table)
gdt_start:
    dq 0x0                              ; Null descriptor
gdt_code:
    dw 0xFFFF                           ; Limit (low)
    dw 0x0                              ; Base (low)
    db 0x0                              ; Base (middle)
    db 10011010b                        ; Access byte
    db 11001111b                        ; Flags + Limit (high)
    db 0x0                              ; Base (high)
gdt_data:
    dw 0xFFFF                           ; Limit (low)
    dw 0x0                              ; Base (low)
    db 0x0                              ; Base (middle)
    db 10010010b                        ; Access byte
    db 11001111b                        ; Flags + Limit (high)
    db 0x0                              ; Base (high)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1          ; Size
    dd gdt_start                        ; Offset

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
