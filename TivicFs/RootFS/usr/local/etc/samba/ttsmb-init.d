#!/bin/sh

# check if /etc/samba exist if not copy it
if [ ! -d /etc/samba ] ;
then
   cp -a /usr/local/etc/samba /etc/samba
fi

# check if the /etc/samba/samba-init.d exist
if [ ! -e /etc/samba/samba-init.d ];
then
   ln -s /usr/local/etc/samba/samba-init.d /etc/samba/samba-init.d
else
# check if /etc/samba/samba-init.d is a link if not replace it and link it to /usr/local/etc/samba/samba-init.d.
   if [ ! -L /etc/samba/samba-init.d ];
   then
   rm -f /etc/samba/samba-init.d
   ln -s /usr/local/etc/samba/samba-init.d /etc/samba/samba-init.d
   fi
fi

# check if the /etc/samba/smb.conf exist
if [ ! -e /etc/samba/smb.conf ];
then
   cp -a /usr/local/etc/samba /etc/samba
else
   if [ ! `grep "\[home\]" /etc/samba/smb.conf` ];
   then
      cp -a /usr/local/etc/samba/smb.conf /etc/samba/
   fi
fi

# check /flash/root/config/sys.conf to determine start/stop smbd
if [ -e /flash/root/config/sys.conf ]; then
   . /flash/root/config/sys.conf
   echo "$samstate samba..."
   /etc/samba/samba-init.d $samstate simple
fi
