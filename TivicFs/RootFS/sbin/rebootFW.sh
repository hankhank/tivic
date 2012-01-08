#!/bin/sh

# routine #########################################
restart_kbs()
{
   local tmp i; i=1
   plugin_list="usbStorage \
                idownloader \
               "
   while true ;do
      if [ -z "`pidof kbs`" ]; then
         for list in $plugin_list; do
            tmp=`ps ef|awk '{print $6}'|grep $list|sed -e'2,30d'`
            tmp=${tmp##*/}
            [ ! -z "`pidof $tmp`" ] && kill -9 `pidof $tmp`
         done
         break
      elif [ $i -lt 31 ]; then
         i=$((i+1))
         echo -n "."
         sleep 1
      else
         kill -9 `pidof kbs`
      fi
   done
   # restart kbs
   /sbin/kbs >/dev/console 2>&1 &
}

reboot_sys()
{
   local i; i=1
   daemon_list="crond \
                smbd \
                nmbd \
                buttonpoll \
                telnetd \
               "
   while true ;do
      if [ -z "`pidof kbs`" ]; then
         for daemon in $daemon_list; do
            [ ! -z "`pidof $daemon`" ] && killall $daemon && echo "kill $daemon ...done"
         done
         break
      elif [ $i -lt 31 ]; then
         i=$((i+1))
         echo -n "."
         sleep 1
      else
         kill -9 `pidof kbs`
      fi
   done
   # reboot
   exec reboot
}

# main ############################################
[ -z $1 ] && reboot_sys
p1=$1; shift 1

case $p1 in
   restart) restart_kbs ;;
   reboot) reboot_sys ;;
   *) reboot_sys ;;
esac

exit 0
