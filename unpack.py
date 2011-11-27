#! /usr/bin/python

# Tivic firmware unpacker
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

def controller():
    opt = optparse.OptionParser(description="Unpack Tivic firmware images into"+
        " the seperate files it contains",
        prog="unpack",
        version="3.14",
        usage="%prog FIRMWARE.ba")

    opt.add_option('--details', '-d',
        action = 'store_true',
        help='Extract and print header and file details',
        default=80)

    options, arguments = opt.parse_args()
    if len(arguments) < 1:
        opt.print_help()
        return
    firmware = arguments[0]
    # Assumptions made
    # 1. There are only 5 files start_install.sh fw_install.elf config kernel 
    #    rootfs
    # 2. File starts with !teltel-dhs!
    # 3. File size info starts at byte 0x16
    # 4. File size info is of the format [name-size][file-size]
    #                                    [ 1 byte  ][ 4 bytes ]   
    numfiles = 5
    companytag = b'!teltel-dhs!'
    sizestart = 0x15

    # Start 
    print("Starting...")
    fw = open(firmware, 'rb')
    
    # Test for company tag
    print("Checking company tag")
    startstring = fw.read(len(companytag))
    if(not startstring == companytag):
        print("The company tag was missing or incorrect. We read " 
            + startstring.decode("utf-8") + " but expected " + companytag)
    
    # Get Magic Number
    structformat = "<1I"
    structsize = struct.calcsize(structformat)
    magicnumber = struct.unpack(structformat,fw.read(structsize))[0]
    if options.details:
        print("Magic Number: {:,} {:,}".format(fwsize/8, fwsize/8/1024/1024))

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
        if options.details:
            print("Filename: {:<20s} Size: {:>12,d}".format(name.decode("UTF-8"), fs[1]))
            fw.read(fs[1]) # read to skip through file
        else:
            print("Extracting file " + name.decode("utf-8"))
            outfile = open(name, 'wb')
            outfile.write(fw.read(fs[1]))
            outfile.close()

def main():
    controller()

if __name__ == '__main__':
    main()
