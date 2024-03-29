#!/bin/ksh
# ********************************************************************************************
# NAME:         CheckSessionProcess.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This Utility will check the the utilization of Session and Processes
#
# USAGE:        CheckSessionProcess.sh
#
# INPUT PARAMETERS:   N/A
#
#
#
# *********************************************************************************************
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
function SendNotification {

        # Uncomment for debug
         set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX " > mail.dat
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n" >> mail.dat
        fi
            print "\n\n${NUM_PROCESS} processes has been utilized out of ${TOT_PROCESS}.\n" >> mail.dat
            print "${NUM_SESSION} session has been utilized out of ${TOT_SESSION}.\n" >> mail.dat
            print "Maximum process Utilization already reached to ${MAX_PROCESS} out of  ${TOT_PROCESS}. \n">> mail.dat
            print "Maximum sessions utilization already reached to ${MAX_PROCESS} out ${TOT_SESSION}. \n">> mail.dat
            print "This Needs the DB to Bounce To increase the processes parameter.\n">> mail.dat

        cat mail.dat | /bin/mail -s "Current PROCESSES utilization reached threshold -- ${LEVEL} ${T_NUM}%  -- ${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        return 0
}

# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
funct_db_online_verify(){
 # Uncomment next line for debugging
 set -x

 ps -ef | grep ora_pmon_$ORACLE_SID | grep -v grep > /dev/null
 if [ $? -ne 0 ]
 then
  print "Database $ORACLE_SID is not running.  Cannot perform CheckSessionProcess.sh"
  SendNotification "Database $ORACLE_SID is not running. $PROGRAM_NAME cannot run "
  export PROCESS_STATUS=FAILURE
  exit 3
 fi
}


############################################################
#                       MAIN
############################################################
#uncomment the below line to debug
set -x
clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
#export MAILTO='vkurra@saba.com'
MAILTO=CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com
#export MAILTO='makhtar@saba.com'
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

 ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}' > $HOME/local/dba/scripts/logs/sid_sess_list.txt
if [[ -s $HOME/local/dba/scripts/logs/sid_sess_list.txt ]]
then
   cat  $HOME/local/dba/scripts/logs/sid_sess_list.txt | while read LINE
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

funct_db_online_verify

CUR_PROCESS=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select round((CURRENT_UTILIZATION/LIMIT_VALUE)*100)
     from v\\\$resource_limit
     where RESOURCE_NAME = 'processes';
EOF`


MAX_PROCESS=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select MAX_UTILIZATION
     from v\\\$resource_limit
     where RESOURCE_NAME = 'processes';
EOF`


CUR_SESSION=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select round((CURRENT_UTILIZATION/LIMIT_VALUE)*100)
     from v\\\$resource_limit
     where RESOURCE_NAME = 'sessions';
EOF`


MAX_SESSION=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select MAX_UTILIZATION
     from v\\\$resource_limit
     where RESOURCE_NAME = 'sessions';
EOF`

TOT_PROCESS=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select LIMIT_VALUE
     from v\\\$resource_limit
     where RESOURCE_NAME = 'processes';
EOF`


NUM_PROCESS=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select CURRENT_UTILIZATION
     from v\\\$resource_limit
     where RESOURCE_NAME = 'processes';
EOF`


TOT_SESSION=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select LIMIT_VALUE
     from v\\\$resource_limit
     where RESOURCE_NAME = 'sessions';
EOF`


NUM_SESSION=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
     set verify off
     set feedback off
     set heading off
     select CURRENT_UTILIZATION
     from v\\\$resource_limit
     where RESOURCE_NAME = 'sessions';
EOF`

export CUR_PROCESS=$(print $CUR_PROCESS | tr -d " ")
export MAX_PROCESS=$(print $MAX_PROCESS | tr -d " ")
export CUR_SESSION=$(print $CUR_SESSION | tr -d " ")
export MAX_SESSION=$(print $MAX_SESSION | tr -d " ")

export TOT_PROCESS=$(print $TOT_PROCESS | tr -d " ")
export NUM_PROCESS=$(print $NUM_PROCESS | tr -d " ")
export TOT_SESSION=$(print $TOT_SESSION | tr -d " ")
export NUM_SESSION=$(print $NUM_SESSION | tr -d " ")

if [[ $CUR_PROCESS -ge 75 ]] && [[ $CUR_PROCESS -le 85 ]] ; then
#if [[ $CUR_PROCESS -ge 3 ]]; then
LEVEL="Warning"
T_NUM=75
print $LEVEL
SendNotification
fi

if [[ $CUR_PROCESS -ge 75 ]] && [[ $CUR_PROCESS -ge 85 ]] ; then
#if [[ $CUR_PROCESS -ge 3 ]]; then
LEVEL="Critical"
T_NUM=85

print $LEVEL
SendNotification
fi


   done

rm -f $HOME/local/dba/scripts/logs/sid_sess_list.txt
fi

