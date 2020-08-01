ROOT_DIR :=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR := $(ROOT_DIR)/build
TOOLS_DIR := $(ROOT_DIR)/tools

IMAGE_NAME := hikari-os-0.1.0.img
IMAGE_PATH := $(ROOT_DIR)/build/$(IMAGE_NAME)

QEMU_SERIAL_TARGET ?= file:logs/serial.txt
QEMU_FLAGS := -no-reboot -no-shutdown -m 512M -serial $(QEMU_SERIAL_TARGET)

.PHONY: image system-partition clean bochs qemu

all:
	scons
	$(MAKE) image

image: system-partition
	$(TOOLS_DIR)/write_mbr_entry.py build/boot/bootsector.bin 0 build/system_partition.bin

	dd of=$(IMAGE_PATH) if=/dev/zero bs=1M count=64 2> /dev/null
	dd of=$(IMAGE_PATH) if=$(BUILD_DIR)/boot/bootsector.bin seek=0 conv=notrunc 2> /dev/null
	dd of=$(IMAGE_PATH) if=$(BUILD_DIR)/system_partition.bin seek=1 conv=notrunc 2> /dev/null

system-partition:
	dd of=$(BUILD_DIR)/system_partition.bin if=/dev/zero bs=4096 count=16383 2> /dev/null
	dd of=$(BUILD_DIR)/system_partition.bin if=$(BUILD_DIR)/boot/bootloader.bin seek=0 conv=notrunc 2> /dev/null
	$(BUILD_DIR)/tools/hkfs_tools quick-format $(BUILD_DIR)/system_partition.bin
	$(BUILD_DIR)/tools/hkfs_tools import $(BUILD_DIR)/system_partition.bin kernel/kernel_dummy.txt kernel.bin

clean:
	scons $(SCONS_VERBOSE) -c
	rm -f $(BUILD_DIR)/system_partition.bin
	rm -f $(IMAGE_PATH).lock
	rm -f $(IMAGE_PATH)

bochs: 
	bochs -f bochsrc

qemu:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

qemu-kvm:
	qemu-system-x86_64 $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH) -enable-kvm
