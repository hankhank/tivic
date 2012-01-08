## !cj! - to combine qa & production.
##          a. to modify /flash/root/config/sys.conf
##          b. to modify /flash/root/config/kbs.conf
## contact CJ<cj.wang@teltel.com>
#!/bin/sh

# func ##########################

## USAGE: [var] [val of var] [file]
##         $1    $2           $3
tt_conf()
{
   if [ -e $3 ]; then
      local tmp
      tmp=`grep "$1" $3|cut -d= -f2`
      if [ -z $tmp ]; then
         echo "$1=" >>$3
         sed -i /"$1="/s/.*/"$1"="$2"/ $3
      elif [ "$tmp" != "$2" ]; then
         sed -i /"$1="/s/.*/"$1"="$2"/ $3
      fi
   else
      echo "$1=" >$3
      sed -i /"$1="/s/.*/"$1"="$2"/ $3
   fi
}

## USAGE: [num of passwd]
##         $1
tt_passwd()
{
   local passwd_1 passwd_2 tmp_1 tmp_2
   local passwd_11 passwd_12 passwd_21 passwd_22
   passwd_1='root:$1$$JsczCa/fkYxTgZCgM7.MD1:0:0:root:/root:/bin/ash'
   passwd_11='ftp:*:95:95::/var/ftp:'
   passwd_12='nobody:x:506:507::/var/tmp/media:'
   passwd_2='root:$1$$sls09PxtVFLVzuN8qlAiw/:0:0:root:/root:/bin/ash'
   passwd_21='ftp:*:95:95::/var/ftp:'
   passwd_22='nobody:x:506:507::/var/tmp/media:'

   tmp_1=`cat /etc/passwd|grep root`
   case $1 in
   1)
      if [ "$tmp_1" != "$passwd_1" ]; then
         echo $passwd_1 >/etc/passwd
         echo $passwd_11 >>/etc/passwd
         echo $passwd_12 >>/etc/passwd
      fi
      ;;
   2)
      if [ "$tmp_1" != "$passwd_2" ]; then
         echo $passwd_2 >/etc/passwd
         echo $passwd_21 >>/etc/passwd
         echo $passwd_22 >>/etc/passwd
      fi
      ;;
   *)
      echo $passwd_1 >/etc/passwd
      echo $passwd_11 >>/etc/passwd
      echo $passwd_12 >>/etc/passwd
      ;;
   esac
}

# main ##########################
sysconf=/flash/root/config/sys.conf
kbsconf=/flash/root/config/kbs.config
qaurl="http:\/\/prov.test.teltel.com.tw"
prurl="http:\/\/prov.dhs.teltel.com"
isQA=`/bin/fw_printenv isqa|cut -d= -f2`

if [ "$isQA" = "1" ]; then
   # config kbs.conf
   tt_conf "autoprov_url" $qaurl $kbsconf

   # config passwd
   tt_passwd "1"
else
   # config kbs.conf
   tt_conf "autoprov_url" $prurl $kbsconf

   # config passwd
   tt_passwd "2"
fi
