arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
asm_source_files := $(wildcard src/arch/$(arch)/*.asm)
asm_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

.all: $(kernel)

clean:
	@rm -rf build

run: $(iso)
		@qemu-system-x86_64 -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
		@mkdir -p build/isofiles/boot/grub
		@cp $(kernel) build/isofiles/boot/kernel.bin
		@cp $(grub_cfg) build/isofiles/boot/grub
		@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
		@rm -rf build/isofiles

$(kernel): $(asm_object_files) $(linker_script)
		@ld -n -T $(linker_script) -o $(kernel) $(asm_object_files)


# compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
		@mkdir -p $(shell dirname $@)
		@nasm -felf64 $< -o $@

.PHONY: all clean run iso



