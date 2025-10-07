# HoloXlife OS - Pure Assembly Boot Test
ASM = nasm
LD = ld
OBJCOPY = objcopy

.PHONY: all clean run

all: test.img

# Assembly entry point
test_entry.o: test_entry.asm
	$(ASM) -f elf32 test_entry.asm -o test_entry.o

# Link kernel
test.bin: test_entry.o
	@echo "🔗 Linking Pure Assembly Kernel..."
	$(LD) -m elf_i386 -T linker.ld -o test.elf test_entry.o
	$(OBJCOPY) -O binary test.elf test.bin
	@KERNEL_SIZE=$$(stat -f%z test.bin 2>/dev/null || stat -c%s test.bin 2>/dev/null); \
	echo "✅ Kernel: $$KERNEL_SIZE bytes"

# Build bootloader with calculated sector count
boot.bin: boot.asm test.bin
	@KERNEL_SIZE=$$(stat -f%z test.bin 2>/dev/null || stat -c%s test.bin 2>/dev/null); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	echo "📊 Kernel size: $$KERNEL_SIZE bytes = $$SECTORS sectors"; \
	echo "🔨 Building bootloader..."; \
	nasm -f bin -DHOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin; \
	BOOT_SIZE=$$(stat -f%z boot.bin 2>/dev/null || stat -c%s boot.bin 2>/dev/null); \
	if [ $$BOOT_SIZE -ne 512 ]; then \
		echo "❌ ERROR: Bootloader size is $$BOOT_SIZE bytes (expected 512)"; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes"

# Create OS image
test.img: boot.bin test.bin
	@echo "💾 Creating Test OS image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=test.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@IMG_SIZE=$$(stat -f%z $@ 2>/dev/null || stat -c%s $@ 2>/dev/null); \
	echo "✅ Test Image: $$IMG_SIZE bytes (test.img)"

# Run in QEMU
run: test.img
	@echo "🚀 Booting Pure Assembly Test Kernel..."
	@echo "   📺 VGA: Should show 'BOOTLOADER OK - Assembly Entry Reached!'"
	@echo "   📝 Serial: QEMU output"
	qemu-system-i386 \
		-drive file=test.img,format=raw,if=floppy \
		-serial stdio \
		-no-reboot -no-shutdown

# Debug mode
debug: test.img
	@echo "🐛 DEBUG MODE: Booting with logging..."
	qemu-system-i386 \
		-drive file=test.img,format=raw,if=floppy \
		-serial stdio \
		-D qemu.log -d int,cpu_reset,guest_errors \
		-no-reboot -no-shutdown

clean:
	rm -f *.bin *.o *.img *.elf test.img
	@echo "🧹 Build artifacts cleaned"
