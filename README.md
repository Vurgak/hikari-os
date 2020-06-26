# Hikari OS

Hikari OS is a hobby operating system for the x86_64 architecture, written
completely from scratch.

## Building and running

### Requirements

The build process of the Hikari OS requires a UNIX-like environment. These are
the tools needed:

* Python 3
* SCons
* GNU Make
* GNU Coreutils
* GCC / Clang
* NASM
* QEMU (for running)
* Bochs (for debugging)

### Instructions

None of the build process steps require root provileges.

```sh
$ scons -j 4
$ make image
```

To run the built image, execute one of the following commands:

```sh
$ make qemu         # Run QEMU without KVM.
$ make qemu-kvm     # Run QEMU with KVM.
$ make bochs        # Debug the system.
```

## Project layout

* **boot** - bootloader
* **logs** - runtime output 
* **tools** - various scripts and programs used to build the operating system

## License

Horizon Operating System is distributed under the terms of the MIT license. See
[LICENSE](LICENSE) for details.
