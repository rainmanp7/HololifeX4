; boot.asm - HOLOXLIFE OS BOOTLOADER
[BITS 16]
[ORG 0x7C00]

%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 20
%endif

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

    ; Save boot drive
    mov [boot_drive], dl

    ; Clear screen and show message
    mov ax, 0x0003
    int 0x10
    
    mov si, boot_msg
    call print_string

    ; Load kernel from disk
    mov ax, 0x1000   ; ES:BX = 0x1000:0x0000 (phys 0x10000)
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, HOLOGRAPHIC_KERNEL_SECTORS
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; SUCCESS - Switch to protected mode
    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to 32-bit code segment
    jmp CODE_SEG:init_pm

[BITS 32]
init_pm:
    ; Setup protected mode segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup stack
    mov esp, 0x90000
    mov ebp, esp
    
    ; Clear screen for kernel (VGA direct)
    mov edi, 0xB8000
    mov ecx, 80*25
    mov eax, 0x0F200F20  ; Black spaces
.clear_loop:
    mov [edi], eax
    add edi, 4
    loop .clear_loop
    
    ; Write kernel boot message
    mov dword [0xB8000], 0x0F4B0F48   ; "HK" (HoloKernel)
    mov dword [0xB8004], 0x0F4C0F45   ; "EL"
    
    ; JUMP TO KERNEL - This is the critical line
    jmp 0x10000

[BITS 16]
print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

; GDT
gdt_start:
    dq 0x0000000000000000  ; Null descriptor

gdt_code:
    dw 0xFFFF       ; Limit 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 0x9A         ; Access byte (code)
    db 0xCF         ; Flags + Limit 16-19
    db 0x00         ; Base 24-31

gdt_data:
    dw 0xFFFF       ; Limit 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 0x92         ; Access byte (data)
    db 0xCF         ; Flags + Limit 16-19
    db 0x00         ; Base 24-31
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

boot_drive: db 0
boot_msg:   db 'HoloXlife Bootloader...', 0x0D, 0x0A, 0
error_msg:  db 'Disk Error!', 0x0D, 0x0A, 0

; Padding and boot signature
%if BOOT_PADDING > 0
    times BOOT_PADDING db 0
%endif
dw 0xAA55
