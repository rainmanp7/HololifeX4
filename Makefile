# HoloXlife Pure Ada OS Makefile - v5 Protocol Harmonized
#
# Changes:
# - Removed logical contradiction of a second bootloader (boot.adb).
# - Vastly simplified the 'boot.bin' rule to let NASM handle padding internally.
# - Improved 'run' command for better debugging output.

# Tools
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

# Ada compilation flags
ADAFLAGS = -x ada -gnat2012 -gnatwe -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

# Linker flags
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

.PHONY: all clean run

all: emergeos.img

# Create Ada configuration (pragma restrictions)
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Ada Object Compilation
emergeos.o: emergeos.adb emergeos.ads gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

pulse_types.o: pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_types.ads -o pulse_types.o

pulse_entities.o: pulse_entities.adb pulse_entities.ads pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_entities.adb -o pulse_entities.o

pulse_sync.o: pulse_sync.adb pulse_sync.ads pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_sync.adb -o pulse_sync.o

hardware_entity.o: hardware_entity.adb hardware_entity.ads pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) hardware_entity.adb -o hardware_entity.o

temporal_entity.o: temporal_entity.adb temporal_entity.ads pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) temporal_entity.adb -o temporal_entity.o

uart.o: uart.adb uart.ads gnat.adc
	$(GCC) $(ADAFLAGS) uart.adb -o uart.o

# Link kernel - REMOVED dependency on non-existent 'boot.o'
kernel.bin: emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	@echo "Linking HoloXlife Ada Kernel..."
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "✅ Kernel: $$(wc -c < kernel.bin) bytes"

# Build bootloader - SIMPLIFIED AND ROBUST
# NASM's 'times' directive handles all padding automatically.
boot.bin: boot.asm kernel.bin
	@echo "Building bootloader..."
	@KERNEL_SIZE_BYTES=$$(wc -c < kernel.bin); \
	SECTORS_TO_LOAD=$$(( (KERNEL_SIZE_BYTES + 511) / 512 )); \
	echo "Kernel: $$KERNEL_SIZE_BYTES bytes => $$SECTORS_TO_LOAD sectors"; \
	\
	$(ASM) -f bin \
		-D KERNEL_SECTORS_TO_LOAD=$$SECTORS_TO_LOAD \
		-D BOOT_DRIVE=0x00 \
		boot.asm -o boot.bin; \
	\
	FINAL_SIZE=$$(wc -c < boot.bin); \
	if [ $$FINAL_SIZE -ne 512 ]; then \
		echo "❌ FATAL: Bootloader size is $$FINAL_SIZE bytes, must be 512."; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes (protocol compliant)"

# Create final OS disk image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 >/dev/null 2>&1
	dd if=boot.bin of=$@ conv=notrunc >/dev/null 2>&1
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc >/dev/null 2>&1
	@echo "✅ HoloXlife OS image created: emergeos.img"

# Run in QEMU with enhanced debugging
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

# Clean up all generated files
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc *.log
	@echo "Build environment cleaned."
