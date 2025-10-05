/* HoloXlife Pure Ada OS Linker Script - EmergeOS Entry */
ENTRY(_ada_emergeos__emergeos)

SECTIONS
{
    . = 0x8000;
    
    .text : {
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

_start = _ada_emergeos__emergeos;
