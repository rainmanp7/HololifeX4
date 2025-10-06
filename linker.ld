/* HoloXlife Pure Ada OS Linker Script - Protocol Synchronized */
ENTRY(_ada_boot)

SECTIONS
{
    . = 0x8000;
    
    .text : {
        *(.text._ada_boot)  /* CRITICAL: Entry point at 0x8000 */
        *(.text)
        *(.text.*)
    }
    
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }
    
    .data : {
        *(.data)
        *(.data.*)
    }
    
    .bss : {
        *(.bss)
        *(.bss.*)
    }
}

_start = _ada_boot;
