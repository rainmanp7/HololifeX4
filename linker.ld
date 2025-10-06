/* HoloXlife Pure Ada OS Linker Script - PROTECTED MODE */
ENTRY(_ada_boot)
SECTIONS
{
    . = 0x10000;  /* ← CHANGED from 0x8000 */
    .text : {
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
    }
}
