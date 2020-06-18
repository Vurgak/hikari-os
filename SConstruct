import os

version = '0.1.0-dev'
image_name = f'hikari-os-{version}.img'

env = Environment(platform='posix', tools=['default', 'nasm'],
    ASFLAGS='-f bin')
Export('env')

SConscript('boot/SConscript', variant_dir='build/boot', duplicate=0)

AlwaysBuild(Command(image_name, '', f'dd of=build/$TARGET if=/dev/zero bs=1M count=4 2> /dev/null'))
AlwaysBuild(Command(image_name, '', f'dd of=build/$TARGET if=build/boot/bootsector.bin seek=0 conv=notrunc 2> /dev/null'))
