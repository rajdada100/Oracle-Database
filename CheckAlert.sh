#!/bin/ksh
# ==================================================================================================
# NAME:         CheckAlert.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This script will check the alert_sid.log
#
#
# USAGE:        CheckAlert.sh
#
#
# ==================================================================================================

function SendNotification {

        # Uncomment for debug
         set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX \n\n" > mail.dat

        if [[ -a ${ERROR_FILE} ]]; then
                cat $ERROR_FILE >> mail.dat
                rm ${ERROR_FILE}
        fi


        cat mail.dat | /bin/mail -s "PROBLEM WITH  Environment -- ${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        # Update the mail counter
        MAIL_COUNT=${MAIL_COUNT}+1

        return 0
}


#################### MAIN ##########################
#uncomment the below line to debug
set -x
clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export ERROR_FILE=$HOME/local/dba/scripts/logs/error_msg.txt
#export MAILTO='mimroz@saba.com'
export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com'
export CURDATE=$(date +'%Y%m%d')

if [ $# -gt 0 ]
then
   print "${BOLD}\n\t\tInvalid Arguments!\n"
   print "\t\tUsage : $0 \n"
   exit 1
fi

ostype=$(uname)
if [ $ostype = Linux ]
then
 ORATAB=/etc/oratab
fi
if [ $ostype = SunOS ]
then
 ORATAB=/var/opt/oracle/oratab
fi

 ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}'|sed '/^$/d' > $HOME/local/dba/scripts/logs/sid_list.txt
if [[ -s $HOME/local/dba/scripts/logs/sid_list.txt ]]
then
   cat  $HOME/local/dba/scripts/logs/sid_list.txt | while read LINE
   do

     export sid=$LINE
     sid=$(print $sid|tr -d " ")

     export ORACLE_SID=$sid
     export ORAENV_ASK=NO
     export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null
if [ $? -ne 0 ]
then
 print "\n\n\t\t There seems to be some problem please rectify and Execute Again\n\nAborting Here...."
 exit 2
fi


export VERSION=`sqlplus -s "/ as sysdba" <<EOF
set lines 190
set heading off
set feedback off
SELECT VERSION FROM PRODUCT_COMPONENT_VERSION;
EOF`


export VERSION=$(print $VERSION|tr -d " "|cut -c 1-2)

if [ $VERSION -ge 11 ]
then

export DIAG_LOC=`sqlplus -s "/ as sysdba" <<EOF
set lines 190
set heading off
set feedback off
--select VALUE from v\\\$parameter where NAME='diagnostic_dest';
select value from v\\\$diag_info where name='Diag Trace';
EOF`

export DIAG_LOC=$(print $DIAG_LOC|tr -d " ")
#export ALERTLOG=$(find $DIAG_LOC -type f -name alert_$ORACLE_SID.log|grep trace)
export ALERTLOG=${DIAG_LOC}/alert_$ORACLE_SID.log
export ALERTLOG=$(print $ALERTLOG|tr -d " ")
export logpath=$(dirname $ALERTLOG)
else

export logpath=`sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select replace(value,'?','$ORACLE_HOME')
     from v\\\$parameter
     where name = 'background_dump_dest';
EOF`
fi

     logpath=$(print $logpath|tr -d " ")
     if [[ ! -d "$logpath" ]]
     then
     print "Script Error - bdump path found as $logpath"
     exit 3
     fi

     export alert_log=${logpath}/alert_${ORACLE_SID}.log
     #BLK101019-->grep 'ORA-' $alert_log |egrep -v 'ORA-279|ORA-00060|opiodr aborting process unknown ospid'> $ERROR_FILE
     egrep -i 'ORA-|Error 16198' $alert_log |egrep -v 'ORA-279|ORA-00060|ORA-00312|ORA-3136|opiodr aborting process unknown ospid'> $ERROR_FILE
     cat $alert_log  >> $logpath/alert_${ORACLE_SID}_${CURDATE}.log
     rm -f $alert_log
     touch -a $alert_log
     if [[ -s ${ERROR_FILE} ]]
     then
       SendNotification
     fi
     rm -f  $ERROR_FILE
   done

find ${logpath}  \( -name '*.log' \) -mtime 31 -exec rm {} \; > /dev/null

rm -f $HOME/local/dba/scripts/logs/sid_list.txt
fi

exit 0
