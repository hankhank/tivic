#! /usr/bin/python2.7

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

# Take byte array and return a stringisation of it
def bytesTostring(barray):
    return array.array('B', barray).tostring()

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
    # Think this section is CRC/Verioning/something. This one came from image
    # DHS_M6_0911061401.ba
    unknown_magic_int = [0xbe, 0x37, 0x2a, 0x24] 

    # Start 
    print("Starting...")
    
    # Header
    fw = ''
    fw += companytag
    fw += bytesTostring(unknown_magic_int)
    
    # Calculate name and file sizes
    for f in arguments:
        fsize = os.stat(f).st_size
        nsize = len(f)
        print("File: {:20} NameSize: {:10} FileSize: {:10,}".format(f, nsize, fsize))
        filesizing = struct.pack('BI', nsize, fsize)
        fw += filesizing
    print fw
    exit()
    # Test for company tag
    print("Checking company tag")
    startstring = fw.read(len(companytag))
    if(not startstring == companytag):
        print "The company tag was missing or incorrect. We read " + startstring
        + " but expected " + companytag
    
    # Goto file sizes and read them out
    fw.seek(sizestart)
    structformat = "<1B1I"
    structsize = struct.calcsize(structformat)
    filesizes = []
    for i in range(0,numfiles):
        filesizes.append(struct.unpack(structformat,fw.read(structsize)))
    
    # Dump the files
    for fs in filesizes:
        name = fw.read(fs[0])
        print "Now reading and writing file " + name
        outfile = open(name, 'w')
        outfile.write(fw.read(fs[1]))
        outfile.close()

def main():
    controller()

if __name__ == '__main__':
    main()
