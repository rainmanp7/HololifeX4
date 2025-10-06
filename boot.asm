; HoloXlife Pure Ada OS Bootloader
; Supports automatic padding calculation from Makefile

[BITS 16]
[ORG 0x7C00]

; HOLOGRAPHIC_KERNEL_SECTORS will be passed from Makefile
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 10  ; Default fallback
%endif

; BOOT_PADDING will be passed from Makefile on second pass
%ifndef BOOT_PADDING
    %define BOOT_PADDING 0  ; Default for first pass
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
    mov ah, 0x02                    ; BIOS read sector function
    mov al, HOLOGRAPHIC_KERNEL_SECTORS  ; Number of sectors to read
    mov ch, 0                       ; Cylinder 0
    mov cl, 2                       ; Start from sector 2 (after boot sector)
    mov dh, 0                       ; Head 0
    mov dl, 0x80                    ; First hard drive (use 0x00 for floppy)
    mov bx, 0x1000                  ; Load to 0x1000:0x0000
    int 0x13

    jc disk_error                   ; Jump if carry flag set (error)

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

; Automatic padding - calculated by Makefile
times BOOT_PADDING db 0

; Boot signature (must be at bytes 510-511)
dw 0xAA55
