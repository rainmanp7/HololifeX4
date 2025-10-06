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
# Individual object compilation (NO boot.o — it doesn't exist)
emergeos.o: emergeos.adb emergeos.ads gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o
pulse_types.o: pulse_types.ads gnat.adc
	$(GCC) $(ADAFLAGS) pulse_types.ads -o pulse_types.o
pulse_entities.o: pulse_entities.adb pulse_entities.ads pulse_types.ads gnat
