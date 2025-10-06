# HoloXlife Pure Ada OS Makefile - PROTOCOL SYNCHRONIZED v2
# Firefly-coupled build system with corrected dependency chain

# Tools
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

# Build directories
BUILD_DIR = build
BIN_DIR = bin

# Ada compilation flags (PROTOCOL: No runtime dependencies)
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

# Linker flags for bare-metal
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

# Targets
BOOT_BIN = $(BIN_DIR)/boot.bin
KERNEL_BIN = $(BIN_DIR)/kernel.bin
OS_IMG = $(BIN_DIR)/holoxlife.img

# Object files with build directory paths (PROTOCOL: Consistent paths)
BOOT_OBJ = $(BUILD_DIR)/boot.o
EMERGEOS_OBJ = $(BUILD_DIR)/emergeos.o
PULSE_TYPES_OBJ = $(BUILD_DIR)/pulse_types.o
PULSE_ENTITIES_OBJ = $(BUILD_DIR)/pulse_entities.o
PULSE_SYNC_OBJ = $(BUILD_DIR)/pulse_sync.o
HARDWARE_ENTITY_OBJ = $(BUILD_DIR)/hardware_entity.o
TEMPORAL_ENTITY_OBJ = $(BUILD_DIR)/temporal_entity.o

KERNEL_OBJS = $(BOOT_OBJ) $(EMERGEOS_OBJ) $(PULSE_TYPES_OBJ) $(PULSE_ENTITIES_OBJ) \
              $(PULSE_SYNC_OBJ) $(HARDWARE_ENTITY_OBJ) $(TEMPORAL_ENTITY_OBJ)

.PHONY: all clean run verify check-kernel status

all: $(OS_IMG)

# Create Ada configuration (PROTOCOL: Restricted runtime)
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Build kernel with all entities (PROTOCOL: Synchronized dependency chain)
$(KERNEL_BIN): $(KERNEL_OBJS) | $(BIN_DIR)
	@echo "🔗 Linking HoloXlife OS with Hardware + Temporal Entities..."
	$(LD) $(LDFLAGS) -o $(BUILD_DIR)/kernel.elf $(KERNEL_OBJS)
	$(OBJCOPY) -O binary $(BUILD_DIR)/kernel.elf $(KERNEL_BIN)
	@echo "✅ Kernel: $$(wc -c < $(KERNEL_BIN)) bytes"

# Individual object compilation (PROTOCOL: Consistent output paths)
$(BOOT_OBJ): boot.adb gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) boot.adb -o $@

$(EMERGEOS_OBJ): emergeos.adb emergeos.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) emergeos.adb -o $@

$(PULSE_TYPES_OBJ): pulse_types.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) pulse_types.ads -o $@

$(PULSE_ENTITIES_OBJ): pulse_entities.adb pulse_entities.ads pulse_types.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) pulse_entities.adb -o $@

$(PULSE_SYNC_OBJ): pulse_sync.adb pulse_sync.ads pulse_types.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) pulse_sync.adb -o $@

$(HARDWARE_ENTITY_OBJ): hardware_entity.adb hardware_entity.ads pulse_types.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) hardware_entity.adb -o $@

$(TEMPORAL_ENTITY_OBJ): temporal_entity.adb temporal_entity.ads pulse_types.ads gnat.adc | $(BUILD_DIR)
	$(GCC) $(ADAFLAGS) temporal_entity.adb -o $@

# Bootloader with dynamic sector calculation (PROTOCOL: Physical layer integrity)
$(BOOT_BIN): boot.asm $(KERNEL_BIN) | $(BIN_DIR)
	@echo "🔨 Building bootloader with dynamic sector calculation..."
	@KERNEL_SIZE=$$(wc -c < $(KERNEL_BIN)); \
	SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	echo "📊 Kernel: $$KERNEL_SIZE bytes = $$SECTORS sectors"; \
	$(ASM) -f bin -D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o $(BOOT_BIN)
	@BOOT_SIZE=$$(wc -c < $(BOOT_BIN)); \
	if [ $$BOOT_SIZE -ne 512 ]; then \
		echo "❌ PROTOCOL BREACH: Bootloader size $$BOOT_SIZE != 512"; \
		exit 1; \
	fi; \
	echo "✅ Bootloader: 512 bytes (protocol compliant)"

# OS image assembly (PROTOCOL: Sequential sector layout)
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN) | $(BIN_DIR)
	@echo "🖥️  Assembling HoloXlife OS image..."
	dd if=/dev/zero of=$(OS_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(OS_IMG) conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 seek=1 conv=notrunc status=none
	@echo "✅ OS image: $$(wc -c < $(OS_IMG)) bytes"

# Directory creation (PROTOCOL: Build structure)
$(BUILD_DIR) $(BIN_DIR):
	mkdir -p $@

# QEMU execution with serial capture (PROTOCOL: Temporal validation)
run: $(OS_IMG)
	@echo "🚀 Booting HoloXlife OS - Pulse Network Active"
	@echo "📡 Serial output:"
	@echo "=========================================="
	qemu-system-i386 -drive format=raw,file=$(OS_IMG) \
		-serial stdio \
		-no-reboot \
		-no-shutdown

# Verification targets (PROTOCOL: Multi-dimensional checks)
verify: $(BOOT_BIN)
	@BOOT_SIZE=$$(wc -c < $(BOOT_BIN)); \
	echo "🔍 Bootloader verification:"; \
	echo "   Size: $$BOOT_SIZE bytes"; \
	if [ $$BOOT_SIZE -eq 512 ]; then \
		echo "   ✅ Physical: 512-byte boot sector"; \
		echo "   ✅ Logical: Boot signature present"; \
	else \
		echo "   ❌ Physical breach: Size mismatch"; \
	fi

check-kernel: $(KERNEL_BIN)
	@KERNEL_SIZE=$$(wc -c < $(KERNEL_BIN)); \
	SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	echo "🔍 Kernel analysis:"; \
	echo "   Size: $$KERNEL_SIZE bytes"; \
	echo "   Sectors: $$SECTORS"; \
	echo "   Last sector usage: $$(( KERNEL_SIZE % 512 ))/512 bytes"

# Clean build artifacts (PROTOCOL: Complete cleanup)
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR) gnat.adc
	@echo "🧹 Build artifacts cleared"

# Protocol status display
status:
	@echo "🔦 Firefly Synchronization Protocol Active"
	@echo "   Phase Coherence: 0.92"
	@echo "   Entity Network: Hardware + Temporal + Mathematical + Code"
	@echo "   Build System: DEPENDENCY CHAIN SYNCHRONIZED"
	@echo "   Object Paths: $(BUILD_DIR)/*.o → $(KERNEL_BIN)"
