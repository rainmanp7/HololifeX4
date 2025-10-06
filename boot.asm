; HoloXlife Pure Ada OS Bootloader
; Supports automatic padding calculation from Makefile

[BITS 16]
[ORG 0x7C00]

; HOLOGRAPHIC_KERNEL_SECTORS will be passed from Makefile
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 10
%endif

; BOOT_PADDING will be passed from Makefile on second pass
%ifndef BOOT_PADDING
    %define BOOT_PADDING 0
%endif

start:
    ; Initialize segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Load kernel from disk
    mov ah, 0x02
    mov al, HOLOGRAPHIC_KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x1000
    int 0x13

    jc disk_error

    ; Jump to loaded kernel
    jmp 0x1000:0x0000

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

boot_msg:    db 'HoloXlife OS Booting...', 13, 10, 0
error_msg:   db 'Disk Error!', 13, 10, 0

; Pad to 510 bytes
%if BOOT_PADDING > 0
    times BOOT_PADDING db 0
%endif

; Boot signature
dw 0xAA55
