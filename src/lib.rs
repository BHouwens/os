#![feature(lang_items)]
#![feature(unique)]
#![no_std]
extern crate rlibc;
extern crate volatile;
mod vga_buffer;


#[no_mangle]
pub extern fn rust_main() {
    // NB: we have a very small stack and no guard page

    let hello = b"Hello World!";
    let colour_byte = 0x1f; // white foreground, blue background

    let mut hello_coloured = [colour_byte; 24];
    
    for (i, char_byte) in hello.into_iter().enumerate() {
        hello_coloured[i*2] = *char_byte;
    }

    // Write 'Hello World' to the centre of the VGA text buffer
    let buffer_ptr = (0xb8000 + 1988) as *mut _;
    unsafe { *buffer_ptr = hello_coloured };

    loop{}
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! { loop{}}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] #[no_mangle] pub extern fn panic_fmt() -> ! {loop{}}