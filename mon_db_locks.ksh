#!/bin/ksh
set -ux

############################################################################################
#
#       PROGRAM: mon_db_locks.ksh
#
#       DESCRIPTION:
#                Monitor db locks
#
#       EXIT STATUS:
#           0   - script processed successfully
#         >=1   - error
#
#       AUTHOR: Brij Lal Kapoor (BLK)
#
#       Date: 10/21/2013
#*******************************************************************************************
# Date          Developer       Change Description
#===========================================================================================
# 10/21/2013    BLK (BRIJ)       Initial creation
#===========================================================================================
#Last Modified
#
# 10/08/2017  ZISHAN SAUDAGAR  Modified Script to fetch blocking session's port number
# 10/24/2017  BRIJ updated to introduce wait time in the argumentation to make it more generic
############################################################################################

db_env() {
if [ "${OS_TYPE}" = "Linux" ] ; then
        ORATAB="/etc/oratab"
fi
echo $(ps eww $(ps -ef| grep pmon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep ORACLE_HOME | awk -F= '{print $2}') >$OHOMES
export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
if [ -z ${ORACLE_HOME} ] ; then
        echo $(ps eww $(ps -ef| grep smon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep ORACLE_HOME | awk -F= '{print $2}') >$OHOMES
        export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
        if [ -z ${ORACLE_HOME} ] ; then
                export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $ORACLE_SID| grep -v grep| awk -F":" '{print $2}'`
                if [ -z ${ORACLE_HOME} ] ; then
                        SID=`ps -ef | grep pmon | grep -i ${ORACLE_SID} | sed -e 's/ora_pmon_//g'| awk '{print $8}'| awk '{print substr($0,0,length($0)-1)}'`
                        export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $SID| grep -v grep| awk -F":" '{print $2}'`
                fi
        fi
fi

echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep LD_LIBRARY_PATH | awk -F= '{print $2}') >$OHOMES
export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
if [ -z ${LD_LIBRARY_PATH} ] ; then
        echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep LIBPATH | awk -F= '{print $2}') >$OHOMES
        export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
fi
export PATH=$ORACLE_HOME/bin:$PATH:.
}

script_usage() {
echo "Expected atleast wait time duration and one db as an argument."
echo "SCRIPT USAGE: ${PROG_NAME}.sh -t|tim <total_seconds> -s|-sid <dbname> ..... -t|tim <total_seconds> -s|-sid <dbname>"
echo " "
}


######MAIN####
ORAENV_ASK=no
export ORAENV_ASK
export OHOMES=/tmp/ohomes_$$.lst
export OS_TYPE=`uname`

if [ $# -ge 2 ] ; then
RETVAL=0

CHK_LOGS=/tmp/orachk_$$.log
MAILLIST='CloudOps-DBA@saba.com,CloudOps-DBA@csod.com'

while [ "$#" != "0" ]
do
case $1 in
-waittime|-t)
   shift
   export WAITING_TIME=${1:-$WAITING_TIME}
   shift
   ;;
-sid|-s)
   shift
   if [ "$1" ] ; then
        export ORACLE_SID=${1:-$ORACLE_SID}

        SCRIPT_LOG=`dirname $0`/logs/${ORACLE_SID}_lock_monitor.log
        cat /dev/null > $SCRIPT_LOG

        ORACLE_SID=`ps -ef| grep pmon | grep $ORACLE_SID| grep -v grep | awk '{print $8}' | cut -d'_' -f3`

        if [ ${ORACLE_SID} ] ; then
        db_env
        export ORAENV_ASK=NO
        . /usr/local/bin/oraenv

        sqlplus -S "/nolog" <<BLK>$CHK_LOGS
        conn / as sysdba
        define waittime=${WAITING_TIME}
        set lines 500 pages 5000 feedback off verify off
        col starttime format a20 heading "DB Session|Start|Time"
        col blocking_status format a85 heading 'Locking|Details'
        col locked_object format a30 heading 'Locked|Object'
        select to_char(s1.logon_time,'ddmmyyyy:hh24:mi:ss') starttime
        ,s1.schemaname||'@'||decode(instr(s1.machine,'.'),0,s1.machine,
        substr(s1.machine,1,instr(s1.machine,'.')-1))||'/'||s1.port||'  '||'(Session='||'('||''''||s1.sid||','||s1.serial#||''''||')'||
        'Status=' ||s1.status ||' sqlid=>'||s1.sql_id||') blocking '||
         s2.schemaname||'@'||decode(instr(s2.machine,'.'),0,s2.machine,
        substr(s2.machine,1,instr(s2.machine,'.')-1))||'/'||s2.port||'  '||'(Session='||'('||''''||s2.sid||','||s2.serial#||''''||')'||'
        Status=' ||s2.status ||' sqlid='||s2.sql_id||') for the last '|| sw.seconds_in_wait ||' seconds.' AS blocking_status
        , dbo.owner||'.'||dbo.object_name locked_object
        from gv\$lock l1, gv\$session s1, gv\$lock l2, gv\$session s2, gv\$session_wait sw, dba_objects dbo, gv\$locked_object lo
        where s1.sid=l1.sid
        and s2.sid=l2.sid
        and l1.BLOCK=1
        and l2.request > 0
        and l1.id1 = l2.id1
        and l2.id2 = l2.id2
        and sw.sid = l2.sid
        and lo.object_id = dbo.object_id
        and l1.sid = lo.session_id
        and sw.seconds_in_wait>=&waittime
        and l1.INST_ID=s1.INST_ID
        and s1.INST_ID=l2.INST_ID
        and l2.INST_ID=s2.INST_ID
        order by sw.seconds_in_wait desc, s1.logon_time;
BLK
        RETVAL=$?

        if [ -s $CHK_LOGS ] ; then

        echo "`(date +"%m-%d-%Y-%T")`:Database Lock(s) Details for $ORACLE_SID database." >> $SCRIPT_LOG
        echo "`(date +"%m-%d-%Y-%T")`:======================================================================" >> $SCRIPT_LOG
        cat $CHK_LOGS >> $SCRIPT_LOG
        echo "`(date +"%m-%d-%Y-%T")`:======================================================================" >> $SCRIPT_LOG
        echo " " >> $SCRIPT_LOG
        echo " " >> $SCRIPT_LOG

        ps -ef| grep oracle| egrep -v 'grep|LOCAL|ora_|tns|sudo su|su -|ps -ef|-bash|expdp|impdp|sshd|mon_db_locks' | grep $ORACLE_SID > $CHK_LOGS
        RETVAL=$?

        if [ -s $CHK_LOGS ] ; then

        echo "`(date +"%m-%d-%Y-%T")`:======================================================================" >> $SCRIPT_LOG
        echo "`(date +"%m-%d-%Y-%T")`:Check these processes running on `hostname`." >> $SCRIPT_LOG
        echo "`(date +"%m-%d-%Y-%T")`:======================================================================" >> $SCRIPT_LOG
        cat $CHK_LOGS >> $SCRIPT_LOG
        echo "`(date +"%m-%d-%Y-%T")`:======================================================================" >> $SCRIPT_LOG

        fi

        fi


        if [ -s $SCRIPT_LOG ] ; then
                mailx -s "CRITICAL: DB LOCKS found for $ORACLE_SID database on `hostname`." $MAILLIST < $SCRIPT_LOG
                RETVAL=0
        fi

        fi
   fi
   shift
   ;;
-help|-h)
   script_usage
   RETVAL=2
   shift
   ;;
esac
done
else
   script_usage
   RETVAL=2
fi
if [ $RETVAL -ne 0 ] ; then
   echo "Refer script execution output log mentioned in cron for more specifications." | mailx -s "DB LOCKS script failing on `hostname`." $MAILLIST
fi
rm -f $CHK_LOGS $OHOMES
exit $RETVAL
