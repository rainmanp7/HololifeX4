# HoloXlife Pure Ada OS Makefile
ASM = nasm
GCC = gcc-10
LD = ld
OBJCOPY = objcopy

ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O0 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc

LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

.PHONY: all clean run

all: emergeos.img

gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc

kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 kernel_entry.asm -o kernel_entry.o

emergeos.o: emergeos.adb emergeos.ads gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

kernel.elf: kernel_entry.o emergeos.o
	@echo "🔗 Linking Ada Kernel..."
	$(LD) $(LDFLAGS) -o kernel.elf kernel_entry.o emergeos.o

kernel.bin: kernel.elf
	$(OBJCOPY) -O binary kernel.elf kernel.bin

boot.bin: boot.asm kernel.bin
	@KERNEL_SIZE=$$(stat -c%s kernel.bin 2>/dev/null); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	echo "Loading $$SECTORS sectors for kernel ($$KERNEL_SIZE bytes)"; \
	$(ASM) -f bin -DHOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

emergeos.img: boot.bin kernel.bin
	@echo "📀 Creating OS image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "✅ emergeos.img created: $$(stat -c%s $@) bytes"

run: emergeos.img
	@echo "🚀 Booting HoloXlife OS..."
	qemu-system-i386 \
		-drive file=emergeos.img,format=raw,if=floppy \
		-serial stdio \
		-no-reboot -no-shutdown

clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "🧹 Cleaned build artifacts"
