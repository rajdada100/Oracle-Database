#!/bin/ksh
# ==================================================================================================
# NAME:         CheckDiskSpace.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This script will check the Disk Space utilization
#
#
# USAGE:        CheckDiskSpace.sh
#
#
# ==================================================================================================

function SendNotification {

        # Uncomment for debug
         set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX \n\n" > mail.dat
        if [[ -s $HOME/local/dba/scripts/logs/disckspace_warning.txt ]]
        then
        print "***********WARNING***************">> mail.dat
        cat $HOME/local/dba/scripts/logs/disckspace_warning.txt >> mail.dat
        print "*********************************">> mail.dat
        fi
        if [[ -s $HOME/local/dba/scripts/logs/disckspace_critical.txt ]]
        then
        print "***********CRITICAL***************">> mail.dat
        cat $HOME/local/dba/scripts/logs/disckspace_critical.txt >> mail.dat
        print "**********************************">> mail.dat
        fi
        cat mail.dat | /bin/mail -s "File System Usage Exceeded Threshold -- ${PROGRAM_NAME} on ${BOX}" ${MAILTO}
        rm mail.dat

        return 0
}
#################### MAIN ##########################
#uncomment the below line to debug
set -x
clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
#export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com'
MAILTO=CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com
#export MAILTO='makhtar@saba.com'
export CURDATE=$(date +'%Y%m%d')

if [ $# -gt 0 ]
then
   print "${BOLD}\n\t\tInvalid Arguments!\n"
   print "\t\tUsage : $0 \n"
   exit 1
fi

df -h | grep -vE '^Filesystem|tmpfs|home|cdrom'|grep %|awk '{print $(NF-1),"\t",$NF}'|sed '/^$/d' > $HOME/local/dba/scripts/logs/disckspace.txt

if [[ -s $HOME/local/dba/scripts/logs/disckspace.txt ]]
then
   cat  $HOME/local/dba/scripts/logs/disckspace.txt | while read LINE
   do

     export MP=$(print $LINE|awk '{print $1}'|cut -d'%' -f1)
     MP=$(print $MP|tr -d " ")

if [ $MP -ge 97 ] && [ $MP -lt 98 ]
then
print $LINE >> $HOME/local/dba/scripts/logs/disckspace_warning.txt
fi

if [ $MP -ge 98 ]
then
print $LINE >> $HOME/local/dba/scripts/logs/disckspace_critical.txt
fi

done
fi


if [[ -s $HOME/local/dba/scripts/logs/disckspace_warning.txt ]] || [[ -s $HOME/local/dba/scripts/logs/disckspace_critical.txt ]]
then
SendNotification
fi
rm -f $HOME/local/dba/scripts/logs/disckspace_warning.txt
rm -f $HOME/local/dba/scripts/logs/disckspace_critical.txt
rm -f $HOME/local/dba/scripts/logs/disckspace.txt
exit 0
