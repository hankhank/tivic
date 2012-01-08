## !cj! - do dhcpc/pppoe/staticip setting and start one of them
## contact <cj.wang@teltel.com>
## 
## ***** WAN_OPTION *****
## *  0 --> staticip    *
## *  1 --> udhcpc      *
## *  2 --> pppoe       *
## **********************
#!/bin/sh

# func ###################################################
staticip_start()
{
   local bdcast tmp

   echo "* start [static ip] ..."
   echo "ip=$WAN_IP
netmask=$WAN_NETMASK
gateway=$WAN_GATEWAY
dns1=$WAN_DNS1
dns2=$WAN_DNS2" >/dev/console
   
   # kill daemons fisrt
   killdaemon

   # start eth0 second
   ifconfig eth0 up

   # if WAN_DNS2 is empty, set WAN_DNS1 to it
   [ -z "$WAN_DNS2" ] && WAN_DNS2=$WAN_DNS1

   # set hostname
   hostname "idownloader"
   echo 127.0.0.1 localhost.localdomain localhost >/etc/hosts
   echo $WAN_IP idownloader.tp.teltel.com idownloader >>/etc/hosts

   # set dns
   if [ "$WAN_DNS1" != "$WAN_DNS2" ]; then
      echo "nameserver $WAN_DNS1" >/etc/resolv.conf
      echo "nameserver $WAN_DNS2" >>/etc/resolv.conf
   else
      echo "nameserver $WAN_DNS1" >/etc/resolv.conf
   fi

   bdcast=`echo $WAN_IP|awk -F. '{print $1"."$2"."$3".255"}'`
   ifconfig eth0 up
   ifconfig eth0 $WAN_IP netmask $WAN_NETMASK broadcast $bdcast
   route add default gw $WAN_GATEWAY

   # start ntp
   if [ -z "`pidof vsntp`" ]; then
      vsntp 202.5.224.163
   fi
}

udhcpc_start()
{
   # kill daemons fisrt
   killdaemon

   # start eth0 second
   ifconfig eth0 up
   
   # start udhcpc
   echo "* start [udhcpc] ..."
   udhcpc&
}

pppoe_start()
{
   local errlog dns i

   i=0
   errlog=/etc/ppp/connect-errors
   dns=/etc/ppp/resolv.conf

   # kill daemons fisrt
   killdaemon

   # start eth0 second
   ifconfig eth0 up

   echo "id/passwd : $ACCOUNT/$PASSWD" >/dev/console
   echo -n "* start [pppoe] ..."

   # start pppd
   rm -rf $errlog 2>/dev/null
   pppd pty 'pppoe -I eth0' noipdefault defaultroute usepeerdns passive persist name $ACCOUNT password $PASSWD

   # wait for dns info
   while [ ! -e $dns ]; do
      echo -n "."
      sleep 1
   done
   mv $dns /etc/
   echo "ok"

   # start ntp
   if [ -z "`pidof vsntp`" ]; then
      vsntp 202.5.224.163
   fi
}

restart_kbs()
{
   local PROC_PID counter PLUGIN_LIST PLUGIN_PID
   PROC_PID=`pidof kbs`
   PLUGIN_LIST=`ls /flash/root/plugins`
   PLUGIN_PID=`pidof $PLUGIN_LIST`
   counter=0

   while [ ! -z "$PROC_PID" ]; do
      if [ $counter -ge 3 ] && [ $counter -lt 5 ]; then
         kill -9 $PROC_PID 2>/dev/null
      elif [ $counter -lt 3 ]; then
         killall kbs 2>/dev/null
      else
         echo "kill [kbs] ...failed"
         return 1;
      fi
      sleep 3
      counter=$((counter+1))
      PROC_PID=`pidof kbs`
   done
   echo "kill [kbs] ...done"
   
   PLUGIN_LIST=`ls /flash/root/plugins`
   PLUGIN_PID=`pidof $PLUGIN_LIST`
   counter=0

   while [ ! -z "$PLUGIN_PID" ]; do
      if [ $counter -lt 3 ]; then
         kill -9 $PLUGIN_PID 2>/dev/null
         sleep 2
         counter=$((counter+1))
         PLUGIN_PID=`pidof $PLUGIN_LIST`
      else
         echo "kill plugins ...failed"
         return 1
      fi
   done
   echo "kill plugins ...done"

   echo "restart kbs ..."
   exec /sbin/kbs >/dev/console 2>&1
}

# kill pppoe & udhcpc & vsntp ...
killdaemon()
{
   local i daemon

   daemon="pppd \
           pppoe \
           udhcpc \
           vsntp \
          "

   for list in $daemon; do
      i=0
      while [ ! -z "`pidof $list`" ]; do
         if [ $i -lt 5 ]; then
            killall $list 2>/dev/null
         else
            kill -9 `pidof $list` 2>/dev/null
         fi
         i=$((i+1))
         sleep 1
      done
   done
}

# main ###################################################
WAN_CONF="/flash/root/config/wan.conf"
MAC=`fw_printenv ethaddr|cut -d= -f2`

ifconfig eth0 hw ether "$MAC"
ifconfig lo up
if [ ! -e "$WAN_CONF" ]; then
   udhcpc_start
else
   dos2unix $WAN_CONF 2>/dev/null || cat $WAN_CONF|tr -d '\r' >$WAN_CONF
   . $WAN_CONF
   case $WAN_OPTION in
      0*) staticip_start ;;
      1*) udhcpc_start ;;
      2*) pppoe_start ;;
      *) udhcpc_start ;;
   esac
fi

[ "$1" != "simple" ] && restart_kbs


