#!/bin/ksh
# ********************************************************************************************
# NAME:         Check_Temp_Tablespace.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This Utility will the the utilization of tablespace reached to the threshold which 90%.
#               If the Tablespace utilization reached to 90% it will send the alert.
#
# USAGE:        Check_Temp_Tablespace.sh
#
# INPUT PARAMETERS:   N/A
#
# Last modified By: Brij Lal Kapoor (BLK) on 14-Sep-2013
#
# *********************************************************************************************
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------

function SendNotification {

        # Uncomment for debug
        # set -x

        cat $HOME/local/dba/scripts/logs/temp_tablespace.log >> mail.dat
        cat mail.dat | /bin/mail -s "Temp Tablespace Usage Exceeded the Threshold -- on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        return 0
}


# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
funct_db_online_verify(){
 # Uncomment next line for debugging
 #set -x

 ps -ef | grep ora_pmon_$ORACLE_SID | grep -v grep > /dev/null
 if [ $? -ne 0 ]
 then
  print "Database $ORACLE_SID is not running.  Cannot perform CheckSessionProcess.sh"
  SendNotification "Database $ORACLE_SID is not running. $PROGRAM_NAME cannot run "
  export PROCESS_STATUS=FAILURE
  exit 3
 fi
}


############################################################
#                       MAIN
############################################################
#uncomment the below line to debug
set -ux
#clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
MAILTO=CloudOps-DBA@Saba.com
export CURDATE=$(date +'%Y%m%d')

if [ $# -gt 0 ]
then
   print "${BOLD}\n\t\tInvalid Arguments!\n"
   print "\t\tUsage : $0 \n"
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

ps -ef | grep "ora_smon_" | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}' > $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
#ps -ef | grep "ora_smon_" | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}' > $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
if [[ -s $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt ]]
then
   cat  $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt | while read LINE
   do

     export sid=$LINE
     sid=$(print $sid|tr -d " ")

     export ORACLE_SID=$sid
     export ORAENV_ASK=NO
     export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null
if [ $? -ne 0 ]
then
 print "\n\n\t\t There seems to be some problem please rectify and Execute Again\n\nAborting Here...."
 exit 2
fi

funct_db_online_verify

RW_CHK=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
set pages 0
select open_mode from v\\$database;
EOF`
RW_CHK2='READ WRITE'
if [[ $RW_CHK ==  $RW_CHK2 ]] ; then

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
set feedback off echo off verify off
declare
cursor c1 is
select tablespace_name
from (
        select f.tablespace_name,
                (s.used_bytes)/1024/1024/1024 used_GB,
                (f.total_bytes)/1024/1024/1024 total_GB,
                (f.total_bytes-s.used_bytes)/1024/1024/1024 free_GB
        from (select b.tablespace_name, sum(a.used_blocks*b.block_size) used_bytes
                        from v\$sort_segment a, dba_tablespaces b
                        where a.tablespace_name =b.tablespace_name
                        and b.contents='TEMPORARY'
                        group by b.tablespace_name) s,
                (select tablespace_name, sum(TOTAL_BYTES) TOTAL_BYTES, sum(DBFS) DBFS from (
                                select b.tablespace_name, decode(a.autoextensible,'YES', sum(a.maxbytes), sum(a.blocks)*b.block_size) total_bytes , count(*) DBFs
                                from dba_temp_files a, dba_tablespaces b
                                where a.tablespace_name=b.tablespace_name
                                and b.contents='TEMPORARY'
                                group by b.tablespace_name, a.autoextensible,b.block_size)
                                group by tablespace_name) f
        where s.tablespace_name=f.tablespace_name)
where round(free_GB/total_GB*100,2)<10;
sql_string varchar2(5000);
begin
for i in c1 loop
begin
sql_string:='alter tablespace '||i.tablespace_name||' shrink space';
execute immediate sql_string;
exception
when others then
 null;
 end;
end loop;
end;
/
exit
EOF


$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF > $HOME/local/dba/scripts/logs/temp_tablespace.log
WHENEVER SQLERROR EXIT FAILURE
set feed off
set linesize 100
set pagesize 200
column Tablespace format a25
column FreeSpc format 999999999 heading "Free|Space(MB)"
column Tot_Size format 999999999 heading "Total|Allocated(MB)"
column Free_Spc_perc format 99999 heading "Free|Space%"
column DBFs format 99999 heading "Num|DBFs"
set pages 5000
select *from (
        select f.tablespace_name tablespace,
                        (f.total_bytes-s.used_bytes)/1024/1024 FreeSpc,
                        (f.total_bytes)/1024/1024 Tot_Size,
                        round(((f.total_bytes-s.used_bytes))*100,2) Free_Spc_perc,
                        f.dbfs
        from    (select b.tablespace_name, sum(a.used_blocks*b.block_size) used_bytes
                                from v\$sort_segment a, dba_tablespaces b
                                where a.tablespace_name =b.tablespace_name
                                and b.contents='TEMPORARY'
                                group by b.tablespace_name) s,
                (select tablespace_name, sum(TOTAL_BYTES) TOTAL_BYTES, sum(DBFS) DBFS from (
                                select b.tablespace_name, decode(a.autoextensible,'YES', sum(a.maxbytes), sum(a.blocks)*b.block_size) total_bytes , count(*) DBFs
                                from dba_temp_files a, dba_tablespaces b
                                where a.tablespace_name=b.tablespace_name
                                and b.contents='TEMPORARY'
                                group by b.tablespace_name, a.autoextensible,b.block_size)
                                group by tablespace_name) f
        where s.tablespace_name=f.tablespace_name)
where Free_Spc_perc<10
order by tablespace;
exit
EOF
fi

if [[ -s $HOME/local/dba/scripts/logs/temp_tablespace.log ]]; then

print "\n\n\n\n" >> $HOME/local/dba/scripts/logs/temp_tablespace.log

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF >> $HOME/local/dba/scripts/logs/temp_tablespace.log
WHENEVER SQLERROR EXIT FAILURE
set feedback off echo off verify off;
set serveroutput on
declare
sql_active_since varchar2(20);
sql_text clob;
cursor c1 is
select s.osuser, s.process, s.username,s.schemaname,s.machine, s.sid, s.serial#,s.sql_id,round(s.LAST_CALL_ET/60,2) last_elapsed_et,
        sum(u.blocks)*vp.value/1024/1024/1024 sort_size_GB
 from   sys.v_\$session s, sys.v_\$sort_usage u, sys.v_\$parameter vp
 where  s.saddr = u.session_addr
   and  vp.name = 'db_block_size'
   and s.sql_id is not null
 group  by s.osuser, s.process, s.username, s.schemaname,s.machine,s.sid, s.serial#, vp.value, s.sql_id, round(s.LAST_CALL_ET/60,2)
 having sum(u.blocks)*vp.value/1024/1024/1024>1;
 begin
 for i in c1 loop
 dbms_output.put_line('---------------------------------------------------------------');
 dbms_output.put_line('---------------------------------------------------------------');
 dbms_output.put_line('session                 : '||''''||i.sid||','||i.serial#||'''');
 dbms_output.put_line('OS user                 : '||i.osuser);
 dbms_output.put_line('DB/Tenant User          : '||i.username||'/'||i.schemaname);
 dbms_output.put_line('Machine                 : '||i.machine);
 dbms_output.put_line('Sql Id                  : '||i.sql_id);
 dbms_output.put_line('Total Temp Used (in GB) : '||i.sort_size_GB);
 dbms_output.put_line('Elapsed Time (in Mins.) : '||i.last_elapsed_et);
 dbms_output.put_line('SQL Text:');
 select q.sql_fulltext into sql_text
 from v\$sqlarea q
 where q.sql_id=i.sql_id;
 dbms_output.put_line(sql_text);
 end loop;
 end;
 /
exit
EOF

SendNotification
fi
rm -f $HOME/local/dba/scripts/logs/temp_tablespace.log
done

rm -f $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
fi

exit

