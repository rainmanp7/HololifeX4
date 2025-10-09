; =========================================================================
; HoloXlife OS Bootloader - TWO-STAGE LOADING (Most Compatible)
; =========================================================================
[org 0x7c00]
[bits 16]

; --- Configuration Constants ---
KERNEL_LOAD_TEMP    equ 0x10000      ; Temporary load location (64KB)
KERNEL_LOAD_FINAL   equ 0x100000     ; Final kernel location (1MB)

_start:
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

    ; 3. Enable A20 Line (CRITICAL)
    call enable_a20

    ; 4. Load Kernel to LOW MEMORY (below 1MB)
    mov si, msg_loading
    call print_string
    
    mov si, dap
    mov ah, 0x42
    mov dl, BOOT_DRIVE
    int 0x13
    jc disk_error

    mov si, msg_kernel_loaded
    call print_string

    ; 5. Switch to 32-bit Protected Mode
    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mode_entry

disk_error:
    mov si, msg_disk_error
    call print_string
    jmp $

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

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
    ; Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Set up stack
    mov ebp, 0x90000
    mov esp, 0x90000

    ; CRITICAL: Copy kernel from low memory (0x10000) to high memory (0x100000)
    ; This is necessary because BIOS INT 13h can't load directly above 1MB
    mov esi, KERNEL_LOAD_TEMP           ; Source
    mov edi, KERNEL_LOAD_FINAL          ; Destination
    mov ecx, KERNEL_SECTORS_TO_LOAD     ; Number of sectors
    shl ecx, 9                          ; Convert sectors to bytes (512 bytes/sector)
    shr ecx, 2                          ; Convert bytes to dwords (4 bytes/dword)
    
    cld                                 ; Clear direction flag (forward copy)
    rep movsd                           ; Copy ECX dwords from ESI to EDI

    ; Zero out registers for clean state
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi

    ; Jump to kernel at 1MB
    jmp KERNEL_LOAD_FINAL

[bits 16]
; --- Data Section ---
msg_boot:           db 'HoloXlife OS Booting...', 13, 10, 0
msg_loading:        db 'Loading kernel from disk...', 13, 10, 0
msg_kernel_loaded:  db 'Kernel loaded, relocating to 1MB...', 13, 10, 0
msg_disk_error:     db 'FATAL: Disk Read Error!', 13, 10, 0

; Disk Address Packet - Load to 0x10000 (64KB mark)
align 4
dap:
    db 0x10                     ; Size of packet
    db 0                        ; Reserved
    dw KERNEL_SECTORS_TO_LOAD   ; Number of sectors
    dw 0x0000                   ; Offset
    dw 0x1000                   ; Segment (0x1000 * 16 = 0x10000)
    dd 1                        ; Start LBA (sector 1)
    dd 0                        ; High 32 bits of LBA

; --- GDT Section ---
align 8
gdt_start:
gdt_null:
    dq 0x0000000000000000

gdt_code:
    dw 0xFFFF                   ; Limit low
    dw 0x0000                   ; Base low
    db 0x00                     ; Base middle
    db 10011010b                ; Access: Present, Ring 0, Code, Execute/Read
    db 11001111b                ; Flags: 4KB pages, 32-bit, Limit high
    db 0x00                     ; Base high

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                ; Access: Present, Ring 0, Data, Read/Write
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start + 0x7c00

times 510 - ($ - $$) db 0
dw 0xAA55
