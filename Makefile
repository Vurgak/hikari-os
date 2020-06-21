IMAGE_NAME := hikari-os-0.1.0.img
IMAGE_PATH := build/$(IMAGE_NAME)

QEMU_SERIAL_TARGET ?= file:logs/serial.txt
QEMU_FLAGS := -no-reboot -no-shutdown -m 512M -serial $(QEMU_SERIAL_TARGET)

image:
	tools/write_mbr_entry.py build/boot/bootsector.bin 0 build/boot/bootloader.bin

	dd of=$(IMAGE_PATH) if=/dev/zero bs=1M count=4 2> /dev/null
	dd of=$(IMAGE_PATH) if=build/boot/bootsector.bin seek=0 conv=notrunc 2> /dev/null
	dd of=$(IMAGE_PATH) if=build/boot/bootloader.bin seek=1 conv=notrunc 2> /dev/null

clean:
	scons $(SCONS_VERBOSE) -c
	rm -f build/$(IMAGE_PATH).lock
	rm -f build/$(IMAGE_PATH)

bochs: 
	bochs -f bochsrc

qemu:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

qemu-kvm:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH) -enable-kvm
