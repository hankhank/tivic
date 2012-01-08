#!/bin/sh
#idownloader=1
zwave_check(){
    if [ -e /dev/ttyUSB0 ];
    then
	 #echo "exist";
	pluginpid=`pidof plugin1`
	if [ $? -eq 1 ] ;
	then
	     /flash/root/plugins/plugin1 > /dev/null &
	fi
    else
	 #echo "not exist";
	return 0;
    fi
}

kill_zwave(){
     pluginpid=`pidof plugin1`
     if [ $? != 1 ] ;
     then
	 kill -9 $pluginpid ;
     fi
     sleep 5;
}

kill_idownloader(){
     #get idownloader's pid
     idownloader_pid=`pidof idownloader1` 
     if [ $? -eq 0 ] ; 
     then
	 kill -9 $idownloader_pid
     fi 
     #get usb storage plugin 
     usbstorage_pid=`pidof usbStoragePlugin1`
     if [ $? -eq 0 ] ;
     then
	 kill -9 $usbstorage_pid 
     fi
}

check_buttonpoll(){
#get buttonpoll's pid
    buttonpoll_pid=`pidof buttonpoll`
    if [ $? -eq 0 ] ;
    then
	return 0;
    else
	return 1;
    fi
}

check_kbsupdate(){
#check if the kbs is updating
    if [ -e /var/run/kbsupdate ];
    then
	return 0;
    else
	return 1;
    fi
}

kbs_restart_check(){
#restart kbs and check its status after 5 secs 3 times. if Zombie kill and restart if disappear start it.
check_count=1;
while [ $check_count -lt 5 ];
do  
    pids=`/bin/pidof kbs`
    if [ $? -eq 0 ] ;
    then
        ### kbs process is on the way it goes ###
	for p in $pids;
	do
	    ### check Zombie ###
	    if [ `cat /proc/$p/stat|cut -d " " -f 3` = "Z" ]; 
	    then
		echo "Process $p become Zombie Killing all process"
		for j in $pids;
		do
		    kill -9 $j;
		done
		if [ ! $check_count -ge 4 ];
		then
		    echo "bring back the KBS process try $check_count time " `date`
		    /sbin/kbs > /dev/console 2>&1 &
		fi
		abnormal=1;
		break;
	    else
		echo "Process $p normal "
		abnormal=0;
	    fi
	done
	if [ $abnormal -eq 0 ];
	then
	    break;
	fi
    else
        ### kbs is gone ###
	if [ ! $check_count -ge 4 ];
	then
	    echo "bring back the KBS process try $check_count time " `date`
	    /sbin/kbs > /dev/console 2>&1 &
	fi
    fi
    sleep $(( 5 * $check_count ));
    check_count=$(( $check_count + 1 ));
done
if [ $check_count -eq 5 ];
then
    ### reboot proceed ###
    reboot_proceed;
fi
return 0;
}

reboot_proceed(){
### start kbs failed. reboot sika nai ###
    echo "REBOOT IN PROGRESS"
    BUSYBOX="/var/busybox"
    cp /bin/busybox $BUSYBOX

### stop all process ###
    /bin/killall resetbtn	# kill for customer driver
    /bin/killall crond
    /bin/killall button.sh
    /bin/killall klogd
    /bin/killall syslogd
    /bin/killall psntpdate
    /bin/killall telnetd
    /bin/killall looprun
    /bin/killall httpdloop	##keep this 2 month for old version
    /bin/killall boa.arm
    /bin/killall mini_httpd.arm
    /bin/killall snmpd
    /bin/killall upnpd
    /bin/killall dnsmasq
    /bin/killall vpnc
### unbind IP Address ###
    case $wan_ip_assignment in
	0)      /etc/init.d/staticip.sh stop > /dev/null 2>&1 ;;
	1)	/etc/init.d/udhcpc.sh stop > /dev/null 2>&1 ;;
	2)      /etc/init.d/pppoe.sh stop  > /dev/null 2>&1 ;;
	*)      /etc/init.d/udhcpc.sh stop > /dev/null 2>&1 ;;
    esac
    /etc/init.d/udhcpd.sh stop >/dev/null 2>&1
    /etc/init.d/voip.sh stop >/dev/null 2>&1	##now stop by webctrl#
    /etc/init.d/run_provision.sh stop >/dev/null 2>&1
    /etc/init.d/ddns.sh stop >/dev/null 2>&1
    /etc/init.d/dnsmasq.sh stop >/dev/null 2>&1
    sleep 2	## wait for voip

### down all interface ###
    for i in `ifconfig -a|cut -c1-8`; do
	ifconfig $i down && echo Shutdown interface [$i]
    done

### proceeding umount ###
    cd /
    $BUSYBOX sync
    $BUSYBOX umount /proc/bus/usb/
    if [ $? != "0" ]; then
	logmsg "umount fail! Please logout first!"
    fi

### rmmod * skip fvmem and rt73(ToDo: hope to remove it)
    for m in `lsmod|cut -d' ' -f1|grep -v Module`; do
	if [ $m != fvmem ]; then
	    rmmod $m && echo Remove module [$m]
	fi
    done

### proceeding reboot ###
    $BUSYBOX sync
    $BUSYBOX ps -ef
    $BUSYBOX umount /flash/
    if [ $? != "0" ]; then
	logmsg "umount fail before reboot! Please logout first!"
	$BUSYBOX kill -TERM 1
    fi
}

###### main ######
#check_myself
if [ -e /var/tmp/km.pid ];
then
    ### check process in /proc
    . /var/tmp/km.pid
    running=0
    for kp in $km_pid;
    do
	if [ ! -d /proc/$kp ];
	then
	    running=0;
	else
	    running=1;
	    break;
	fi
    done
    if [ $running -eq 0 ];
    then
	echo "km_pid="\"`pidof kbs_monitor.sh`\">/var/tmp/km.pid ;
    else
	echo "myself running quit";
	return 0;
    fi
else
    echo "km_pid="\"`pidof kbs_monitor.sh`\">/var/tmp/km.pid ;
fi
#check if machine sleeping
check_buttonpoll;
if [ $? -eq 0 ] ;
then
    echo "sleeping";
    rm -f /var/tmp/km.pid;
    return 0;
fi
check_kbsupdate;
if [ $? -eq 0 ] ;
then
    echo "updating";
    rm -f /var/tmp/km.pid;
    return 0;
fi
pids=`/bin/pidof kbs`
if [ $? -eq 0 ] ;
then
### kbs process is on the way it goes ###
# echo "run" ;
######### Zwave plugin check to ENABLE add zwave=1 in top of file  #############
 if [ ! -z $zwave ];
 then
     zwave_check
 fi
 for p in $pids;
 do
     if [ `cat /proc/$p/stat|cut -d " " -f 3` = "Z" ]; 
     then
	 echo "Process $p become Zombie Killing all process"
	 for j in $pids;
	 do
	     kill -9 $j;
	 done
	 echo "kill all plugin process"
	 ### kill zwave process for restart kbs ###
	 if [ ! -z $zwave ] ;
	 then
	     kill_zwave
	 fi
	 ### kill idownloader process for restart kbs ###
	 if [ ! -z $idownloader ];
	 then 
	     kill_idownloader
	 fi
	 echo "bring back the KBS process at " `date`

	 /sbin/kbs > /dev/console 2>&1 &
	 sleep 5
	 kbs_restart_check ;
	 break;
     else
	 echo "Process $p normal "
     fi
 done
else
### kbs is gone ###
######## zwave plugin check to ENABLE add zwave=1 #########
 if [ ! -z $zwave ] ;
 then
     kill_zwave
 fi

######### iDownloader plugin check to ENABLE add idownload=1 ##########
 if [ ! -z $idownloader ];
 then 
     kill_idownloader
 fi
 echo "bring back the KBS process at " `date`
 /sbin/kbs > /dev/console 2>&1 &
 sleep 5
 kbs_restart_check
fi
rm -f /var/tmp/km.pid;
return 0;
