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
import cgi
import re
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
        <downloadmethod>http</downloadmethod>
        <downloadaddr>http://prov.teltel.com/</downloadaddr>
      </fred-to-ta.createacctresp>
    </body>
        </fredresponse>'''

class tivicHandler(http.server.BaseHTTPRequestHandler):
    
    mac_re = 'MAC_ADDR=([0-9A-Fa-f]{12})'

    def __init__(self, request, client_address, server):
        http.server.BaseHTTPRequestHandler.__init__(self, request, client_address, server)

    def do_GET(self):
        print("do_Get")
        print(self.path)
    
    def do_HEAD(self):
        print("head")

    def do_POST(self):
        print("Handling POST for {:} request from {:}".format(self.path, self.client_address[0]))
        #self.send_response(100)
        self.protocol_version = 'HTTP/1.1'
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=UTF-8")
        self.send_header("Content-Length", len(fredrsp)+7)
        self.end_headers()

        # First request sent by tivic. Looking for fred response 
        # which tells it where to get its shit from
        if self.path.endswith("index.php"):
            data = self.rfile.read(21) # blocks unless we specify how long to expect
            mac = re.match(self.mac_re, data.decode("utf-8"))
            if mac:
                print(fredrsp.format(mac.group(1)),'UTF-8')
                self.wfile.write(bytes(fredrsp.format(mac.group(1)),'UTF-8'))
            return

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
