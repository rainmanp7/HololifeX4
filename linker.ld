/*
 * linker.ld - HoloXlife OS Linker Script (Protocol Harmonized)
 *
 * This script correctly structures the kernel ELF file so that 'objcopy'
 * can successfully strip it into a pure, bootable binary image.
 */

ENTRY(_ada_boot) /* The C-style name we exported from Ada */

SECTIONS
{
    /* Start placing sections at 1MB (0x100000), the standard for 32-bit kernels. */
    . = 0x100000;

    /* The '.text' section contains all executable code. */
    .text :
    {
        *(.text)
    }

    /* Read-only data. */
    .rodata :
    {
        *(.rodata)
    }

    /* Initialized data. */
    .data :
    {
        *(.data)
    }

    /* Uninitialized data (BSS). The OS must zero this itself. */
    .bss :
    {
        *(.bss)
    }

    /* This is a special symbol that we can reference from our code
       to know where the kernel's memory footprint ends. */
    . = ALIGN(4096);
    end_of_kernel = .;

    /* Discard unnecessary ELF sections to keep the binary clean. */
    /DISCARD/ :
    {
        *(.comment)
        *(.note.gnu.build-id)
    }
}
