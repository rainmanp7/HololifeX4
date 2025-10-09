; =========================================================================
; HoloXlife OS Bootloader - OPTIMIZED VERSION (fits in 512 bytes)
; =========================================================================

[org 0x7c00]
[bits 16]

KERNEL_LOAD_TEMP    equ 0x10000
KERNEL_LOAD_FINAL   equ 0x100000

_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov [boot_drive], dl
    sti

    ; Print boot message
    mov si, msg_boot
    call print

    ; Enable A20 (fast method only)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Load kernel
    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc error

    mov si, msg_ok
    call print

    ; Enter protected mode
    cli
    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pm_start

error:
    mov si, msg_err
    call print
    hlt
    jmp $

print:
    pusha
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

[bits 32]
pm_start:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov esp, 0x90000

    ; Copy kernel from 0x10000 to 0x100000
    mov esi, KERNEL_LOAD_TEMP
    mov edi, KERNEL_LOAD_FINAL
    mov ecx, KERNEL_SECTORS_TO_LOAD
    shl ecx, 7              ; *128 dwords (512 bytes/sector / 4)
    cld
    rep movsd

    ; Initialize COM1 for serial output
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8
    mov al, 0x03
    out dx, al
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al
    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al
    mov dx, 0x3FC
    mov al, 0x0B
    out dx, al

    ; Zero registers
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi

    jmp KERNEL_LOAD_FINAL

[bits 16]
boot_drive: db 0

msg_boot: db 'Boot', 13, 10, 0
msg_ok:   db 'OK', 13, 10, 0
msg_err:  db 'ERR', 13, 10, 0

align 4
dap:
    db 0x10
    db 0
    dw KERNEL_SECTORS_TO_LOAD
    dw 0x0000
    dw 0x1000
    dd 1
    dd 0

align 8
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF   ; Code: base=0, limit=4GB, 32-bit, exec/read
    dq 0x00CF92000000FFFF   ; Data: base=0, limit=4GB, 32-bit, read/write
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start + 0x7c00

times 510 - ($ - $$) db 0
dw 0xAA55
