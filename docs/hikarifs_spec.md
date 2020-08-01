# Hikari file system specification

Hikari FS is a 64-bit FAT-like file system which focuses on simplicity and ease
of implementation. It is ideal for hobbyist operating system developers who want
a straightforward file system solution.

## Bootsector

The bootsector is the very first sector (512 bytes) in a file system and has the
following structure:

| Offset | Size | Name            | Description                                                                           |
| ------ | ---- | --------------- | ------------------------------------------------------------------------------------- |
| 0      | 2    | jump_to_code    | Skips the HkFS header and jumps straight to the boot code. Must be set to 0xEB, 0x1C. |
| 2      | 4    | signature       | File system signature (magic value). Must be equal to "HkFS" in ASCII.                |
| 6      | 2    | version         | BCD-encoded version of the file system implementation. Must be set to 0x0001.         |
| 8      | 8    | block_count     | Total number of blocks in a file system.                                              |
| 16     | 4    | bytes_per_block | Number of bytes in a single block. Must be a multiple of 512.                         |
| 20     | 4    | reserved_blocks | Number of reserved blocks in a file system. Must be at least 1.                       |
| 24     | 4    | main_dir_blocks | Unused; to be removed in a future version.                                            |
| 28     | 484  | boot_code       | Free to use by the implementation.                                                    |

## Reserved blocks

Reserved blocks start on the beginning of a filesystem. Number of reserved blocks
in a filesystem has to be at least 1 and includes the bootsector.

## File allocation table

File allocation table starts immediately after reserved blocks. FAT entries are
contiguous and occupy 8 bytes (64 bits) each.

* 0x00000000_00000000: free-to-use block
* 0x00000000_00000001 - 0xFFFFFFFF_FFFFFFFD: denotes next block in a chain
* 0xFFFFFFFF_FFFFFFFE: reserved block
* 0xFFFFFFFF_FFFFFFFF: last block in a chain

Because file allocation table always occupies full blocks, the length of it can
be calculated as: `(block_count * sizeof(uint64) + bytes_per_block - 1) / bytes_per_block`.

## Main directory

Main directory starts immediately after file allocation table and initially
occupies only a single block. It is no different from any other directory.

## Directories

TODO: Write this section.

## Directory entry

| Offset | Size    | Name              | Description                                                                                         |
| ------ | ------- | ----------------- | --------------------------------------------------------------------------------------------------- |
| 0      | 1       | length            | The length of this entry in bytes. Cannot exceed 256 bytes.                                         |
| 1      | 1       | attributes        | Attributes attached to this entry. See [Directory entry attributes](###Directory-entry-attributes). |
| 2      | 6       | reserved          | Padding. Always set to 0.                                                                           |
| 8      | 8       | size              | File size in bytes. Ignored for directories; should be set to 0.                                    |
| 16     | 8       | creation_time     | Signed 64-bit time since epoch in seconds. Set then the entry is created.                           |
| 24     | 8       | modification_time | Signed 64-bit time since epoch in seconds. Set when the entry changes.                              |
| 32     | 8       | access_time       | Signed 64-bit time since epoch in seconds. Set when the entry is accessed.                          |
| 40     | 8       | first_block       | Index of the first block in the file allocation table.                                              |
| 48     | 1 - 208 | name              | Byte string (never NULL-terminated) describing the name of an entry.                                |

### Directory entry attributes

The following table describes the format of the `attributes` field of each
directory entry.

| Bit | Mask | Name         | Description                                       |
| --- | ---- | ------------ | ------------------------------------------------- |
| 7   | 0x80 | -unused-     | Unused. Should always be set to 0.                |
| 6   | 0x40 | -unused-     | Unused. Should always be set to 0.                |
| 5   | 0x20 | -unused-     | Unused. Should always be set to 0.                |
| 4   | 0x10 | -unused-     | Unused. Should always be set to 0.                |
| 3   | 0x08 | -unused-     | Unused. Should always be set to 0.                |
| 2   | 0x04 | -unused-     | Unused. Should always be set to 0.                |
| 1   | 0x02 | read_only    | Set for read-only files. Ignored for directories. |
| 0   | 0x01 | is_directory | Set for directories, clear for files.             |
