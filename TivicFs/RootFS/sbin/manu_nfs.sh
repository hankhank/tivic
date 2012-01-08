#!/bin/sh
# this script is intended to be sourced by .
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/flash/root:/flash; export PATH
if [ "$1" = "unload" ]; then
	cd /flash/root
	umount /mnt
	rmmod nfs lockd sunrpc
	cd $OLDPWD
	return
fi
mount|grep "$1:$2 on /mnt" && PATH=$PATH:/mnt/tools/bin:/mnt/tools/sbin &&return 
NFSIP=$1
MNPT="$2"
[ -z "$NFSIP" -a -f .nfsip ] && NFSIP=`cat .nfsip 2>/dev/null`
[ -z "$NFSIP" ] && NFSIP=10.20.0.11
[ ! -z "$1" -a -f nfs.sh ] && echo "$1" > .nfsip

for m in sunrpc lockd nfs; do
	grep $m /proc/modules>/dev/null || insmod $m
done
#echo "$MNPT"
mount -t nfs -orsize=8192,wsize=8192,nolock,soft,intr $NFSIP:"$MNPT" /mnt

mount|grep /mnt && PATH=$PATH:/mnt/tools/bin:/mnt/tools/sbin
