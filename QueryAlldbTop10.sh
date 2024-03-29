#!/bin/ksh
######################################################################
# NAME:         QueryAlldbTop10.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:
#
#
# USAGE:        QueryAlldbTop10.sh
#
# Last modified By: Brij Lal Kapoor
# Last Modified Dt: 10-Aug-2018
# Last Modified Text: SQLs modified to consider data as per the run frequency
#                                         Logic modified to only list those SQL running for more than 1min.
#                                         Combine all databases in one single file instead of multiple files.
#####################################################################
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
export MAILTO='CloudOps-DBA@csod.com,DLSBXDevLeadership@csod.com'
export CLUSTER=$2
export CONNUSER=sabaadmin
export CONNPASS=dba4you
export LOGFILE=$HOME/scripts/logs/top_10_sql_for_${CLUSTER}_${DAY}.txt
export TOP20SQLSLOCAL=top_10_sql_for_${CLUSTER}_${DAY}.htm
export ZIPLOGFILE=$HOME/scripts/logs/top_10_sql_for_${CLUSTER}_${DAY}.zip

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

>$TOP20SQLSLOCAL
cat $HOME/scripts/logs/server_db_${CURDATE}_new.txt | while read LINE
do
SERVER=`print $LINE |awk '{print $1}'`
PORT=`print $LINE |awk '{print $2}'`
DB=`print $LINE |awk '{print $3}'`

$ORACLE_HOME/bin/sqlplus -s ${CONNUSER}/${CONNPASS}@${SERVER}:${PORT}/${DB}<<!
SET MARKUP HTML ON ENTMAP OFF ;
SET HEADING  OFF
SET FEEDBACK OFF
CLEAR BREAKS;
CLEAR COLUMNS;
set long 400000
spool $TOP20SQLSLOCAL append
select '<H1 id="Section1">Top 10 SQLs on $DB</H1>' from dual
where 1 <= (select count(*) from (
select
 parsing_schema_name as Tenant,
 stat.sql_id,
 sum((elapsed_time_total/1000/1000)/decode(stat.executions_total,0,1,stat.executions_total)) elapsed_time_in_secs
from
 dba_hist_sqlstat stat,
 dba_hist_snapshot snap
where
 stat.snap_id=snap.snap_id
 and snap.begin_interval_time>=sysdate-4
 and parsing_schema_name not in(select username from dba_users
                                                          where to_char(created,'dd-MON-rr') =(select created from (select distinct to_date(to_char(created,'dd-MON-rr')) created
                                                                                                                                                        from dba_users order by created)
                                                                                                                                   where rownum < 2))
                and parsing_schema_name not in ('DBSNMP','PERFSTAT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR')
group by parsing_schema_name,stat.sql_id
having sum((elapsed_time_total/1000/1000)/decode(stat.executions_total,0,1,stat.executions_total)) > 60) where rownum <11);
SET HEADING  ON
select txt.SQL_TEXT, top_sqlid.* from (
select * from (
select
 parsing_schema_name as Tenant,
 stat.sql_id,
 sum((elapsed_time_total/1000/1000)/decode(stat.executions_total,0,1,stat.executions_total)) elapsed_time_in_secs
from
 dba_hist_sqlstat stat,
 dba_hist_snapshot snap
where
 stat.snap_id=snap.snap_id
 and snap.begin_interval_time>=sysdate-4
 and parsing_schema_name not in(select username from dba_users
                                                          where to_char(created,'dd-MON-rr') =(select created from (select distinct to_date(to_char(created,'dd-MON-rr')) created
                                                                                                                                                        from dba_users order by created)
                                                                                                                                   where rownum < 2))
                and parsing_schema_name not in ('DBSNMP','PERFSTAT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR')
group by parsing_schema_name,stat.sql_id
having sum((elapsed_time_total/1000/1000)/decode(stat.executions_total,0,1,stat.executions_total)) > 60
order by 3 desc
) where rownum <11) top_sqlid, dba_hist_sqltext txt
where top_sqlid.sql_id=txt.sql_id
order by top_sqlid.elapsed_time_in_secs desc;
exit;
!
done

if [ $? -gt 0 ]
then
SendNotification "can not zip for top 10 sql on $CLUSTER ."
exit 3
fi

zip -9m  ${ZIPLOGFILE} $TOP20SQLSLOCAL
mail -s "Top 10 SQLs for $CLUSTER on $DAY." -a ${ZIPLOGFILE}  $MAILTO <<EOF
EOF

rm  ${ZIPLOGFILE}

exit 0
