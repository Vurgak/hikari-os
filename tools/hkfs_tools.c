#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_DIRECTORY_ENTRY_NAME_LENGTH 208

#define HKFS_END_OF_CHAIN 0xFFFFFFFFFFFFFFFF

enum hkfs_header_offsets_t
{
    HKFS_HEADER_JUMP_TO_CODE_OFFSET = 0,
    HKFS_HEADER_SIGNATURE_OFFSET = 2,
    HKFS_HEADER_VERSION_OFFSET = 6,
    HKFS_HEADER_BLOCK_COUNT_OFFSET = 8,
    HKFS_HEADER_BYTES_PER_BLOCK_OFFSET = 16,
    HKFS_HEADER_RESERVED_BLOCKS_OFFSET = 20,
    HKFS_MAIN_DIRECTORY_BLOCKS_OFFSET = 24
};

struct directory_entry_t
{
    uint8_t length; // Length of the entry.
    uint8_t attributes;
    uint8_t reserved[6];
    uint64_t size; // File size in bytes.
    uint64_t creation_time;
    uint64_t modification_time;
    uint64_t access_time;
    uint64_t starting_block;
    uint8_t *name;
};

uint8_t read_byte(FILE *image_file, size_t *position)
{
    uint8_t value;
    fseek(image_file, *position, SEEK_SET);
    fread(&value, sizeof(uint8_t), 1, image_file);
    *position += sizeof(uint8_t);
    return value;
}

uint16_t read_word(FILE *image_file, size_t *position)
{
    uint16_t value;
    fseek(image_file, *position, SEEK_SET);
    fread(&value, sizeof(uint16_t), 1, image_file);
    *position += sizeof(uint16_t);
    return value;
}

uint32_t read_dword(FILE *image_file, size_t *position)
{
    uint32_t value;
    fseek(image_file, *position, SEEK_SET);
    fread(&value, sizeof(uint32_t), 1, image_file);
    *position += sizeof(uint32_t);
    return value;
}

uint64_t read_qword(FILE *image_file, size_t *position)
{
    uint64_t value;
    fseek(image_file, *position, SEEK_SET);
    fread(&value, sizeof(uint64_t), 1, image_file);
    *position += sizeof(uint64_t);
    return value;
}

void write_byte(FILE *file, size_t *position, const uint8_t value)
{
    fseek(file, *position, SEEK_SET);
    fwrite(&value, sizeof(uint8_t), 1, file);
    *position += sizeof(uint8_t);
}

void write_word(FILE *file, size_t *position, const uint16_t value)
{
    fseek(file, *position, SEEK_SET);
    fwrite(&value, sizeof(uint16_t), 1, file);
    *position += sizeof(uint16_t);
}

void write_dword(FILE *file, size_t *position, const uint32_t value)
{
    fseek(file, *position, SEEK_SET);
    fwrite(&value, sizeof(uint32_t), 1, file);
    *position += sizeof(uint32_t);
}

void write_qword(FILE *file, size_t *position, const uint64_t value)
{
    fseek(file, *position, SEEK_SET);
    fwrite(&value, sizeof(uint64_t), 1, file);
    *position += sizeof(uint64_t);
}

void print_usage()
{
    puts("Usage: hfs_tools <action> [arguments]");
    puts("");
    puts("Actions:");
    puts("\timport\t\tTODO: Add description.");
    puts("\tquick-format\tTODO: Add description.");
}

uint64_t find_first_free_block_in_fat(FILE *image_file, const uint64_t start_from, const uint64_t fat_end)
{
    for (uint64_t entry_index = start_from; entry_index < fat_end; entry_index += sizeof(uint64_t))
    {
        uint64_t position = entry_index;
        if (read_qword(image_file, &position) == 0)
        {
            return entry_index;
        }
    }
    return 0;
}

struct directory_entry_t *make_directory_entry(const char *entry_name, uint64_t file_size, uint64_t starting_block)
{
    struct directory_entry_t *directory_entry = malloc(sizeof(struct directory_entry_t));
    memset(directory_entry, '\0', sizeof(struct directory_entry_t));

    const int entry_name_length = strlen(entry_name);
    if (entry_name_length > MAX_DIRECTORY_ENTRY_NAME_LENGTH)
    {
        fprintf(stderr, "Maximum directory entry length is %d, but a name of length %d was given.\n",
                MAX_DIRECTORY_ENTRY_NAME_LENGTH, entry_name_length);
        return NULL;
    }

    directory_entry->length = (uint8_t)entry_name_length + 48;
    directory_entry->name = malloc(entry_name_length);
    strncpy(directory_entry->name, entry_name, entry_name_length);

    directory_entry->size = file_size;
    directory_entry->starting_block = starting_block;

    return directory_entry;
}

void free_directory_entry(struct directory_entry_t *directory_entry)
{
    free(directory_entry->name);
    free(directory_entry);
}

/**
 * Read a directory entry from an image file.
 *
 * @note Remember to free 'entry' when it's no longer needed!
 *
 * @param image_file
 * @param position
 * @param entry
 *
 * @return 0 if the directory was read; 1 otherwise; -1 when the entry was invalid.
 */
int read_directory_entry(FILE *image_file, size_t position, struct directory_entry_t *directory_entry)
{
    const uint8_t length = read_byte(image_file, &position);
    if (length == 0)
    {
        directory_entry = NULL;
        return 1;
    }
    if (length > 256)
    {
        directory_entry = NULL;
        return -1;
    }

    if (directory_entry == NULL)
        return 0;

    directory_entry = malloc(sizeof(struct directory_entry_t));
    directory_entry->length = length;

    const int name_length = length - 48;
    directory_entry->name[name_length] = '\0';

    position += 6; // Skip reserved area.

    directory_entry->size = read_qword(image_file, &position);
    directory_entry->creation_time = read_qword(image_file, &position);
    directory_entry->modification_time = read_qword(image_file, &position);
    directory_entry->access_time = read_qword(image_file, &position);
    directory_entry->starting_block = read_qword(image_file, &position);

    for (size_t i = 0; i < name_length; ++i)
        directory_entry->name[i] = read_byte(image_file, &position);

    return 0;
}

uint64_t find_first_free_directory_entry_position(FILE *image_file, const uint64_t directory_start, const uint64_t directory_length)
{
    const uint64_t directory_end = directory_start + directory_length;

    for (uint64_t directory_iterator = directory_start; directory_iterator < directory_end; ++directory_iterator)
    {
        const uint64_t directory_entry_position = directory_iterator;
        if (read_directory_entry(image_file, directory_entry_position, NULL) != 0)
            return directory_entry_position;
    }

    return 0;
}

int write_directory_entry(
    FILE *image_file,
    const uint64_t main_directory_start,
    const uint64_t main_directory_length,
    const struct directory_entry_t *directory_entry)
{
    if (directory_entry == NULL)
        return 1;

    const uint64_t free_directory_entry_position = find_first_free_directory_entry_position(image_file, main_directory_start, main_directory_length);
    if (free_directory_entry_position == 0xFFFFFFFFFFFFFFFF)
        return 1;

    uint64_t write_ptr = free_directory_entry_position;

    write_byte(image_file, &write_ptr, directory_entry->length);
    write_byte(image_file, &write_ptr, directory_entry->attributes);

    for (int i = 0; i < 6; ++i)
        write_byte(image_file, &write_ptr, 0);

    write_qword(image_file, &write_ptr, directory_entry->size);
    write_qword(image_file, &write_ptr, directory_entry->creation_time);
    write_qword(image_file, &write_ptr, directory_entry->modification_time);
    write_qword(image_file, &write_ptr, directory_entry->access_time);
    write_qword(image_file, &write_ptr, directory_entry->starting_block);

    fwrite(directory_entry->name, sizeof(char), strlen(directory_entry->name), image_file);

    return 0;
}

size_t get_file_size(FILE *file)
{
    int old_position = ftell(file);
    fseek(file, 0, SEEK_END);
    int file_size = ftell(file);
    fseek(file, old_position, SEEK_SET);
    return file_size;
}

void copy_file_to_file(FILE *source_file, uint64_t source_position, uint64_t data_length, FILE *destination_file,
                       uint64_t destination_position)
{
    // TODO: Check if the buffer was allocated successfully.
    // TODO: Check if fread/fwrite read/wrote a correct amount of bytes.
    // TODO: Check if we don't exceed file size on read/write.

    uint8_t *buffer = calloc(data_length, sizeof(uint8_t));

    fseek(source_file, source_position, SEEK_SET);
    fread(buffer, sizeof(uint8_t), data_length, source_file);

    fseek(destination_file, destination_position, SEEK_SET);
    fwrite(buffer, sizeof(uint8_t), data_length, destination_file);

    free(buffer);
}

int import_file(const int argc, const char *argv[], FILE *image_file, const size_t image_size)
{
    if (argc < 1)
    {
        fprintf(stderr, "Missing argument: path to the file to import.\n");
        return 1;
    }

    const char *file_to_import_path = argv[0];
    FILE *file_to_import = fopen(file_to_import_path, "rb");
    if (!file_to_import)
    {
        fprintf(stderr, "Error: Failed to open the file to import.\n");
        return 1;
    }

    if (argc < 2)
    {
        fprintf(stderr, "Missing argument: target file name.\n");
    }
    const char *target_file_name = argv[1];

    size_t position = HKFS_HEADER_BLOCK_COUNT_OFFSET;

    const uint64_t block_count = read_qword(image_file, &position);
    const uint32_t bytes_per_block = read_dword(image_file, &position);
    const uint32_t reserved_blocks = read_dword(image_file, &position);
    const uint32_t main_directory_blocks = read_dword(image_file, &position);

    const uint64_t fat_offset_in_bytes = reserved_blocks * bytes_per_block;
    const uint64_t fat_length_in_blocks = (block_count * sizeof(uint64_t) + bytes_per_block - 1) / bytes_per_block;
    const uint64_t fat_end = fat_offset_in_bytes + fat_length_in_blocks * bytes_per_block;

    const uint64_t main_directory_start = (reserved_blocks + fat_length_in_blocks) * bytes_per_block;
    const uint64_t main_directory_length = main_directory_blocks * bytes_per_block;
    const uint64_t main_directory_end = main_directory_start + main_directory_length;

    // Find first free main directory entry.
    uint64_t free_main_directory_entry_position = find_first_free_directory_entry_position(image_file, main_directory_start, main_directory_length);

    // Write the chain to the FAT and copy the file contents at the same time.
    uint64_t file_to_import_size = get_file_size(file_to_import);
    uint64_t file_block_count = (file_to_import_size + bytes_per_block - 1) / bytes_per_block;
    uint64_t free_block = (find_first_free_block_in_fat(image_file, fat_offset_in_bytes, fat_end) - fat_offset_in_bytes) / sizeof(uint64_t);
    const uint64_t first_block = free_block;
    for (uint64_t block_iterator = 0; block_iterator < file_block_count; ++block_iterator)
    {
        const uint64_t src_position = block_iterator * bytes_per_block;
        const uint64_t dst_position = free_block * bytes_per_block;

        if (block_iterator != file_block_count - 1)
        {
            // Copy file contents.
            copy_file_to_file(
                file_to_import, src_position, bytes_per_block, image_file, dst_position);

            // Write the link to the chain.
            uint64_t entry_offset = fat_offset_in_bytes + free_block * sizeof(uint64_t);
            free_block = find_first_free_block_in_fat(image_file, entry_offset + sizeof(uint64_t), fat_end);
            write_qword(image_file, &entry_offset, free_block);
        }
        else
        {
            // Copy file contents.
            const uint64_t data_to_copy_size = file_to_import_size % bytes_per_block == 0
                                                   ? bytes_per_block
                                                   : file_to_import_size % bytes_per_block;
            copy_file_to_file(
                file_to_import, src_position, data_to_copy_size, image_file, dst_position);

            // Write the link to the chain.
            uint64_t entry_offset = fat_offset_in_bytes + free_block * sizeof(uint64_t);
            write_qword(image_file, &entry_offset, HKFS_END_OF_CHAIN);
        }
    }

    // Write the entry to the main directory.
    const struct directory_entry_t *directory_entry = make_directory_entry(target_file_name, file_to_import_size,
                                                                           first_block);
    const int directory_entry_write_status = write_directory_entry(
        image_file, main_directory_start, main_directory_length, directory_entry);
    if (directory_entry_write_status == 1)
    {
        fprintf(stderr, "Error: Entry with the given target name already exists.\n");
        return 1;
    }
    if (directory_entry_write_status == 2)
    {
        fprintf(stderr, "Error: The root directory if full.\n");
        return 1;
    }

    return 0;
}

int quick_format(const int argc, const char *argv[], FILE *image_file, const size_t image_size)
{
    size_t position = 0;

    // Jump to code.
    write_byte(image_file, &position, 0xEB);
    write_byte(image_file, &position, 0x1A);

    // Signature.
    write_byte(image_file, &position, 'H');
    write_byte(image_file, &position, 'k');
    write_byte(image_file, &position, 'F');
    write_byte(image_file, &position, 'S');

    // Version.
    write_word(image_file, &position, 0x0001);

    const uint32_t bytes_per_block = 4096;
    const uint64_t block_count = (image_size + bytes_per_block - 1) / bytes_per_block;
    const uint32_t reserved_blocks = 4;
    const uint32_t main_directory_size = 4;

    // Number of blocks.
    if (image_size % bytes_per_block != 0)
    {
        fprintf(stderr, "Warning: Image size is not block-aligned.\n");
    }

    // Fields that carry important information about the file system.
    write_qword(image_file, &position, block_count);
    write_dword(image_file, &position, bytes_per_block);
    write_dword(image_file, &position, reserved_blocks);
    write_dword(image_file, &position, main_directory_size);

    // Bootable signature.
    // position = 510;
    // write_byte(image_file, &position, 0x55);
    // write_byte(image_file, &position, 0xAA);

    uint64_t fat_start = reserved_blocks * bytes_per_block;
    uint64_t fat_size = (block_count * sizeof(uint64_t) + bytes_per_block - 1) / bytes_per_block;
    for (size_t i = 0; i < reserved_blocks + fat_size + main_directory_size; ++i)
    {
        uint64_t position = fat_start + i * sizeof(uint64_t);
        write_qword(image_file, &position, 0xFFFFFFFFFFFFFFFE);
    }

    return 0;
}

int main(const int argc, const char *argv[])
{
    if (argc < 2)
    {
        print_usage();
        return 0;
    }

    const char *action_name = argv[1];

    if (argc < 3)
    {
        fprintf(stderr, "Missing argument: image file path.\n");
        return 0;
    }
    const char *image_path = argv[2];
    FILE *image_file = fopen(image_path, "rb+");
    if (!image_file)
    {
        fprintf(stderr, "Error: Failed to open the image file.\n");
        return 1;
    }
    fseek(image_file, 0, SEEK_END);
    const size_t image_size = ftell(image_file);
    fseek(image_file, 0, SEEK_SET);

    int exit_code = 0;
    const int action_argc = argc - 3;
    const char **action_argv = argv + 3;
    if (strcmp(action_name, "import") == 0)
        exit_code = import_file(action_argc, action_argv, image_file, image_size);
    else if (strcmp(action_name, "quick-format") == 0)
        exit_code = quick_format(action_argc, action_argv, image_file, image_size);
    else
    {
        fprintf(stderr, "Error: Unknown action specified.\n");
        exit_code = 1;
    }

    fclose(image_file);

    return exit_code;
}
