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
