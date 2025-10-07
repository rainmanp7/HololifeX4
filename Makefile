# Test with pure assembly first
ASM = nasm
LD = ld
OBJCOPY = objcopy

all: test.img

test_entry.o: test_entry.asm
	$(ASM) -f elf32 test_entry.asm -o test_entry.o

test.bin: test_entry.o
	$(LD) -m elf_i386 -T linker.ld -o test.elf test_entry.o
	$(OBJCOPY) -O binary test.elf test.bin

boot.bin: boot.asm test.bin
	@KERNEL_SIZE=$$(stat -f%z test.bin 2>/dev/null || stat -c%s test.bin 2>/dev/null); \
	SECTORS=$$(( ($$KERNEL_SIZE + 511) / 512 )); \
	nasm -f bin -DHOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

test.img: boot.bin test.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=test.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "✅ Test image created"

run: test.img
	qemu-system-i386 -drive file=test.img,format=raw,if=floppy -serial stdio

clean:
	rm -f *.bin *.o *.img *.elf
