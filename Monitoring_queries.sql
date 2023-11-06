===================================================================== 
******************Read Log File******************** 
===================================================================== 
cd /var/logs/sa
/var/log/sa

tail -n 5 <file_1_with-path> <file_2_with-path> *
*************** To monitor real-time log files **************** 
tail -f <file_1_with-path> tailf -F <file_1_with-path> 
**************** To search item ********************* 
tail -f <file_1_with-path> | grep searchitem 
**************to check sar logs *************** 
which sar (go to sar bin directory ) sar 10 2 sar -q -f sa11 

sar -q -f sa02

---- total number of processes and load average using ‘-q‘ option.
sar -q 2 5


SQL> !env|grep ORA;hostname;date;

======================================================================================
 ****************** to check cron working or not ******************** 
====================================================================================== 

 grep RMANArcLogBkp_All_Clean.sh /var/log/syslog

echo "cronjob triggered" $HOME/local/dba/backups/rman/cron_check.log
======================================================================================
 ****************** softlink search ******************** 
====================================================================================== 
find . -type l -ls 
find /backup_spcora03/syd/PSYDMETA -type l -ls

create softlink in linux 
ln -s /backup_spcora01/syd/PSPCA502 /backup/syd/PSPCA502
ln -s /backup_spcora01/syd/PSPCA503 /backup/syd/PSPCA503
ln -s /backup_spcora02/syd/psydspc /backup/syd/psydspc


======================================================================================
 ****************** Create Authentication SSH-Keygen Keys  ******************** 
====================================================================================== 
ssh-keygen -t rsa

======================================================================================
 ****************** create snapshot in oracle  ******************** 
====================================================================================== 
EXEC dbms_workload_repository.create_snapshot;


======================================================================================
 ****************** create temporary 50G file  ******************** 
====================================================================================== 
fallocate -l 50G file.txt

fallocate -l 10G file1.txt

====================================================================================== 
****************** METADB checks ******************** 
====================================================================================== 
sqlplus METADB/METADB
SET LINES 200 PAGES 120;
COL SITE_NAME FOR A30;
COL DB_NAME FOR A15;
COL USE_SECONDARY FOR A15;
SELECT
       SITE_NAME
     , DB_NAME
     , USE_SECONDARY
FROM
       mdt_site_db_mapping
WHERE
       USE_SECONDARY!='0'
;

SET LINES 200 PAGES 120;
COL SITE_NAME FOR A30;
COL DB_NAME FOR A15;
COL USE_SECONDARY FOR A15;
SELECT  SITE_NAME, DB_NAME, USE_SECONDARY FROM    mdt_site_db_mapping WHERE  USE_SECONDARY!='0 ' and DB_NAME='Prod4_DS' ;

select db_name, sec_conn_str, use_secondary from mdt_db_details where use_secondary=1 and SEC_CONN_STR like '%PNA3N101%';

select db_name, conn_str from MDT_DB_DETAILS where db_name in (select distinct db_name from mdt_site_db_mapping where use_secondary=1);

select use_secondary from mdt_site_db_mapping  where site_name='NA10P1PRD079' and db_name = 'PROD4_DS';

set line 1500 pages 0 heading off feedback off serveroutput on
col DB_IP_NAME for a30
col sid for a10
col port for a10
select distinct DB_IP_NAME||':'||SID||':'||Port from (
select substr(substr(CONN_STR,instr(CONN_STR,'@')+1),1,instr(substr(CONN_STR,instr(CONN_STR,'@')+1),':')-1) DB_IP_NAME,
substr(substr(CONN_STR,instr(CONN_STR,':',-1)+1),instr(substr(CONN_STR,instr(CONN_STR,':',-1)+1),'/')+1) SID,
substr(substr(CONN_STR,1,length(CONN_STR)-length(substr(CONN_STR,instr(CONN_STR,':',-1)))),instr(substr(CONN_STR,1,length(CONN_STR)-length(substr(CONN_STR,instr(CONN_STR,':',-1)))),':',-1)+1) Port
from (select replace(b.CONN_STR,'/',':') CONN_STR from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME and a.IS_ACTIVE='1'
/*and upper(a.DB_NAME) not like '%SABAMEETING%' and upper(a.db_name) not like '%SM_DS%'i*/));


select db_name,CONN_STR from  mdt_db_details;


set line 1500 pages 0 heading off feedback off serveroutput on
col DB_IP_NAME for a30
col sid for a10
col port for a10
select distinct DB_IP_NAME||':'||SID||':'||Port from (
select substr(substr(CONN_STR,instr(CONN_STR,'@')+1),1,instr(substr(CONN_STR,instr(CONN_STR,'@')+1),':')-1) DB_IP_NAME,
substr(substr(CONN_STR,instr(CONN_STR,':',-1)+1),instr(substr(CONN_STR,instr(CONN_STR,':',-1)+1),'/')+1) SID,
substr(substr(CONN_STR,1,length(CONN_STR)-length(substr(CONN_STR,instr(CONN_STR,':',-1)))),instr(substr(CONN_STR,1,length(CONN_STR)-length(substr(CONN_STR,instr(CONN_STR,':',-1)))),':',-1)+1) Port
from (select replace(b.CONN_STR,'/',':') CONN_STR from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME and a.IS_ACTIVE='1'
and b.CONN_STR like '%n1pp01spcora07%'
/*and upper(a.DB_NAME) not like '%SABAMEETING%' and upper(a.db_name) not like '%SM_DS%'i*/))
;
====================================================================================== 
****************** SSH Key for OEM setup ******************** 
====================================================================================== 
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAvQwNRVJKD1E3GDtdI2ZjMRd2EQWZnLQhdYmxgiwX5C6geKQAj4Q7TNuuMO0fxxx4bd/abT12qglpMycoNznOj8Z0gWwzeoq6UpBT4ZNDM6pHLOOn3bdRGb8LihcK6IAD2KfcN5Mi2cklshVMVOvvviq7rnZrYu3rmUOCqRpiL+FNUCR1pUyZNjIb9MS2MdHluHzI/CYU9B/lQBb7P/GqV6+5B7YFMLoyyFDYlZSOQwWRg44R6l7bbSOAMfOpzH33G2+X/N9qhNX+3OTYhRqhw/x0K8EYy7kkBmA3bqUSgdjcsEVino1sJ80DUb6lAq80Fig1GR5EmgIavEmeDxoz9Q== rsa-key-20200422

====================================================================================== 
****************** DB start/stop automation ******************** 
====================================================================================== 
. ./tsyda501_19c_env.sh sqlplus "/ as sysdba" <<BLK > start_tsyda501.log &
connect  / as sysdba
startup;
BLK
---------------------------
. ./tsyda501_19c_env.sh sqlplus "/ as sysdba" <<BLK > shut_tsyda501.log &
connect                                                                                     / as sysdba shut immediate;
BLK 
====================================================================================== 
****************** rsync ******************** 
====================================================================================== 
rsync -avzh /backup/syd/psydspc/20220422_190001 a5paa01spcora02:/backup/syd/psydspc/20220422_190001 
nohup rsync --progress -zae '/usr/bin/ssh -x -a -c blowfish' /backup/syd/psydspc/20220422_190001 a5paa01spcora02:/backup/syd/psydspc/ > bkp_move.log &


rsync -zae '/usr/bin/ssh -x -a -c blowfish' /saba/sabatools/local/* /saba1/sabatools/local/
====================================================================================== 
****************** oracle sessions check at server level ******************** 
====================================================================================== 
netstat -pant | grep -i oracle | wc -l 

====================================================================================== 
****************** oracle/mongo FS check except other mounts (byweekly)*************** 
====================================================================================== 
for i in `cat servers.lst`;do echo $i; ssh oracle@$i "df -h |egrep -v 'home|root|var|tmp|run|CLICK_REFRESH|DUMPS|DECOMMISSION|boot' ";
echo "----------------------------------";done > /tmp/fs_SEP_4th_week_DE.log 2> /tmp/fs_SEP_4th_week_DE.err 

**** mongo FS check except other mounts 
for i in `cat mongo_servers.lst`; do echo $i; ssh mongouser@$i "df -h |egrep -v 'home|root|var|tmp|run|CLICK_REFRESH|DUMPS|DECOMMISSION|boot' ";
echo "----------------------------------";done > /tmp/fs_SEP_4th_week_DE_mongo.log 2> /tmp/fs_SEP_4th_week_DE_mongo.err 

mailx -a /tmp/fs_SEP_4th_week_DE.log -s  fs_SEP_4th_week_DE -- rdada@csod.com < /dev/null
mailx -a /tmp/fs_SEP_4th_week_DE_mongo.log -s fs_SEP_4th_week_DE_mongo  -- rdada@csod.com < /dev/null

shubhampatankar@csod.com
for i in `cat servers.lst`;do echo $i; ssh oracle@$i "df -h |egrep -v 'home|root|var|tmp|run|CLICK_REFRESH|DUMPS|DECOMMISSION|boot' ";
echo "----------------------------------";done > /tmp/fs_AUG_4th_week_CA_mongo.log 2> /tmp/fs_AUG_4th_week_CA_mongo.err 
========================================================================================  
****************** oracle/mongo FS check for Pending Patching server list*************** 
======================================================================================== 
for i in `cat servers.lst`;do echo $i; ssh oracle@$i "uname -r";
echo "----------------------------------";done > /DB_TRANSFER/DB/for_pending_paching_U54_oracle.log 2> /DB_TRANSFER/DB/for_pending_paching_U54_oracle.err 

mailx -a /DB_TRANSFER/DB/for_pending_paching_U54_oracle.log -s for_pending_paching_U54_oracle -- rdada@csod.com < /dev/null

**** mongo FS check except other mounts 
for i in `cat mongo_servers.lst`; do echo $i; ssh mongouser@$i "uname -r";
echo "----------------------------------";done > /DB_TRANSFER/DB/for_pending_paching_U54_mongo.log 2> /DB_TRANSFER/DB/for_pending_paching_U54_mongo.err 



mailx -a /DB_TRANSFER/DB/for_pending_paching_U54_mongo.log -s for_pending_paching_U54_mongo -- rdada@csod.com < /dev/null
 
====================================================================================== 
****************** Check for mount point is either in user of not ********************
====================================================================================== 
1. lsof 2. fuser fully_qualified_directory_path 
====================================================================================== 
****************** screen session ******************** 
======================================================================================
 ---start screen session
 screen -R session_name -L
 -- detache screen session
 ctrl+a d
 ---reattached screen session
 screen -r session_id
 --to reconnect to disconnected screen sesison
 screen -x DB_TRANSFER_move
 --list all screen sessions
 screen -ls 
 **** start screen session screen -R DB_TRANSFER_move -L 

----error
Cannot open your terminal '/dev/pts/1' - please check
----solution
script /dev/null
=============================================================================== 
****************** To find Huge Page allocation setting ********************
=============================================================================== 
cat /etc/sysctl.conf|grep vm.nr_hugepages 
=============================================================================== 
****************** Check for Current Huge Page allocation ******************** 
=============================================================================== 
cat /proc/meminfo|grep -i hugepages 
========================================================================================= 
****************** How to check Transparent Huge pages setting ******************** ========================================================================================= 
cat /sys/kernel/mm/transparent_hugepage/enabled
 ---> enabled
 [always] madvise never
 ---> disabled
 always madvise [never]
===================================================================== 
****************** SWAP usage check ******************** 
===================================================================== 
# free -g # free -k # free -m 
===================================================================== 
****************** DB restart Validation ******************** 
=====================================================================
 ----------------- ---------------
 [rdada@e2paa01infctl01 ~]$ sudo su - sabatools [sudo] password for rdada: [sabatools@e2paa01infctl01 ~]$ cd /home/sabatools/local/dba/scripts/CLICK_DB_RESTART/logs [sabatools@e2paa01infctl01 logs]$ pwd /home/sabatools/local/dba/scripts/CLICK_DB_RESTART/logs /home/sabatools/local/dba/scripts/ ls -lrt |grep -i UK2|grep -i main
 ------vi latest main log file [search for below keyword in logs --->/ n ]
 keyword ---> SABAMASTER - INVALID objects details
 keyword ---> RESTART_STATUS  --> It should be Restart Successful
 ===================================================================== 
 ******************Remove Old Trace Files******************** 
 ===================================================================== 
 for i in G M K; do du -kh | grep [0-9]$i | sort -nr -k 1; done | head -n 11
 
 find *.aud -mtime +30 -exec rm {} \;
 find *.trc -mtime +15 -exec rm {} \;
 find *.trm -mtime +15 -exec rm {} \;
 find *.log -mtime +31 -exec rm {} \;
 
 find . -name "*.aud" -print | xargs rm
 find . -name "*.aud" -mtime +15  -print | xargs rm
 
 find *.trc -mtime +15 -size +100M 
 find *.trc -size +1G 
 find *.trm -size +1G 
 find *.trm -size +100M 
 find *.log -size +100M 
 find *.xml -size +100M 
 find *.log -mtime +15 -exec rm {} \;
 find *.xml -mtime +7 -exec rm {} \;
 find *.aud -mtime +15 -exec rm {} \;
 find *.trc -mtime +15 -exec rm {} \;
 find *.trm -mtime +15 -exec rm {} \;
 find *.trc.gz -mtime +7 -exec rm {} \;
 find *.trm.gz -mtime +7 -exec rm {} \;
 find *.log -mtime +30 -exec rm {} \;
 ===================================================================== 
 ****************** Find Active Listener Services ******************** 
 ===================================================================== 
 ps -ef | grep lsnr 
 
===================================================================== 
 ****************** DB Growth By Segment For Last Days **************
===================================================================== 
 
SELECT TRUNC(begin_interval_time) c1,
object_name c2,
round(space_used_total/1024/1024,2) c3,
o.object_type
FROM dba_hist_seg_stat s,
dba_hist_seg_stat_obj o,
dba_hist_snapshot sn
WHERE o.tablespace_name = 'TBS'
AND s.obj# = o.obj#
AND sn.snap_id = s.snap_id
ORDER BY begin_interval_time desc;
 –-AND TRUNC(begin_interval_time) BETWEEN '01/02/23' AND '13/02/23'
 
 
 
================================================================================= 
 ****************** LOB Segment size in a TABLE Column wise  ******************** 
================================================================================= 
SET LINESIZE 200
COLUMN owner FORMAT A30
COLUMN table_name FORMAT A30
COLUMN column_name FORMAT A30
COLUMN segment_name FORMAT A30
COLUMN tablespace_name FORMAT A30
COLUMN size_mb FORMAT 99999999.00

SELECT *
FROM   (SELECT l.owner,
               l.table_name,
               l.column_name,
               l.segment_name,
               l.tablespace_name,
               ROUND(s.bytes/1024/1024,2) size_mb
        FROM   dba_lobs l
               JOIN dba_segments s ON s.owner = l.owner AND s.segment_name = l.segment_name
      AND l.owner='&OWNER'
     -- AND l.TABLE_NAME='&TABLE_NAME'
        ORDER BY 6 DESC)
WHERE  ROWNUM <= 20;" 
===================================================================================================================================   
 ****************** searching  tables from databases which are greater than 1 GB **************
===================================================================================================================================    
SELECT owner,segment_name,SUM(bytes)/1024/1024 MB,tablespace_name
FROM DBA_EXTENTS
where segment_type='TABLE'
group by owner,segment_name,tablespace_name
having SUM(bytes)/1024/1024 >1024
order by SUM(bytes)/1024/1024 desc;

===================================================================================================================================   
 ****************** Tables Having Foreign Key without INDEX on Foreign Key Column **************
===================================================================================================================================

SELECT acc.column_name unindexed_on_child_table,
t.table_name parent_table,
t.OWNER parent_table_owner,
c.constraint_name child_constraint,
c.table_name child_table,
c.OWNER child_table_owner
FROM all_constraints t,
all_constraints c,
all_cons_columns acc
WHERE c.r_constraint_name = t.constraint_name
AND c.table_name = acc.table_name
AND c.constraint_name = acc.constraint_name
AND NOT EXISTS (SELECT '1'
FROM all_ind_columns aid
WHERE aid.table_name = acc.table_name
AND aid.column_name = acc.column_name)
AND T.OWNER NOT IN ('DBSNMP','SYSMAN','SYS','SYSTEM','OLAPSYS','EXFSYS','SCOTT','ORDDATA')
AND C.OWNER NOT IN ('DBSNMP','SYSMAN','SYS','SYSTEM','OLAPSYS','EXFSYS','SCOTT','ORDDATA')
ORDER BY c.table_name;


 set line 1000 pages 1000 long 40000000 col object_name format a60 heading SQLs col object_type for a25
 Select
        object_name
      , object_type
      , created
      , last_ddl_time
      , status
 From
        dba_objects
 Where
        object_name = 'ANF_SURVEY_COMMENTS'
 ;
 
 -- To compile all objects in database
 @$ORACLE_HOME/rdbms/admin/utlrp.sql 
 
 
 
 
set pages 999
col c1 heading 'owner' format a15
col c2 heading 'name' format a40
col c3 heading 'type' format a10
col c4 heading 'status' format a10
ttitle 'Invalid|Objects'

select
   owner       c1,
   object_type c3,
   object_name c2,
   status c4
from
   dba_objects
where
   status != 'VALID'
   and owner = 'SABAADMIN'
order by
   owner,
   object_type;
 ===================================================================== 
 ******************Analytics Finder Query Check 1******************** 
 =====================================================================
 undefine username
 undefine sid
 undefine schemaname
 undefine os_pid
 undefine machine
 undefine sql_address
 undefine sql_id
 set line 1000 pages 1000 long 40000000 col sql_fulltext format a60 heading SQLs col username for a25
 select
        s.sql_id
      , s.username
               ||','
               ||s.schemaname username
      , s.count_runs
      , sq.sql_fulltext
 from
        (
               select
                      inst_id
                    , sql_id
                    , username
                    , schemaname
                    , status
                    , count(*) count_runs
               from
                      (
                             select
                                    inst_id
                                  , sid
                                  , sql_id
                                  , username
                                  , schemaname
                                  , status
                             from
                                    gv$session
                             where
                                    sql_id is not null
                                    and sid         <>
                                    (
                                           SELECT DISTINCT
                                                  SID
                                           FROM
                                                  V$MYSTAT
                                    )
                      )
               group by
                      inst_id
                    , sql_id
                    , username
                    , schemaname
                    , status
        )
                   s
      , gv$sqlarea sq
 where
        s.username       like upper('%&&username%')
        and s.schemaname like upper('%&&schemaname%')
        and sq.sql_id    like '%&&sql_id%'
        and sq.sql_id       =s.sql_id
        and s.inst_id       =sq.inst_id
        and s.status        ='ACTIVE'
 order by
        3 desc
 ;
 
 ===================================================================== 
 ****************** Last DDL ON Object ******************** 
 =====================================================================
 
 
 select
        object_name,
        to_char(last_ddl_time,'DD-MM-YY HH24:MI:SS')last_ddl
 from
        ALL_OBJECTS
 where
        OWNER          ='CA1PRD0032'
        AND OBJECT_NAME='TPT_TRANSCRIPT_STG'
 ;
 
 
 alter session set NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
 select object_name,last_ddl_time from dba_objects where owner='CA1PRD0032' and object_name='TPT_TRANSCRIPT_STG';
 
 
====================================================================================== 
******************table last modified/ table definition change******************** 
====================================================================================== 
SET LINES 200 PAGES 120;
COL owner FOR A30;
COL object_name FOR A25;
COL object_type FOR A15;
select owner,object_name,object_type,status,to_char(last_ddl_time,'DD-MM-YY HH24:MI:SS')last_ddl from dba_objects where object_name='TPT_TRANSCRIPT_STG' and owner = 'CA1PRD0032' and object_type='TABLE';



SET LINES 200 PAGES 120;
COL owner FOR A30;
COL object_name FOR A25;
COL object_type FOR A15;
select object_name,object_type,status,to_char(last_ddl_time,'DD-MM-YY HH24:MI:SS')last_ddl from user_objects where object_name='TPT_TRANSCRIPT_STG' and  object_type='TABLE'; 
 ===================================================================== 
 ****************** Last DDL ON Object ******************** 
 =====================================================================
 SELECT
        index_name
      , index_type
      , uniqueness
 FROM
        all_indexes
 WHERE
        owner          = UPPER('&owner')
        AND table_name = UPPER('&table_name')
 ;
 
 ===================================================================== 
 ******************Analytics Finder Query Check 2******************** 
 =====================================================================
 SET LINES 200 PAGES 1200;
 COL USERNAME FOR A30;
 COL SCHEMANAME FOR A20;
 col MACHINE for a30;
 COL PROGRAM FOR A50;
 COL STATUS FOR A15;
 select
        SCHEMANAME
      , MACHINE
      , PROGRAM
      , status
      , count(*)
      , sid
      ,serial#
      ,sql_id
 from
        v$session
 where
        schemaname    !='SYS'
        and STATUS     ='ACTIVE'
        and PROGRAM like '%ANALYTI%'
 GROUP BY
        SCHEMANAME
      , PROCESS
      , MACHINE
      , PROGRAM
      , status
      , sid
      ,serial#
      ,sql_id
 ORDER BY
        4 DESC
 ;
 
 
 =========================================================================== 
 ******************Find Sessions Consuming Lot Of CPU******************** 
 =========================================================================== 
 col program form a30 heading "Program" col CPUMins form 99990 heading "CPU in Mins"
 select
        rownum as rank
      , a.*
 from
        (
               SELECT
                      v.sid
                    , program
                    , v.value / (100 * 60) CPUMins
                    , sess.sql_id
               FROM
                      v$statname s
                    , v$sesstat  v
                    , v$session  sess
               WHERE
                      s.name          = 'CPU used by this session'
                      and sess.sid    = v.sid
                      and v.statistic#=s.statistic#
                      and v.value     >0
               ORDER BY
                      v.value DESC
        )
        a
 where
        rownum < 11
 ;
 
 =========================================================================== 
 ******************SQL id consuming more CPU in Oracle******************** 
 =========================================================================== 
 SET LINES 300 PAGES 1500;
 col program form a35 heading "Program" 
 col cpu_usage_sec form 99990 heading "CPU in Seconds" 
 col MODULE for a28 
 col OSUSER for a10 
 col USERNAME for a15 
 col schemaname for a15
 col MACHINE for a20
 col OSPID for a15 heading "OS PID" 
 col SID for 99999 
 col SERIAL# for 999999 
 col SQL_ID for a15
 select *
 from
        (
               select
                      p.spid "ospid"
                    , (se.SID)
                    , ss.serial#
                    , ss.SQL_ID
                    , ss.schemaname
                    , ss.username
                    , substr(ss.program,1,30) "program"
                    , ss.osuser
                    , ss.MACHINE
                    , ss.status
                    , se.VALUE/100 cpu_usage_sec
                    , ss.port
               from
                      v$session  ss
                    , v$sesstat  se
                    , v$statname sn
                    , v$process  p
               where
                      se.STATISTIC#             = sn.STATISTIC#
                      and NAME               like '%CPU used by this session%'
                      and se.SID                = ss.SID
                      and ss.username          !='SYS'
                      and ss.status             ='ACTIVE'
                      and ss.username is not null
                      and ss.paddr              =p.addr
                      and value                 > 0
               order by
                      se.VALUE desc
        )
 ;
 
 ===================================================================== 
 ****************** checkpoint checking ******************** 
 =====================================================================
 select
        checkpoint_change#
      , controlfile_change#
 from
        v$database
 ;
 
 =========================================================================================== 
 ****************** -- Get default tablespace of a user:    ********************
 ===========================================================================================
 set lines 200 col username for a23
 select
        username
      , DEFAULT_TABLESPACE
 from
        dba_users
 ;
 
 ===================================================================== 
 ****************** Check Undersize SGA/PGA ******************** 
 ===================================================================== 
 login to OEM-->go to db instance-->go to recommendation --> ADDM findings-->login with sys-->check for undersize SGA/PGA
 
 or
 
 login to OEM-->go to instance--> performance--> advisors home-->check for ADDM report
 ===================================================================== 
 ****************** Generate AWR Report ******************** 
 =====================================================================
 connect as sysdba
 and
 execute below script SQL> @$ORACLE_HOME/rdbms/admin/awrrpt.sql 
 ===================================================================== 
 ****************** Generate ASH Report ******************** 
 ===================================================================== 
 SQL> @$ORACLE_HOME/rdbms/admin/ashrpt.sql [MM/DD[/YY]] HH24:MI[:SS]
 --        Examples: 02/23/03 14:30:15
 06/01/23  06:47:32 6 Thu Jun  1 06:47:32 EDT 2023

 PNA9N101 
 mailx -a  /u01/oracle/awrrpt_n1pp01secora12_31july2023_01.html -s awrrpt_n1pp01secora12_31july2023_01 -- rdada@csod.com < /dev/null
 mailx -a  /tmp/awrrpt_01jun2023.html -s awrrpt_01jun2023 -- rdada@csod.com < /dev/null
 
 
================================================================================= 
 ******************** Flush Bad SQL Plan from Shared Pool ******************** 
 ================================================================================= 
 
 https://expertoracle.com/2015/07/08/flush-bad-sql-plan-from-shared-pool/
 
 ================================================================================= 
 ******************** Generating explain plan for a sql query ******************** 
 ================================================================================= 
 alter session set CURRENT_SCHEMA= schema_name;
 --- LOAD THE EXPLAIN PLAN TO PLAN_TABLE
 SQL> explain plan for 2
 select
        count(*)
 from
        dbaclass
 ;
 
 Explained.
 --- DISPLAY THE EXPLAIN PLAN
 SQL> set lines 150
 select *
 from
        table(dbms_xplan.display)
 ;
 
 OR
 SQL> @$ORACLE_HOME/rdbms/admin/utlxpls.sql 
 
 	
 ---generate explain plan from sql_id
 set lines 2000
set pagesize 2000

SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('71tq5tcxj4rsb'));

Explain plan of a sql_id from AWR:
set lines 2000
set pagesize 2000
SELECT * FROM table(DBMS_XPLAN.DISPLAY_AWR('784hbkw0dvf64'));


Explain plan of a sql_id using sql_id and plan hash value:
 set lines 2000
set pagesize 2000
 SELECT * FROM table(DBMS_XPLAN.DISPLAY_AWR('g1rjjatn11amc',3328009182));      
 
--Find with help of Plan Hash Value
 set lines 2000
set pagesize 2000       
col object_owner for a5
col name for a30
col operation for a35
col cpu_cost a10 
col time a20
select id,operation ,object_owner||'-'||object_name as Name,BYTES,cpu_cost,time,PLAN_HASH_VALUE from v$SQL_PLAN where PLAN_HASH_VALUE= '1572568773';




 set lines 2000
set pagesize 2000       
col object_owner for a5
col name for a30
col operation for a35
col cpu_cost a10 
col time a20
select id,operation ,object_owner||'-'||object_name as Name,BYTES,cpu_cost,time,PLAN_HASH_VALUE from v$SQL_PLAN where SQL_ID= '3hq1bdfytww38';

 ====================================================================== 
 ******************** How to Enable SQL Tuning Advisor ******************** 
 ======================================================================

SQL> show parameter control_management_pack
NAME                                 TYPE                             VALUE
————————————                        ——————————–                      ——————————
control_management_pack_access       string                           NONE
SQL> ALTER system SET CONTROL_MANAGEMENT_PACK_ACCESS='DIAGNOSTIC+TUNING';
System altered.
SQL>  show parameter control_management_pack
NAME                                 TYPE                             VALUE
————————————                        ——————————–                        ——————————
control_management_pack_access       string                           DIAGNOSTIC+TUNING


SQL> ALTER system SET CONTROL_MANAGEMENT_PACK_ACCESS='DIAGNOSTIC';

DIAGNOSTIC

=============================================
*******SQL Tuning Advisor*******
==============================================
SET serveroutput ON
DECLARE
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sql_id      => '4d59s3fk9v8dv',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 60,
                          task_name   => 'sql_tuning_task_4d59s3fk9v8dv',
                          description => 'Tuning task for statement 	4d59s3fk9v8dv.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/
SELECT task_name, STATUS FROM dba_advisor_log WHERE task_name LIKE '%4d59s3fk9v8dv%';
EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => 'sql_tuning_task_4d59s3fk9v8dv');
SELECT task_name, STATUS FROM dba_advisor_log WHERE task_name LIKE 'sql_tuning_task_4d59s3fk9v8dv';

set long 65536
set longchunksize 65536
set linesize 100
select dbms_sqltune.report_tuning_task('sql_tuning_task_4d59s3fk9v8dv') from dual;


BEGIN
  DBMS_SQLTUNE.drop_tuning_task (task_name => 'sql_tuning_task_4d59s3fk9v8dv');
END;
/

DECLARE
my_plans PLS_INTEGER;
BEGIN
my_plans := DBMS_SPM.LOAD_PLANS_FROM_SQLSET(sqlset_name => 'fpkp050uuj1a7');
END;
/
=============================================================================
 ************ Worst and best PLAN_HASH_VALUE calulator for a sql_id ************
 =============================================================================
 WITH snaps
     AS (SELECT /*+  materialize */
               dbid, SNAP_ID
           FROM dba_hist_snapshot s
          WHERE (begin_interval_time BETWEEN sysdate-&1 AND sysdate))
select * from (
SELECT t.*, row_number () over (order by impact_secs desc ) seq#
FROM (
  SELECT DISTINCT  sql_id
                  , execs executions
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg DESC) worst_plan
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id), 2) worst_plan_et_secs
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg ASC) best_plan
                  , ROUND (MIN (pln_avg) OVER (PARTITION BY sql_id), 2) best_plan_et_secs
                  , ROUND ( (MAX (pln_avg) OVER (PARTITION BY sql_id) - MIN (pln_avg) OVER (PARTITION BY sql_id)) * execs) impact_secs
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id) / MIN (pln_avg) OVER (PARTITION BY sql_id), 2) times_faster
    FROM (SELECT PARSING_SCHEMA_NAME
                 , sql_id
                 , plan_hash_value
                 , AVG (elapsed_time_delta / 1000000 / executions_delta) OVER (PARTITION BY sql_id, plan_hash_value) pln_avg
                 , SUM (executions_delta) OVER (PARTITION BY sql_id) execs
            FROM DBA_HIST_SQLSTAT h
           WHERE  sql_id='fpkp050uuj1a7'  and  (dbid, SNAP_ID) IN (SELECT dbid, SNAP_ID FROM snaps)
                 AND NVL (h.executions_delta, 0) > 0)
) t
)
where seq# < 11
ORDER BY seq#;

########### Query to find Plan Hash Values for a SQLID in Oracle
SELECT DISTINCT sql_id, plan_hash_value
FROM dba_hist_sqlstat dhs,
    (
    SELECT /*+ NO_MERGE */ MIN(snap_id) min_snap, MAX(snap_id) max_snap
    FROM dba_hist_snapshot ss
    WHERE ss.begin_interval_time BETWEEN (SYSDATE - &No_Days) AND SYSDATE
    ) s
WHERE dhs.snap_id BETWEEN s.min_snap AND s.max_snap
  AND dhs.sql_id IN ( '&SQLID');

 =============================================================================
 ************ segment advisor ************ 
 =============================================================================
 
 https://www.support.dbagenesis.com/post/oracle-segment-advisor
 
 
 ====================================================================== 
 ******************** Object/Table Size ******************** 
 ======================================================================
 set pages 5000
 set lines 190 col segment_name for a50
 select
        segment_name
      , sum(bytes)/1024/1024/1024 GB
 from
        dba_segments
 where
        segment_name=upper('FGT_DETAIL')
 group by
        segment_name
 ;
 
================================================================================= 
 How To Find Execution History Of An Sql_id
================================================================================= 
select a.instance_number inst_id, a.snap_id,a.plan_hash_value, to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime, abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions, round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" from dba_hist_SQLSTAT a, dba_hist_snapshot b
where sql_id='0ansn3bpz081g' 
and a.snap_id=b.snap_id
and a.instance_number=b.instance_number
order by snap_id desc, a.instance_number;

================================================================================= 
******************** Check Current User Permissions/privilegs ******************** 
=================================================================================
select * from USER_ROLE_PRIVS where USERNAME='LEAP_HP';
select * from USER_TAB_PRIVS where Grantee = 'SABAEXPIMP';
select * from USER_SYS_PRIVS where USERNAME = 'SABAEXPIMP';
 
 ================================================================================= 
 ******************** Find locks present in database ******************** 
 =================================================================================
 col session_id head 'Sid' form 9999 
 col object_name head "Table|Locked" form a30 
 col oracle_username head "Oracle|Username" form a10 truncate 
 col os_user_name head "OS|Username" form a10 truncate 
 col process head "Client|Process|ID" form 99999999 
 col mode_held form a15
 select
        lo.session_id
      , lo.oracle_username
      , lo.os_user_name
      , lo.process
      , do.object_name
      , decode(lo.locked_mode, 0, 'None', 1, 'Null', 2, 'Row Share (SS)' , 3, 'Row Excl (SX)', 4, 'Share', 5, 'Share Row Excl (SSX)', 6, 'Exclusive' , to_char(lo.locked_mode)) mode_held
 from
        v$locked_object lo
      , dba_objects     do
 where
        lo.object_id = do.object_id
 order by
        1
      , 5
 ;
 
 =================================================================================================== 
 ******************** Check existing datafile is autoextensibleor not ******************** 
 =================================================================================================== 
 col tablespace_name head 'tablespace_name' form a20 
 col file_name head "file_name" form a60 
 col autoextensible head "autoextensible" form a10 truncate
 select
        tablespace_name
      , file_name
      , autoextensible
 from
        dba_data_files
 where
        tablespace_name like upper('SYSAUX')
 ;
 
 select
        file_name
      , autoextensible
 from
        dba_data_files
 where
        tablespace_name like upper('PMDBNA3P1_TBS')
 ;
 
 ----ALTER DATABASE DATAFILE '/u05/oradata/PNA3N101/NA3P1PRD006_026.dbf' AUTOEXTEND OFF;
 ================================================================================= 
 ******************** Delete Older Archive Logs  ******************** 
 ================================================================================= 
 RMAN>
 DELETE
        ARCHIVELOG ALL COMPLETED BEFORE 'sysdate-20'
 ;
 
 RMAN> CROSSCHECK ARCHIVELOG ALL;
 RMAN>
 DELETE
        EXPIRED ARCHIVELOG ALL
 ;
 
                                  
================================================================================= 
******************** check the syntax of RMAN commands ******************** 
================================================================================= 
RMAN> rman checksyntax RMAN> backup database;
 The command has no syntax errors 
================================================================================= 
******************** alert log destination ******************* 
=================================================================================
 set lines 200 col name format a10 col value format a60
 select
        inst_id
      , name
      , value
 from
        v$diag_info
 where
        name = 'Diag Trace'
 ;
 
 ============================================================= 
 ******* find the session generating ARCHIVELOG ********** 
 =============================================================
 SET LINESIZE 160 PAGESIZE 200 COL s.sid FOR a10 COL s.serial# FOR a16 COL s.program FOR a64
 SELECT
        s.sid
      , s.serial#
      , s.username
      , s.program
      , i.block_changes
 FROM
        v$session s
      , v$sess_io i
 WHERE
        s.sid = i.sid
 ORDER BY
        5 desc
      , 1
      , 2
      , 3
      , 4
 ;
 
 select
        sql.sql_text            sql_text
      , t.USED_UREC             Records
      , t.USED_UBLK             Blocks
      , (t.USED_UBLK*8192/1024) KBytes
 from
        v$transaction t
      , v$session     s
      , v$sql         sql
 where
        t.addr         = s.taddr
        and s.sql_id   = sql.sql_id
        and s.username ='SABAADMIN'
 ;
 
 col program for a10 col username for a10
 select
        to_char(sysdate,'hh24:mi')
      , username
      , program
      , a.sid
      , a.serial#
      , b.name
      , c.value
 from
        v$session  a
      , v$statname b
      , v$sesstat  c
 where
        b.STATISTIC#  =c.STATISTIC#
        and c.sid     =a.sid
        and b.name like 'redo%'
 order by
        value
 ;
 
================================================================================= 
 ******************** Find active sessions in oracle database ******************* 
=================================================================================
 
 set linesize 200
 set pages 500
 set feedback on col sid head "Sid" form 9999 trunc col serial# form 99999 trunc head "Ser#" col username form a8 trunc col sql_id form a20 col osuser form a7 trunc col machine form a20 trunc head "Client|Machine" col program form a15 trunc head "Client|Program" col login form a11 col "last call" form 9999999 trunc head "Last Call|In Secs" col status form a6 trunc
 select
        sid
      , serial#
      , sql_id
      , substr(username,1,10) username
      , substr(osuser,1,10)   osuser
      , substr(program
               ||module,1,15)               program
      , substr(machine,1,22)                machine
      , to_char(logon_time,'ddMon hh24:mi') login
      , last_call_et "last call"
      , status
 from
        v$session
 where
        status='ACTIVE'
 order by
        1
 ;
 
=============================================================================  
 ****************** Response Time / Transaction Per sec ******************** 
============================================================================= 
 
 select CASE METRIC_NAME
 WHEN 'SQL Service Response Time' then 'SQL Service Response Time (secs)'
 WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
 ELSE METRIC_NAME
 END METRIC_NAME,
 CASE METRIC_NAME
 WHEN 'SQL Service Response Time' then ROUND((MINVAL / 100),2)
 WHEN 'Response Time Per Txn' then ROUND((MINVAL / 100),2)
 ELSE MINVAL
 END MININUM,
 CASE METRIC_NAME
 WHEN 'SQL Service Response Time' then ROUND((MAXVAL / 100),2)
 WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),2)
 ELSE MAXVAL
 END MAXIMUM,
 CASE METRIC_NAME
 WHEN 'SQL Service Response Time' then ROUND((AVERAGE / 100),2)
 WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),2)
 ELSE AVERAGE
 END AVERAGE
 from SYS.V_$SYSMETRIC_SUMMARY 
 where METRIC_NAME in ('CPU Usage Per Sec',
 'CPU Usage Per Txn',
 'Database CPU Time Ratio',
 'Database Wait Time Ratio',
 'Executions Per Sec',
 'Executions Per Txn',
 'Response Time Per Txn',
 'SQL Service Response Time',
 'User Transaction Per Sec')
 ORDER BY 1;

 
 ===================================================================== 
 ****************** for long running sessions ******************** 
 =====================================================================
 
set echo off
set pagesize 50
set lines 140
set verify off
set heading on
set feedback on
col SESS format a12
col status format a10
col program format a30
col terminal format a12
col "Machine Name" format a30
col "DB User" format a14
col "OS User" format a10
col "Logon Time" format a14
set lines 190
col schemaname for a15
col sql_id for a15
select rpad(s.username,14,' ') as "DB User",
 schemaname , to_char(logon_time,'hh24:mi Mon/dd') as "Logon Time",
   initcap(status) as "Status",s.sid||','||s.serial# SESS,
   sql_id,
   rpad(upper(substr(s.program,instr(s.program,'\',-1)+1)),30,' ') as "Program",
   rpad(lower(osuser),10,' ') as "OS User", rpad(s.terminal,12,' ') "Terminal",
   rpad(initcap(machine),30,' ') as "Machine Name",last_call_et/60  as "Active Since" from v$session s
   where upper(s.username) like upper('%&Username%') and s.status='ACTIVE'
   --order by machine,s.program
   and s.username not in ('SYS','SYSTEM')
   order by  "Active Since";





 ==================================================== 
 ************** Check Active Session *************** 
 ====================================================
 ---------------
 set lines 200 pages 1200;
 col username for a30;
 select
        username
      , status
      , count(*)
 from
        v$session
 group by
        username
      , status
 ;
 
 ===================================================================== 
 ****************** current sessions ******************** 
 =====================================================================
 set verify off
 set feedback off
 column machine format a30
 column schemaname format a20
 column status for a10 col program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , status
      , sid
      , machine
      , program
      , count(*)
 from
        v$session
 where
        schemaname not in 'SYS'
        and status = 'ACTIVE'
 group by
        schemaname
      , status
      , sid
      , machine
      , program
 order by
        program
 ;
 
 -----schema specific
 set verify off
 set feedback off
 column machine format a30
 column schemaname format a20
 column status for a10 col program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , sid
      , serial#
      , status
      , machine
      , program
      , count(*)
 from
        v$session
 where
        schemaname in ('NA7P1PRD104' )
 group by
        schemaname
      , sid
      , serial#
      , status
      , machine
      , program
 ;
 
 -----active sessions---
 set verify off
 set feedback off
 column machine format a30
 column schemaname format a20
 column status for a10 col program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , status
      , sid
      , serial#
      , machine
      , program
      , sql_id
 from
        v$session
 where
        schemaname not in ('SYSTEM'
                         ,'SYS')
        and status = 'ACTIVE'
 group by
        schemaname
      , status
      , sid
      , serial#
      , machine
      , program
      , sql_id
 order by
        program
 ;
 
 set verify off
 set feedback off
 column machine format a30
 column schemaname format a20
 column status for a10
 column logon_time a30 col program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , status
      , sid
      , serial#
      , to_char(LOGON_TIME,'DD-MON-YYYY HH24:MI:SS')logon_time
      , machine
      , port
      , program
      , sql_id
 from
        v$session
 where
        status = 'INACTIVE'
        and schemaname not in ('SYSTEM' ,'SYS')
 group by
        schemaname ,status , sid
      , serial# , logon_time , machine  , port , program , sql_id
 order by        program, logon_time   ;
 
 
 -----machine wise session count---
 select distinct program, schemaname, machine,count(*) 
 from v$session where program like 'na4%' group by program, schemaname, machine;
 
 set verify off
 column machine format a30
 column schemaname format a20
 column status for a10 
 column program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , sid
      , serial#
      , status
      , machine
      , program
      , count(*)
 from
        v$session
 where
        schemaname not in 'SYS'        
 group by
        schemaname
      , status
      , sid
      , serial#
      , machine
      , program
 order by
        program
 ;
 
 select  count(*) from  v$session where  status = 'INACTIVE'  and schemaname not in ('SYSTEM','SYS') ;
 
 set verify off
 set feedback off
 set pages 5000
 set lines 190
 column machine format a27
 column unique(PROGRAM) format a25
 column status) format a20
 select unique(PROGRAM),machine,status, count(*) from  v$session where  status='INACTIVE' group by  PROGRAM,status,machine order by  count(*) ;
 
 set verify off
 set feedback off
 set pages 5000
 set lines 190
 column machine format a20
 column unique(PROGRAM) format a22
 column status) format a20
 select unique(PROGRAM),SCHEMANAME,machine,status, count(*) from  v$session where  status='ACTIVE' group by  PROGRAM,SCHEMANAME,status,machine order by  count(*) ;
 
 set verify off
 set feedback off
 set pages 5000
 set lines 190
 column machine format a20
 column unique(PROGRAM) format a22
 column status) format a20
 select unique(PROGRAM),SCHEMANAME,machine,status, count(*), sid
      , serial# from  v$session where  status='INACTIVE'
and  machine like '%na4-n1np01spcapp08%'
 group by  PROGRAM,SCHEMANAME,status,machine, sid
      , serial# order by  count(*) ;
 
select distinct program, schemaname, machine,count(*) from v$session where program like 'na4%' group by program, schemaname, machine;
 
 select unique(PROGRAM),machine,status,sql_id,schemaname from v$session where  status='ACTIVE'  group by PROGRAM,status,machine,sql_id,schemaname ;
 
 SELECT
        sql_text
 FROM
        v$sql
 WHERE
        sql_id = '2p6schj7h5gxb'
 ;
 
 set verify off
 set feedback off
 column machine format a30
 column schemaname format a20
 column status for a10
 column logon_time a30 col program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , status
      , sid
      , serial#
      , to_char(LOGON_TIME,'DD-MON-YYYY HH24:MI:SS')logon_time
      , machine
      , program
      , sql_id
      , count(*)
 from
        v$session
 where
        status = 'ACTIVE'
        and schemaname not in ('SYSTEM'
                             ,'SYS')
        and program like '%JDBC Thin Client%'
        and machine = 'na4-n1np01spcapp08'
 group by
        schemaname
      , status
      , sid
      , serial#
      , logon_time
      , machine
      , program
      , sql_id
 order by
        program
      , logon_time
 ;
 SELECT 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' IMMEDIATE;' FROM v$session where status='INACTIVE'
 and program = 'na4-t2-app-30036-n03-SC_APP';
 
 
 ------check with session ID-----
 set verify off
 column machine format a30
 column schemaname format a20
 column status for a10 
 column program for a50
 set pages 5000
 set lines 190
 select
        schemaname
      , sid
      , serial#
      , status
      , machine
      , program
      , count(*)
 from
        v$session
 where
        schemaname not in 'SYS'        
 group by
        schemaname
      , status
      , sid
      , serial#
      , machine
      , program
 order by
        program
 ;
 
 select
        CURRENT_UTILIZATION
 from
        v$resource_limit
 where
        RESOURCE_NAME = 'sessions'
 ;
 

 column inst_id format 9999
 column resource_name format a20
 column current_utilization for 9999
 column max_utilization for 9999
  set lines 200 pages 1200;
 SELECT 
inst_id,resource_name, 
current_utilization, 
max_utilization, 
limit_value 
FROM gv$resource_limit 
WHERE resource_name in ('processes','sessions');


SET LINES 200 PAGES 1200;
COL RESOURCE_NAME FOR A30;
select RESOURCE_NAME,CURRENT_UTILIZATION,MAX_UTILIZATION,LIMIT_VALUE from v$resource_limit where resource_name in ('processes','sessions');

set lines 200 pages 1200;
col username for a15;
col schemaname for a15;
col machine for a30;
col PROGRAM for a30;
select sql_id,username,schemaname,status,machine,program,count(*) from v$session where username not in ('SYS') group by sql_id,username,schemaname,status,machine,program;

set lines 200 pages 1200;
col username for a15;
col schemaname for a15;
col machine for a25;
col PROGRAM for a25;
select sql_id,username,schemaname,status,machine,program,port,count(*) from v$session where username not in ('SYS') group by sql_id,username,schemaname,status,machine,program,port;
================================================================  
 ************** Show session login history from ASH *************
================================================================ 
 SELECT c.username,
         a.SAMPLE_TIME,
         a.SQL_OPNAME,
         a.SQL_EXEC_START,
         a.program,
         a.module,
         a.machine,
         b.SQL_TEXT
    FROM DBA_HIST_ACTIVE_SESS_HISTORY a, dba_hist_sqltext b, dba_users c
   WHERE     a.SQL_ID = b.SQL_ID(+)
         AND a.user_id = c.user_id
         AND c.username = '&username'
ORDER BY a.SQL_EXEC_START ASC;
 ==================================================== 
 ************** Check flashback_scn *************** 
 ====================================================
 select
        dbms_flashback.get_system_change_number scn
 from
        dual
 ;
 
==================================================== 
 ************** Memory *************** 
====================================================
 
 --------SGA USAGE-------
 
 column TOTAL_SGA for a20
column USEED for a20
column FREE for a20
select  round(sum(bytes)/1024/1024,2)||' MB' total_sga,
      round(round(sum(bytes)/1024/1024,2) - round(sum(decode(name,'free memory',bytes,0))/1024/1024,2))||' MB' used,
      round(sum(decode(name,'free memory',bytes,0))/1024/1024,2)||' MB' free
    from v$sgastat;

 
 
 
 
==================================================== 
 ************** user's profile details *************** 
====================================================
 
  select username, profile from dba_users where username = 'INFDB';

select username, profile from dba_users where username = 'RMAN';

  set lines 200 pages 150;
 column PROFILE a10
 column RESOURCE_NAME  a20
 column RESOURCE_TYPE a20
 column LIMIT  a20       
 column COMMON   a20     
 column INHERITED   a20  
 column IMPLICIT    a20 
select * from dba_profiles where profile='DEFAULT';

SELECT resource_name,limit FROM dba_profiles WHERE profile='DEFAULT' AND resource_name='PASSWORD_LIFE_TIME';

ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
 ============================================================
 ************** Execution History Of An Sql_id *************** 
 ============================================================
 set pages 5000
set lines 190
 select a.instance_number inst_id, a.snap_id,a.plan_hash_value, to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime, abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions, round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" from dba_hist_SQLSTAT a, dba_hist_snapshot b
where sql_id='bppg6qbm1zrj9' and a.snap_id=b.snap_id
and a.instance_number=b.instance_number
order by snap_id desc, a.instance_number;  



 
================================================================================================== 
 ************** script to find out the table growth for the last 60 days. *************** 
 ==================================================================================================
 set lines 200 pages 1200;
 SELECT
        o.OWNER
      , o.OBJECT_NAME
      , o.SUBOBJECT_NAME
      , o.OBJECT_TYPE
      , t.NAME "Tablespace Name"
      , s.growth/(1024*1024) "Growth in MB"
      , (
               SELECT
                      sum(bytes)/(1024*1024)
               FROM
                      dba_segments
               WHERE
                      segment_name=o.object_name
        )
        "Total Size(MB)"
 FROM
        DBA_OBJECTS o
      , (
               SELECT
                      TS#
                    , OBJ#
                    , SUM(SPACE_USED_DELTA) growth
               FROM
                      DBA_HIST_SEG_STAT
               GROUP BY
                      TS#
                    , OBJ#
               HAVING
                      SUM(SPACE_USED_DELTA) > 0
               ORDER BY
                      2 DESC
        )
                     s
      , v$tablespace t
 WHERE
        s.OBJ#     = o.OBJECT_ID
        AND s.TS#  =t.TS#
        AND rownum < 51
 ORDER BY
        6 DESC
 ;
 
 select
        a.USER_ID
      , b.username
 from
        DBA_HIST_ACTIVE_SESS_HISTORY a
      , dba_users                    b
 where
        SQL_ID       = '2kbxrp4tuz3kf'
        and a.user_id=b.user_id
 ;
 
 ===========================================================
 *************** ++ Blocking sessions ++ *************** 
 ============================================================ 1)
set pagesize 250
SET LINESIZE 32000 
col A.USERNAME heading username a20 
col A.BLOCKING_SESSION heading bloking_session for a7 
col A.STATUS heading status for a6 
col A.SID heading sid for a9 
col A.SERIAL# heading serial_no for a8 
col A.WAIT_CLASS for a20 
col A.SECONDS_IN_WAIT for 
a5 col "MINUTES IN WAIT" for a5 col A.MACHINE format a11 
col A.BLOCKING_SESSION_STATUS heading BLOCKING_SESSION_STATUS for a10 
col A.STATE for a10
SELECT
       A.USERNAME
     , A.BLOCKING_SESSION
     , A.STATUS
     , A.SID
     , A.SERIAL#
     , A.WAIT_CLASS
     , A.SECONDS_IN_WAIT
     , A.SECONDS_IN_WAIT/60 "MINUTES IN WAIT"
     , A.MACHINE
     , A.BLOCKING_SESSION_STATUS
     , A.STATE
FROM
       V$SESSION A
     , V$SQLAREA B
WHERE
       A.SQL_ID                         =B.SQL_ID(+)
       AND A.BLOCKING_SESSION IS NOT NULL
ORDER BY
       A.BLOCKING_SESSION
;





set lines 750 pages 9999
col blocking_status for a100 
 select s1.inst_id,s2.inst_id,s1.username || '@' || s1.machine
 || ' ( SID=' || s1.sid || ' )  is blocking '
 || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
  from gv$lock l1, gv$session s1, gv$lock l2, gv$session s2
  where s1.sid=l1.sid and s2.sid=l2.sid and s1.inst_id=l1.inst_id and s2.inst_id=l2.inst_id
  and l1.BLOCK=1 and l2.request > 0
  and l1.id1 = l2.id1
  and l2.id2 = l2.id2
order by s1.inst_id; 
    



2)
set pagesize 250
SET LINESIZE 32000
column "wait event" format a50 word_wrap
column "session" format a25
column "minutes" format 9999D9
column CHAIN_ID noprint
column N noprint
column l noprint
with w as
     (
            select
                   chain_id
                 , rownum n
                 , level  l
                 , lpad(' ',level,' ')
                          ||
                   (
                          select
                                 instance_name
                          from
                                 gv$instance
                          where
                                 inst_id=w.instance
                   )
                          ||' '''
                          ||w.sid
                          ||','
                          ||w.sess_serial#
                          ||'@'
                          ||w.instance
                          ||'''' "session"
                 , lpad(' ',level,' ')
                          ||w.wait_event_text
                          ||
                   case
                          when w.wait_event_text like 'enq: TM%'
                                 then ' mode '
                                        ||decode(w.p1 , 1414332418,'Row-S' , 1414332419,'Row-X' , 1414332420,'Share' , 1414332421,'Share RX' , 1414332422,'eXclusive')
                                        ||
                                 (
                                        select
                                               ' on '
                                                      ||object_type
                                                      ||' "'
                                                      ||owner
                                                      ||'"."'
                                                      ||object_name
                                                      ||'" '
                                        from
                                               all_objects
                                        where
                                               object_id=w.p2
                                 )
                          when w.wait_event_text like 'enq: TX%'
                                 then
                                 (
                                        select
                                               ' on '
                                                      ||object_type
                                                      ||' "'
                                                      ||owner
                                                      ||'"."'
                                                      ||object_name
                                                      ||'" on rowid '
                                                      ||dbms_rowid.rowid_create(1,data_object_id,relative_fno,w.row_wait_block#,w.row_wait_row#)
                                        from
                                               all_objects
                                             , dba_data_files
                                        where
                                               object_id           =w.row_wait_obj#
                                               and w.row_wait_file#=file_id
                                 )
                   end "wait event"
                 , w.in_wait_secs/60 "minutes"
                 , s.username
                 , s.program
            from
                   v$wait_chains w
                   join
                          gv$session s
                          on
                                 (
                                        s.sid        =w.sid
                                        and s.serial#=w.sess_serial#
                                        and s.inst_id=w.instance
                                 )
                                 connect by prior w.sid   =w.blocker_sid
                                 and prior w.sess_serial# =w.blocker_sess_serial#
                                 and prior w.instance     = w.blocker_instance start with w.blocker_sid is null
     )
select *
from
       w
where
       chain_id in
       (
              select
                     chain_id
              from
                     w
              group by
                     chain_id
              having
                     max("minutes") >= 1
                     and max(l)      >1
       )
order by
       n
;

-------------------------------------------------------------------
set linesize 300
select
       B.USERNAME
              ||' ('
              ||B.SID
              ||','
              ||B.SERIAL#
              ||',@'
              ||B.INST_ID
              ||') is Currently '
              ||B.STATUS
              ||' for last '
              ||B.LAST_CALL_ET
              ||' Sec and it''s BLOCKING user '
              || W.USERNAME
              || ' ('| |W.SID
              ||','
              ||W.SERIAL#
              ||',@'
              ||W.INST_ID
              ||')'
from
       (
              select
                     INST_ID
                   , SID
                   , SERIAL#
                   , USERNAME
                   , STATUS
                   , BLOCKING_INSTANCE
                   , BLOCKING_SESSION
                   , LAST_CALL_ET
              from
                     gv$session
              where
                     BLOCKING_SESSION >0
       )
       W
     , (
              select
                     INST_ID
                   , SID
                   , SERIAL#
                   , USERNAME
                   , STATUS
                   , LAST_CALL_ET
              from
                     gv$session
       )
       B
where
       W.BLOCKING_INSTANCE   =B.INST_ID
       and W.BLOCKING_SESSION=B.SID
;

=================================================================
 *************** ++ Long Running Queries ++ *************** 
==================================================================
select
       sid
     , inst_id
     , opname
     , totalwork
     , sofar
     , start_time
     , time_remaining
from
       gv$session_longops
where
       totalwork<>sofar
;

select
       sid
     , SQL_ID
     , inst_id
     , opname
     , totalwork
     , sofar
     , start_time
     , time_remaining
from
       gv$session_longops
where
       SQL_ID = '0wusm955fqbpm'
;

set lines 200 pages 1200;
col TARGET for a20;
col OPNAME for a30;
SELECT SID, SERIAL#, OPNAME, TARGET, SOFAR, TOTALWORK,TIME_REMAINING/60 AS TIME_REMAINING_MINS,ELAPSED_SECONDS/60 AS ELAPSED_MINS,ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$SESSION_LONGOPS WHERE OPNAME NOT LIKE '%aggregate%' AND TOTALWORK != 0 AND SOFAR <> TOTALWORK;

select
       sid
     , inst_id
     , opname
     , totalwork
     , sofar
     , start_time
     , time_remaining
from
       gv$session_longops
where
       totalwork<>sofar
;

set echo off
set pagesize 50
set lines 140
set verify off
set heading on
set feedback on
col SESS format a12
col status format a10
col program format a30
col terminal format a12
col "Machine Name" format a20
col "DB User" format a14
col "OS User" format a10
col "Logon Time" format a14
set lines 190
col schemaname for a15
col sql_id for a15
select rpad(s.username,14,' ') as "DB User",
 schemaname , to_char(logon_time,'hh24:mi Mon/dd') as "Logon Time",
   initcap(status) as "Status",s.sid||','||s.serial# SESS,
   sql_id,
   rpad(upper(substr(s.program,instr(s.program,'\',-1)+1)),30,' ') as "Program",
   rpad(lower(osuser),10,' ') as "OS User", rpad(s.terminal,12,' ') "Terminal",
   rpad(initcap(machine),20,' ') as "Machine Name",last_call_et/60  as "Active Since" from v$session s
   where upper(s.username) like upper('%&Username%') and s.status='ACTIVE'
   --order by machine,s.program
   order by  "Active Since";
       
       
       
select count(s.status) "INACTIVE SESSIONS > 1HOUR ",s.sid, s.serial#,s.sql_id
from gv$session s, v$process p
where
p.addr=s.paddr and
s.last_call_et > 3600 and
s.status='INACTIVE'
group by s.sid, s.serial#,s.sql_id;
       
=================================================================
 *************** ++ SQLs INVOLVED IN BLOCKING ++ *************** 
==================================================================
set pagesize 100
set linesize 300 col sql_text for a100 col SQL_ID for a30
SELECT distinct
       /*+ RULE */
       SQL_ID
     , sql_text
FROM
       GV$SQL
WHERE
       SQL_ID IN
       (
              select
                     SQL_ID
              from
                     (
                            select
                                   SQL_ID
                            from
                                   gv$session
                            where
                                   BLOCKING_SESSION >0
                     )
              union
              select
                     B.SQL_ID --Blocker Current SQL
              from
                     (
                            select
                                   INST_ID
                                 , SID
                                 , BLOCKING_INSTANCE
                                 , BLOCKING_SESSION
                            from
                                   gv$session
                            where
                                   BLOCKING_SESSION >0
                     )
                     W
                   , (
                            select
                                   INST_ID
                                 , SID
                                 , SERIAL#
                                 , SQL_ID
                            from
                                   gv$session
                     )
                     B
              where
                     W.BLOCKING_INSTANCE   =B.INST_ID
                     and W.BLOCKING_SESSION=B.SID
              union
              select
                     B.PREV_SQL_ID --Blocker PRIV SQL
              from
                     (
                            select
                                   INST_ID
                                 , SID
                                 , BLOCKING_INSTANCE
                                 , BLOCKING_SESSION
                            from
                                   gv$session
                            where
                                   BLOCKING_SESSION >0
                     )
                     W
                   , (
                            select
                                   INST_ID
                                 , SID
                                 , SERIAL#
                                 , PREV_SQL_ID
                            from
                                   gv$session
                     )
                     B
              where
                     W.BLOCKING_INSTANCE   =B.INST_ID
                     and W.BLOCKING_SESSION=B.SID
       )
ORDER BY
       sql_id
;

================================================================= 
*************** ++ Objects involved in Blocking Lock ++ ***************
================================================================== 
col ltype for a30 
col holder for a25 
col waiter for a25
set linesize 300 
col object_name for a30
SELECT
       /*+ RULE */
       DISTINCT o.object_name
     , sh.username
              || '('
              || sh.sid
              || ')' Holder
     , sw.username
              || '('
              || sw.sid
              || ')'                                                                                                                  Waiter
     , DECODE ( lh.lmode , 1, 'NULL' , 2, 'row share' , 3, 'row exclusive' , 4, 'share' , 5, 'share row exclusive' , 6, 'exclusive' ) ltype
FROM
       all_objects o
     , gv$session  sw
     , gv$lock     lw
     , gv$session  sh
     , gv$lock     lh
WHERE
       lh.id1                    = o.object_id
       AND lh.id1                = lw.id1
       AND sh.sid                = lh.sid
       AND sw.sid                = lw.sid
       AND sh.lockwait     IS NULL
       AND sw.lockwait IS NOT NULL
       AND lh.TYPE               = 'TM'
       AND lw.TYPE               = 'TM'
;

---------------------------------------------------------------------
GET SQLID
-------------------------------------------------------------------
SELECT
       /*+ RULE */
       s.sid
     , s.serial#
     , p.spid "OS SID"
     , s.sql_hash_value "HASH VALUE"
     , s.username "ORA USER"
     , s.status
     , s.osuser "OS USER"
     , s.machine
     , s.terminal
     , s.type
     , s.program
     , s.logon_time
     , s.last_call_et
     , s.sql_id
     , l.id1
     , l.id2
     , decode(l.block, 0,'WAITING', 1,'BLOCKING')                                                                                       block
     , decode( l.LMODE, 1,'No Lock' , 2,'Row Share' , 3,'Row Exclusive' , 4,'Share' , 5,'Share Row Exclusive' , 6,'Exclusive' , null)   lmode
     , decode( l.REQUEST, 1,'No Lock' , 2,'Row Share' , 3,'Row Exclusive' , 4,'Share' , 5,'Share Row Exclusive' , 6,'Exclusive' , null) request
     , round(l.ctime/60,2) "MIN WAITING"
     , l.type
FROM
       v$process p
     , v$session s
     , v$Lock    l
where
       p.addr   = s.paddr
       and s.sid=l.sid
       and
       (
              l.id1,l.id2,l.type
       )
       in
       (
              SELECT
                     l2.id1
                   , l2.id2
                   , l2.type
              FROM
                     V$LOCK l2
              WHERE
                     l2.request<>0
       )
order by
       l.id1
     , l.id2
     , l.block desc
;

##-----get what its doing-----##
col sql_id format full
select
       sql_text
from
       v$sqltext
where
       sql_id='f9pb2557khxdk'
;

==========================================================================
 *************** Who is blocking who, with some decoding *************** 
===========================================================================
 select
        sn.USERNAME
      , m.SID
      , sn.SERIAL#
      , m.TYPE
      , decode(LMODE , 0, 'None' , 1, 'Null' , 2, 'Row-S (SS)' , 3, 'Row-X (SX)' , 4, 'Share' , 5, 'S/Row-X (SSX)' , 6, 'Exclusive')   lock_type
      , decode(REQUEST , 0, 'None' , 1, 'Null' , 2, 'Row-S (SS)' , 3, 'Row-X (SX)' , 4, 'Share' , 5, 'S/Row-X (SSX)' , 6, 'Exclusive') lock_requested
      , m.ID1
      , m.ID2
      , t.SQL_TEXT
 from
        v$session sn
      , v$lock    m
      , v$sqltext t
 where
        t.ADDRESS        = sn.SQL_ADDRESS
        and t.HASH_VALUE = sn.SQL_HASH_VALUE
        and
        (
               (
                      sn.SID         = m.SID
                      and m.REQUEST != 0
               )
               or
               (
                      sn.SID        = m.SID
                      and m.REQUEST = 0
                      and LMODE    != 4
                      and
                      (
                             ID1, ID2
                      )
                      in
                      (
                             select
                                    s.ID1
                                  , s.ID2
                             from
                                    v$lock S
                             where
                                    REQUEST  != 0
                                    and s.ID1 = m.ID1
                                    and s.ID2 = m.ID2
                      )
               )
        )
 order by
        sn.USERNAME
      , sn.SID
      , t.PIECE
 ;
 
 ============================================================================ 
 *************** Who is blocking whom and what are they doing ***************
 ============================================================================ 
 col blocked_session for a30 col event for a25 col time_in_wait for a25
 set linesize 300 col username for a30
 WITH blockers_and_blockees AS
      (
             SELECT
                    ROWNUM rn
                  , a.*
             FROM
                    gv$session a
             WHERE
                    blocking_session_status = 'VALID'
                    OR
                    (
                           inst_id, sid
                    )
                    IN
                    (
                           SELECT
                                  blocking_instance
                                , blocking_session
                           FROM
                                  gv$session
                           WHERE
                                  blocking_session_status = 'VALID'
                    )
      )
 SELECT
        LPAD(' ', 3 * (LEVEL - 1))
               || sid
               || DECODE(LEVEL , 1, ' root blocker') blocked_session
      , inst_id
      , event
      , TO_CHAR(FLOOR(seconds_in_wait / 3600), 'fm9900')
               || ':'
               || TO_CHAR(FLOOR(MOD(seconds_in_wait, 3600) / 60), 'fm00')
               || ':'
               || TO_CHAR(MOD(seconds_in_wait, 60), 'fm00') time_in_wait
      , username
      , osuser
      , machine
      , (
               SELECT
                      owner
                             || '.'
                             || object_name
               FROM
                      dba_objects
               WHERE
                      object_id = b.row_wait_obj#
        )
        waiting_on_object
      , CASE
               WHEN row_wait_obj# > 0
                      THEN DBMS_ROWID.rowid_create(1, row_wait_obj#, row_wait_file#, row_wait_block#, row_wait_row#)
        END waiting_on_rowid
      , (
               SELECT
                      sql_text
               FROM
                      gv$sql s
               WHERE
                      s.sql_id           = b.sql_id
                      AND s.inst_id      = b.inst_id
                      AND s.child_number = b.sql_child_number
        )
        current_sql
      , status
      , serial#
      , (
               SELECT
                      spid
               FROM
                      gv$process p
               WHERE
                      p.addr        = b.paddr
                      AND p.inst_id = b.inst_id
        )
        os_process_id
 FROM
        blockers_and_blockees b CONNECT BY PRIOR sid = blocking_session
        AND PRIOR inst_id                            = blocking_instance START WITH blocking_session IS NULL
 ;
 
 =========================================================
 ************ Oracle Database Startup History ************ 
 =========================================================
 set lines 200 col instance_name for a50
 select *
 from
        (
               select
                      STARTUP_TIME
               FROM
                      dba_hist_database_instance
               ORDER BY
                      startup_time DESC
        )
 WHERE
        rownum < 10
 ;
 
============================================================================= 
************ When My Oracle Database Instance was Last Restarted ************ 
=============================================================================
 select
        instance_name
      , to_char(startup_time,'mm/dd/yyyy hh24:mi:ss') as startup_time
 from
        v$instance
 ;
 
 =============================================================================
 ************ Oracle Database Uptime History ************ 
 =============================================================================
 set lines 200 col host_name for a20 col instance_name for a15
 SELECT
        host_name
      , instance_name
      , TO_CHAR(startup_time, 'DD-MM-YYYY HH24:MI:SS') startup_time
      , FLOOR(sysdate-startup_time)                    days
 FROM
        sys.v_$instance
 ;
 
 
 =============================================================================
 ************ Add redo log group with 2 members ************ 
 =============================================================================
 
 alter database add logfile group 15 ('/u02/oradata/PSPCA502/redo0015a.log','/u02/oradata/PSPCA502/redo0015b.log') size 500m;
 
 
 
 

 
 =============================================================================
 ************ SQL Monitoring ************ 
 ============================================================================= 
 
column rows_prsd_per_exec format 999,999,999,999 heading "ROWS|PRSC PER EXEC"
column cpu_time_per_exec_secs format 999,999,999.99 heading "CPU TIME|PER EXEC SECS"
column elap_time_per_exec_secs format 999,999,999.99 heading "ELAP TIME|PER EXEC SECS"
column lio_per_exec formt 999,999,999,999
column phyio_per_exec format 999,999,999,999
column plan_hash_value format a25
column sql_profile format a30
set pagesize 100 linesize 200 timing on
with q as ( -----------FETCHING RESOURCE INTENSIVE SQL QUERIES
select sql_id from(
select q.sql_id,sum(disk_reads),sum(buffer_gets),sum(cpu_time),sum(elapsed_time)
 from v$sqlarea q, v$session s
 where s.sql_hash_value = q.hash_value
 and s.sql_address = q.address
 and s.username is not null 
 group by q.sql_id
order by 5 desc,4 desc,2 desc,3 desc)
where rownum<21),
t as (
select snap_id,instance_number inst_id,sql_id,plan_hash_value,sql_profile,sum(executions_delta) sum_executions,
round(sum(rows_processed_delta)/(sum(executions_delta) + .0001),2) avg_rows_prsd_per_exec,
round(sum(disk_reads_delta)/(sum(executions_delta) + .0001),2) avg_phyio_per_exec,
round(sum(buffer_gets_delta)/(sum(executions_delta) + .0001),2) avg_lio_per_exec,
round(sum(cpu_time_delta)/1000000/(case when sum(executions_delta) =0 then 1 else sum(executions_delta) end),2) avg_cpu_time_per_exec_secs,
round(sum(elapsed_time_delta)/1000000/(case when sum(executions_delta) =0 then 1 else sum(executions_delta) end),2) avg_elap_time_per_exec_secs
 from dba_hist_sqlstat
 where sql_id in (
 select sql_id from q
 )
 group by snap_id,instance_number,sql_id,plan_hash_value, sql_profile
 order by snap_id)
select sql_id,lpad(plan_hash_value,15)||' MIN ' plan_hash_value, min(sum_executions) executions,round(min(avg_rows_prsd_per_exec),2)
    rows_prsd_per_exec,
round(min(avg_phyio_per_exec),2) phyio_per_exec,
round(min(avg_lio_per_exec),2) lio_per_exec,
round(min(avg_cpu_time_per_exec_secs),2) cpu_time_per_exec_secs,
round(min(avg_elap_time_per_exec_secs),2) elap_time_per_exec_secs,sql_profile
from t group by sql_id,plan_hash_value,sql_profile
union all
select sql_id,lpad(plan_hash_value,15)||' MAX ' plan_hash_value,max(sum_executions) executions,round(max(avg_rows_prsd_per_exec),2)
    rows_prsd_per_exec,
round(max(avg_phyio_per_exec),2) phyio_per_exec,
round(max(avg_lio_per_exec),2) lio_per_exec,
round(max(avg_cpu_time_per_exec_secs),2) cpu_time_per_exec_secs,
round(max(avg_elap_time_per_exec_secs),2) elap_time_per_exec_secs,sql_profile
from t group by sql_id,plan_hash_value,sql_profile
union all
SELECT sql_id,lpad(plan_hash_value,15)||'-CURRENT' plan_hash_value,sum(executions) executions,
round(sum(rows_processed)/(sum(executions) + .0001),2) rows_prsd_per_exec,
round(sum(disk_reads)/(sum(executions) + .0001),2) phyio_per_exec,
round(sum(buffer_gets)/(sum(executions) + .0001),2) lio_per_exec,
round(sum(cpu_time)/1000000/(case when sum(executions) =0 then 1 else sum(executions) end),2) cpu_time_per_exec_secs,
round(SUM(elapsed_time)/1000000/(case when sum(executions) =0 then 1 else sum(executions) end),2) elap_time_per_exec_secs,sql_profile
FROM gv$sql where sql_id in ( 
select sql_id from q
)
group by sql_id,plan_hash_value,sql_profile
order by 1,2;

  
PROMPT ================================
PROMPT SQL_MONITOR REPORT
PROMPT ================================  

set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000
select
DBMS_SQLTUNE.REPORT_SQL_MONITOR(
   sql_id=>'&sql_id',
   report_level=>'ALL',
   type=>'TEXT')
from dual;

PROMPT =========================
PROMPT Sql Monitor - REPORT
PROMPT =========================

column text_line format a1000
set lines 750 pages 9999
set long 20000 longchunksize 20000
select  dbms_sqltune.report_sql_monitor_list() text_line from dual;

 =============================================================================
 ************ Worst and best PLAN_HASH_VALUE calulator for a sql_id ************ 
 ============================================================================= 
 WITH snaps
     AS (SELECT /*+  materialize */
               dbid, SNAP_ID
           FROM dba_hist_snapshot s
          WHERE (begin_interval_time BETWEEN sysdate-&1 AND sysdate))
select * from (
SELECT t.*, row_number () over (order by impact_secs desc ) seq#
FROM (
  SELECT DISTINCT  sql_id
                  , execs executions
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg DESC) worst_plan
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id), 2) worst_plan_et_secs
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg ASC) best_plan
                  , ROUND (MIN (pln_avg) OVER (PARTITION BY sql_id), 2) best_plan_et_secs
                  , ROUND ( (MAX (pln_avg) OVER (PARTITION BY sql_id) - MIN (pln_avg) OVER (PARTITION BY sql_id)) * execs) impact_secs
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id) / MIN (pln_avg) OVER (PARTITION BY sql_id), 2) times_faster
    FROM (SELECT PARSING_SCHEMA_NAME
                 , sql_id
                 , plan_hash_value
                 , AVG (elapsed_time_delta / 1000000 / executions_delta) OVER (PARTITION BY sql_id, plan_hash_value) pln_avg
                 , SUM (executions_delta) OVER (PARTITION BY sql_id) execs
            FROM DBA_HIST_SQLSTAT h
           WHERE  sql_id='0dghnwz6zbud0'  and  (dbid, SNAP_ID) IN (SELECT dbid, SNAP_ID FROM snaps) 
                 AND NVL (h.executions_delta, 0) > 0)
) t
)
where seq# < 11
ORDER BY seq#;

=============================================================================
*********** Flush Bad SQL Plan from Shared Pool ************ 
=============================================================================

https://expertoracle.com/2015/07/08/flush-bad-sql-plan-from-shared-pool/

=============================================================================
*********** To get the all schemas size from the oracle database ************ 
=============================================================================
 set linesize 150
 set pagesize 5000 col owner for a15 col segment_name for a30 col segment_type for a20 col TABLESPACE_NAME for a30
 clear breaks
 clear computes
 compute sum of SIZE_IN_GB on report
 break on report
 select
        OWNER
      , sum(bytes)/1024/1024/1000 "SIZE_IN_GB"
 from
        dba_segments
 group by
        owner
 order by
        owner
 ;
 
 -----for single schema name
 set linesize 150
 set pagesize 5000 col owner for a15 col segment_name for a30 col segment_type for a20 col TABLESPACE_NAME for a30
 clear breaks
 clear computes
 compute sum of SIZE_IN_GB on report
 break on report
 select
        OWNER
      , sum(bytes)/1024/1024/1000 "SIZE_IN_GB"
 from
        dba_segments
 where
        owner = 'NA7P1PRD031'
 group by
        owner
 order by
        owner
 ;
 
 ===============================================================================================
 SQL Query to Find Out Oracle Session Details for a Past Time Period from the History tables 
 =============================================================================================== 
 col program for a35 
 col module for a40 
 col event for a30
 set pages 300 lines 220
 SELECT
        SESSION_ID
      , program
      , module
      , event
      , sql_id
      , TIME_WAITED
      , SESSION_STATE
 FROM
        v$active_session_history
 where
        session_id  =6789
        and program ='eu2-p1-prjet-n02-SC_JET'
 ;
 
 WHERE sample_time between to_date('12-11-21 08:00:10','dd-mm-yyyy hh24:mi:ss')
 and
 to_date('12-11-21 09:00:33','dd-mm-yyyy hh24:mi:ss');
 
 ======================================================= 
 Monitoring Data pump Jobs 
 ======================================================= 
 —-- View the JOB_NAME using dba_datapump_jobs using below sql
 SET lines 1000 COL owner_name FORMAT a10;
 COL job_name FORMAT a20 COL state FORMAT a11 COL operation LIKE state COL job_mode LIKE state
 select *
 from
        dba_datapump_jobs
 where
        state='EXECUTING'
 ;
 
 -----–Run the following query to monitor the progress by running the following SQLs.
 SET lines 1000
 COL sid FORMAT a20
  COL sid serial# 9999
 select
        sid
      , serial#
      , sofar
      , totalwork
      , dp.owner_name
      , dp.state
      , dp.job_mode
 from
        gv$session_longops sl
      , gv$datapump_job    dp
 where
        sl.opname  = dp.job_name
        and sofar != totalwork
 ;
 
 SELECT
        SID
      , SERIAL#
      , opname
      , SOFAR
      , TOTALWORK
      , ROUND(SOFAR/TOTALWORK*100,2) COMPLETE
 FROM
        V$SESSION_LONGOPS
 WHERE
        TOTALWORK != 0
        AND SOFAR != TOTALWORK
 order by
        1
 ;
 
 SELECT
        sl.sid
      , sl.serial#
      , sl.sofar
      , sl.totalwork
      , dp.owner_name
      , dp.state
      , dp.job_mode
 FROM
        v$session_longops sl
      , v$datapump_job    dp
 WHERE
        sl.opname     = dp.job_name
        AND sl.sofar != sl.totalwork
 ;
 
 —--- Check current Datapump job details
 select
        x.job_name
      , b.state
      , b.job_mode
      , b.degree
      , x.owner_name
      , z.sql_text
      , p.message
      , p.totalwork
      , p.sofar
      , round((p.sofar/p.totalwork)*100,2) done
      , p.time_remaining
 from
        dba_datapump_jobs b
        left join
               dba_datapump_sessions x
               on
                      (
                             x.job_name = b.job_name
                      )
        left join
               v$session y
               on
                      (
                             y.saddr = x.saddr
                      )
        left join
               v$sql z
               on
                      (
                             y.sql_id = z.sql_id
                      )
        left join
               v$session_longops p
               ON
                      (
                             p.sql_id = y.sql_id
                      )
 WHERE
        y.module             ='Data Pump Worker'
        AND p.time_remaining > 0
 ;
 
 =====================================================
 ******* Number of Customers for database ********** 
 =====================================================
 select
        a.SCHEMA_NAME
      , a.MONGODB_NAME
      , c.customer_name
      , b.CONN_STR
 from
        MDT_SITE_DB_MAPPING a
      , MDT_DB_DETAILS      b
      , tenantmaster        c
 where
        a.DB_NAME      = b.DB_NAME
        and c.name     =a.site_name
        and a.IS_ACTIVE='1'
 order by
        a.schema_name
        and b.CONN_STR like '%&DBNAME%'
 ;
 
 ========================================================
 ******* CSOD Mandatory DB Parameters Settings **********
 ========================================================
 -----------
 set lines 200 pages 1200 col name for a40 col value for a30
 select
        name
      , value
 from
        v$parameter
 where
        name in('compatible'
              ,'_log_segment_dump_parameter'
              ,'_log_segment_dump_patch'
              ,'_fix_control'
              ,'sga_max_size'
              ,'pga_aggregate_target'
              ,'use_large_pages'
              ,'sga_target'
              ,'pga_aggregate_limit')
 ;
 
 col SQL_FEATURE for a30
 set lines 190
 SELECT *
 FROM
        v$system_fix_control
 WHERE
        BUGNO in(23473108)
 ;
 
 SELECT
        NAME
      , DB_UNIQUE_NAME
      , OPEN_MODE
      , DATABASE_ROLE
 FROM
        V$DATABASE
 ;
 
 ========================================================
 ******* CSOD For encryption ********** 
 ========================================================
 SET LINES 200 PAGES 5000;
 COL WALLET_LOCATION FOR A50;
 select
        wrl_type wallet
      , status
      , wrl_parameter wallet_location
 from
        v$encryption_wallet
 ;
 
 ======================================================== 
 ******* CSOD Find encrypted Tenant and validate ********** 
 ========================================================
 select distinct
        owner
 from
        dba_encrypted_columns
 ;
 
 select *
 from
        EU2PRD0112.CMT_PERSON
 where
        rownum < 5
 ;
 
 select *
 from
        NA9P1PRD002.CMT_PERSON
 where
        rownum < 5
 ;
 
 select *
 from
        NA9P1QAD001.CMT_PERSON
 where
        rownum < 5
 ;
 
 select *
 from
        NA9P1PRD001.CMT_PERSON
 where
        rownum < 5
 ;
 
 ======================================================== 
 ******* Query to check RMAN backup status ********** 
 ======================================================== 
 col STATUS format a10 
 col hrs format 999.99
 select
        SESSION_KEY
      , INPUT_TYPE
      , STATUS
      , to_char(START_TIME,'mm/dd/yy hh24:mi') start_time
      , to_char(END_TIME,'mm/dd/yy hh24:mi')   end_time
      , elapsed_seconds/3600                   hrs
 from
        V$RMAN_BACKUP_JOB_DETAILS
 order by
        session_key
 ;
 
 
 set linesize 500
col BACKUP_SIZE for a20
SELECT
INPUT_TYPE "BACKUP_TYPE",
--NVL(INPUT_BYTES/(1024*1024),0)"INPUT_BYTES(MB)",
--NVL(OUTPUT_BYTES/(1024*1024),0) "OUTPUT_BYTES(MB)",
STATUS,
TO_CHAR(START_TIME,'MM/DD/YYYY:hh24:mi:ss') as START_TIME,
TO_CHAR(END_TIME,'MM/DD/YYYY:hh24:mi:ss') as END_TIME,
TRUNC((ELAPSED_SECONDS/60),2) "ELAPSED_TIME(Min)",
--ROUND(COMPRESSION_RATIO,3)"COMPRESSION_RATIO",
--ROUND(INPUT_BYTES_PER_SEC/(1024*1024),2) "INPUT_BYTES_PER_SEC(MB)",
--ROUND(OUTPUT_BYTES_PER_SEC/(1024*1024),2) "OUTPUT_BYTES_PER_SEC(MB)",
--INPUT_BYTES_DISPLAY "INPUT_BYTES_DISPLAY",
OUTPUT_BYTES_DISPLAY "BACKUP_SIZE",
OUTPUT_DEVICE_TYPE "OUTPUT_DEVICE"
--INPUT_BYTES_PER_SEC_DISPLAY "INPUT_BYTES_PER_SEC_DIS",
--OUTPUT_BYTES_PER_SEC_DISPLAY "OUTPUT_BYTES_PER_SEC_DIS"
FROM V$RMAN_BACKUP_JOB_DETAILS
where start_time > SYSDATE -10
and INPUT_TYPE != 'ARCHIVELOG'
ORDER BY END_TIME DESC
;

SET LINES 200 PAGES 5000; 
col OPNAME format a40
col Time_remaining format 999.99 
SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,opname ,
ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE", Time_remaining
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%'
AND OPNAME NOT LIKE '%aggregate%'
AND TOTALWORK != 0
AND SOFAR != TOTALWORK;

SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
ROUND (SOFAR/TOTALWORK*100, 2) "% COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%' AND OPNAME NOT LIKE '%aggregate%'
AND TOTALWORK! = 0 AND SOFAR <> TOTALWORK; 
 
col STATUS format a9
col hrs format 999.99
select SESSION_KEY, INPUT_TYPE, STATUS,
to_char(START_TIME,'mm/dd/yy hh24:mi') start_time,
to_char(END_TIME,'mm/dd/yy hh24:mi') end_time,
elapsed_seconds/3600 hrs from V$RMAN_BACKUP_JOB_DETAILS
order by session_key;

======================================================== 
 ******* Query to check RMAN backup Estimation ********** 
======================================================== 
SET LINES 200 PAGES 5000;
col dbsize_mbytes      for 99,999,990.00 justify right head ""DBSIZE_MB""
col input_mbytes       for 99,999,990.00 justify right head ""READ_MB""
col output_mbytes      for 99,999,990.00 justify right head ""WRITTEN_MB""
col output_device_type for a10           justify left head ""DEVICE""
col complete           for 990.00        justify right head ""COMPLETE %"" 
col compression        for 990.00        justify right head ""COMPRESS|% ORIG""
col est_complete       for a20           head ""ESTIMATED COMPLETION""
col recid              for 9999999       head ""ID""

select recid
     , output_device_type
     , dbsize_mbytes
     , input_bytes/1024/1024 input_mbytes
     , output_bytes/1024/1024 output_mbytes
     , (output_bytes/input_bytes*100) compression
     , (mbytes_processed/dbsize_mbytes*100) complete
     , to_char(start_time + (sysdate-start_time)/(mbytes_processed/dbsize_mbytes),'DD-MON-YYYY HH24:MI:SS') est_complete
  from v$rman_status rs
     , (select sum(bytes)/1024/1024 dbsize_mbytes from v$datafile) 
 where status='RUNNING'
   and output_device_type is not null;

col pct_done format 999
col done_by 999.99
select sl.sid, sl.opname,
       to_char(100*(sofar/totalwork), '990.9')||'%' pct_done,
       sysdate+(TIME_REMAINING/60/60/24) done_by
  from v$session_longops sl, v$session s
 where sl.sid = s.sid
   and sl.serial# = s.serial#
   and sl.sid in (select sid from v$session where module like 'backup%' or module like 'restore%' or module like 'rman%')
   and sofar != totalwork
        and totalwork > 0;
 
 
======================================================== 
 ******* Check RMAN  backup speed history ********** 
======================================================== 
 select to_char(START_TIME,'DD-MM-YYYY HH24:MI:SS') as START_TIME,to_char(END_TIME,'DD-MM-YYYY HH24:MI:SS') as END_TIME,ELAPSED_SECONDS/60/60,INPUT_BYTES/1024/1024/1024/1024 as INPUT_TB,OUTPUT_BYTES/1024/1024/1024/1024 as OUTPUT_TB,INPUT_BYTES_PER_SEC/1024/1024 as INPUT_SEC_MB,OUTPUT_BYTES_PER_SEC/1024/1024 as OUTPUT_SEC_MB,status from 
V$RMAN_BACKUP_job_details where INPUT_TYPE like 'DB%INCR%';

 ======================================================== 
 ******* Check RMAN historical backup details ********** 
 ========================================================
 set linesize 500 pagesize 2000 col Hours format 9999.99 col STATUS format a10
 select
        SESSION_KEY
      , INPUT_TYPE
      , STATUS
      , to_char(START_TIME,'mm-dd-yyyy hh24:mi:ss') as RMAN_Bkup_start_time
      , to_char(END_TIME,'mm-dd-yyyy hh24:mi:ss')   as RMAN_Bkup_end_time
      , elapsed_seconds/3600                           Hours
 from
        V$RMAN_BACKUP_JOB_DETAILS
 order by
        session_key
 ;
 
 ======================================================== 
 ******* How To Determine RMAN Backup Size ********** 
 ========================================================
 set linesize 500 pagesize 2000 col completion_time format 9999.99 col type format a10
SELECT
       TO_CHAR(completion_time, 'YYYY-MON-DD') completion_time
     , type
     , round(sum(bytes)          /1048576) MB
     , round(sum(elapsed_seconds)/60)      min
FROM
       (
              SELECT
                     CASE
                            WHEN s.backup_type='L'
                                   THEN 'ARCHIVELOG'
                            WHEN s.controlfile_included='YES'
                                   THEN 'CONTROLFILE'
                            WHEN s.backup_type            ='D'
                                   AND s.incremental_level=0
                                   THEN 'LEVEL0'
                            WHEN s.backup_type            ='I'
                                   AND s.incremental_level=1
                                   THEN 'LEVEL1'
                     END                      type
                   , TRUNC(s.completion_time) completion_time
                   , p.bytes
                   , s.elapsed_seconds
              FROM
                     v$backup_piece p
                   , v$backup_set   s
              WHERE
                     p.status   ='A'
                     AND p.recid=s.recid
              UNION ALL
              SELECT
                     'DATAFILECOPY' type
                   , TRUNC(completion_time)
                   , output_bytes
                   , 0 elapsed_seconds
              FROM
                     v$backup_copy_details
       )
GROUP BY
       TO_CHAR(completion_time, 'YYYY-MON-DD')
     , type
ORDER BY
       1 ASC
     , 2
     , 3
;

SELECT p.SPID, s.sid, s.serial#, sw.EVENT, sw.SECONDS_IN_WAIT AS
SEC_WAIT, sw.STATE, CLIENT_INFO
FROM V$SESSION_WAIT sw, V$SESSION s, V$PROCESS p
WHERE s.client_info LIKE 'rman%'
AND s.SID=sw.SID
AND s.PADDR=p.ADDR;

======================================================== 
****** currently running rman backup status. ****** 
========================================================
set linesize 500 pagesize 2000 col SID format 9999.99 col CONTEXT format a10
SELECT
       SID
     , SERIAL#
     , CONTEXT
     , SOFAR
     , TOTALWORK
     , ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM
       V$SESSION_LONGOPS
WHERE
       OPNAME         LIKE 'RMAN%'
       AND OPNAME NOT LIKE '%aggregate%'
       AND TOTALWORK    != 0
       AND SOFAR        <> TOTALWORK
;

======================================================================= 
****** RMAN backup Status (Remaining TimePercentage) ****** 
=======================================================================. 
col dbsize_mbytes for 99,999,990.00 justify right head "DBSIZE_MB" col input_mbytes for 99,999,990.00 justify right head "READ_MB" col output_mbytes for 99,999,990.00 justify right head "WRITTEN_MB" col output_device_type for a10 justify left head "DEVICE" col complete for 990.00 justify right head "COMPLETE %" col compression for 990.00 justify right head "COMPRESS|% ORIG" col est_complete for a20 head "ESTIMATED COMPLETION" col recid for 9999999 head "ID"
select
       recid
     , output_device_type
     , dbsize_mbytes
     , input_bytes /1024/1024                                                                               input_mbytes
     , output_bytes/1024/1024                                                                               output_mbytes
     , (output_bytes      /input_bytes*100)                                                                 compression
     , (mbytes_processed  /dbsize_mbytes*100)                                                               complete
     , to_char(start_time + (sysdate-start_time)/(mbytes_processed/dbsize_mbytes),'DD-MON-YYYY HH24:MI:SS') est_complete
from
       v$rman_status rs
     , (
              select
                     sum(bytes)/1024/1024 dbsize_mbytes
              from
                     v$datafile
       )
where
       status                           ='RUNNING'
       and output_device_type is not null
;

======================================================================= 
****** Query of sync and async tables ****** 
The following query joins the v$backup_async_io and v$backup_sync_io and provides information that is may be helpful for performance debugging:
======================================================================= 



set linesize 999
set pagesize 999
set numwidth 14
set numformat 999G999G999G990
alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
column inst format a4
with subq as
(select 'ASYNC', to_char(inst_id) inst, substr(filename,1,60), open_time, close_time, elapsed_time/100, substr(device_type,1,10) devtype,
set_count, set_stamp, maxopenfiles agg, buffer_size, buffer_count, buffer_size*buffer_count buffer_mem, io_count, total_bytes, bytes,
decode(nvl(close_time,sysdate), open_time, null, io_count*buffer_size/((nvl(close_time,sysdate)-open_time)*86400))*1 rate,
effective_bytes_per_second eff
from gv$backup_async_io where type<>'AGGREGATE'
union all
select 'SYNC', to_char(inst_id), substr(filename,1,60), open_time, close_time, elapsed_time/100, substr(device_type,1,10) devtype, 
set_count, set_stamp, maxopenfiles agg, buffer_size, buffer_count, buffer_size*buffer_count buffer_mem, io_count, total_bytes,
bytes, decode(nvl(close_time,sysdate), open_time, null,io_count*buffer_size/((nvl(close_time,sysdate)-open_time)*86400))*1 rate,
effective_bytes_per_second eff
from gv$backup_sync_io where type<>'AGGREGATE')
select subq.*, io_count*buffer_size/((nvl(close_time,sysdate)-open_time)*86400+agg)*1 rate_with_create,
decode(buffer_mem,0,null,rate/buffer_mem)*1000 efficiency
from subq order by open_time;
========================================================
 ******* Find Primary Key of Table ********** 
========================================================
SELECT
       cols.table_name
     , cols.column_name
     , cols.position
     , cons.status
     , cons.owner
FROM
       all_constraints  cons
     , all_cons_columns cols
WHERE
       cols.table_name          = 'FGT_DOMAIN'
       AND cons.constraint_type = 'P'
       AND cons.constraint_name = cols.constraint_name
       AND cons.owner           = cols.owner
       AND cons.owner           = 'EU2TNB0185'
ORDER BY
       cols.table_name
     , cols.position
;

'

=======================================================================
******* users  **********
=======================================================================
 select distinct  username from dba_users where username not in
('SYS','SYSTEM','OUTLN','DIP','ORACLE_OCM','DBSNMP','APPQOSSYS','WMSYS','EXFSYS','CTXSYS','ANONYMOUS','XDB','XS$NULL','SI_INFORMTN_SCHEMA','MDSYS','ORDDATA','ORDPLUGINS','ORDSYS','OLAPSYS','MDDATA','SPATIAL_CSW_ADMIN_USR','FLOWS_FILES', 'APEX_030200','APEX_PUBLIC_USER','OWBSYS','OWBSYS_AUDIT','SYSDG','SYSBACKUP','SYSKM','GSMADMIN_INTERNAL','SYSRAC','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYS$UMF','GSMCATUSER','GGSYS','OJVMSYS','SABAEXPIMP','DVSYS' ,'AUDSYS');


=======================================================================
******* Check Last State Gahters infor for Tenant/last_analyzed **********
=======================================================================
set lines 200
set pagesize 150
col owner format a30
select owner ,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY HH24:MM:SS'), count(*) from dba_tables where owner = 'A501PRD0037' group by owner,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY HH24:MM:SS');

set lines 200
set pagesize 150
col owner format a30
select owner ,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY'), count(*) from dba_tables group by owner,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY');

exec dbms_utility.compile_schema('NA10P1PRD006');
exec DBMS_STATS.GATHER_SCHEMA_STATS(OWNNAME =>'NA10P1PRD006',DEGREE => 5,estimate_percent => 99, CASCADE => TRUE);

set lines 200
set pagesize 150
col owner format a30
col LAST_ANALYZED format a30
select distinct owner ,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY') LAST_ANALYZED, count(*) from dba_tables where owner not in
('OUTLN','DIP','ORACLE_OCM','DBSNMP','APPQOSSYS','WMSYS','EXFSYS','CTXSYS','ANONYMOUS','XDB','XS$NULL','SI_INFORMTN_SCHEMA','MDSYS','ORDDATA','ORDPLUGINS','ORDSYS','OLAPSYS','MDDATA','SPATIAL_CSW_ADMIN_USR','FLOWS_FILES', 'APEX_030200','APEX_PUBLIC_USER','OWBSYS','OWBSYS_AUDIT','SYSDG','SYSBACKUP','SYSKM','GSMADMIN_INTERNAL','SYSRAC','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYS$UMF','GSMCATUSER','GGSYS','OJVMSYS','SABAEXPIMP','DVSYS' ,'AUDSYS')
group by owner,to_char(trunc(LAST_ANALYZED),'DD-MM-YYYY');


----Displays Last Analyzed Details for a Given Schema
SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINESIZE 300
col owner format a30
col table_name format a30
col LAST_ANALYZED format a30
SELECT t.owner,
       t.table_name AS "Table Name", 
       t.num_rows AS "Rows", 
       t.avg_row_len AS "Avg Row Len", 
       Trunc((t.blocks * p.value)/1024) AS "Size KB", 
       to_char(t.last_analyzed,'DD/MM/YYYY HH24:MM:SS') AS "Last Analyzed"
FROM   dba_tables t,
       v$parameter p
WHERE t.owner = Decode(Upper('ALL'), 'ALL', t.owner, Upper('ALL'))
AND   p.name = 'db_block_size'
and t.owner not in('SRINITEST','DOC2SITE','TNT050','RASDB','BASE201SITE','SITE013','ATHENA2','SABA_DI','SMRAS1','TNT123','TNT104','TEST','DQTNT003','SPCDEMO','MOBILESITE','HPLEARN','TNT103','SABA','CUST01','A501DMO0001','SITE026','JD','LEAPPMDB','RAS','PMSITE','SPC_ERCO','SITE022','MD','SOCIALSITE','SEC71RC','ANT','CENTRARAS','SABA_REPORT','lvvwd_54sp2','TNT122','TNT124','XDB','WMSYS','WKSYS','WKPROXY','SYSTEM','SYSMAN','SYS','OUTLN','ORDSYS','ORDPLUGINS','ORACLE_OCM','DBSNMP','CTXSYS','ANONYMOUS','RAS3');
ORDER by t.owner,t.last_analyzed,t.table_name;



SET PAGESIZE 60
SET LINESIZE 300
col owner format a30
col LAST_ANALYZED format a30
SELECT t.owner,
       to_char(t.last_analyzed,'DD/MM/YYYY HH24:MM:SS') AS "Last Analyzed"
FROM   dba_tables t,
       v$parameter p
WHERE t.owner = Decode(Upper('ALL'), 'ALL', t.owner, Upper('ALL'))
AND   p.name = 'db_block_size'
and t.owner not in('SRINITEST','DOC2SITE','TNT050','RASDB','BASE201SITE','SITE013','ATHENA2','SABA_DI','SMRAS1','TNT123','TNT104','TEST','DQTNT003','SPCDEMO','MOBILESITE','HPLEARN','TNT103','SABA','CUST01','A501DMO0001','SITE026','JD','LEAPPMDB','RAS','PMSITE','SPC_ERCO','SITE022','MD','SOCIALSITE','SEC71RC','ANT','CENTRARAS','SABA_REPORT','lvvwd_54sp2','TNT122','TNT124','XDB','WMSYS','WKSYS','WKPROXY','SYSTEM','SYSMAN','SYS','OUTLN','ORDSYS','ORDPLUGINS','ORACLE_OCM','DBSNMP','CTXSYS','ANONYMOUS','RAS3');
ORDER by t.owner,t.last_analyzed;

SET PAGESIZE 60
SET LINESIZE 300
col owner format a30
col LAST_ANALYZED format a30
SELECT t.owner,
       to_char(t.last_analyzed,'DD/MM/YYYY HH24:MM:SS') AS "Last Analyzed"
FROM   dba_tables t,
       v$parameter p
WHERE t.owner = Decode(Upper('ALL'), 'ALL', t.owner, Upper('ALL'))
AND   p.name = 'db_block_size'
and t.owner  in('EU2PRD0033');
ORDER by t.owner,t.last_analyzed;

SET LINESIZE 450

COLUMN approximate_ndv_algorithm FORMAT A25
COLUMN auto_stat_extensions FORMAT A20
COLUMN auto_task_status FORMAT A16
COLUMN auto_task_max_run_time FORMAT A22
COLUMN auto_task_interval FORMAT A18
COLUMN cascade FORMAT A23
COLUMN concurrent FORMAT A10
COLUMN degree FORMAT A6
COLUMN estimate_percent FORMAT A27
COLUMN global_temp_table_stats FORMAT A23
COLUMN granularity FORMAT A11
COLUMN incremental FORMAT A11
COLUMN incremental_staleness FORMAT A21
COLUMN incremental_level FORMAT A17
COLUMN method_opt FORMAT A25
COLUMN no_invalidate FORMAT A26
COLUMN options FORMAT A7
COLUMN preference_overrides_parameter FORMAT A30
COLUMN publish FORMAT A7
COLUMN options FORMAT A7
COLUMN stale_percent FORMAT A13
COLUMN stat_category FORMAT A28
COLUMN table_cached_blocks FORMAT A19
COLUMN wait_time_to_update_stats FORMAT A19

SELECT DBMS_STATS.GET_PREFS('APPROXIMATE_NDV_ALGORITHM') AS approximate_ndv_algorithm,
       DBMS_STATS.GET_PREFS('AUTO_STAT_EXTENSIONS') AS auto_stat_extensions,
       DBMS_STATS.GET_PREFS('AUTO_TASK_STATUS') AS auto_task_status,
       DBMS_STATS.GET_PREFS('AUTO_TASK_MAX_RUN_TIME') AS auto_task_max_run_time,
       DBMS_STATS.GET_PREFS('AUTO_TASK_INTERVAL') AS auto_task_interval,
       DBMS_STATS.GET_PREFS('CASCADE') AS cascade,
       DBMS_STATS.GET_PREFS('CONCURRENT') AS concurrent,
       DBMS_STATS.GET_PREFS('DEGREE') AS degree,
       DBMS_STATS.GET_PREFS('ESTIMATE_PERCENT') AS estimate_percent,
       DBMS_STATS.GET_PREFS('GLOBAL_TEMP_TABLE_STATS') AS global_temp_table_stats,
       DBMS_STATS.GET_PREFS('GRANULARITY') AS granularity,
       DBMS_STATS.GET_PREFS('INCREMENTAL') AS incremental,
       DBMS_STATS.GET_PREFS('INCREMENTAL_STALENESS') AS incremental_staleness,
       DBMS_STATS.GET_PREFS('INCREMENTAL_LEVEL') AS incremental_level,
       DBMS_STATS.GET_PREFS('METHOD_OPT') AS method_opt,
       DBMS_STATS.GET_PREFS('NO_INVALIDATE') AS no_invalidate,
       DBMS_STATS.GET_PREFS('OPTIONS') AS options,
       DBMS_STATS.GET_PREFS('PREFERENCE_OVERRIDES_PARAMETER') AS preference_overrides_parameter,
       DBMS_STATS.GET_PREFS('PUBLISH') AS publish,
       DBMS_STATS.GET_PREFS('STALE_PERCENT') AS stale_percent,
       DBMS_STATS.GET_PREFS('STAT_CATEGORY') AS stat_category,
       DBMS_STATS.GET_PREFS('TABLE_CACHED_BLOCKS') AS table_cached_blocks,
       DBMS_STATS.GET_PREFS('WAIT_TIME_TO_UPDATE_STATS') AS wait_time_to_update_stats
FROM   dual;





https://smarttechways.com/2020/08/18/check-and-change-setting-of-gather-statistics-in-oracle/

****** COMMAND TO DELETE EXISTING DB USING DBCA
dbca -silent -deleteDatabase -sourceDB PRDQAN33 -sysDBAUserName sys -sysDBAPassword xxxxxx
EU2MONPDS2










=============================================================
 **********      find redo logfiles **********
=============================================================
SET PAGESIZE 60
SET LINESIZE 300
col group format a20
col name format a50
SELECT
   a.group#,
   substr(b.member,1,30) name,
   a.members,
   a.bytes,
   a.status
FROM
   v$log     a,
   v$logfile b
WHERE
   a.group# = b.group#
;

 
=============================================================
 **********      schema size  **********
=============================================================

SET PAGESIZE 60
SET LINESIZE 300
col owner format a20
select owner,sum(bytes/1024/1024/1024) ||'GB' from dba_segments group by owner order by sum(bytes/1024/1024/1024) desc; 

SELECT  owner,Sum(bytes)/1024/1024/1024 AS total_size_gb
FROM dba_segments
WHERE owner =upper('&1') group by  owner;
 
=============================================================
 **********      Exact database size  **********
=============================================================
select
"Reserved_Space(GB)", "Reserved_Space(GB)" - "Free_Space(GB)" "Used_Space(GB)",
"Free_Space(GB)"
from(
select
(select sum(bytes/(1014*1024*1024)) from dba_data_files) "Reserved_Space(GB)",
(select sum(bytes/(1024*1024*1024)) from dba_free_space) "Free_Space(GB)",
(select sum(bytes/(1024*1024*1024)) from v$logfile) "Free_Space(GB)"
from dual
);


col "Database Size" format a20
col "Free space" format a20
col "Used space" format a20
select round(sum(used.bytes) / 1024 / 1024 / 1024 ) || ' GB' "Database Size"
, round(sum(used.bytes) / 1024 / 1024 / 1024 ) -
round(free.p / 1024 / 1024 / 1024) || ' GB' "Used space"
, round(free.p / 1024 / 1024 / 1024) || ' GB' "Free space"
from (select bytes
from v$datafile
union all
select bytes
from v$tempfile
union all
select bytes
from v$log) used
, (select sum(bytes) as p
from dba_free_space) free
group by free.p;

select a.data_size+b.temp_size+c.redo_size+d.controlfile_size ""total_size in MB"" from ( select sum(bytes)/1024/1024 data_size
from dba_data_files) a,( select nvl(sum(bytes),0)/1024/1024 temp_size from dba_temp_files ) b,( select sum(bytes)/1024/1024 redo_size from sys.v_$log ) c,
( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024 controlfile_size from v$controlfile) d;



=============================================================
******* table size **********
=============================================================
select   segment_name,sum(bytes/1024/1024/1024) "TABLE_SIZE(GB)" from dba_extents where  segment_type='TABLE' and owner=upper('&OWNER') and segment_name =upper( '&SEGMENT_NAME') group by segment_name;

=============================================================
******* Top 10 large tables  **********
=============================================================
SET PAGESIZE 60
SET LINESIZE 300
col owner format a20
select   * from (select  owner,segment_name, bytes/1024/1024/1024 meg from  dba_segments 
   where segment_type = 'TABLE' and owner not in ('SYS','SYSTEM','DBSNMP','APEX_040200','MDSYS')
   order by   bytes/1024/1024 desc) where  rownum <= 10;

=============================================================
******* Database Growth  **********
=============================================================

select to_char(creation_time, 'DD/MM/YYYY HH24:MM:SS') "Day",
   sum(bytes)/1024/1024/1024 "Growth in GBs"
   from sys.v_$datafile
   where creation_time > SYSDATE-30
   group by to_char(creation_time, 'DD/MM/YYYY HH24:MM:SS');
=============================================================
******* Check for Password Version  **********
=============================================================
SET LINESIZE 160 PAGESIZE 200
COL username FOR a10
COL password_versions FOR a20
SELECT username, password_versions
FROM dba_users WHERE username LIKE 'TEST_%';


=============================================================
******* find the corresponding hashes Password **********
=============================================================
SET LINESIZE 160 PAGESIZE 200
COL name FOR a10
COL password FOR a16
COL spare4 FOR a64
SELECT name,password,spare4
FROM user$ WHERE name LIKE 'TEST_%' ORDER BY 1;


=============================================================
******* INFDB/infdb **********
=============================================================

SET LINESIZE 160 PAGESIZE 200
COL object_name FOR a16
COL object_type FOR a16
select object_name,object_type  from dba_objects where owner = 'INFDB' and object_type = 'TABLE';


SET LINES 200 PAGES 1200;
COL LOCATION FOR a20;
COL HOST_NAME FOR a30;
COL ORACLE_VERSION FOR a15;
COL DB_IP FOR a15;
COL MGM_IP FOR a15;
SELECT * FROM INFDB.DB_MACHINES WHERE HOST_NAME in ('a5pab01spcora03');


SET LINESIZE 160 PAGESIZE 200
COL SID FOR a16
COL HOST_NAME FOR a16
COL ENVIRONMENT FOR a10
COL ORACLE_VERSION FOR a16
select SID,HOST_NAME,ENVIRONMENT,ORACLE_VERSION,CREATED_DATE,STATUS from INFDB.DATABASES;


SET LINESIZE 160 PAGESIZE 200
COL SID FOR a16
COL HOST_NAME FOR a16
COL ENVIRONMENT FOR a10
COL ORACLE_VERSION FOR a16
select SID,HOST_NAME,ENVIRONMENT,ORACLE_VERSION,CREATED_DATE,STATUS from INFDB.DATABASES where HOST_NAME = 'a5pab01spcora04';


SET LINESIZE 160 PAGESIZE 200
COL SID FOR a16
COL HOST_NAME FOR a16
COL ENVIRONMENT FOR a10
COL ORACLE_VERSION FOR a16
select SID,HOST_NAME,ENVIRONMENT,ORACLE_VERSION,CREATED_DATE,STATUS from INFDB.DATABASES where SID = 'DSECQA01';


insert into INFDB.DATABASES (SID,HOST_NAME,ENVIRONMENT,ORACLE_VERSION,CREATED_DATE,STATUS) values ('PRDQASEC','n3np01secora01','PRODQA SEC','19.8.0.0.0','14-APR-20','open')

INSERT INTO DB_MACHINES VALUES('ATT WT','n1np06spcora02','10.22.48.149','10.22.180.20','19.8.0.0.0','prod','48','251');
COMMIT;

SID              HOST_NAME        ENVIRONMEN ORACLE_VERSION   CREATED_DATE       STATUS
---------------- ---------------- ---------- ---------------- ------------------ --------------------
dsm1d301         n3np01secora05   devqa      19.8.0.0.0       29-JUL-15          open

=============================================================
**************** CHECK SEQUENCE ARCHIVED OR NOT *************
=============================================================
SELECT SEQUENCE#,ARCHIVAL_THREAD#,ARCHIVED,STATUS FROM V$ARCHIVED_LOG WHERE SEQUENCE#=31154;



=============================================================
 Oracle RPM package verify
=============================================================
rpm -qa|grep kmod-20-25.el7.x86_64
rpm -qa|grep kmod-libs-20-25.el7.x86_64
rpm -qa|grep compat-libstdc++-33-3.2.3-72.el7.x86_64
rpm -qa|grep libxcb-1.13-1.el7.x86_64
rpm -qa|grep libX11-1.6.7-2.el7.x86_64
rpm -qa|grep libXi-1.7.9-1.el7.x86_64
rpm -qa|grep libXtst-1.2.2*

rpm -qa|grep libxcb-1.13-1.el7.x86_64
rpm -qa|grep libXinerama-1.1.3-2.1.el7.x86_64
rpm -qa|grep libXi-1.7.9-1.el7.x86_64
rpm -qa|grep compat-libstdc++-33-3.2.3-72.el7.x86_64
rpm -qa|grep libX11-common-1.6.7-4.el7_9.noarch
rpm -qa|grep libX11-1.6.7-4.el7_9.x86_64
rpm -qa|grep kmod-20-28.el7.x86_64
rpm -qa|grep kmod-libs-20-28.el7.x86_64
rpm -qa|grep libXtst-1.2.3-1.el7.x86_64
rpm -qa|grep smartmontools-7.0-2.el7.x86_64

=============================================================
 check /tmp noexec permission
=============================================================
cat /proc/mounts | grep /tmp          --> to check the applied one
cat /etc/fstab        --> This will be set after next server restart

=============================================================
OS limits for Oracle
=============================================================
[oracle@n3pp07spcora02 ~]$ cat /etc/sysctl.conf
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
vm.min_free_kbytes=3145728
#----Oracle Parameters-----
kernel.pid_max=65536
kernel.shmmax=4398046511104
kernel.shmall=4294967296
kernel.shmmni=4096
kernel.sem=250        32000   100     128
#DBA--vm.nr_hugepages = 39448
vm.nr_hugepages = 41472
fs.file-max=26289098
fs.aio-max-nr=3145728
net.core.wmem_max=1048576
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.rmem_default=262144
net.ipv4.ip_local_port_range=9000     65500
net.ipv4.tcp_wmem=4096        16384   4194304
net.ipv4.tcp_rmem=4096        87380   4194304
vm.max_map_count=200000

#----CIS Baseline Parameters-----
kernel.randomize_va_space=2
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
#END----CIS Baseline Parameters-----
net.ipv4.route.flush=1

-----/etc/security/limits.conf
#----Oracle Cluster OS limits----
oracle   soft   nofile    131072
oracle   hard   nofile    524288

oracle   soft   nproc    131072
oracle   hard   nproc    524288

oracle   soft   core    unlimited
oracle   hard   core    unlimited

oracle   soft   stack   unlimited
oracle   soft   data   unlimited

oracle   hard   data   unlimited
oracle   hard   stack   unlimited

oracle   soft   memlock    64424509440
oracle   hard   memlock    64424509440


[oracle@e1np02spcora01 ~]$ ipcs -ls

------ Semaphore Limits --------
max number of arrays = 200
max semaphores per array = 270
max semaphores system wide = 32000
max ops per semop call = 100
semaphore max value = 32767

[oracle@e1np02spcora01 ~]$


=============================================================
Get DDL of Tablespace
=============================================================

set heading off;
set echo off;
set pages 2000
set long 99999
spool tablespace_temp.sql
select dbms_metadata.get_ddl('TABLESPACE', 'TEMP') from dba_temp_files;

=============================================================

### TO add new tempfile
=============================================================

ALTER TABLESPACE TEMP ADD TEMPFILE '/u03/oradata/PNA3N105/temp08.dbf' size 100m autoextend on next 100m maxsize 20g;

=============================================================
steps to upload backup to sftp
=============================================================

DB User: shire
SFTP User: shire_pharma
SFTP Hostname: sacsftp.sabahosted.com
SFTP_Password :tC6M6LTe

Within datacenter connect to 		
WT - m1sftp002.ops.saba		
sftp -oport=22222 shire_pharma@sacsftp.sabahosted.com		
Username: shire_pharma		
Password: tC6M6LTe		

sftp -oport=22222 shire_pharma@sacsftp.sabahosted.com

mkdir shire_bkp_SEC_94461
sftp> put test.txt

=============================================================
**** How to download updated DB inventory:
=============================================================
1) Open WinSCP connection to below sftp server.
m1sftp002.ops.saba
Port: 22222
username: dbateam
password: s9ahu6Eq4R
2) Once sftp connection established then go to /dbateam/Inventory/ location.
3) Here you can see latest updated Db invetory with below metioned name.
Saba Database Servers Inventory.xlsx
4) Download and save this file in your system.
5) While opening donloaded file you have to submit below passwords.
To open the file:  dba4you
To open the file in read-write mode: sabadba4you




SET lines 1000
COL owner_name FORMAT a10;
COL job_name FORMAT a20
COL state FORMAT a11
COL operation LIKE state
COL job_mode LIKE state
select * from dba_datapump_jobs where state='EXECUTING';
12:21
impdp "'sys/sys as sysdba'" attach="SYS_IMPORT_FULL_01"
expdp "'sys/sys as sysdba'" attach=SYS_EXPORT_SCHEMA_01



=============================================================
---> how long expdp / impdp will take
=============================================================
set lines 750 pages 9999
  col  job_name for a30
  col STATE for a10
  col sql_text for a100
  col message for a100
  col job_mode for a30
  
  SELECT x.job_name,
       b.state,
 --      b.degree,
 --      x.owner_name,
 --      z.sql_text,
       p.MESSAGE,
       p.totalwork,
       p.sofar,
       ROUND ( (p.sofar / p.totalwork) * 100, 2) done,
       p.time_remaining
  FROM dba_datapump_jobs b
       LEFT JOIN dba_datapump_sessions x ON (x.job_name = b.job_name)
       LEFT JOIN v$session y ON (y.saddr = x.saddr)
       LEFT JOIN v$sql z ON (y.sql_id = z.sql_id)
       LEFT JOIN v$session_longops p ON (p.sql_id = y.sql_id)
WHERE y.module = 'Data Pump Worker' AND p.time_remaining > 0;


col username for a20
col opname for a50 
col  message for a100
set lines 750 pages 9999
select username,opname,target_desc,sofar,totalwork,message from V$SESSION_LONGOPS where message not like '%RMAN%' and username='SYS';


SELECT sl.sid, sl.serial#, sl.sofar, sl.totalwork, dp.owner_name, dp.state, dp.job_mode
     FROM v$session_longops sl, v$datapump_job dp
     WHERE sl.opname = dp.job_name
     AND sl.sofar != sl.totalwork;


select x.job_name,b.state,b.job_mode,b.degree
, x.owner_name,z.sql_text, p.message
, p.totalwork, p.sofar
, round((p.sofar/p.totalwork)*100,2) done
, p.time_remaining
from dba_datapump_jobs b
left join dba_datapump_sessions x on (x.job_name = b.job_name)
left join v$session y on (y.saddr = x.saddr)
left join v$sql z on (y.sql_id = z.sql_id)
left join v$session_longops p ON (p.sql_id = y.sql_id)
WHERE y.module='Data Pump Worker'
AND p.time_remaining > 0;

SELECT DISTINCT dp.job_name, dp.session_type, s.inst_id, s.SID, s.serial#,
 s.username, s.inst_id, s.event, s.sql_id, q.sql_text,
 dj.operation, dj.state
 FROM gv$session s,
 dba_datapump_sessions dp,
 dba_datapump_jobs dj,
 gv$sql q
 WHERE s.saddr = dp.saddr
 AND dp.job_name = dj.job_name
 AND s.sql_id = q.sql_id
 AND s.inst_id IN (1, 2, 3) 
ORDER BY s.inst_id;



 set lines 750 pages 9999
  col  job_name for a30
  col STATE for a10
  col sql_text for a100
  col message for a100
  col job_mode for a30
  
  SELECT x.job_name,
       b.state,
 --      b.degree,
 --      x.owner_name,
 --      z.sql_text,
       p.MESSAGE,
       p.totalwork,
       p.sofar,
       ROUND ( (p.sofar / p.totalwork) * 100, 2) done,
       p.time_remaining
  FROM dba_datapump_jobs b
       LEFT JOIN dba_datapump_sessions x ON (x.job_name = b.job_name)
       LEFT JOIN v$session y ON (y.saddr = x.saddr)
       LEFT JOIN v$sql z ON (y.sql_id = z.sql_id)
       LEFT JOIN v$session_longops p ON (p.sql_id = y.sql_id)
WHERE y.module = 'Data Pump Worker' AND p.time_remaining > 0;


select x.job_name,b.state,b.job_mode,b.degree
, x.owner_name,z.sql_text, p.message
, p.totalwork, p.sofar
, round((p.sofar/p.totalwork)*100,2) done
, p.time_remaining
from dba_datapump_jobs b
left join dba_datapump_sessions x on (x.job_name = b.job_name)
left join v$session y on (y.saddr = x.saddr)
left join v$sql z on (y.sql_id = z.sql_id)
left join v$session_longops p ON (p.sql_id = y.sql_id)
WHERE y.module='Data Pump Worker'
AND p.time_remaining > 0;

=============================================================
---> to generate encrypt key
=============================================================
echo 6opRi2&tR- | openssl enc -k secretpassword123 -aes256 -base64 -e
U2FsdGVkX1/vgXJpU0SUJbjSOCcDKugRAaumHiqmfkw=
12:13
==============
echo <Tenant password> | openssl enc -k <Secret Key> -aes256 -base64 –e
Tenant password:  6opRi2&tR-
Secret key: In the DB inventory
New
12:13
SQL> ALTER USER NA10P1PRD079 IDENTIFIED BY 6opRi2&tR-;
12:14
CP Team ko below needed to share:
U2FsdGVkX185G8cd2mPFt9odBr2RPzldYyQjMSri8xs=


case reference :https://jira.saba.com/browse/COIR-84599?focusedCommentId=2510839&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-2510839



=============================================================
---> rman restore commands
=============================================================

If you want to restore all archive logs from backup use the below command.
rman> restore archivelog all;

To restore archive log from log number 215 to end.
restore archivelog from logseq=215;

To restore  archive log between starting and ending scn.
restore archivelog from logs


http://www.juliandyke.com/Research/RMAN/ListCommand.php


=============================================================
---> datafile movement dynamic SQL
=============================================================
set lines 200 pages 5000;
SELECT 'ALTER DATABASE MOVE DATAFILE '''||file_name||''' TO '''||'&New_mount_Name'||substr(file_name,instr(file_name,'/',1,2),length(file_name))||''';' from dba_data_files where file_name like '%u01%';

=============================================================
---> Check all Database related file locations
=============================================================

show parameter control_files
archive log list
show parameter db_recovery_file_dest
show parameter spfile
set lines 200 pages 1200;
col tablespace_name for a30;
col USED_FILE_LOCATIONS for a40;
select distinct(substr(file_name,1,instr(file_name,'/',1,(LENGTH(file_name) - LENGTH(REPLACE(file_name, '/', '')))))) "USED_FILE_LOCATIONS" from dba_data_files
group by tablespace_name,substr(file_name,1,instr(file_name,'/',1,(LENGTH(file_name) - LENGTH(REPLACE(file_name, '/', ''))))) order by 1 desc;

set lines 200 pages 1200
col tablespace_name for a20
col autoextensible for a15
col file_name for a60
select tablespace_name,autoextensible, file_name,bytes/1024/1024/1024 "USED GB",maxbytes/1024/1024/1024 "TOTAL GB" from dba_temp_files;

set lines 200 pages 1200
col PROPERTY_VALUE for a20
SELECT PROPERTY_VALUE
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME = 'DEFAULT_TEMP_TABLESPACE';

show parameter undo_tablespace
set line 450 pages 1500
col file_name for a60
select a.file_name, a.bytes/1024/1024/1024 bytes_GB, a.MAXBYTES/1024/1024/1024 maxsize_GB , b.creation_time
from dba_data_files a, v$datafile b
where tablespace_name like '%UNDO%'
and a.file_id=b.file#
order by 4,1;

  

column REDOLOG_FILE_NAME format a50;
set lines 1000 pages 1200
SELECT a.GROUP#, a.THREAD#, a.SEQUENCE#,
a.ARCHIVED, a.STATUS, b.MEMBER AS REDOLOG_FILE_NAME,
(a.BYTES/1024/1024) AS SIZE_MB FROM v$log a
JOIN v$logfile b ON a.Group#=b.Group#
ORDER BY a.GROUP#;

set lines 1000
column REDOLOG_FILE_NAME format a70;
SELECT a.GROUP#, a.THREAD#, a.SEQUENCE#,
a.ARCHIVED, a.STATUS, b.MEMBER AS REDOLOG_FILE_NAME,
(a.BYTES/1024/1024) AS SIZE_MB FROM v$standby_log a
JOIN v$logfile b ON a.Group#=b.Group#
ORDER BY a.GROUP#;


=============================================================
---> Tuning Semaphore Parameters. Refer to the following guidelines.

=============================================================
  Calculate the minimum total semaphore requirements using the following formula: 
 1. sum (process parameters of all database instances on the system) + overhead for background processes + system and other applications.
 2. Set semmns (total semaphores systemwide) to this total.
 3. Set semmsl (semaphores for each set ) to 256
 4. Set semmni (total semaphores sets) to semmns devided by semmsl, rounded up to the nearest multiple of 1024
12:05
sem=semmsl semmns semopm semmni
 kernel.sem = 256 32768 100 228
12:09
[oracle@n1rp10spcora01 ~]$ ipcs -ls
------ Semaphore Limits --------
max number of arrays = 200
max semaphores per array = 250
max semaphores system wide = 64000
max ops per semop call = 100
semaphore max value = 32767




-----------------------------------------------------
How to access VNC on any DB server for GUI Access ?
-----------------------------------------------------
Here need to configure vnc access on a5paa01dbaoem01 server to work on GUI for OEM installation.
Refer: https://jira.saba.com/browse/COIR-84983
1) Check on the server that there is no any vnc server process already configured.
[oracle@a5paa01dbaoem01 ~]$ ps -ef|grep vnc
oracle   58850 58819  0 14:46 pts/0    00:00:00 grep --color=auto vnc
2) Reuest infra team to install vnc on target DB server. Then network team has to allow port for vnc.
Refer:
https://jira.saba.com/browse/COIR-84983?focusedCommentId=2534530&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-2534530
3) Once infra confirmaed then check vnc processes on the target DB server. It should be there now like below.
[oracle@a5paa01dbaoem01 ~]$ ps -ef|grep vnc
oracle   48977     1  0 May18 ?        00:00:00 /usr/bin/Xvnc :1 -auth /u01/oracle/.Xauthority -desktop a5paa01dbaoem01:1 (oracle) -fp catalogue:/etc/X11/fontpath.d -geometry 1024x768 -pn -rfbauth /u01/oracle/.vnc/passwd -rfbport 5901 -rfbwait 30000
oracle   58850 58819  0 14:46 pts/0    00:00:00 grep --color=auto vnc
(NOTE: by default network team is allowing vnc on port: 1)
4) Now to access vnc server for target DB server a5paa01dbaoem01 from your desktop, we need to install tight vnc software.
(You can download and install in office laptop.)
5) Before accessing vnc we need to set password for vnc access from target DB server where vnc server process is running.
Follow below steps to setup password for vnc on target DB server:
--> Switch to oracle user.
[nmalwade@a5paa01dbaoem01 ~]$sudo su - oracle
--> execute below command to set vnc password and set new password.
[oracle@a5paa01dbaoem01 ~]$ vncpasswd
Password: oracle
6) Now to access vnc open tightVNC viewer in laptop and put below value in the address field.
a5paa01dbaoem01:1
--> click on open and enter vnc password.
7) Now you will get the vnc acces on target server.



=============================================================
************   Gather States for Table   *******************
=============================================================

EXEC DBMS_STATS.gather_table_stats('CA1PRD0032','CMI_PROFILE_ENTRY_ID_LOCALE_ID');
EXEC DBMS_STATS.gather_table_stats('A501PRD0037','CNT_DNF_ENROLLMENT_CURSOR',cascade=>TRUE);

SELECT owner, table_name, last_analyzed, stale_stats
FROM dba_tab_statistics
WHERE table_name='CNT_DNF_ENROLLMENT_CURSOR'
and owner='A501PRD0037';
=============================================================
************   Gather States for Index   *******************
=============================================================
EXEC DBMS_STATS.gather_index_stats('CA1PRD0032','ANT_QUERY_COMPOSER');


SELECT owner, table_name, index_name last_analyzed, stale_stats FROM dba_ind_statistics 
WHERE table_name='EMPLOYEES'
and owner = 'HR';




SELECT dbms_stats.get_prefs('INCREMENTAL','OE','ORDERS_DEMO') "INCREMENTAL" FROM   dual;
=============================================================
************  OEM   *******************
=============================================================


set lines 300 pages 300
col Parameter for a35
col "Session Value" for a20
col "Instance Value" for a20
SELECT a.ksppinm "Parameter", b.KSPPSTDF "Default Value",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value",
decode(bitand(a.ksppiflg/256,1),1,'TRUE','FALSE') IS_SESSION_MODIFIABLE,
decode(bitand(a.ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') IS_SYSTEM_MODIFIABLE
FROM x$ksppi a,
x$ksppcv b,
x$ksppsv c
WHERE a.indx = b.indx
AND a.indx = c.indx
AND a.ksppinm LIKE '/_%' escape '/'
AND a.ksppinm in ('_optimizer_nlj_hj_adaptive_join','_optimizer_strans_adaptive_pruning','_px_adaptive_dist_method','_sql_plan_directive_mgmt_control','_optimizer_dsdir_usage_control','_optimizer_use_feedback','_optimizer_gather_feedback','_optimizer_performance_feedback');


===================================================================================
************  lsof |deleted session finding at db level   *******************
===================================================================================
set lines 300 pages 300
col machine for a35
col "host-pid" for a20
col program for a20
select spid "host-pid",p.pid, s.sid, s.serial#, p.program, s.machine ,s.status
from v$session s, v$process p where paddr=addr and  spid=60957 order by p.pid;





===================================================================================
************  Deployment ssh connectivity check   *******************
===================================================================================
a) Place below script on target (oracle/mongo) server under sabatools user home directory.
vi SC_Get_RemoteHome.sh
#!/bin/ksh
# ********************************************************************************************
# NAME:         SC_Get_RemoteHome.sh
#
# NOTE: Just for testing.
############################################################################################
echo $1
####echo $1
b) Assign execute permission to above file.
chmod 755 SC_Get_RemoteHome.sh
c) Execute below command from respective control tier server with sabatols user
ssh n1pp07spcmon02 'sudo -u mongouser /home/sabatools/SC_Get_RemoteHome.sh /home/sabatools'


===================================================================================
************  invalid views after deployement  *******************
===================================================================================

----only analytics views-----
set lines 200 pages 1200;
col owner for a25;
col object_name for a35;
col object_type for a20;
col status for a15;
select owner,object_name,object_type,status,LAST_DDL_TIME from dba_objects where status='INVALID' and object_type='VIEW' and owner not in('SYS','OLAPSYS','SYSTEM','CTXSYS','APEX_030200','WMSYS') and object_name like '%ANV%';SQL> SQL> SQL> SQL> SQL>


set lines 200 pages 1200;
col owner for a25;
col object_name for a35;
col object_type for a20;
col status for a15;
select owner,object_name,object_type,status,LAST_DDL_TIME from dba_objects where status='INVALID' and object_type='VIEW' 
and owner not in('SYS','OLAPSYS','SYSTEM','CTXSYS','APEX_030200','WMSYS') ;



set lines 200 pages 1200;
col owner for a25;
col object_name for a35;
col object_type for a20;
col status for a15;
select 'alter view ' || owner ||'.'||object_name || ' compile;' from dba_objects where status='INVALID' and object_type='VIEW' 
and owner not in('SYS','OLAPSYS','SYSTEM','CTXSYS','APEX_030200','WMSYS') ;





set lines 200 pages 1200;
col owner for a25;
col object_name for a35;
col object_type for a20;
col status for a15;
select  owner ,object_name ,object_type from dba_objects where status='INVALID' 
and owner not in('SYS','OLAPSYS','SYSTEM','CTXSYS','APEX_030200','WMSYS') ;



---------------------------------
compile invalids after deployment
---------------------------------
!env|grep ORA;hostname;date;

set lines 300 pages 3000;
col owner for a15;
col object_type for a35;
col object_name for a35;
col status for a10;
SELECT owner,object_type,object_name,status
FROM
  dba_objects
WHERE
  status = 'INVALID' and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
  AND  object_type IN (
    'PROCEDURE',
    'FUNCTION',
    'PACKAGE',
    'PACKAGE BODY',
    'TRIGGER',
    'VIEW', 'TYPE BODY', 'TYPE','SYNONYM'
  ) ORDER BY  1;


set head off;
set lines 300 pages 3000;
spool test.sql
SELECT
  'alter '
  || DECODE(object_type,'PACKAGE BODY','PACKAGE',object_type)
  || ' '
  || owner
  || '.'
  || object_name
  || ' compile '
  || DECODE(object_type,'PACKAGE BODY','BODY',' ')
  || ';'
FROM
  dba_objects
WHERE
  status = 'INVALID' and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
  AND  object_type IN (
    'PROCEDURE',
    'FUNCTION',
    'PACKAGE',
    'PACKAGE BODY',
    'TRIGGER',
    'VIEW', 'TYPE BODY', 'TYPE','SYNONYM'
  ) ORDER BY  1;
spool off;



select 'alter '||object_type||' '||owner||'.'||object_name||' compile;'
from dba_objects
where status<>'VALID'
and object_type not in ('PACKAGE BODY','TYPE BODY','UNDEFINED','JAVA CLASS','SYNONYM')
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter package '||owner||'.'||object_name||' compile body;'
from dba_objects
where status<>'VALID'
and object_type='PACKAGE BODY'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter type '||owner||'.'||object_name||' compile body;'
from dba_objects
where status<>'VALID'
and object_type='TYPE BODY'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter materialized view '||owner||'.'||object_name||' compile;'
from dba_objects
where status<>'VALID'
and object_type='UNDEFINED'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter java class '||owner||'.'||object_name||' resolve;'
from dba_objects
where status<>'VALID'
and object_type='JAVA CLASS'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter synonym '||owner||'.'||object_name||' compile;'
from dba_objects
where status<>'VALID'
and object_type='SYNONYM'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS')
union
select 'alter public synonym '||object_name||' compile;'
from dba_objects
where status<>'VALID'
and object_type='SYNONYM'
and owner not in ('OLAPSYS','SYS','SYSTEM','XDB','GSMADMIN_INTERNAL','FLOWS_FILES','MDSYS','ORDSYS');








set lines 300 pages 3000;
col table_name for a10;
col index_name for a35;
col columns for a70;
col table_owner for a15;
select ind.table_owner || '.' || ind.table_name as "TABLE",
       ind.index_name,
       LISTAGG(ind_col.column_name, ',')
            WITHIN GROUP(order by ind_col.column_position) as columns,
       ind.index_type,
       ind.uniqueness
from sys.all_indexes ind
join sys.all_ind_columns ind_col
           on ind.owner = ind_col.index_owner
           and ind.index_name = ind_col.index_name
where ind.table_owner  in ('CA1PRD0032')
and ind.table_name = 'TPT_COMPANY'
group by ind.table_owner,
         ind.table_name,
         ind.index_name,
         ind.index_type,
         ind.uniqueness 
order by ind.table_owner,
         ind.table_name;
         

set lines 300 pages 1500;
col table_name for a10;
col index_name for a20;
col columns for a35;
col table_owner for a15;     
select ind.table_owner || '.' || ind.table_name as "TABLE",
ind.index_name,
LISTAGG(ind_col.column_name, ',')            WITHIN GROUP(order by ind_col.column_position) as columns,
ind.index_type,
ind.uniqueness
from sys.dba_indexes ind
join sys.dba_ind_columns ind_col
           on ind.owner = ind_col.index_owner
           and ind.index_name = ind_col.index_name
where ind.table_owner in ('CA1PRD0032')
and ind.table_name = 'TPT_COMPANY'
group by ind.table_owner,
         ind.table_name,
         ind.index_name,
         ind.index_type,
         ind.uniqueness 
order by ind.table_owner,
         ind.table_name;
         
         
         
         
         
---------------------------------------------------------------------------------------------------         
#### DE Oracle Databases Control file backup issue with the new /backup storage volumes.
---------------------------------------------------------------------------------------------------
https://jira.saba.com/browse/COIR-93113         




---------------------------------------------------------------------------------------------------         
#### tablespace ddl
---------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/tablespace_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified tablespace, or all tablespaces.
-- Call Syntax  : @tablespace_ddl (tablespace-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLESPACE', tablespace_name)
FROM   dba_tablespaces
WHERE  tablespace_name = DECODE(UPPER('&1'), 'ALL', tablespace_name, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
