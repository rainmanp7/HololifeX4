# HoloXlife Pure Ada OS Makefile - PROTOCOL SYNCHRONIZED
# Tools
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

# Ada compilation flags
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

# Linker flags
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

.PHONY: all clean run debug

all: emergeos.img

# Create Ada configuration
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Individual object compilation
pulse_types.o: pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_types.ads -o pulse_types.o

pulse_entities.o: pulse_entities.adb pulse_entities.ads pulse_types.o gnat.adc
	$(GCC) $(ADAFLAGS) pulse_entities.adb -o pulse_entities.o

pulse_sync.o: pulse_sync.adb pulse_sync.ads pulse_types.o gnat.adc
	$(GCC) $(ADAFLAGS) pulse_sync.adb -o pulse_sync.o

hardware_entity.o: hardware_entity.adb hardware_entity.ads pulse_types.o gnat.adc
	$(GCC) $(ADAFLAGS) hardware_entity.adb -o hardware_entity.o

temporal_entity.o: temporal_entity.adb temporal_entity.ads pulse_types.o gnat.adc
	$(GCC) $(ADAFLAGS) temporal_entity.adb -o temporal_entity.o

# SIMPLE UART DRIVER COMPILATION
uart.o: uart.adb uart.ads gnat.adc
	$(GCC) $(ADAFLAGS) uart.adb -o uart.o

# Main OS compilation (depends on all other units)
emergeos.o: emergeos.adb emergeos.ads pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

# Link kernel
kernel.bin: emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	@echo "🔗 Linking HoloXlife OS kernel..."
	$(LD) $(LDFLAGS) -o kernel.elf emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@KERNEL_SIZE=$$(stat -f%z kernel.bin 2>/dev/null || stat -c%s kernel.bin 2>/dev/null); \
	echo "✅ Kernel: $$KERNEL_SIZE bytes"

# Build bootloader with calculated sector count
boot.bin: boot.asm kernel.bin
	@KERNEL_SIZE=$$(stat -f%z kernel.bin 2>/dev/null || stat -c%s kernel.bin 2>/dev/null); \
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
emergeos.img: boot.bin kernel.bin
	@echo "💾 Creating HoloXlife OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@IMG_SIZE=$$(stat -f%z $@ 2>/dev/null || stat -c%s $@ 2>/dev/null); \
	echo "✅ OS Image: $$IMG_SIZE bytes (emergeos.img)"

# Run in QEMU with serial output
run: emergeos.img
	@echo "🚀 Booting HoloXlife Pure Ada Operating System..."
	@echo "   📺 VGA: QEMU window"
	@echo "   📝 Serial: serial.log"
	@echo "   🐛 Debug: qemu.log"
	@echo "=========================================="
	@rm -f serial.log qemu.log
	qemu-system-i386 \
		-drive format=raw,file=emergeos.img,if=ide \
		-serial file:serial.log \
		-D qemu.log -d int,cpu_reset,guest_errors \
		-display sdl \
		-no-reboot -no-shutdown
	@echo ""
	@echo "=========================================="
	@if [ -f serial.log ]; then \
		echo "📝 Serial Output:"; \
		cat serial.log; \
	else \
		echo "⚠️  No serial output captured"; \
	fi

# Debug mode - shows more verbose output
debug: emergeos.img
	@echo "🐛 DEBUG MODE: Booting with extra logging..."
	@rm -f serial.log qemu.log
	qemu-system-i386 \
		-drive format=raw,file=emergeos.img,if=ide \
		-serial stdio \
		-D qemu.log -d int,cpu_reset,guest_errors,exec \
		-display sdl \
		-no-reboot -no-shutdown

# Clean build artifacts
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc serial.log qemu.log
	@echo "🧹 Build artifacts cleaned"
