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
import os
import http.server
import http.client

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

downloadaddr = 'prov.teltel.com'

getrsp = '''phone_number1=1000602425_AT_63.50.teltel.com
pnpn_no=99000124
displayname1=99000124
auth_username1=1000602425@63.50.teltel.com
auth_password1=8095731de192dc54
service_domain=teltel.com
outbound_proxy_ip=209.133.58.69
outbound_proxy_port=443
transport=TLS
image_file=DHS_M6_0911061401.ba
auto_fw_check_time=432000
obp_candidate=202.5.224.91:443,tls|203.153.165.31:443,tls|209.133.58.51:443,tls|202.5.224.85:443,tls|59.151.38.17:443,tls
apvstatus=1
fw_download_url=http://download.tsp.teltel.com/dhs/firmware/starsemi
EdgeProxies=209.133.58.73:443;transport=tls|59.151.38.19:443;transport=tls|59.151.38.31:443;transport=tls
TurnServers=209.133.58.68:3478|202.5.224.224:3478
x_accesskey=71736460873d6604
plugin_prov_url=http://kbsapi.teltel.com/KS_API.php
plugin_verchk_interval=604800
ice_disable=0
gserv_info_url=http://ossapi.tsp.teltel.com/oss_api.php
'''

ASKTELTEL = False
FIRMWAREIMAGE = ''

#/?MAC_ADDR=0026cd00002f&KT_KEY=JoIj1D87N3VupmbY59HPzGhUvsdQOykFde5866b0d355f070d685746ad16b84ea&MY_IMAGE_FILE=DHS_M6_0909102305.ba
class tivicHandler(http.server.BaseHTTPRequestHandler):
    
    mac_re = 'MAC_ADDR=([0-9A-Fa-f]{12})'

    def __init__(self, request, client_address, server):
        http.server.BaseHTTPRequestHandler.__init__(self, request, client_address, server)
        self.details = {}

    def makeDict(self, rsp):
        ret = {}

        for line in rsp.splitlines():
            [key, value] = line.split('=', 1)
            ret[key] = value
        return ret

    def do_GET(self):
        print("Handling GET for {:} request from {:}".format(self.path, self.client_address[0]))
        self.protocol_version = 'HTTP/1.1'
        self.send_response(200)

        if self.path.startswith('/dhs/firmware/starsemi/'):
            global FIRMWAREIMAGE
            print("Wants to download firmware")       
            fsize = os.stat(FIRMWAREIMAGE).st_size
            fwimg = open(FIRMWAREIMAGE, 'rb')
            self.send_header("Content-Type", "text/plain; charset=UTF-8")
            self.send_header("Content-Length", fsize)
            self.end_headers()
            self.wfile.write(fwimg.read())

        elif self.path.startswith('/'):
            rsp = getrsp
            if ASKTELTEL:
                print("Lets request from teltel and get back the bits and pieces we need")
                hc = http.client.HTTPConnection(downloadaddr)
                hc.request('GET', self.path)
                rsp = hc.getresponse().read().decode('UTF-8')
            self.details = self.makeDict(rsp)
            # Check for new firmware once a minute
            self.details["auto_fw_check_time"] = "60"
            dstr = "\n".join("{:}={:}".format(d, self.details[d]) for d in self.details).encode("UTF-8")
            self.send_header("Content-Type", "text/html; charset=UTF-8")
            self.send_header("Content-Length", len(dstr)+7)
            self.end_headers()
            self.wfile.write(dstr)

    def do_HEAD(self):
        print("head")

    def do_POST(self):
        print("Handling POST for {:} request from {:}".format(self.path, self.client_address[0]))
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
    opt = optparse.OptionParser(description="", 
        prog="pseudo_tivic_server",
        version="3.14",
        usage="%prog fw_image")

    opt.add_option('--port', '-p',
        action = 'store',
        help='Port for server to sit on',
        default=80)

    opt.add_option('--ask_teltel', '-a',
        action = 'store_true',
        help='Make requests to tivic servers',
        default=False)
	
    options, arguments = opt.parse_args()
    ASKTELTEL = options.ask_teltel

    if len(arguments) < 1:
        opt.print_help()
        return
    
    global FIRMWAREIMAGE
    FIRMWAREIMAGE = arguments[0]

    # Start Server
    run(int(options.port))

def main():
    controller()

if __name__ == '__main__':
    main()
