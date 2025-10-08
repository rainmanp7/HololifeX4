/* linker.ld - HoloXlife OS Linker Script (Protocol Harmonized) */
ENTRY(_ada_boot)

SECTIONS
{
    . = 0x100000;

    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    /* We now explicitly mark the start and end of the BSS section. */
    .bss :
    {
        __bss_start = .; /* Symbol for the start of BSS */
        *(.bss)
        __bss_end = .;   /* Symbol for the end of BSS */
    }

    . = ALIGN(4096);
    end_of_kernel = .;

    /DISCARD/ :
    {
        *(.comment)
        *(.note.gnu.build-id)
    }
}
