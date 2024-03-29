#!/bin/ksh
#uncomment the below line to debug
set -ux
#******************************************************************************
#
#       PROGRAM: monitor Shared pool.ksh
#
#       DESCRIPTION:
#                sharedpool_mon.sh
#
#       EXIT STATUS:
#           0   - script processed successfully
#         >=1   - error
#
#       AUTHOR: Brij Lal Kapoor (BLK)
#
#       Date: 11/10/2015
#******************************************************************************
# Date          Developer       Change Description
#==============================================================================
# 11/1/2016    BLK             Initial creation
#==============================================================================

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


db_chk() {
export SHRPOOL=`$ORACLE_HOME/bin/sqlplus -s  /nolog <<ENDSQL
conn / as sysdba
set pagesize 0 echo off feedback off trimspool on linesize 1000 serveroutput on
declare
sharepool_mb number;
bcache_mb number;
starget_mb number;
sga_max_mb number;
begin
Select sum(bytes)/1024/1024 into sharepool_mb from v\\$sgastat where pool='shared pool';
Select sum(bytes)/1024/1024 into bcache_mb from v\\$sgastat where name='buffer_cache';
select value/1024/1024 into starget_mb from v\\$parameter where name='sga_target';
select value/1024/1024 into sga_max_mb from v\\$parameter where name='sga_max_size';
--if (60/100*100) > 50 and 60 > 50 then
if (sharepool_mb/starget_mb*100) > 80 and sharepool_mb > bcache_mb and starget_mb<>sga_max_mb then
dbms_output.put_line('1');
elsif (sharepool_mb/starget_mb*100) > 80 and sharepool_mb > bcache_mb and starget_mb=sga_max_mb then
dbms_output.put_line('2');
else
dbms_output.put_line('0');
end if;
end;
/
exit;
ENDSQL`

RETVAL=$?
return
}

############################################################
#                       MAIN
############################################################
MAIL_LIST='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com'
HOST_NAME=`hostname`
HOST_NAME=`echo $HOST_NAME | awk -F. '{print $1}'`
export OHOMES=/tmp/ohomes.lst
export OS_TYPE=`uname`
export SID_LIST=$HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
export RETVAL=0

ps -ef | grep ora_smon | egrep -v '+ASM|grep' | awk '{print $8}' | awk -F_ '{print $3}' > ${SID_LIST}
if [[ -s ${SID_LIST} ]]
then
cat  ${SID_LIST} | while read LINE
do

 export sid=$LINE
 sid=$(echo $sid|tr -d " ")

 export ORACLE_SID=$sid
 export ORAENV_ASK=NO
 #export PATH=/usr/local/bin:$PATH
 #. /usr/local/bin/oraenv > /dev/null
 db_env
 db_chk
 if [[ $SHRPOOL -eq 1 && ${RETVAL} -eq 0 ]] ; then
        echo "Increase sga_target on $HOST_NAME for db:$ORACLE_SID"| mail -s "Critical:SharedPool size grown huge" -- $MAIL_LIST
 elif [[ $SHRPOOL -eq 2 && ${RETVAL} -eq 0 ]] ; then
        echo "There is no scope to increase sga_target, work with SRE team to get the db bounce if flushing sharedpool does not help at all on $HOST_NAME for db:$ORACLE_SID"| mail -s "Critical:SharedPool size grown huge" -- $MAIL_LIST
 fi
 rm -f ${SID_LIST}
done
fi

exit ${RETVAL}
