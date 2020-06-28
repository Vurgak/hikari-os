IMAGE_NAME := hikari-os-0.1.0.img
IMAGE_PATH := build/$(IMAGE_NAME)

QEMU_SERIAL_TARGET ?= file:logs/serial.txt
QEMU_FLAGS := -no-reboot -no-shutdown -m 512M -serial $(QEMU_SERIAL_TARGET)

.PHONY: image system-partition clean bochs qemu

image: system-partition
	tools/write_mbr_entry.py build/boot/bootsector.bin 0 build/system_partition.bin

	dd of=$(IMAGE_PATH) if=/dev/zero bs=1M count=64 2> /dev/null
	dd of=$(IMAGE_PATH) if=build/boot/bootsector.bin seek=0 conv=notrunc 2> /dev/null
	dd of=$(IMAGE_PATH) if=build/system_partition.bin seek=1 conv=notrunc 2> /dev/null

system-partition:
	dd of=build/system_partition.bin if=/dev/zero bs=4096 count=16383 2> /dev/null
	dd of=build/system_partition.bin if=build/boot/bootloader.bin seek=0 conv=notrunc 2> /dev/null
	build/tools/hkfs_tools quick-format build/system_partition.bin

clean:
	scons $(SCONS_VERBOSE) -c
	rm -f build/system_partition.bin
	rm -f $(IMAGE_PATH).lock
	rm -f $(IMAGE_PATH)

bochs: 
	bochs -f bochsrc

qemu:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

qemu-kvm:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH) -enable-kvm
