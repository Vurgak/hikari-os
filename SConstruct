#!/usr/bin/env python

import os
import subprocess

env = Environment(platform="posix", tools=["default", "nasm"], ASFLAGS="-f bin")
Export("env")

SConscript("boot/SConscript", variant_dir="build/boot", duplicate=0)
