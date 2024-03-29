#!/bin/ksh
# ==================================================================================================
# NAME:         CheckStandbySync.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:
#
#
# This script is to be run from the DR or Manual DR host.
# The script will make a local sqlplus connection to the DR database.
# The script will make a sqlplus connection using SQL*Net with a connect string to the Production host.
# It compares the maximum log sequence number on both databases and compares how far Production is ahead of DR.
# If the DR is more than $behind_threshold behind, it will send out an email alert to $MAILTO.
# Script to check archive log gap.
#
#
# USAGE:        CheckStandbySync.sh [ Oracle SID ]
#
# Note: Script to be run from one of the standby databases.
# ==================================================================================================

function recovery_proc_chk
{
set -x
RECOVER_PROC_CHK=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn sabaadmin/smadmin@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select count(*) from v\\$managed_standby where process='MRP0';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        RECOVER_PROC_CHK=`echo $RECOVER_PROC_CHK | sed 's/ //g'`
 fi
 return 0
}


function get_fal_server_details
{
set -x
FAL_SERVER=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn / as sysdba
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select value from v\\$parameter where name='fal_server';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        FAL_SERVER=`echo $FAL_SERVER | awk -F, '{print $1}' | sed 's/ //g'`
 fi
 return 0
}

function get_fal_client_details
{
set -x
FAL_CLIENT=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn / as sysdba
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select value from v\\$parameter where name='fal_client';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        FAL_CLIENT=`echo $FAL_CLIENT | awk -F, '{print $1}' | sed 's/ //g'`
 fi
 return 0
}

function get_standby_max_seq
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${GAP_CHK_DR}
conn sabaadmin/smadmin@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select thread#, max(sequence#) apl_max_seq from v\$archived_log where applied='YES' group by thread#;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}

function get_prod_max_seq
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${GAP_CHK_PRD}
conn sabaadmin/smadmin@${FAL_SERVER}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select thread#, max(sequence#) from v\$archived_log where thread#=$1 and status='A' group by thread#;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}

#new function added by brij
function get_active_standby_realtime_sync_status
{
set -x
BLK=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn sabaadmin/smadmin@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select count(*) FROM V\\$DATAGUARD_STATS WHERE name like 'apply lag' and (value is null or value not like '+00 00:0%') ;
EOF`

if [ $BLK -ne 0 ] ; then
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn sabaadmin/smadmin@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 10 sqlp "" trim on trims on lines 450
select name,value, TIME_COMPUTED, DATUM_TIME from v\$DATAGUARD_STATS WHERE name like 'apply lag' ;
EOF
 BLK_COUNTER=`expr ${BLK_COUNTER} + 1`
 echo ${BLK_COUNTER}>${BLK_COUNTER_CHK}
else
 echo 0 >${BLK_COUNTER_CHK}
fi
return 0
}

function get_standby_sync
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${SYNC_CHK_DR}
conn sabaadmin/smadmin@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select to_char(scn_to_timestamp(current_scn),'dd:mm:rrrr:hh24:mi') date_time from v\$database;
EOF
 if [ $? -ne 0 ] ; then
  return 1
 else
        dayp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $1}'`
        monp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $2}'`
        yyyp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $3}'`
        hrsp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $4}'`
        minp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $5}'`

        days=`cat ${SYNC_CHK_DR} | awk -F: '{print $1}'`
        mons=`cat ${SYNC_CHK_DR} | awk -F: '{print $2}'`
        yyys=`cat ${SYNC_CHK_DR} | awk -F: '{print $3}'`
        hrss=`cat ${SYNC_CHK_DR} | awk -F: '{print $4}'`
        mins=`cat ${SYNC_CHK_DR} | awk -F: '{print $5}'`

 if [[ $dayp -ne $days && $monp -ne $mons && $yyyp -ne $yyys && $hrsp -ne $hrss && $minp -ne $mins ]] ; then
        BLK_COUNTER=`expr ${BLK_COUNTER} + 1`
        echo ${BLK_COUNTER}>${BLK_COUNTER_CHK}
 else
        echo 0 >${BLK_COUNTER_CHK}
 fi
 fi
 return 0
}

function get_prod_sync
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${SYNC_CHK_PRD}
conn sabaadmin/smadmin@${FAL_SERVER}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select to_char(scn_to_timestamp(current_scn),'dd:mm:rrrr:hh24:mi') date_time from v\$database;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}


#########################################
### MAIN  ###############################
#########################################
set -x
if [ $# -ne 1 ]
then
   echo "Invalid Arguments!"
   echo "Usage : $0 <ORACLE_SID>"
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

export ORACLE_SID=$1
sid_in_oratab=$(grep -v "^#" $ORATAB | grep -w $ORACLE_SID | awk -F: '{print $1}')
if [ '1'$sid_in_oratab != '1' ] ; then
export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null

export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export PROGRAM_NAME_FIRST=$(print $PROGRAM_NAME | awk -F. '{print $1}')
export PROGRAM_LOG_PATH=`dirname $0`/logs
export MAILTO='CloudOps-DBA@csod.com'
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export behind_threshold=2
export BLK_COUNTER_CHK=${PROGRAM_LOG_PATH}/${PROGRAM_NAME_FIRST}_${ORACLE_SID}.chk
if [ ! -f ${BLK_COUNTER_CHK} ] ; then
        echo 0 > ${BLK_COUNTER_CHK}
else
        BLK_COUNTER=`cat ${BLK_COUNTER_CHK} | awk '{print $1}'`
fi

get_fal_server_details
get_fal_client_details
recovery_proc_chk
if [ ${RECOVER_PROC_CHK} -ne 0 ] ; then

export GAP_CHK_DR=/tmp/dr_seq_chk_$$.log
export GAP_CHK_PRD=/tmp/prod_seq_chk_$$.log
export SYNC_CHK_DR=/tmp/dr_sync_chk_$$.log
export SYNC_CHK_PRD=/tmp/prod_sync_chk_$$.log
get_standby_max_seq
if [ $? -eq 0 ] ; then

#added by brij - need to run once at db level than sequence
#get_active_standby_realtime_sync_status
get_prod_sync
get_standby_sync
if [ $? -eq 0 ] ; then

while read drseq ; do

threadno_dr=`echo $drseq |awk '{print $1}'|  sed 's/ //g'`
dr_max_seq_no=`echo $drseq | awk '{print $2}'|  sed 's/ //g'`

get_prod_max_seq $threadno_dr
if [ $? -eq 0 ] ; then
        while read prodseq ; do

        threadno_prod=`echo  $prodseq |awk '{print $1}'|  sed 's/ //g'`
        prod_max_seq_no=`echo  $prodseq | awk '{print $2}'|  sed 's/ //g'`

        how_far_behind=`expr $prod_max_seq_no - $dr_max_seq_no`
        if [[ ${how_far_behind} -gt ${behind_threshold} && ${BLK_COUNTER} -gt 5 ]] ; then
                mailx -s "$(hostname): $ORACLE_SID ACTIVE DATAGUARD behind Prod" $MAILTO<<EOF
$PROGRAM_NAME
Machine: $BOX

Critical: $ORACLE_SID ACTIVE DATAGUARD behind Prod by ${how_far_behind} archive logs at $(date)

Thread# $threadno_dr with threshold limit $behind_threshold is ${how_far_behind} logs behind.

Last archived log sequence on Primary is : ${prod_max_seq_no}

Last archived log sequence on Standby is : ${dr_max_seq_no}
EOF
        fi

        done < ${GAP_CHK_PRD}
else
mailx -s "$(hostname): $ORACLE_SID Prod cannot get max log sequence number" $MAILTO<<EOF
$PROGRAM_NAME
Machine: $BOX

Critical:$(hostname): $ORACLE_SID Prod cannot get max log sequence number at $(date)
EOF

fi
done < ${GAP_CHK_DR}
else
mailx -s "$(hostname): $ORACLE_SID HA setup is not found in realtime sync, check ACTIVE DATAGUARD status" $MAILTO<<EOF
$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID HA setup is not found in realtime sync, check ACTIVE DATAGUARD status at $(date)
EOF
fi
else
mailx -s "$(hostname): $ORACLE_SID ACTIVE DATAGUARD cannot get max log sequence number!!" $MAILTO<<EOF
$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID ACTIVE DATAGUARD cannot get max log sequence number at $(date)
EOF
fi
else
mailx -s "$(hostname): $ORACLE_SID ACTIVE DATAGUARD managed recovery is DOWN!!" $MAILTO<<EOF
$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID ACTIVE DATAGUARD managed recovery is DOWN!! at $(date)!!!
EOF
fi
else
 print "There is no $ORACLE_SID entry in $ORATAB file"
fi
rm -f ${GAP_CHK_DR} ${GAP_CHK_PRD} ${SYNC_CHK_DR} ${SYNC_CHK_PRD}
exit $?

