#!/bin/ksh
######################################################################
# NAME:         Invalid_objects.sh
#
# AUTHOR:       Raj Dada
#
# PURPOSE:     Find Details of Invalid Objects across cluster
#
#
# USAGE:        Invalid_objects.sh
#
#
#####################################################################
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
# How to Execute script : ksh /tmp/temp.sh METADB1 NA1 (script_path metadb_instance_name cluster_name)
#
function SendNotification {

        # Uncomment for debug
         set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX " > mail.dat
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n" >> mail.dat
        fi

        cat mail.dat | /bin/mail -s "PROBLEM WITH  Environment -- ${PROGRAM_NAME} on ${BOX}" ${MAILTO}
        rm mail.dat

        return 0
}

########################
##### MAIN #############
########################
set -x

mkdir -p $HOME/local/dba/scripts/logs
mkdir -p $HOME/scripts/logs
export CURDATE=$(date +'%Y%m%d_%H%M%S')
export DAY=$(date '+%d-%h-%Y')
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export MAILTO='DL-Tech-PCLD-CloudOps@csod.com'
export CLUSTER=$2
export CONNUSER=sabaadmin
export CONNPASS=dba4you
export LOGFILE=$HOME/scripts/logs/top_10_sql_for_${CLUSTER}_${DAY}.txt
export INVALIDOBJECTS=Invalid_objects_for_${CLUSTER}_${DAY}.htm
export ZIPLOGFILE=$HOME/scripts/logs/Invalid_objects_for_${CLUSTER}_${DAY}.zip


if [ $# -gt 2 ]
then
   print "${BOLD}\n\t\tInvalid Arguments!\n"
   print "\t\tUsage : $0 \n"
   SendNotification
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



if [ $# -lt 2 ]
then
        echo -e "\nUsage: $0 METADB_SID CLUSTERNAME\n"
        exit 1
fi

export ORACLE_SID=$1
export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv
export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib


$ORACLE_HOME/bin/sqlplus -s metadb/metadb@${ORACLE_SID}<<!
WHENEVER SQLERROR EXIT FAILURE
set heading off
set pages 500
set lines 190
set feedback off
spool $HOME/scripts/logs/conn_string_${CURDATE}.txt
select distinct b.CONN_STR
from MDT_SITE_DB_MAPPING a ,
MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME
and b.CONN_STR not like '%1521%'
and upper(a.DB_NAME) not like upper('%SabaMeeting%');
exit;
!
if [ $? -gt 0 ]
then
SendNotification "Count not connect to metadb."
exit 2
fi



cat $HOME/scripts/logs/conn_string_${CURDATE}.txt |sed  '/^$/d'|tr -d " \t\r"|awk -F\@ '{print $2}'|awk -F\: '{print $1,$2,$3}' > $HOME/scripts/logs/server_db_${CURDATE}_new.txt
rm $HOME/scripts/logs/conn_string_${CURDATE}.txt

>$INVALIDOBJECTS
cat $HOME/scripts/logs/server_db_${CURDATE}_new.txt | while read LINE
do
SERVER=`print $LINE |awk '{print $1}'`
PORT=`print $LINE |awk '{print $2}'`
DB=`print $LINE |awk '{print $3}'`

 #Invalid count  before compile
                INVALID_COUNT=`$ORACLE_HOME/bin/sqlplus -s ${CONNUSER}/${CONNPASS}@${SERVER}:${PORT}/${DB} <<RAJ
                set echo off line 150 pages 0 heading off feedback off
                select  count(*) from  dba_objects where  status != 'VALID'order by   owner,object_type;
RAJ`

if [[ ${INVALID_COUNT} > 0 ]] ; then
$ORACLE_HOME/bin/sqlplus -s ${CONNUSER}/${CONNPASS}@${SERVER}:${PORT}/${DB}<<!
SET MARKUP HTML ON ENTMAP OFF ;
SET HEADING  OFF
SET FEEDBACK OFF
CLEAR BREAKS;
CLEAR COLUMNS;
set long 400000
spool $INVALIDOBJECTS append
select '<H1 id="Section1" >Invalid Objects on  $DB</H1>' from dual
where 1 <= (select count(*) from (
select   owner ,object_type ,object_name ,status from dba_objects where status != 'VALID' order by   owner,   object_type));
SET HEADING  ON
select owner ,object_type ,object_name ,status from 
(select   owner ,object_type ,object_name ,status from dba_objects where status != 'VALID' and owner not in 
('OUTLN','DIP','ORACLE_OCM','DBSNMP','APPQOSSYS','WMSYS','EXFSYS','CTXSYS','ANONYMOUS','XDB','XS$NULL','SI_INFORMTN_SCHEMA',
'MDSYS','ORDDATA','ORDPLUGINS','ORDSYS','OLAPSYS','MDDATA','SPATIAL_CSW_ADMIN_USR','FLOWS_FILES', 'APEX_030200','APEX_PUBLIC_USER','OWBSYS','OWBSYS_AUDIT',
'SYSDG','SYSBACKUP','SYSKM','GSMADMIN_INTERNAL','SYSRAC','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYS$UMF','GSMCATUSER','GGSYS','OJVMSYS','SABAEXPIMP','DVSYS' ,'AUDSYS')order by   owner,   object_type);

exit;
!
fi




done

if [ $? -gt 0 ]
then
SendNotification "can not zip for Invalid Objects on $CLUSTER ."
exit 3
fi

zip -9m  ${ZIPLOGFILE} $INVALIDOBJECTS
mail -s "Invalid Objects for $CLUSTER on $DAY." -a ${ZIPLOGFILE}  $MAILTO <<EOF
EOF

rm  ${ZIPLOGFILE}

exit 0
