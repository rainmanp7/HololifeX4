; =========================================================================
; HoloXlife OS Bootloader - Corrected and Robust Version
; =========================================================================
[org 0x7c00]
[bits 16]

; --- Configuration Constants ---
; Values are provided by the Makefile using the -D flag.
; KERNEL_SECTORS_TO_LOAD
; BOOT_DRIVE
KERNEL_LOAD_ADDRESS     equ 0x100000     ; ***UPDATED***: Load kernel to 1MB.

_start:
    ; ... rest of the file is identical and correct ...
    ; 1. Setup Segment Registers and Stack
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    ; 2. Announce Boot
    mov si, msg_boot
    call print_string

    ; 3. Load Kernel from Disk
    ; We now need to use Extended Read (INT 13h, AH=42h) for addresses > 1MB
    mov si, dap
    mov ah, 0x42
    mov dl, BOOT_DRIVE
    int 0x13
    jc disk_error

    ; 4. Switch to 32-bit Protected Mode
    cli
    lgdt [gdt.descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp gdt.code_seg:protected_mode_entry

disk_error:
    mov si, msg_disk_error
    call print_string
    hlt

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret

[bits 32]
protected_mode_entry:
    mov ax, gdt.data_seg
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    jmp KERNEL_LOAD_ADDRESS

[bits 16]
; --- Data Section ---
msg_boot:       db 'HoloXlife OS Booting (1MB Kernel)...', 13, 10, 0
msg_disk_error: db 'FATAL: Disk Read Error!', 13, 10, 0

; Disk Address Packet (DAP) for INT 13h, AH=42h
dap:
    db 0x10                 ; Size of packet (16 bytes)
    db 0                    ; Reserved, must be 0
.sectors:
    dw KERNEL_SECTORS_TO_LOAD ; Number of sectors to read
.buffer:
    dw 0x0000               ; Offset of buffer
    dw 0x10000              ; Segment of buffer (0x10000 << 4 = 0x100000)
.lba_low:
    dd 1                    ; Low 32 bits of LBA (start at sector 1, as bootloader is sector 0)
.lba_high:
    dd 0                    ; High 32 bits of LBA (0 for now)

; --- GDT Section ---
gdt:
.null:      dq 0x0
.code:
    dw 0xFFFF, 0x0000, 0x00, 0b10011010, 0b11001111, 0x00
.data:
    dw 0xFFFF, 0x0000, 0x00, 0b10010010, 0b11001111, 0x00
.end:
.descriptor:
    dw gdt.end - gdt.null - 1
    dd gdt.null + 0x7c00
.code_seg equ gdt.code - gdt.null
.data_seg equ gdt.data - gdt.null

times 510 - ($ - $$) db 0
dw 0xAA55