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

.PHONY: all clean run

all: emergeos.img

# Create Ada configuration
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Individual object compilation (NO boot.o — entry is in emergeos.adb)
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

# SIMPLE UART DRIVER COMPILATION
uart.o: uart.adb uart.ads gnat.adc
	$(GCC) $(ADAFLAGS) uart.adb -o uart.o

# Link kernel — NO boot.o
kernel.bin: emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o uart.o
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities + Simple UART..."
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "✅ Kernel: $$(wc -c < kernel.bin) bytes"

# Build bootloader — PROTECTED MODE, FIXED SIZE
boot.bin: boot.asm kernel.bin
	@KERNEL_SIZE=$$(wc -c < kernel.bin); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	echo "Kernel: $$KERNEL_SIZE bytes = $$SECTORS sectors"; \
	nasm -f bin -D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin; \
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
		-drive format=raw,file=emergeos.img \
		-serial file:serial.log \
		-D qemu.log -d int,cpu_reset,guest_errors \
		-display sdl

# Clean
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc uart.ali
	@echo "Build cleaned"
