#!/usr/bin/env python2

"""
Requires Python 2!
Usage: write_mbr_entry.py <bootsector file> <partition index> <partition file>
"""

import os
import sys

BYTES_PER_SECTOR = 512
SECTORS_PER_HEAD = 63
HEADS_PER_CYLINDER = 16

MAX_SECTOR = 63
MAX_HEAD = HEADS_PER_CYLINDER - 1

PARTITION_ENTRY_SIZE = 16


def print_usage():
    print "Usage: write_mbr_entry.py <bootsector file> <partition index> <partition file>"


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print_usage()
        sys.exit(1)

    bootsector_file_path = sys.argv[1]
    partition_index = int(sys.argv[2])
    partition_file_path = sys.argv[3]

    if partition_index != 0:
        print "Currently can only write to the first partition entry."
        sys.exit(1)

    partition_size = os.stat(partition_file_path).st_size
    partition_size_in_sectors = (
        partition_size + BYTES_PER_SECTOR - 1
    ) / BYTES_PER_SECTOR

    partition_start_lba = 1

    partition_start_sector = 2
    partition_start_head = 0
    partition_start_cylinder = 0

    partition_end_lba = partition_start_lba + partition_size_in_sectors

    partition_end_sector = (partition_end_lba % SECTORS_PER_HEAD) + 1
    partition_end_head = (partition_end_lba / SECTORS_PER_HEAD) % HEADS_PER_CYLINDER
    partition_end_cylinder = partition_end_lba / (HEADS_PER_CYLINDER * SECTORS_PER_HEAD)

    data = []
    with open(bootsector_file_path, "rb") as f:
        data = bytearray(f.read(BYTES_PER_SECTOR))

    partition_entry_offset = 446 + partition_index * PARTITION_ENTRY_SIZE

    data[partition_entry_offset + 0] = 0x80
    data[partition_entry_offset + 1] = partition_start_head
    data[partition_entry_offset + 2] = partition_start_sector
    data[partition_entry_offset + 3] = partition_start_cylinder
    data[partition_entry_offset + 4] = 0x0C
    data[partition_entry_offset + 5] = partition_end_head
    data[partition_entry_offset + 6] = partition_end_sector
    data[partition_entry_offset + 7] = partition_end_cylinder
    data[partition_entry_offset + 8] = partition_start_lba & 0x000000FF
    data[partition_entry_offset + 9] = (partition_start_lba & 0x0000FF00) >> 8
    data[partition_entry_offset + 10] = (partition_start_lba & 0x00FF0000) >> 16
    data[partition_entry_offset + 11] = (partition_start_lba & 0xFF000000) >> 24
    data[partition_entry_offset + 12] = partition_size_in_sectors & 0x000000FF
    data[partition_entry_offset + 13] = (partition_size_in_sectors & 0x0000FF00) >> 8
    data[partition_entry_offset + 14] = (partition_size_in_sectors & 0x00FF0000) >> 16
    data[partition_entry_offset + 15] = (partition_size_in_sectors & 0xFF000000) >> 24

    data = bytearray(data)
    with open(bootsector_file_path, "wb") as f:
        f.write(data)
