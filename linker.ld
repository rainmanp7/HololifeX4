ENTRY(_ada_boot)

SECTIONS
{
    /* Start placing kernel sections at 1MB (0x100000) */
    . = 0x100000;
    
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : { *(.bss) }
    
    /DISCARD/ : { *(.comment) *(.note.gnu.build-id) }
}