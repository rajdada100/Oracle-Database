#!/bin/ksh
# ********************************************************************************************
# NAME:         GatherSchemaStats.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This utility will Gather the stats  of the specified database for allapplication  users
#
# USAGE:        GatherSchemaStats.sh ORACLE_SID
#
# INPUT PARAMETERS:
#               SID     Oracle SID of database to backup
#
# Modifications:
#               Brij Lal Kapoor (BLK) to incorporate parallelism when run for 2 dbs at once.
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

        if [[ -a ${ERROR_FILE} ]]; then
                cat $ERROR_FILE >> mail.dat
                rm ${ERROR_FILE}
        fi

        if [[ $2 = 'FATAL' ]]; then
                print "*** This is a FATAL ERROR - ${PROGRAM_NAME} aborted at this point *** " >> mail.dat
        fi

        cat mail.dat | /bin/mail -s "PROBLEM WITH  Environment -- ${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        # Update the mail counter
        MAIL_COUNT=${MAIL_COUNT}+1

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
  print "Database $ORACLE_SID is not running.  Cannot perform GatherSchemaStats.sh"
  SendNotification "Database $ORACLE_SID is not running. $PROGRAM_NAME cannot run "
  export PROCESS_STATUS=FAILURE
  exit 15
 fi
}


############################################################
#                       MAIN
############################################################
        ORATAB='/etc/oratab'
        HOSTNAME=$(hostname)
        # Uncomment next line for debugging
        set -x
        export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
        export PROGRAM_NAME_FIRST=$(print $PROGRAM_NAME | awk -F "." '{print $1}')
        export BOX=$(print $(hostname) | awk -F "." '{print $1}')
        export DB_INSTANCE
        #export MAILTO='bkhan@saba.com,BHiremath@Saba.com,UKulkarni@saba.com,GNOC@saba.com,ond-tierTwoSaba@Saba.com'
        export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com'
        #export MAILTO='makhtar@saba.com'
        export CURDATE=$(date +'%Y%m%d%H%M%S')
        export ERROR_FILE=$HOME/local/dba/gather/log/Error_Log_${CURDATE}.txt

        if [ $# -ne 1 ]
        then
         print "\n$0 Failed: Incorrect number of arguments -> $0 ORACLE_SID "
         print "The ORACLE_SID must be passed as a parameter "
         SendNotification "Incorrect number of arguments -> ${PROGRAM_NAME} ORACLE_SID "
         exit 1
        fi

        export ORACLE_SID=$1
        grep "^${ORACLE_SID}:" $ORATAB > /dev/null
        if [ $? -ne 0 ]
        then
         print "\nThe first parameter entered into script is not a valid Oracle SID in $ORATAB."
         print "Choose a valid Oracle SID from $ORATAB.\n"
         SendNotification "Not a valid Oracle SID -> ${PROGRAM_NAME} ORACLE_SID "
         exit 2
        fi
        export ORAENV_ASK=NO
        export PATH=/usr/local/bin:$PATH
        . /usr/local/bin/oraenv
        export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
        export LD_LIBRARY_PATH=$ORACLE_HOME/lib
        export ORACLE_BASE=$HOME

        export chk_run=$(ps -ef | grep GatherSchemaStats.sh | grep -v grep | awk '{print $9,$10}' | grep ${ORACLE_SID}|awk -F/ '{print $2}')
        if [[! -n $chk_run ]]
        then
        SendNotification "${PROGRAM_NAME} already Running...Terminating this Occurrence"
        exit 1
        fi

        mkdir -p $HOME/local/dba/gather/log
funct_db_online_verify

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off
set feedback off
spool $HOME/local/dba/gather/log/AllSchema_${CURDATE}.tmp
---select username from dba_users where username not in('SRINITEST','DOC2SITE','TNT050','RASDB','BASE201SITE','SITE013','ATHENA2','SABA_DI','SMRAS1','TNT123','TNT104','TEST','DQTNT003','SPCDEMO','MOBILESITE','HPLEARN','TNT103','SABA','CUST01','A501DMO0001','SITE026','JD','LEAPPMDB','RAS','PMSITE','SPC_ERCO','SITE022','MD','SOCIALSITE','SEC71RC','ANT','CENTRARAS','SABA_REPORT','lvvwd_54sp2','TNT122','TNT124','XDB','WMSYS','WKSYS','WKPROXY','SYSTEM','SYSMAN','SYS','OUTLN','ORDSYS','ORDPLUGINS','ORACLE_OCM','DBSNMP','CTXSYS','ANONYMOUS','RAS3');
select username from dba_users where username not in('XDB','WMSYS','WKSYS','WKPROXY','SYSTEM','SYSMAN','SYS','OUTLN','ORDSYS','ORDPLUGINS','ORACLE_OCM','DBSNMP','CTXSYS','ANONYMOUS');
EOF
cat $HOME/local/dba/gather/log/AllSchema_${CURDATE}.tmp | sed '/^$/d' > $HOME/local/dba/gather/log/AllSchema_${CURDATE}.txt
rm -f $HOME/local/dba/gather/log/AllSchema_${CURDATE}.tmp
if [[ -s $HOME/local/dba/gather/log/AllSchema_${CURDATE}.txt ]]
then
cat $HOME/local/dba/gather/log/AllSchema_${CURDATE}.txt | while read LINE
  do
     export users=$(print $LINE | tr -d " ")
     print "exec DBMS_STATS.GATHER_SCHEMA_STATS(OWNNAME =>'$users',DEGREE => 5,estimate_percent => 99, CASCADE => TRUE);" >> $HOME/local/dba/gather/log/GatherAllSchema_${CURDATE}.txt
  done
else
  SendNotification "PROBLEM WITH $PROGRAM_NAME Cant Create the List of Schema"
fi
rm -f $HOME/local/dba/gather/log/AllSchema_${CURDATE}.txt
if [[ -s $HOME/local/dba/gather/log/GatherAllSchema_${CURDATE}.txt ]]
then
 cat $HOME/local/dba/gather/log/GatherAllSchema_${CURDATE}.txt | while read LINE
 do
  print "$LINE" > $HOME/local/dba/gather/log/LetsGatherStat_${CURDATE}.sql

export start_time=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off
set feedback off
alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';
select sysdate from dual;
EOF`
#start_time=$(print $start_time | tr -d " ")

export for_user=$(cat $HOME/local/dba/gather/log/LetsGatherStat_${CURDATE}.sql |awk  -F\' '{print $2}')
for_user=$(print $for_user | tr -d " ")
print "============================Start for $for_user===================================\n\n" >>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
print "Started Gathering Schema at $start_time for $for_user ...\n">>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
print "$LINE" >>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF >>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
WHENEVER SQLERROR EXIT FAILURE
@$HOME/local/dba/gather/log/LetsGatherStat_${CURDATE}.sql
EOF

export end_time=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off
set feedback off
alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';
select sysdate from dual;
EOF`
#end_time=$(print $start_time | tr -d " ")
print "Finished Gathering Schema at $end_time for  $for_user" >>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
print "\n\n=========================End for $for_user======================================\n\n" >>$HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt
rm -f $HOME/local/dba/gather/log/LetsGatherStat_${CURDATE}.sql
 done
else
 SendNotification "PROBLEM WITH $PROGRAM_NAME Can not run Gather stats...Please check"
fi

grep "ORA-" $HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt > $ERROR_FILE
if [[ -s $ERROR_FILE ]]
then
 SendNotification
else
#print "DONE"
    MAIL_DASHBOARD_LOC=$HOME/local/dba/backups/rman/
       mkdir -p $MAIL_DASHBOARD_LOC

         export DATE_NEW=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        echo $DATE_NEW "|" ${BOX} "|" ${ORACLE_SID} "|" "STATUS: "Successfully Stats build complete.  >>  $MAIL_DASHBOARD_LOC/mail_status
#cat $HOME/local/dba/gather/log/Final_${CURDATE}_GatherStat_Log.txt|/bin/mail -s "${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID} Completed Successfully for All Schema" ${MAILTO}
fi
rm -f $ERROR_FILE
exit 0
