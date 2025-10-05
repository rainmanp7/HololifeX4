# Pure Ada HoloXlife OS Makefile - NO RUNTIME DEPENDENCIES
ASM = nasm
GCC = gcc-10
# Use GCC directly for Ada compilation (bypass gnatmake)
# CRITICAL: Remove -gnatwa (all warnings) and -gnatwo (warnings as errors) for boot files
BOOT_ADAFLAGS = -x ada -gnat2012 -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc \
           -gnatg  # CRITICAL: Enable GNAT implementation features for machine code

# Keep style checking for non-boot files
ADAFLAGS = $(BOOT_ADAFLAGS) -gnatwa -gnatwo

# Linker flags for bare-metal Ada
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static
BOCHS = bochs
BOCHS_CONFIG = bochsrc.txt

all: emergeos.img

# Create Ada configuration file (restricts runtime features)
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc
	@echo "pragma Restrictions (No_Secondary_Stack);" >> gnat.adc

# Compile bootloader in Ada - NO STYLE CHECKING FOR BOOT FILES
boot.o: boot.adb gnat.adc system.ads
	@echo "🔧 Compiling bootloader (style checks disabled for bare metal)..."
	$(GCC) $(BOOT_ADAFLAGS) boot.adb -o boot.o
	@echo "✅ Bootloader compiled with machine code support"

# Compile Pure Ada kernel using GCC directly (no gnatmake)
emergeos.o: emergeos.adb emergeos.ads gnat.adc system.ads
	@echo "🔧 Compiling kernel (style checks disabled for bare metal)..."
	$(GCC) $(BOOT_ADAFLAGS) emergeos.adb -o emergeos.o
	@echo "✅ Kernel compiled with machine code support"

# ===========================================
# PULSE-COUPLED CORE COMPILATION (PHASE 1)
# ===========================================

# Compile Pulse-Coupled Core Types
pulse_types.o: pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_types.ads -o pulse_types.o

# Compile Base Entity Framework
pulse_entities.o: pulse_entities.ads pulse_entities.adb pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_entities.adb -o pulse_entities.o

# Compile Synchronization Engine
pulse_sync.o: pulse_sync.ads pulse_sync.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_sync.adb -o pulse_sync.o

# ===========================================
# PHASE 3: SPECIALIZED ENTITIES COMPILATION
# ===========================================

# Compile Hardware Entity
hardware_entity.o: hardware_entity.ads hardware_entity.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) hardware_entity.adb -o hardware_entity.o

# Compile Temporal Entity (NEW - PHASE 3 WEEK 2)
temporal_entity.o: temporal_entity.ads temporal_entity.adb pulse_types.ads pulse_entities.ads gnat.adc
	$(GCC) $(ADAFLAGS) temporal_entity.adb -o temporal_entity.o

# ===========================================
# ENHANCED KERNEL LINKING WITH MULTI-ENTITY NETWORK
# ===========================================

# Link Pure Ada OS kernel with Hardware + Temporal Entities
kernel.bin: boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o linker.ld
	@echo "Linking HoloXlife OS with Hardware + Temporal Entities..."
	ld $(LDFLAGS) -o kernel.elf boot.o emergeos.o pulse_types.o pulse_entities.o pulse_sync.o hardware_entity.o temporal_entity.o
	objcopy -O binary kernel.elf kernel.bin
	@echo "✅ Kernel linked with Hardware + Temporal Entities"
	@echo "📊 Kernel size: $$(stat -c%s kernel.bin) bytes"

# Build bootloader from assembly
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
	@echo "🎉 HoloXlife OS (Phase 3: Hardware+Temporal Entities) image created: emergeos.img"
	@echo "📊 Image size: $$(stat -c%s emergeos.img) bytes"

# Run Pure Ada OS in Bochs
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System with Hardware+Temporal Entities..."
	$(BOCHS) -f $(BOCHS_CONFIG)

# Clean build artifacts (including all entities)
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "🧹 Pure Ada OS + Multi-Entity build cleaned"

# Build info target
info:
	@echo "🔧 HoloXlife Pure Ada OS Build Information:"
	@echo "   Compiler: $(GCC)"
	@echo "   Assembler: $(ASM)"
	@echo "   Boot Flags: -gnat2012 -gnatg (no style checks)"
	@echo "   Entity Flags: -gnatwa -gnatwo (full style checks)"
	@echo "   Entities: Hardware + Temporal (Phase 3)"
	@echo "   Features: Direct VGA memory access, Pulse-coupled sync"

.PHONY: all clean run info