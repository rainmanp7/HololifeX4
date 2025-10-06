[BITS 16]
[ORG 0x7C00]

; HoloXlife Pure Ada OS Bootloader
; FIXED VERSION - Serial output bugs corrected

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call serial_send_boot

    mov ax, 0x0003
    int 0x10

    call serial_send_video

    mov ah, 0x02
    mov al, HOLOGRAPHIC_KERNEL_SECTORS
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x8000
    
    call serial_send_disk_read
    
    int 0x13
    jc disk_error

    call serial_send_disk_ok

    lgdt [gdt_descriptor]
    call serial_send_gdt_loaded
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    call serial_send_pm_enabled
    
    jmp 0x08:protected_mode

disk_error:
    call serial_send_disk_error
    mov si, disk_error_msg
    call print_string
    hlt

; ===========================================
; FIXED SERIAL OUTPUT ROUTINES
; ===========================================

serial_init:
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al
    
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al
    
    mov dx, 0x3F8
    mov al, 0x03
    out dx, al
    
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al
    
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al
    
    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al
    
    ret

serial_send_char:
    push dx
    push ax
    mov dx, 0x3FD
.wait:
    in al, dx
    test al, 0x20
    jz .wait
    
    pop ax
    mov dx, 0x3F8
    out dx, al
    pop dx
    ret

serial_send_boot:
    call serial_init
    mov si, boot_msg
    call serial_send_string
    ret

serial_send_video:
    mov si, video_msg
    call serial_send_string
    ret

serial_send_disk_read:
    mov si, disk_read_msg
    call serial_send_string
    ret

serial_send_disk_ok:
    mov si, disk_ok_msg
    call serial_send_string
    ret

serial_send_disk_error:
    mov si, disk_err_diag_msg
    call serial_send_string
    ret

serial_send_gdt_loaded:
    mov si, gdt_msg
    call serial_send_string
    ret

serial_send_pm_enabled:
    mov si, pm_msg
    call serial_send_string
    ret

; FIXED: Properly preserves character while waiting
serial_send_string:
    pusha
.next_char:
    lodsb
    or al, al
    jz .done
    
    push ax            ; Save character before waiting
    mov dx, 0x3FD
.wait:
    in al, dx
    test al, 0x20
    jz .wait
    
    pop ax             ; Restore character
    mov dx, 0x3F8
    out dx, al
    jmp .next_char
    
.done:
    popa
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

boot_msg db "[BOOT] Bootloader started", 13, 10, 0
video_msg db "[BOOT] Video mode set", 13, 10, 0
disk_read_msg db "[BOOT] Reading disk sectors...", 13, 10, 0
disk_ok_msg db "[BOOT] Disk read successful", 13, 10, 0
disk_err_diag_msg db "[BOOT] DISK READ ERROR!", 13, 10, 0
gdt_msg db "[BOOT] GDT loaded", 13, 10, 0
pm_msg db "[BOOT] Protected mode enabled", 13, 10, 0
disk_error_msg db "Disk read error!", 0

gdt_start:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    call serial_send_32bit_kernel

    call 0x8000

    call serial_send_kernel_returned
    hlt

; FIXED: 32-bit serial output properly preserves character
serial_send_32bit_kernel:
    mov esi, kernel_call_msg_32
    call serial_send_string_32
    ret

serial_send_kernel_returned:
    mov esi, kernel_return_msg
    call serial_send_string_32
    ret

serial_send_string_32:
    pusha
.next_char_32:
    lodsb
    or al, al
    jz .done_32
    
    push eax           ; Save character (use full register in 32-bit)
    mov edx, 0x3FD
.wait_32:
    in al, dx
    test al, 0x20
    jz .wait_32
    
    pop eax            ; Restore character
    mov edx, 0x3F8
    out dx, al
    jmp .next_char_32
    
.done_32:
    popa
    ret

kernel_call_msg_32 db "[PM32] Calling kernel at 0x8000", 13, 10, 0
kernel_return_msg db "[PM32] KERNEL RETURNED - UNEXPECTED!", 13, 10, 0

%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 10
%endif

times 510-($-$$) db 0
dw 0xAA55
