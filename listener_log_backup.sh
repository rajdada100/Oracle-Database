#!/bin/ksh
set -ux
#******************************************************************************
#
#       PROGRAM: Listener log backup
#
#       DESCRIPTION:
#       Backup listener log > 500M and zip it.
#
#       EXIT STATUS:
#           0   - script processed successfully
#         >=1   - error
#
#       AUTHOR: Brij Lal Kapoor (BLK)
#
#       Date: 10/21/2013
#******************************************************************************
# Date          Developer       Change Description
#==============================================================================
# 10/21/2013    BLK             Initial creation
#==============================================================================
db_env() {
if [ "${OS_TYPE}" = "Linux" ] ; then
        ORATAB="/etc/oratab"
fi
echo $(ps eww $(ps -ef| grep pmon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep "ORACLE_HOME=" | awk -F= '{print $2}') >$OHOMES
export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
if [ -z ${ORACLE_HOME} ] ; then
        echo $(ps eww $(ps -ef| grep smon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep "ORACLE_HOME=" | awk -F= '{print $2}') >$OHOMES
        export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
        if [ -z ${ORACLE_HOME} ] ; then
                export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $ORACLE_SID| grep -v grep| awk -F":" '{print $2}'`
                if [ -z ${ORACLE_HOME} ] ; then
                        SID=`ps -ef | grep pmon | grep -i ${ORACLE_SID} | sed -e 's/ora_pmon_//g'| awk '{print $8}'| awk '{print substr($0,0,length($0)-1)}'`
                        export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $SID| grep -v grep| awk -F":" '{print $2}'`
                fi
        fi
fi

echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep "LD_LIBRARY_PATH=" | awk -F= '{print $2}') >$OHOMES
export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`

if [ -z ${LD_LIBRARY_PATH} ] ; then
        echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep "LIBPATH=" | awk -F= '{print $2}') >$OHOMES
        export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
fi
echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep "ORACLE_SID=" | awk -F= '{print $2}') >$OHOMES
export ORACLE_SID=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`

export PATH=$ORACLE_HOME/bin:$PATH:.
}

FIND_ORATAB()
{
if [ -f /etc/oratab ] ; then
        export ORATAB=/etc/oratab
        RETVAL=0
elif [ -f /var/opt/oracle/oratab ] ; then
        export ORATAB=/var/opt/oracle/oratab
        RETVAL=0
fi
return $RETVAL
}

script_usage() {
export PROG_NAME=$(print $0 | sed 's/.*\///g')
echo "Expected atleast one argument in below syntax."
echo "SCRIPT USAGE: ${PROG_NAME}.sh <size_in_MB eg: 300>"
echo " "
}

######MAIN####

if [ $# lt 1 ] ; then
script_usage
else
FIND_ORATAB
ORAENV_ASK=no
export ORAENV_ASK
SIDLIST=/tmp/orasid.lst
LISTLIST=/tmp/oralistener.lst
THRESLIMIT=$1
LIS_LOG_DIR_DET=/tmp/oradir.lst
LIS_LOG_TRC_DET=/tmp/trcdir.lst
LIS_LOG_FILE_DET=/tmp/oralogfile.lst
#SCRIPT_LOG=`dirname $0`/logs/list_backup.log
SCRIPT_LOG=/tmp/list_backup.log
DATE=`(date +"%m-%d-%Y")`

#cat $ORATAB | sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' > $SIDLIST
ps -ef | grep ora_smon | egrep -v '+ASM|grep' | awk '{print $8}' | awk -F_ '{print $3}' > $SIDLIST

LOOPTOP=`cat $SIDLIST| wc -l`
export LOOPTOP=`expr $LOOPTOP + 1`
export LOOPCOUNTER=1

while [ $LOOPCOUNTER -lt $LOOPTOP ] ; do

GETLINE1=`head -$LOOPCOUNTER $SIDLIST| tail -1`
export ORACLE_SID=`echo $GETLINE1|awk -F":" '{print $1}'`
export ORACLE_HOME=`echo $GETLINE1|awk -F":" '{print $2}'`
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=$ORACLE_HOME/bin:$PATH:.
export OHOMES=/tmp/ohomes.lst
export OS_TYPE=`uname`
db_env

ps -ef| grep tns | grep $ORACLE_HOME | awk '{print $9}'> $LISTLIST
LISTLOOPTOP=`cat $LISTLIST| wc -l`
export LISTLOOPTOP=`expr $LISTLOOPTOP + 1`
export LISLOOPCOUNTER=1

while [ $LISLOOPCOUNTER -lt $LISTLOOPTOP ] ; do

GETLINE2=`head -$LOOPCOUNTER $LISTLIST| tail -1`
export LIS_NAME=`echo $GETLINE2|awk -F":" '{print $1}'`

DB_VER=`sqlplus -s /nolog <<BLK
conn / as sysdba
set echo off heading off feedback off pages 0
select property_value from database_properties where property_name='NLS_RDBMS_VERSION';
exit;
BLK`
DB_VER=`echo $DB_VER| awk -F"." {'print $1'}`

lsnrctl <<BLK >$LIS_LOG_DIR_DET
set current_listener $LIS_NAME
show log_directory
exit
BLK

lsnrctl <<BLK >$LIS_LOG_FILE_DET
set current_listener $LIS_NAME
show log_file
exit
BLK

lsnrctl <<BLK >$LIS_LOG_TRC_DET
set current_listener $LIS_NAME
show trc_directory
exit
BLK

LIS_LOG_DIR=`grep "log_directory" ${LIS_LOG_DIR_DET}| awk '{print $6}'`
LIS_LOG_FILENAME=`grep "log_file" ${LIS_LOG_FILE_DET}| awk '{print $6}'`
LIS_TRACE_DIR=`grep "trc_directory" ${LIS_LOG_TRC_DET}| awk '{print $6}'`
LIS_LOG_FILE=`echo ${LIS_LOG_FILENAME}| awk -F"." '{print $1}'`
echo $LIS_LOG_DIR
echo $LIS_LOG_FILENAME
echo $LIS_TRACE_DIR
echo $LIS_LOG_FILE

if [ $DB_VER -le 10  ] ; then
NEW_LOG_FILENAME=${LIS_LOG_DIR}/${LIS_LOG_FILE}_$DATE.log
FILESIZE_CHK=`ls -lrt ${LIS_LOG_DIR}/${LIS_LOG_FILENAME}| awk '{print $5}'`
FILESIZE_CHK=`expr $FILESIZE_CHK / 1024 / 1024 + 0`
typeset -i FILESIZE_CHK=$FILESIZE_CHK
else
NEW_LOG_FILENAME=${LIS_LOG_FILE}_$DATE.log
typeset -i FILESIZE_CHK=`ls -lrt ${LIS_LOG_FILENAME}| awk '{print $5}'`
LOG_FNAME=`echo "$LIS_NAME" | tr '[A-Z]' '[a-z]'`
FILESIZE_CHK=`ls -lrt ${LIS_TRACE_DIR}/${LOG_FNAME}.log| awk '{print $5}'`
FILESIZE_CHK=`expr ${FILESIZE_CHK} / 1024 / 1024 + 0`
typeset -i FILESIZE_CHK=$FILESIZE_CHK
fi

if [ $FILESIZE_CHK -ge $THRESLIMIT ] ; then

lsnrctl <<BLK
set current_listener ${LIS_NAME}
set log_status off
exit
BLK

echo "`(date +"%m-%d-%Y-%T")`:: =========================================================================================">> $SCRIPT_LOG
echo "`(date +"%m-%d-%Y-%T")`:: Starting backup of listener name:$LIS_NAME logfile (${LIS_LOG_DIR}${LIS_LOG_FILENAME}).">> $SCRIPT_LOG
if [ $DB_VER -le 10  ] ; then
mv ${LIS_LOG_DIR}${LIS_LOG_FILENAME} ${NEW_LOG_FILENAME}
gzip ${NEW_LOG_FILENAME}
else
find ${LIS_LOG_DIR}/* -type f -mtime +30 -exec rm -f {} \;
mv ${LIS_TRACE_DIR}/${LOG_FNAME}.log ${LIS_TRACE_DIR}/${LOG_FNAME}_$DATE.log
gzip ${LIS_TRACE_DIR}/${LOG_FNAME}_$DATE.log &
fi
echo "`(date +"%m-%d-%Y-%T")`:: Completed backup of listener name:$LIS_NAME logfile.">> $SCRIPT_LOG
echo "`(date +"%m-%d-%Y-%T")`:: =========================================================================================">> $SCRIPT_LOG
echo " " >> $SCRIPT_LOG
echo " " >> $SCRIPT_LOG

lsnrctl <<BLK
set current_listener ${LIS_NAME}
set log_status on
exit
BLK
fi

LISLOOPCOUNTER=`expr $LISLOOPCOUNTER + 1`
RETVAL=0
done

LOOPCOUNTER=`expr $LOOPCOUNTER + 1`
RETVAL=0
done

rm -f $SIDLIST $LISTLIST $LIS_LOG_DIR_DET $LIS_LOG_FILE_DET $LIS_LOG_TRC_DET $OHOMES
fi
exit $RETVAL
