#!/bin/sh
#
# Start/stop script for Samba TNG
#
# This is from a Solaris box.  Proper links need to be made to it from the
# rcX.d directories.  For Linux, it goes into /etc/rc.d/init.d
#
# Lonnie
#
# Heavily modified and integrated with autoconf by Elrond
#
# RedHat 7.0 or above puts this in /etc/init.d
# chkconfig: - 91 35
# description: Starts and stops the Samba TNG daemons
#
# The following is for lsb compliance:
### BEGIN INIT INFO
# Provides: samba-tng
# Required-Start: $remote_fs $network $syslog $named
# Required-Stop: $remote_fs $network $syslog
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Short-Description: Samba TNG - SMB/CIFS and MSRPC services
# Description:
#	Start/stop Samba TNG, which provices SMB/CIFS and
#	MSRPC services under Unix.
### END INIT INFO
#
# Some comments about above choosing:
# At start:
#    $remote_fs: So /usr and all other filesystems are there.
#    $network: Especialy nmbd does not like "no interfaces".
#    $syslog: So we can feed our important logs somewhere at startup.
#             You want to know, why it's not starting, right?
#    $named: So name resolution works, so people can put names in
#            smb.conf.
# The above reasons mainly count for stop as well, so here some
# extra notes:
#    $remote_fs: So we can close files cleanly.
#    not $named: Well, I don't see any point in resolving names
#                at stop-time.
#
# As I've learned today, it's no good idea to have two init-scripts
# on the same system providing the same facility. So in theory we
# could provide "samba", but that would mean, that it's harder to run
# samba classic and TNG together on the same box.
#

prefix=/usr/local/samba
#prefix=/mnt/samba
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
bindir=${exec_prefix}/bin
sbindir=${exec_prefix}/sbin
localstatedir=/var/samba
tmpdir=${localstatedir}/locks
piddir=$tmpdir
sysconfdir=${prefix}/etc
etcdir=${sysconfdir}
psiptnpath=/flash/root/config/psiptn
smbconf=/etc/samba/smb.conf

if [ ! -d /var/samba ]; then
	mkdir -p /var/samba/locks
	mkdir -p /var/samba/private
fi

if [ ! -d /var/log/samba ]; then
	mkdir -p /var/log/samba
fi

if [ ! -e /var/samba/private/smbpasswd ];
then
	cp /etc/samba/smbpasswd /var/samba/private/
fi

if [ ! -d $samhome ];
then
	mkdir -p $samhome
fi

# !tittan! - for /var/samba/locks permission denied
chmod -R 755 /var/samba

# !cj! - Modify netbios name
if [ -e $psiptnpath ]; then
   psiptn_num=`cat $psiptnpath`
   psiptn_num=${psiptn_num#*=}
else
   psiptn_num="iDownloader"
fi
netbios_name=`grep '^netbios name' $smbconf`
netbios_name=${netbios_name#*= }
if [ "$psiptn_num" != "$netbios_name" ]; then
   sed -i /"netbios name = "/s/.*/"netbios name = $psiptn_num"/ $smbconf
fi

# !cj! - modify val of interface in /etc/samba/smb.conf
for val in `ifconfig eth0`; do
   case $val in
   addr*.*.*.*) ip=`echo $val|cut -d: -f2` ;;
   Mask*.*.*.*) mask=`echo $val|cut -d: -f2` ;;
   esac
done
sed -i /interfaces/s/.*/"interfaces = \"$ip\/$mask\""/ $smbconf

if [ "$2" = "simple" ]; then
   daemons="nmbd smbd"
else
   daemons="nmbd
            smbd
            netlogond
            samrd
            browserd
            lsarpcd
            srvsvcd
            winregd
            wkssvcd
            spoolssd
            svcctld
           "
fi

unset TMPDIR

case "$1" in
	start)
		cd /
		echo -n "Starting SMB services:"

		if [ -r "${tmpdir}/vuid.tdb" ]; then
			echo -n " (removing vuid.tdb)"
			rm "${tmpdir}/vuid.tdb"
		fi

		PATH="${sbindir}:${bindir}:${PATH}"
		export PATH
		for i in $daemons; do
			echo -n " $i"
			eval $i -D
		done
		echo "."
		;;
	stop)
      echo -n "Stopping SMB services:"
		for i in $daemons; do
			file="${piddir}/$i.pid"
         if [ -r $file ]; then
            echo -n " $i"
            kill -9 `pidof $i`
            rm $file
         fi
      done

      if [ -r "${tmpdir}/vuid.tdb" ]; then
         echo -n " (removing vuid.tdb)"
         rm "${tmpdir}/vuid.tdb"
      fi
      echo "."
      ;;
	reload|force-reload)
		echo -n "Reloading SMB configuration:"
		for i in $daemons; do
			file="${piddir}/$i.pid"
			if [ -r $file ]
			then
				echo -n " $i"
				kill -HUP `cat $file`
			fi
		done
		echo "."
		;;
	restart)
		$0 stop
		$0 start
		;;
	status)
		echo -n "Checking Samba TNG status: "
		somerunning=0
		somedead=0
		somedown=0
		for i in $daemons; do
			file="${piddir}/$i.pid"
			if [ -r $file ]
			then
				# echo -n " $i"
				if kill -0 `cat $file` 2>/dev/null
				then
					somerunning=1
				else
					somedead=1
				fi
			else
				somedown=1
			fi
		done
		# echo -n $somerunning $somedead $somedown
		if [ $somedead = 1 ]; then
			echo "Some daemons died."
			exit 1
		fi
		if [ $somerunning = 1 ] && [ $somedown = 1 ]; then
			echo "Some running, some are down"
			# Don't really know.
			exit 3
		fi
		if [ $somedown = 1 ]; then
			echo "stopped"
			exit 3
		fi
		if [ $somerunning = 1 ]; then
			echo "running"
			exit 0
		fi
		;;
	*)
      echo "Usage: $0 { start | stop | restart | reload | force-reload }"
      exit 1
      ;;
esac
exit 0
