#!/bin/ksh
#set -x
###########################################################################
# Author : Raj Dada
# Purpose : RMAN to delete archivelogs
#
#
# Creation Date : 18 Nov 2013
# Version : 1.0.0
# Details: Script to cleanup  archivelogs on primary SYSDATE-1
# How to Execute: $HOME/local/dba/scripts/rman_archivelog_deletion.sh -s DB_SID -s DB_SID >$HOME/local/dba/scripts/logs/rman_archivelog_deletion.log 2>$HOME/local/dba/scripts/logs/rman_archivelog_deletion.err
##########################################################################

LOG="/tmp/rman_archivelog_deletion.log"
# define other mail variables #
MAIL=`which mail`
MAILDIST="CloudOps-DBA@csod.com,CloudOps-DBA@saba.com"
MAILSUBJECT="RMAN archivelog deletion status for:  "
ORATAB=/etc/oratab
COUNTER=0
rm -f $LOG
#-------------------------------------------------------------------------------
# Check for usage.
#-------------------------------------------------------------------------------
if [ "$#" -lt 1 ]
then
        echo "Archivelog deletion :" >> $LOG
        echo "Usage: rman_archivelog_deletion -s {database_sid}...... -s {database_sid}..... -s {database_sid} " >> $LOG
        echo "Exiting." >> $LOG
        exit 1
fi


while [ $# -gt 0 ]
do
ORACLE_SID=""
ORACLE_HOME=""
   case "$1" in
        -sid|-s)
                shift
                if [ "$1" != "" ] ; then
                   COUNTER=`expr $COUNTER + 1`
                   export ORACLE_SID=${1:-$ORACLE_SID}
                   export SID=$ORACLE_SID
                   echo "*************************************************" >> $LOG
                   echo "`date '+Execution Start Time:%H:%M:%S Date:%m-%d-%y'`" >> $LOG
                   echo " "  >> $LOG
                   if [ $COUNTER -eq 1 ] ; then
                        MAILSUBJECT=${MAILSUBJECT}' '$ORACLE_SID
                   else
                        MAILSUBJECT=${MAILSUBJECT}','$ORACLE_SID
                   fi
                   ENVSET=`echo "$ORACLE_SID" | tr '[A-Z]' '[a-z]'`
                   ORACLE_HOME=`grep \^$ORACLE_SID: $ORATAB | cut -f2 -d:`

export ORACLE_SID=`ps -ef | grep pmon | grep -i $ORACLE_SID | sed -e 's/ora_pmon_//g' | awk -F" " '{  while(i<=NF)
{
if (i=NF)
{
array[i]=$i
str1=array[i]}
i++
}
print str1}'`
                  export ORACLE_HOME
                  . $HOME/.profile_${ENVSET}
                  #export ORAENV_ASK=NO
                  #. /usr/local/bin/oraenv
                  # to check if pmon is running #
                  DB=`ps -eo user,pid,args | grep pmon | grep $SID | awk '$3 !~ /grep/ {print substr($3,10,20)}'`
                  if [ "$DB" == "" ] ; then

                                echo "ORA-ERROR:- Oracle ${ORACLE_SID} not found running..pls check instance status!" >> $LOG
                                echo " "  >> $LOG
                                echo " " >> $LOG
                                echo "*************************************************" >> $LOG
                   else
                                echo " " >> $LOG
                                echo "RMAN deletion log for database: $SID" >> $LOG
                                echo " " >> $LOG

       

        run_rman=`$ORACLE_HOME/bin/rman <<ZS >>$LOG 2>&1
        connect target /
        DELETE NOPROMPT FORCE ARCHIVELOG UNTIL TIME 'SYSDATE-1';
        crosscheck archivelog all ;
        exit
        ZS`
                           echo " "  >> $LOG
                           echo " " >> $LOG
                           echo "`date '+Execution End Time:%H:%M:%S Date:%m-%d-%y'`" >> $LOG
                           echo "*************************************************" >> $LOG
                   fi
                   shift
                fi
                ;;
   esac
done
ERR_CHK=`grep ORA- $LOG | wc -l`
if [ $ERR_CHK -ne 0 ] ;  then
        $MAIL -s "$MAILSUBJECT" $MAILDIST < ${LOG}
fi
exit 0

