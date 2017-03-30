ENTRY(start)

SECTIONS {
    . = 1M;

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        /* KEEP here is used to prevent gc on Rust libcore sections from sweeping it */
        KEEP(*(.multiboot_header))
    }

    .text :
    {
        *(.text)
    }
}