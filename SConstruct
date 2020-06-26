#!/usr/bin/env python

import os
import subprocess

host_env = Environment(tools=["default", "nasm"], ASFLAGS="-f bin")
host_env.Append(CCFLAGS="-g")
Export("host_env")

boot_dir = SConscript("boot/SConscript", variant_dir="build/boot", duplicate=0)
tools_dir = SConscript("tools/SConscript", variant_dir="build/tools", duplicate=0)
