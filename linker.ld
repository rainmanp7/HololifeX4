/* HoloXlife Pure Ada OS Linker Script - PROTECTED MODE */
OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)  /* Use assembly entry point */
SECTIONS
{
    . = 0x10000;
    .text : {
        *(.text._start)    /* Ensure entry point is first */
        *(.text._ada_boot)
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
        *(COMMON)
    }
    
    /DISCARD/ : {
        *(.comment)
        *(.note*)
        *(.eh_frame)
    }
}
