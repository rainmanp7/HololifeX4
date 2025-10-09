; =========================================================================
; HoloXlife OS Bootloader - COMPLETE FIXED VERSION
; =========================================================================
; This bootloader:
; 1. Loads kernel from disk to low memory (0x10000)
; 2. Enables A20 gate for >1MB access
; 3. Sets up GDT and enters protected mode
; 4. Copies kernel from low memory to 1MB (0x100000)
; 5. Jumps to kernel entry point
; =========================================================================

[org 0x7c00]
[bits 16]

; --- Configuration Constants ---
; KERNEL_SECTORS_TO_LOAD and BOOT_DRIVE are provided by Makefile via -D flags
KERNEL_LOAD_TEMP    equ 0x10000      ; Temporary load location (64KB)
KERNEL_LOAD_FINAL   equ 0x100000     ; Final kernel location (1MB)

_start:
    ; === STAGE 1: REAL MODE SETUP ===
    
    ; Disable interrupts during setup
    cli
    
    ; Zero out segment registers and set up stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00          ; Stack grows down from bootloader
    
    ; Save boot drive number (BIOS puts it in DL)
    mov [boot_drive], dl
    
    ; Re-enable interrupts
    sti

    ; === STAGE 2: PRINT BOOT MESSAGE ===
    
    mov si, msg_boot
    call print_string

    ; === STAGE 3: ENABLE A20 LINE ===
    ; Required for accessing memory above 1MB
    
    mov si, msg_a20
    call print_string
    
    call enable_a20
    
    ; Verify A20 is enabled
    call check_a20
    cmp ax, 1
    je .a20_ok
    
    ; A20 failed
    mov si, msg_a20_fail
    call print_string
    jmp error_halt
    
.a20_ok:
    mov si, msg_a20_ok
    call print_string

    ; === STAGE 4: LOAD KERNEL FROM DISK ===
    
    mov si, msg_loading
    call print_string
    
    ; Use Extended Read (INT 13h, AH=42h) to load kernel
    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]    ; Use saved boot drive
    int 0x13
    jc disk_error

    mov si, msg_kernel_loaded
    call print_string

    ; === STAGE 5: ENTER PROTECTED MODE ===
    
    mov si, msg_protected
    call print_string
    
    cli                     ; Disable interrupts before mode switch
    lgdt [gdt_descriptor]   ; Load GDT
    
    ; Set PE (Protection Enable) bit in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to flush CPU pipeline and load CS with GDT selector
    jmp 0x08:protected_mode_entry

; === ERROR HANDLERS ===

disk_error:
    mov si, msg_disk_error
    call print_string
    jmp error_halt

error_halt:
    mov si, msg_halted
    call print_string
    cli
    hlt
    jmp $

; === HELPER FUNCTIONS ===

; Enable A20 line using multiple methods
enable_a20:
    pusha
    
    ; Method 1: Fast A20 (port 0x92)
    in al, 0x92
    test al, 2
    jnz .done               ; Already enabled
    or al, 2
    and al, 0xFE            ; Don't accidentally reset
    out 0x92, al
    
.done:
    popa
    ret

; Check if A20 line is enabled
; Returns: AX = 1 if enabled, 0 if disabled
check_a20:
    pushf
    push ds
    push es
    push di
    push si
 
    cli
    
    xor ax, ax
    mov es, ax
    mov di, 0x0500
 
    mov ax, 0xFFFF
    mov ds, ax
    mov si, 0x0510
 
    mov al, byte [es:di]
    push ax
    mov al, byte [ds:si]
    push ax
 
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
 
    cmp byte [es:di], 0xFF
    
    pop ax
    mov byte [ds:si], al
    pop ax
    mov byte [es:di], al
 
    mov ax, 0
    je .exit
    mov ax, 1
    
.exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

; Print null-terminated string
; Input: SI = pointer to string
print_string:
    pusha
    mov ah, 0x0e            ; BIOS teletype output
    mov bh, 0               ; Page 0
.loop:
    lodsb                   ; Load byte from SI into AL
    test al, al             ; Check for null terminator
    jz .done
    int 0x10                ; Print character
    jmp .loop
.done:
    popa
    ret

; === 32-BIT PROTECTED MODE CODE ===

[bits 32]
protected_mode_entry:
    ; Set up segment registers with data selector
    mov ax, 0x10            ; GDT data segment selector
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Set up stack (below kernel at 576KB)
    mov ebp, 0x90000
    mov esp, 0x90000

    ; === COPY KERNEL TO FINAL LOCATION ===
    ; Copy from 0x10000 (64KB) to 0x100000 (1MB)
    ; This is necessary because BIOS INT 13h can't load directly above 1MB
    
    mov esi, KERNEL_LOAD_TEMP       ; Source: 64KB
    mov edi, KERNEL_LOAD_FINAL      ; Destination: 1MB
    mov ecx, KERNEL_SECTORS_TO_LOAD ; Number of sectors
    shl ecx, 9                      ; Convert sectors to bytes (*512)
    shr ecx, 2                      ; Convert bytes to dwords (/4)
    
    cld                             ; Clear direction flag (forward)
    rep movsd                       ; Copy ECX dwords from ESI to EDI

    ; === INITIALIZE SERIAL PORT (COM1) FOR EARLY DEBUGGING ===
    ; Port 0x3F8 = COM1
    
    ; Disable all interrupts
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al
    
    ; Enable DLAB (set baud rate divisor)
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al
    
    ; Set divisor to 3 (38400 baud)
    mov dx, 0x3F8
    mov al, 0x03
    out dx, al
    
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al
    
    ; 8 bits, no parity, one stop bit
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al
    
    ; Enable FIFO, clear them, with 14-byte threshold
    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al
    
    ; IRQs enabled, RTS/DSR set
    mov dx, 0x3FC
    mov al, 0x0B
    out dx, al
    
    ; Send boot complete message to serial
    mov esi, msg_serial_boot
.serial_loop:
    lodsb
    test al, al
    jz .serial_done
    
    ; Wait for transmit ready
    mov dx, 0x3FD
.wait_tx:
    in al, dx
    test al, 0x20
    jz .wait_tx
    
    ; Send character
    mov dx, 0x3F8
    mov al, [esi-1]
    out dx, al
    jmp .serial_loop
    
.serial_done:

    ; === CLEAN CPU STATE ===
    ; Zero out general-purpose registers for clean kernel entry
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi

    ; === JUMP TO KERNEL ===
    jmp KERNEL_LOAD_FINAL

; === DATA SECTION ===

[bits 16]
align 4

; Boot drive storage
boot_drive: db 0

; Messages
msg_boot:           db 'HoloXlife OS Bootloader v6', 13, 10, 0
msg_a20:            db 'Enabling A20 line...', 0
msg_a20_ok:         db 'OK', 13, 10, 0
msg_a20_fail:       db 'FAILED', 13, 10, 0
msg_loading:        db 'Loading kernel from disk...', 0
msg_kernel_loaded:  db 'OK', 13, 10, 0
msg_protected:      db 'Entering protected mode...', 13, 10, 0
msg_disk_error:     db 13, 10, 'FATAL: Disk read error!', 13, 10, 0
msg_halted:         db 'System halted.', 13, 10, 0

[bits 32]
msg_serial_boot:    db 'Bootloader->Kernel transition complete', 13, 10, 0

; === DISK ADDRESS PACKET ===
; For INT 13h Extended Read (AH=42h)
[bits 16]
align 4
dap:
    db 0x10                     ; Size of packet (16 bytes)
    db 0                        ; Reserved (always 0)
    dw KERNEL_SECTORS_TO_LOAD   ; Number of sectors to read
    dw 0x0000                   ; Offset (0x10000 = 0x1000:0x0000)
    dw 0x1000                   ; Segment (0x1000 * 16 = 0x10000 = 64KB)
    dd 1                        ; Starting LBA (sector 1, after bootloader)
    dd 0                        ; High 32 bits of LBA (0 for <2TB disks)

; === GLOBAL DESCRIPTOR TABLE (GDT) ===
align 8
gdt_start:

gdt_null:
    ; Null descriptor (required by CPU)
    dq 0x0000000000000000

gdt_code:
    ; Code segment: Base=0, Limit=4GB, 32-bit, executable
    dw 0xFFFF                   ; Limit (bits 0-15)
    dw 0x0000                   ; Base (bits 0-15)
    db 0x00                     ; Base (bits 16-23)
    db 10011010b                ; Access: P=1, DPL=0, S=1, Type=1010 (code exec/read)
    db 11001111b                ; Flags: G=1, D=1, L=0, AVL=0 + Limit (bits 16-19)
    db 0x00                     ; Base (bits 24-31)

gdt_data:
    ; Data segment: Base=0, Limit=4GB, 32-bit, writable
    dw 0xFFFF                   ; Limit (bits 0-15)
    dw 0x0000                   ; Base (bits 0-15)
    db 0x00                     ; Base (bits 16-23)
    db 10010010b                ; Access: P=1, DPL=0, S=1, Type=0010 (data read/write)
    db 11001111b                ; Flags: G=1, D=1, L=0, AVL=0 + Limit (bits 16-19)
    db 0x00                     ; Base (bits 24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT size - 1
    dd gdt_start + 0x7c00       ; GDT linear address (add origin offset)

; === BOOT SIGNATURE ===
; Pad to 510 bytes and add boot signature
times 510 - ($ - $$) db 0
dw 0xAA55                       ; Boot signature (little-endian)
