
echo "Fetching pxeboot for menu"
#rm pxeboot
#wget ftp://planets:pp2006-10@archive.ruf.uni-freiburg.de/internal/pxeboot


# create the mconf configuration for the system to boot selection
echo -e 'mainmenu "OpenSLX Selection of Bootable Systems\nchoice\n\
  prompt "Bootable Systems"\n' > boot.mconf

count=0
while read line; do
  #echo $line
  case "$line" in
    LABEL\ *)
      count=$(expr 1 + $count)
      file=${line#LABEL }
      echo "label=$file" > ${count}${file}.system
      echo -e "config boot_system${count}\n" >> boot.mconf
    ;;
    *MENU\ LABEL*)
      echo "menuentry=\"${line#* ^}\"" >> ${count}${file}.system
      echo "  bool \"${line#* ^}\"" >> boot.mconf
    ;;
    *KERNEL\ *)
      echo "kernel=${line#*::}" >> ${count}${file}.system
    ;;
    *IPAPPEND*)
      :
    ;;
    *APPEND\ *)
      echo $line|sed "s/.*APPEND /append=\"/;s,initrd=.*/init,initrd=init,;s/$/\"/" >> ${coun
t}${file}.system
      echo $line|sed "s,.*APPEND.*initrd=.*/init,initramfs=init,;s, .*,,;" >> ${count}${file}
.system
    ;;
    *TEXT\ HELP*)
      echo "  help\n    Help text here ..." >> boot.mconf
    ;;
  esac
done < pxeboot

#while test -e ${i}*.system && . ${i}*.system 2>/dev/null ; do
#  dialogstring="$dialogstring \"$menuentry\" \"\" 1"
#  i=$(expr 1 + $i)
#done



wget ftp://planets:pp2006-10@archive.ruf.uni-freiburg.de/internal/$kernel -o kernel
wget ftp://planets:pp2006-10@archive.ruf.uni-freiburg.de/internal/$initramfs -o initramfs

