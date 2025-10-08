# HoloXlife Pure Ada OS Makefile - PROTOCOL SYNCHRONIZED
# Tools
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

# ... Ada flags and other rules are identical ...
# (gnat.adc, emergeos.o, pulse_types.o, etc.)
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

.PHONY: all clean run

all: emergeos.img

gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	# ... rest of gnat.adc rule is identical ...

# ... Ada object compilation rules are identical ...

kernel.bin: emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities + Simple UART..."
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "✅ Kernel: $$(wc -c < kernel.bin) bytes"

# Build bootloader — PROTECTED MODE, DYNAMIC SIZE, CONFIGURABLE DRIVE
boot.bin: boot.asm kernel.bin
	@KERNEL_SIZE=$$(wc -c < kernel.bin); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	echo "Kernel: $$KERNEL_SIZE bytes = $$SECTORS sectors"; \
	nasm -f bin \
		-D KERNEL_SECTORS_TO_LOAD=$$SECTORS \
		-D BOOT_DRIVE=0x00 \
		boot.asm -o boot.bin; \
	FINAL_SIZE=$$(wc -c < boot.bin); \
	if [ $$FINAL_SIZE -ne 512 ]; then \
		echo "❌ Bootloader size incorrect: $$FINAL_SIZE != 512"; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes (protected mode, protocol compliant)"

# Create OS image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "HoloXlife OS image created: emergeos.img"

# Run in QEMU — TRIPLE OUTPUT
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	@echo "  - VGA output: QEMU window (SDL)"
	@echo "  - Serial output: serial.log"
	@echo "  - QEMU debug log: qemu.log"
	qemu-system-i386 \
		-fda emergeos.img \
		-serial file:serial.log \
		-D qemu.log -d int,cpu_reset,guest_errors \
		-display sdl

# Clean
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc uart.ali serial.log qemu.log
	@echo "Build cleaned"