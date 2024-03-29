#!/bin/bash
set -x
##############################################
# Author : Brij Lal Kapoor
# Purpose: Directory cleanup.
#
# Creation Date : 21 Jan 2014
# Version : 1.0.0
# Modification :
#
###############################################
#$1 --> is the check whether directory need to be removed of just adhoc archivelog backups files
#$2 --> oracle sid

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
echo "Expected atleast one db as an argument."
echo "SCRIPT USAGE: ${PROG_NAME}.sh -d|dir <0 or 1> -s|-sid <dbname> ..... -s|-sid <dbname>"
echo " "
}

if [ $# -ge 3 ] ; then
RETVAL=0
while [ "$#" != "0" ]
do
        case $1 in
        -sid|-s)
           shift
           if [ "$1" ] ; then
                export ORACLE_SID=${1:-$SID}
           fi
           shift
           ;;
        -dirchk|-d)
           export condition_gate=0
           shift
           ;;
        -filechk|-f)
           export condition_gate=1
           shift
           ;;
        -help|-h)
           script_usage
           RETVAL=2
           shift
           ;;
        esac
done

if [ $RETVAL -eq 0 ] ; then
RMAN_LOG=/tmp/rman_file_deletion.log
RMAN_RETENTION=/tmp/rman_rentetion_pol.log

export OHOMES=/tmp/ohomes.lst
export OS_TYPE=`uname`
db_env

rman target / <<BLK >$RMAN_LOG
show RETENTION POLICY;
exit;
BLK

egrep 'DAYS|TO RECOVERY WINDOW' $RMAN_LOG > ${RMAN_RETENTION}
ret_period=`cat ${RMAN_RETENTION} | awk '{print $8}'`
ret_period=`expr ${ret_period} + 1`

if [ ${ret_period} -gt 0 ] ; then
        dirloc=`sqlplus -s /nolog <<BLK
        conn / as sysdba
        set heading off feedback off echo off pages 0 verify off
        select distinct substr(backup_loc,1,instr(substr(backup_loc,1),'/',-1)-1)
        from
        (select distinct substr(p.handle,1,instr(substr(p.handle,1),'/',-1)-1) backup_loc
        from v\\$backup_piece p, v\\$backup_datafile d
        where d.set_stamp = p.set_stamp
        and d.set_count = p.set_count
        and d.file# = 1);
        exit;
BLK`

        if [ ! -z $dirloc ] ; then
                if [ -d $dirloc ] ; then
                        currdt=`date "+%Y%m%d"`
                        prev_bkp_dt=`date -d "-2 days" "+%Y%m%d"`
                        pastdt=`date -d "-$ret_period days" "+%Y%m%d"`

                        for i in $(ls -l $dirloc| grep -v root | awk '{print $9}'| sed '1d'); do
                                filename=`echo $i | awk '{print substr($1,1,8)}'`
                                if [ $condition_gate -eq 0 ] ; then
                                        if [ $filename -lt $pastdt ] ; then
                                                rm -rf $dirloc/$i
                                        fi
                                elif [ $condition_gate -eq 1 ] ; then
                                        if [ $filename -lt $prev_bkp_dt ] ; then
                                                #for j in $(ls -l $dirloc/$i/al*${ORACLE_SID}*1_1_archive | awk '{print $9}'| sed '1d'); do
                                                        #rm -f $dirloc/$i/$j
                                                #done
                                                rm -f $dirloc/$i/al*${ORACLE_SID}*_1_1_archive
                                        fi
                                fi
                        done
                        RETVAL=$?

                        rman target / <<BLK >$RMAN_LOG
                        crosscheck backup;
                        crosscheck archivelog all;
                        exit;
BLK
                        RETVAL=$?
                        rm -f $RMAN_LOG ${RMAN_RETENTION}
                fi
        fi
fi
fi
rm -f $OHOMES
else
   script_usage
   RETVAL=2
fi
exit $RETVAL
