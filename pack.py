#! /usr/bin/python

# Tivic firmware packer
# Copyright (C) 2011 hank@sideramota
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import optparse
import struct
import array
import os
import sys

# Take byte array and return a stringisation of it
def bytesTostring(barray):
    return array.array('B', barray).tostring()

def make_streams_binary():
    sys.stdin = sys.stdin.detach()
    sys.stdout = sys.stdout.detach()

def controller():


    opt = optparse.OptionParser(description="Pack start_install fw_install Config" 
        + " Kernel Rootfs into a Tivic firmware image format",
        prog="pack",
        version="3.14",
        usage="%prog start_install fw_install config kernel rootfs")

    options, arguments = opt.parse_args()
    if len(arguments) < 5:
        opt.print_help()
        return

    make_streams_binary()

    # File parts
    start_install = arguments[0]
    fw_intall = arguments[1]
    config = arguments[2]
    kernel = arguments[3]
    rootfs = arguments[4]

    # Assumptions made
    # 1. There are only 5 files start_install.sh fw_install.elf config kernel 
    #    rootfs
    # 2. File starts with !teltel-dhs!
    # 3. File size info starts at byte 0x16
    # 4. File size info is of the format [name-size][file-size]
    #                                    [ 1 byte  ][ 4 bytes ]   
    numfiles = 5
    companytag = "!teltel-dhs!"
    sizestart = 0x15

    # Common int to all fw I have seen. Perhaps versioning?
    unknown_padding = bytearray([0x00, 0x00, 0x00, 0x00, 0x03])

    # Start 
    sys.stderr.write("Starting...\n")
    
    # Header
    fw = bytearray()
    fw += companytag.encode()
    # Check sum occupies int here
    fw += unknown_padding
    
    # File names and sizes
    for f in arguments:
        fsize = os.stat(f).st_size
        nsize = len(f)
        sys.stderr.write("File: {:20} NameSize: {:10} FileSize: {:10,}\n".format(f,
            nsize, fsize))
        filesizing = struct.pack("<1B1I", nsize, fsize)
        fw += filesizing
 
    # Calculate checksum   
    structformat = "<1B"
    structsize = struct.calcsize(structformat)
    checksum = 0
    print(fw[0])
    for x in range(len(fw)):
        ub = struct.unpack(structformat, fw[x])[0]
        checksum += ub
    for f in arguments:
        fp = open(f, 'rb')
        while 1:
            b = fp.read(structsize)
            if not b:
                break
            ub = struct.unpack(structformat, b)[0]
            checksum += ub
    structformat = "<1I"
    fw.insert(len(companytag), struct.pack(structformat, checksum))

    # Output header
    sys.stdout.write(fw)
    fw = bytearray()

    # Dump the files
    for f in arguments:
        sys.stdout.write(f.strip().encode("utf-8"))
        fp = open(f, 'rb')
        sys.stdout.write(fp.read())
        fp.close()

    sys.stderr.write("Finished...\n")

def main():
    controller()

if __name__ == '__main__':
    main()
