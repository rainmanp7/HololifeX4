# HoloXlife Pure Ada OS Makefile - v6 BOOT FIX
#
# Critical fixes:
# - Changed from floppy (-fda) to hard disk (-hda) for reliable booting
# - Enhanced debug output
# - Better error checking
# - Proper boot sector verification

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

.PHONY: all clean run debug test-boot

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

# Link kernel
kernel.bin: emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	@echo "=== Linking HoloXlife Ada Kernel ==="
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@KSIZE=$$(wc -c < kernel.bin); \
	echo "✅ Kernel: $$KSIZE bytes"; \
	if [ $$KSIZE -gt 1048576 ]; then \
		echo "⚠️  WARNING: Kernel exceeds 1MB!"; \
	fi

# Build bootloader with verification
boot.bin: boot.asm kernel.bin
	@echo "=== Building Bootloader ==="
	@KERNEL_SIZE_BYTES=$$(wc -c < kernel.bin); \
	SECTORS_TO_LOAD=$$(( (KERNEL_SIZE_BYTES + 511) / 512 )); \
	echo "Kernel: $$KERNEL_SIZE_BYTES bytes => $$SECTORS_TO_LOAD sectors"; \
	\
	$(ASM) -f bin \
		-D KERNEL_SECTORS_TO_LOAD=$$SECTORS_TO_LOAD \
		-D BOOT_DRIVE=0x80 \
		boot.asm -o boot.bin; \
	\
	FINAL_SIZE=$$(wc -c < boot.bin); \
	if [ $$FINAL_SIZE -ne 512 ]; then \
		echo "❌ FATAL: Bootloader is $$FINAL_SIZE bytes, must be 512"; \
		exit 1; \
	fi; \
	\
	BOOT_SIG=$$(hexdump -s 510 -n 2 -e '1/1 "%02x"' boot.bin); \
	if [ "$$BOOT_SIG" != "55aa" ]; then \
		echo "❌ FATAL: Boot signature is $$BOOT_SIG, should be 55aa"; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes, signature: 55aa"

# Create final OS disk image (HARD DISK format for reliability)
emergeos.img: boot.bin kernel.bin
	@echo "=== Creating HoloXlife OS Disk Image ==="
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "✅ Image created: emergeos.img ($$(du -h emergeos.img | cut -f1))"
	@echo ""
	@echo "Boot sector verification:"
	@hexdump -C emergeos.img | head -n 2
	@echo "..."
	@hexdump -C emergeos.img -s 510 -n 2

# Run in QEMU - FIXED: Use -hda instead of -fda
run: emergeos.img
	@echo "=========================================="
	@echo "  Booting HoloXlife Pure Ada OS"
	@echo "=========================================="
	@echo "VGA output    : QEMU window"
	@echo "Serial output : serial.log"
	@echo "Debug log     : qemu.log"
	@echo ""
	qemu-system-i386 \
		-drive format=raw,file=emergeos.img,if=ide,index=0 \
		-serial file:serial.log \
		-D qemu.log \
		-d cpu_reset,int,guest_errors \
		-m 64M \
		-no-reboot \
		-no-shutdown
	@echo ""
	@echo "=== Serial Output ==="
	@cat serial.log 2>/dev/null || echo "No serial output"
	@echo ""
	@echo "=== Checking for errors in qemu.log ==="
	@grep -i "exception\|error\|triple" qemu.log | head -20 || echo "No critical errors"

# Debug run with maximum verbosity
debug: emergeos.img
	@echo "=== DEBUG MODE ==="
	qemu-system-i386 \
		-drive format=raw,file=emergeos.img,if=ide,index=0 \
		-serial stdio \
		-D qemu_debug.log \
		-d cpu_reset,int,cpu,in_asm \
		-m 64M \
		-no-reboot \
		-no-shutdown

# Test bootloader only (with diagnostic version)
test-boot: boot_diagnostic.bin
	@echo "=== Testing Bootloader ==="
	dd if=/dev/zero of=test.img bs=512 count=100 status=none
	dd if=boot_diagnostic.bin of=test.img conv=notrunc status=none
	qemu-system-i386 \
		-drive format=raw,file=test.img,if=ide,index=0 \
		-serial stdio \
		-nographic

boot_diagnostic.bin: boot_diagnostic.asm
	$(ASM) -f bin boot_diagnostic.asm -o boot_diagnostic.bin
	@echo "Diagnostic bootloader size: $$(wc -c < boot_diagnostic.bin) bytes"

# Clean up
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc *.log
	@echo "✨ Build environment cleaned"

# Show what's in the image
inspect: emergeos.img
	@echo "=== Disk Image Contents ==="
	@echo "Total size: $$(du -h emergeos.img | cut -f1)"
	@echo ""
	@echo "Boot sector (first 32 bytes):"
	@hexdump -C emergeos.img -n 32
	@echo ""
	@echo "Boot signature (bytes 510-511):"
	@hexdump -C emergeos.img -s 510 -n 2
	@echo ""
	@echo "Kernel start (sector 1, first 32 bytes):"
	@hexdump -C emergeos.img -s 512 -n 32
