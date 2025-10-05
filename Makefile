# Pure Ada HoloXlife OS Makefile - ASSEMBLY BOOTLOADER VERSION
ASM = nasm
GCC = gcc-10
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

all: emergeos.img

# Create Ada configuration file
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc
	@echo "pragma Restrictions (No_Secondary_Stack);" >> gnat.adc

# Compile Assembly Bootloader (CHANGED: from boot.adb to boot.asm)
boot.o: boot.asm
	$(ASM) -f elf32 boot.asm -o boot.o

# Compile Pure Ada kernel
emergeos.o: emergeos.adb emergeos.ads gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

# Pulse-Coupled Core Compilation
pulse_types.o: pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_types.ads -o pulse_types.o

pulse_entities.o: pulse_entities.ads pulse_entities.adb pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_entities.adb -o pulse_entities.o

pulse_sync.o: pulse_sync.ads pulse_sync.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_sync.adb -o pulse_sync.o

# Specialized Entities
hardware_entity.o: hardware_entity.ads hardware_entity.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) hardware_entity.adb -o hardware_entity.o

temporal_entity.o: temporal_entity.ads temporal_entity.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) temporal_entity.adb -o temporal_entity.o

# Kernel Linking
kernel.bin: boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o linker.ld
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities..."
	ld $(LDFLAGS) -o kernel.elf boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o
	objcopy -O binary kernel.elf kernel.bin
	@echo "✅ Kernel linked with Hardware + Temporal Entities"

# Build bootloader from assembly (CHANGED: uses boot.asm directly)
boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building Pure Ada OS with $$SECTORS kernel sectors"; \
	$(ASM) -f bin -D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Create final OS image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "HoloXlife OS (Phase 3: Hardware+Temporal Entities) image created: emergeos.img"

clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "Pure Ada OS + Multi-Entity build cleaned"

.PHONY: all clean
