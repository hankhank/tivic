## manual update F/W for testing
## contact CJ <cjwang@teltel.com>
#!/bin/sh

# main #########################################################
# only for CJ's envior's
[ "$1" = "auto" ] && /flash/root/manu_nfs.sh 192.168.0.95 /home/teltel/temp

# check nfs mount point
[ -z "`ls /mnt`" ] && echo " *** be SURE to mount nfs ***" && exit 2

# start update F/W
DHS_LIST="`ls /mnt/DHS_*`"
i=1
for list in $DHS_LIST; do
   echo " ($i) $list"
   i=$((i+1))
done

echo "=========================================================="
read ans && [ -z $ans ] && exit 2
DHS_FILE=`echo $DHS_LIST|cut -d' ' -f $ans`

cp $DHS_FILE /var/
DHS_FILE=${DHS_FILE##*/} && DHS_FILE=/var/$DHS_FILE
/sbin/fw_unpack $DHS_FILE /var
echo -n "Press any Enter to continue ? " && read ans
/var/start_install.sh $DHS_FILE &

