#!/bin/sh

# function #################################################
check_version()
{
   current_fw_file_name=`cat $KBS_FW_VERSION_FILE`
   echo "local:	$current_fw_file_name"
   echo "remote:	$firmware_file_name"
   if [ "$firmware_file_name" != "$current_fw_file_name" ]; then
      return 0	# version mismatch.
   else
      return 1	# same version.
   fi
}

download_firmware()
{
   local counter; counter=1
   echo "url=$firmware_url/$firmware_file_name"

   while [ $counter -lt 4 ] ;do
      wget -O /tmp/BASS_WEB $firmware_url/$firmware_file_name
      if [ $? -eq 0 ]; then
         echo "Version mismatched, starting to download the new one ...done"
         ret=0
         break
      else
         counter=$((counter+1))
         sleep 3
         ret=1
      fi
   done

   return $ret
}

install_firmware()
{
   echo "" >/var/run/provision.start

   /sbin/fw_unpack /tmp/BASS_WEB /var

   if [ $? -ne 0 ]; then
      echo "Error firmware image format"
      rm -f /tmp/BASS_WEB
      ret=1
   else
      ## stop memory hot deamon
      echo "Read and check the new firmware ...done"
      ret=0
   fi
   return $ret
}

# main ######################
KBS_FUPDATE_INFO_FILE=/var/kbs_fupdate.inf
KBS_FW_VERSION_FILE=/opt/firmware/version
mac=`ifconfig eth0 | grep HWaddr | cut -d' ' -f11 |sed s/://g |sed s/\r$//g`
ktkey_value=`fw_printenv ktkey|cut -d= -f2`
ret=0

if [ ! -z $mac ]; then
   echo "Got MAC: $mac"
   firmware_url=$2
   firmware_file_name=$3
   
   if [ ! -z $firmware_url ] && [ ! -z $firmware_file_name ]; then
      check_version

      if [ $? -eq 0 ]; then
         download_firmware

         if [ $? -eq 0 ]; then
            install_firmware

            if [ $? -eq 0 ]; then
               echo "Start install firmware ..."
               exec /var/start_install.sh /tmp/BASS_WEB
               ret=0
            fi
         else
            echo "Download failed!!!" 
            ret=1
         fi
      else
         echo "Firmware version matched!!!"
         ret=0
      fi
   else
      echo "Failed to get firmware info!!!"
      ret=1
   fi
else
   echo "Failed to get MAC!!!"
   ret=1
fi

[ "$ret" -ne 0 ] && reboot
