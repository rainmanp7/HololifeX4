# HoloXlife Pure Ada OS Makefile - PROTOCOL SYNCHRONIZED
# Dynamic boot sector padding calculation in Makefile

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

.PHONY: all clean run

all: emergeos.img

# Create Ada configuration
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Individual object compilation
boot.o: boot.adb gnat.adc
	$(GCC) $(ADAFLAGS) boot.adb -o boot.o

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

# UART DRIVER COMPILATION (ADDED)
uart_driver.o: uart_driver.adb uart_driver.ads gnat.adc
	$(GCC) $(ADAFLAGS) uart_driver.adb -o uart_driver.o

# Link kernel (UPDATED to include uart_driver.o)
kernel.bin: boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart_driver.o
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities + UART Driver..."
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "✅ Kernel: $$(wc -c < kernel.bin) bytes"

# Build bootloader with AUTOMATIC PADDING CALCULATION
boot.bin: boot.asm kernel.bin
	@echo "Building bootloader with automatic padding calculation..."
	@KERNEL_SIZE=$$(wc -c < kernel.bin); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	echo "Kernel: $$KERNEL_SIZE bytes = $$SECTORS sectors"; \
	\
	$(ASM) -f bin \
		-D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS \
		-o boot_tmp.bin boot.asm; \
	\
	BOOT_SIZE=$$(wc -c < boot_tmp.bin); \
	BOOT_CODE_SIZE=$$(($$BOOT_SIZE - 2)); \
	echo "Bootloader code + signature: $$BOOT_SIZE bytes (code: $$BOOT_CODE_SIZE bytes)"; \
	\
	if [ $$BOOT_CODE_SIZE -gt 510 ]; then \
		echo "❌ Bootloader code too large! $$BOOT_CODE_SIZE > 510 bytes"; \
		rm -f boot_tmp.bin; \
		exit 1; \
	fi; \
	\
	PADDING_NEEDED=$$((510 - $$BOOT_CODE_SIZE)); \
	echo "Padding needed: $$PADDING_NEEDED bytes"; \
	\
	$(ASM) -f bin \
		-D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS \
		-D BOOT_PADDING=$$PADDING_NEEDED \
		boot.asm -o boot.bin; \
	\
	rm -f boot_tmp.bin; \
	\
	FINAL_SIZE=$$(wc -c < boot.bin); \
	if [ $$FINAL_SIZE -ne 512 ]; then \
		echo "❌ Bootloader size incorrect: $$FINAL_SIZE != 512"; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes (protocol compliant)"

# Create OS image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "HoloXlife OS image created: emergeos.img"

# Run in QEMU
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	qemu-system-i386 -drive format=raw,file=emergeos.img -serial stdio

# Clean (UPDATED to clean uart_driver files)
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc boot_tmp.bin uart_driver.ali
	@echo "Build cleaned"
