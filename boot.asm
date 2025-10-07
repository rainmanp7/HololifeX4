; =========================================================================
; HoloXlife OS Bootloader - Corrected and Robust Version
;
; Loads a kernel from the boot device, switches to 32-bit Protected Mode,
; and jumps to the kernel's entry point.
; =========================================================================

[org 0x7c00]    ; BIOS loads us at this physical address.
[bits 16]       ; We start in 16-bit real mode.

; --- Configuration Constants ---
; These make the bootloader easy to modify.
KERNEL_SECTORS_TO_LOAD  equ 16          ; How many sectors is our kernel?
KERNEL_LOAD_ADDRESS     equ 0x10000     ; Physical address to load the kernel to.
BOOT_DRIVE              equ 0x00        ; 0x00 = floppy, 0x80 = hard disk.

_start:
    ; 1. Setup Segment Registers and Stack
    ; We must ensure DS, ES, SS are 0 to match CS (which starts at 0x07c0)
    ; and provide a safe stack space below our bootloader code.
    cli             ; Disable interrupts during setup.
    xor ax, ax      ; AX = 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00  ; Stack grows downwards from our load address.
    sti             ; Re-enable interrupts.

    ; 2. Announce Boot
    mov si, msg_boot
    call print_string

    ; 3. Load Kernel from Disk
    ; We will load our kernel to linear address 0x10000 (ES:BX = 0x1000:0x0000).
    mov bx, KERNEL_LOAD_ADDRESS
    mov es, bx
    shr bx, 4       ; bx is now free, use it for ES. es = (KERNEL_LOAD_ADDRESS / 16)
    mov bx, 0x0000  ; Offset from ES is 0.

    mov ah, 0x02    ; BIOS Read Sectors function.
    mov al, KERNEL_SECTORS_TO_LOAD ; Number of sectors to read.
    mov ch, 0       ; Cylinder 0.
    mov cl, 2       ; Sector 2 (sector 1 is the bootloader).
    mov dh, 0       ; Head 0.
    mov dl, BOOT_DRIVE ; The drive to read from.
    int 0x13
    jc disk_error   ; If carry flag is set, there was an error.

    ; 4. Switch to 32-bit Protected Mode
    cli             ; Disable interrupts. No more BIOS calls from here.
    lgdt [gdt.descriptor] ; Load our GDT.

    mov eax, cr0
    or eax, 1       ; Set the PE (Protection Enable) bit in CR0.
    mov cr0, eax

    ; Far jump to flush the CPU pipeline and load our 32-bit code segment.
    ; This jump MUST be to the physical address of our 32-bit code.
    jmp gdt.code_seg:protected_mode_entry

disk_error:
    mov si, msg_disk_error
    call print_string
    hlt             ; Halt the system.

; --- 16-bit Functions ---
print_string:
    lodsb           ; Load char from [SI] into AL, increment SI.
    or al, al       ; Check if AL is zero (null terminator).
    jz .done
    mov ah, 0x0e    ; BIOS teletype function.
    int 0x10
    jmp print_string
.done:
    ret


; =========================================================================
; 32-BIT PROTECTED MODE CODE
; =========================================================================
[bits 32]
protected_mode_entry:
    ; 1. Setup 32-bit Segment Registers
    ; We are now in 32-bit mode. We must update segment registers to use
    ; our new GDT selectors.
    mov ax, gdt.data_seg
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; 2. Setup 32-bit Stack
    ; Set up a stack at a high memory address.
    mov ebp, 0x90000
    mov esp, ebp

    ; 3. Jump to the Kernel
    ; Our kernel is loaded and we are ready.
    jmp KERNEL_LOAD_ADDRESS


; =========================================================================
; DATA AND GDT
; =========================================================================
[bits 16]

; --- Messages ---
msg_boot:       db 'HoloXlife OS Booting (Protected Mode)...', 13, 10, 0
msg_disk_error: db 'FATAL: Disk Read Error!', 13, 10, 0

; --- Global Descriptor Table (GDT) ---
gdt:
    ; Null Descriptor (required)
    .null:
        dq 0x0
    
    ; Code Segment Descriptor (Base=0, Limit=4GB, Ring 0)
    .code:
        dw 0xFFFF       ; Limit (low)
        dw 0x0000       ; Base (low)
        db 0x00         ; Base (mid)
        db 0b10011010   ; Access Byte: P, DPL=0, S, Code, C, R, A
        db 0b11001111   ; Flags & Limit (high): G, D, L, AVL, Limit
        db 0x00         ; Base (high)
        
    ; Data Segment Descriptor (Base=0, Limit=4GB, Ring 0)
    .data:
        dw 0xFFFF       ; Limit (low)
        dw 0x0000       ; Base (low)
        db 0x00         ; Base (mid)
        db 0b10010010   ; Access Byte: P, DPL=0, S, Data, E, W, A
        db 0b11001111   ; Flags & Limit (high): G, D, L, AVL, Limit
        db 0x00         ; Base (high)
        
    .end:

    ; GDT Descriptor (for the lgdt instruction)
    .descriptor:
        dw gdt.end - gdt.null - 1  ; Size of GDT
        dd gdt.null + 0x7c00       ; **FIXED**: Physical linear address of GDT

    ; GDT Segment Selectors (constants for easy access)
    .code_seg equ gdt.code - gdt.null
    .data_seg equ gdt.data - gdt.null


; --- Bootloader Signature ---
times 510 - ($ - $$) db 0   ; Pad the rest of the boot sector with zeros.
dw 0xAA55                   ; BIOS boot signature.
