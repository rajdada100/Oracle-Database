#!/bin/ksh
# ********************************************************************************************
# NAME:         RMANArcLogBkp_All_Clean.sh
#
# AUTHOR:       Basit Khan
# Updated By:   Brij to add check for previous runs
#
# PURPOSE:      This utility will perform a RMAN archivelog backup
#
# USAGE:        RMANArcLogBkp_All_Clean.sh ORACLE_SID
#
# INPUT PARAMETERS:
#               SID     Oracle SID of database to backup
#
#
# *********************************************************************************************
############################################################
#                       MAIN
############################################################
        ORATAB='/etc/oratab'
        HOSTNAME=$(hostname)
        # Uncomment next line for debugging
        #set -x
        export BOX=$(print $(hostname) | awk -F "." '{print $1}')
       export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com'

        if [ $# -ne 1 ]
        then
         print "\n$0 Failed: Incorrect number of arguments -> $0 ORACLE_SID "
         print "The ORACLE_SID must be passed as a parameter "
         exit 1
        fi

        export ORACLE_SID=$1
        #grep "^${ORACLE_SID}:" $ORATAB > /dev/null
        #if [ $? -ne 0 ]
        #then
         #print "\nThe first parameter entered into script is not a valid Oracle SID in $ORATAB."
         #print "Choose a valid Oracle SID from $ORATAB.\n"
         #exit 2
        #fi
        #export ORAENV_ASK=NO
        #export PATH=/usr/local/bin:$PATH
        #. /usr/local/bin/oraenv
        #export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
        #export LD_LIBRARY_PATH=$ORACLE_HOME/lib
        #export ORACLE_BASE=$HOME

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_BASE=/u01/app/oracle
export PATH=$ORACLE_HOME/bin:$PATH:.

PROG_NAME=`basename $0`
chk_runs=`ps -ef| grep RmanBackup.sh| grep INCREMENTAL | grep -v $PROG_NAME |grep -v grep | wc -l`
if [ $chk_runs -eq 0 ] ; then

export ARCH_DEST=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<EOF
set heading off
set feedback off
set serveroutput on
declare
cout number;
begin
select count(*) into cout from v\\$parameter where name ='log_archive_dest_1' and value is not null;
if cout = 0 then
select (ceil(round(sum(percent_space_used) + sum(percent_space_reclaimable)))) into cout
from v\\$flash_recovery_area_usage ;
end if;
dbms_output.put_line(cout);
end;
/
EOF`

ARCH_DEST=$(print $ARCH_DEST | tr -d " ")
if [ $ARCH_DEST -eq 1 ] ; then
ARCH_DEST=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<EOF
set heading off
set feedback off
select value from v\\$parameter where name ='log_archive_dest_1';
EOF`
ARCH_DEST=$(print $ARCH_DEST|awk -F= '{print $2}')
ARCH_SIZE=`du --max-depth=0 -m $ARCH_DEST`
ARCH_SIZE=$(print $ARCH_SIZE|awk '{print $1}')
ARCH_SIZE=$(print $ARCH_SIZE | tr -d " ")
if [ $ARCH_SIZE -ge 10000 ] ; then
$HOME/local/dba/backups/rman/RMANArcLogBkp_All_Clean.sh $ORACLE_SID
fi
elif [ $ARCH_DEST -ge 20 ] ; then
$HOME/local/dba/backups/rman/RMANArcLogBkp_All_Clean.sh $ORACLE_SID
fi
fi
exit
