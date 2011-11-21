#! /usr/bin/python

# Pseudo Tivic Update Server
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
import http.server

fredrsp = '''<?xml version='1.0' standalone='yes'?>
<fredresponse>
    <header>
        <sourceid>FRED</sourceid>
        <version>2.0</version>
    </header>
    <body>
        <fred-to-ta.createacctresp>
        <facrst>false</facrst>
        <status>success</status>
        <filename>?MAC_ADDR={:12}</filename>
        <downloadmethod>https</downloadmethod>
        <downloadaddr>https://prov.teltel.com/</downloadaddr>
        </fred-to-ta.createacctresp>
    </body>
</fredresponse>'''

class tivicHandler(http.server.BaseHTTPRequestHandler):

    def __init__(self, request, client_address, server):
        http.server.BaseHTTPRequestHandler.__init__(self, request, client_address, server)
    
    def do_GET(self):
        print("do_Get")
        print(self.path)
    
    def do_HEAD(self):
        print("head")

    def do_POST(self):
        print("do_POST")
        print(self.headers.get('Content'))
        print(self.path)
        print(self.rfile.read())

# From Python doco
def run(port, server_class=http.server.HTTPServer, handler_class=tivicHandler):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()

def controller():
    opt = optparse.OptionParser(description="Pack start_install fw_install Config" 
        + " Kernel Rootfs into a Tivic firmware image format",
        prog="pseudo_tivic_server",
        version="3.14",
        usage="%prog start_install fw_install config kernel rootfs")

    opt.add_option('--port', '-p',
        action = 'store',
        help='Port for server to sit on',
        default=80)
	
    options, arguments = opt.parse_args()
#    if len(arguments) < 5:
#        opt.print_help()
#        return

    # Start Server
    run(int(options.port))

def main():
    controller()

if __name__ == '__main__':
    main()
