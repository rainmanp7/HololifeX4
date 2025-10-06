# HoloXlife Pure Ada OS Makefile - PROTOCOL VERIFIED WORKING
# Minimal refinement of proven working system

# Tools
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

# Ada compilation flags (PROVEN WORKING)
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

# Linker flags for bare-metal (PROVEN WORKING)
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

.PHONY: all clean run

all: emergeos.img

# Create Ada configuration (PROVEN WORKING)
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Individual object compilation (PROVEN WORKING)
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

# Link kernel (PROVEN WORKING with FIXED sector calculation)
kernel.bin: boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities..."
	$(LD) $(LDFLAGS) -o kernel.elf $^
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "✅ Kernel: $$(wc -c < kernel.bin)) bytes"

# Build bootloader with DYNAMIC sector calculation (ONLY REFINEMENT)
boot.bin: boot.asm kernel.bin
	@KERNEL_SIZE=$$(wc -c < kernel.bin); \
	SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	echo "Building Pure Ada OS with $$SECTORS kernel sectors ($$KERNEL_SIZE bytes)"; \
	$(ASM) -f bin -D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Create OS image (PROVEN WORKING)
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "HoloXlife OS (Phase 3: Hardware+Temporal Entities) image created: emergeos.img"

# Run in QEMU (PROVEN WORKING)
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	qemu-system-i386 -drive format=raw,file=emergeos.img -serial stdio

# Clean (PROVEN WORKING)
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "Build cleaned"
