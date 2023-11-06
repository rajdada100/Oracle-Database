https://jira.saba.com/browse/COIR-87503
need blank SM schema

Follow below steps for changing the oracle database name using nid utility. We will change the database name from TUK1SM01 to PUK1SM01.

1. set environment for TUK1SM01 first
2. shutdown TUK1SM01 and mount the DATABASE
3. Run NID utility 
	nid target=sys/sabadba4you@TUK1SM01 DBNAME=PUK1SM01
4. change the db_name parameter in parameter file 
	shut immediate;
	startup nomount;
	alter system set db_name= PUK1SM01 scope=spfile;
	shut immediate;
5. Rename the spfile to new db name
   cp -pr /u01/app/oracle/product/19c/dbhome_1/dbs/spfileTUK1SM01.ora /u01/app/oracle/product/19c/dbhome_1/dbs/spfilePUK1SM01.ora
6. Start database in mount stage
	startup mount;
7. Open database with resetlogs;
	alter database open resetlogs;
	
	
	
----------------execution logs--------------
[oracle@e2paa01spcora01 ~]$ env |grep ORA
ORACLE_UNQNAME=TUK1SM01
ORACLE_SID=TUK1SM01
ORACLE_BASE=/u01/app/oracle
ORACLE_TERM=xterm
ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
[oracle@e2paa01spcora01 ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Thu Jul 28 11:55:05 2022
Version 19.8.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup mount
ORACLE instance started.

Total System Global Area 2147481656 bytes
Fixed Size                  8898616 bytes
Variable Size             486539264 bytes
Database Buffers         1644167168 bytes
Redo Buffers                7876608 bytes
Database mounted.
SQL>
	
[oracle@e2paa01spcora01 ~]$ nid target=sys/sabadba4you@TUK1SM01 DBNAME=PUK1SM01

DBNEWID: Release 19.0.0.0.0 - Production on Thu Jul 28 11:55:49 2022

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Connected to database TUK1SM01 (DBID=3944691338)

Connected to server version 19.8.0

Control Files in database:
    /u02/oradata/TUK1SM01/control01.ctl
    /u02/oradata/TUK1SM01/control02.ctl

Change database ID and database name TUK1SM01 to PUK1SM01? (Y/[N]) => Y

Proceeding with operation
Changing database ID from 3944691338 to 1328771589
Changing database name from TUK1SM01 to PUK1SM01
    Control File /u02/oradata/TUK1SM01/control01.ctl - modified
    Control File /u02/oradata/TUK1SM01/control02.ctl - modified
    Datafile /u02/oradata/TUK1SM01/system01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/undotbs02.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/sysaux01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/undotbs01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/SPCUK1PRD_01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/users01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/undotbs03.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/temp01.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/temp02.db - dbid changed, wrote new name
    Datafile /u02/oradata/TUK1SM01/temp03.db - dbid changed, wrote new name
    Control File /u02/oradata/TUK1SM01/control01.ctl - dbid changed, wrote new name
    Control File /u02/oradata/TUK1SM01/control02.ctl - dbid changed, wrote new name
    Instance shut down

Database name changed to PUK1SM01.
Modify parameter file and generate a new password file before restarting.
Database ID for database PUK1SM01 changed to 1328771589.
All previous backups and archived redo logs for this database are unusable.
Database has been shutdown, open database with RESETLOGS option.
Succesfully changed database name and ID.
DBNEWID - Completed succesfully.

[oracle@e2paa01spcora01 ~]$
	
	
[oracle@e2paa01spcora01 ~]$ env|grep ORA
ORACLE_UNQNAME=TUK1SM01
ORACLE_SID=TUK1SM01
ORACLE_BASE=/u01/app/oracle
ORACLE_TERM=xterm
ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
[oracle@e2paa01spcora01 ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Thu Jul 28 11:57:52 2022
Version 19.8.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup nomount;
ORACLE instance started.

Total System Global Area 2147481656 bytes
Fixed Size                  8898616 bytes
Variable Size             486539264 bytes
Database Buffers         1644167168 bytes
Redo Buffers                7876608 bytes
SQL> alter system set db_name=PUK1SM01 scope=spfile;

System altered.

SQL> shut immediate
ORA-01507: database not mounted


ORACLE instance shut down.

[oracle@e2paa01spcora01 dbhome_1]$ cp -pr /u01/app/oracle/product/19c/dbhome_1/dbs/spfileTUK1SM01.ora /u01/app/oracle/product/19c/dbhome_1/dbs/spfilePUK1SM01.ora


SQL> startup mount
ORACLE instance started.

Total System Global Area 2147481656 bytes
Fixed Size                  8898616 bytes
Variable Size             486539264 bytes
Database Buffers         1644167168 bytes
Redo Buffers                7876608 bytes
Database mounted.
SQL> show parameter db_name

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_name                              string      PUK1SM01
SQL> alter database open resetlogs;

Database altered.

SQL> alter system register;

System altered.

	
[oracle@e2paa01spcora01 dbs]$ cp -pr orapwTUK1SM01 orapwPUK1SM01
You have mail in /var/spool/mail/oracle
[oracle@e2paa01spcora01 dbs]$ pwd
/u01/app/oracle/product/19c/dbhome_1/dbs
	
	
	
[oracle@e2paa01spcora01 u02]$ pwd
/u02
[oracle@e2paa01spcora01 u02]$ ls -lrt
total 4
drwxr-xr-x 3 oracle oinstall   35 Nov 18  2020 bktemp
drwxr-xr-x 6 oracle oinstall   70 Jul 28 11:37 oradata
-rw-r--r-- 1 oracle oinstall 3153 Jul 28 12:31 PUK1SM01_control.sql
	
	
-----------------after following above steps get to know that this NID method just changes db_name parameter for instance rest remains same 
-----------------so I followed controlfile recreation method---------------

1. Create pfile from old instance TUK1SM01 and create one copy with new instance name PUK1SM01 from that FILE
2. Now based on locations mentioned in pfile , create all nessesary directories required. (adump,archive location,datafile location,controlfile location etc.) 
3. Generate contorlfile recreation script from old instance TUK1SM01
sql> alter database backup controlfile to trace as '/u02/PUK1SM01_control.sql';

make nessesary changes as per requirement in PUK1SM01_control.sql file.After changes file looks like as below.

----------------------------------------------------------------------------------------------------------------------------------
STARTUP NOMOUNT PFILE='/u01/app/oracle/product/19c/dbhome_1/dbs/initPUK1SM01.ora';
CREATE CONTROLFILE REUSE DATABASE "PUK1SM01" RESETLOGS  ARCHIVELOG
    MAXLOGFILES 16
    MAXLOGMEMBERS 3
    MAXDATAFILES 100
    MAXINSTANCES 8
    MAXLOGHISTORY 292
LOGFILE
  GROUP 1 (
    '/u02/oradata/PUK1SM01/redo01.log',
    '/u02/oradata/PUK1SM01/redo01a.log'
  ) SIZE 500M BLOCKSIZE 512,
  GROUP 2 (
    '/u02/oradata/PUK1SM01/redo02.log',
    '/u02/oradata/PUK1SM01/redo02a.log'
  ) SIZE 500M BLOCKSIZE 512,
  GROUP 3 (
    '/u02/oradata/PUK1SM01/redo03.log',
    '/u02/oradata/PUK1SM01/redo03a.log'
  ) SIZE 500M BLOCKSIZE 512,
  GROUP 4 (
    '/u02/oradata/PUK1SM01/redo04.log',
    '/u02/oradata/PUK1SM01/redo04a.log'
  ) SIZE 500M BLOCKSIZE 512,
  GROUP 5 (
    '/u02/oradata/PUK1SM01/redo05.log',
    '/u02/oradata/PUK1SM01/redo05a.log'
  ) SIZE 500M BLOCKSIZE 512,
  GROUP 6 (
    '/u02/oradata/PUK1SM01/redo06.log',
    '/u02/oradata/PUK1SM01/redo06a.log'
  ) SIZE 500M BLOCKSIZE 512
-- STANDBY LOGFILE
DATAFILE
  '/u02/oradata/PUK1SM01/system01.dbf',
  '/u02/oradata/PUK1SM01/undotbs02.dbf',
  '/u02/oradata/PUK1SM01/sysaux01.dbf',
  '/u02/oradata/PUK1SM01/undotbs01.dbf',
  '/u02/oradata/PUK1SM01/SPCUK1PRD_01.dbf',
  '/u02/oradata/PUK1SM01/users01.dbf',
  '/u02/oradata/PUK1SM01/undotbs03.dbf'
CHARACTER SET AL32UTF8
;

-- Configure RMAN configuration record 1
--VARIABLE RECNO NUMBER;
--EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('RETENTION POLICY','TO RECOVERY WINDOW OF 14 DAYS');
-- Configure RMAN configuration record 2
--VARIABLE RECNO NUMBER;
--EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE','DISK TO ''/backup/lon/TUK1SM01/CTRLFILE_BACKUP/cf_%F_full_ctrl''');
-- Configure RMAN configuration record 4
-- Replace * with correct password.
--VARIABLE RECNO NUMBER;
--EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('CHANNEL','DEVICE TYPE DISK MAXOPENFILES 1');
-- Commands to re-create incarnation table
-- Below log names MUST be changed to existing filenames on
-- disk. Any one log file from each branch can be used to
-- re-create incarnation records.
-- ALTER DATABASE REGISTER LOGFILE '/archive/PUK1SM01/1_1_1005785759.dbf';
-- ALTER DATABASE REGISTER LOGFILE '/archive/PUK1SM01/1_1_1111061709.dbf';
-- ALTER DATABASE REGISTER LOGFILE '/archive/PUK1SM01/1_1_1111233628.dbf';
-- Recovery is required if any of the datafiles are restored backups,
-- or if the last shutdown was not normal or immediate.
RECOVER DATABASE USING BACKUP CONTROLFILE

-- Database can now be opened zeroing the online logs.
ALTER DATABASE OPEN RESETLOGS;

-- Commands to add tempfiles to temporary tablespaces.
-- Online tempfiles have complete space information.
-- Other tempfiles may require adjustment.
ALTER TABLESPACE TEMP ADD TEMPFILE '/u02/oradata/PUK1SM01/temp01.dbf'
     SIZE 44040192  REUSE AUTOEXTEND ON NEXT 655360  MAXSIZE 32767M;
ALTER TABLESPACE TEMP ADD TEMPFILE '/u02/oradata/PUK1SM01/temp02.dbf'
     SIZE 104857600  REUSE AUTOEXTEND ON NEXT 104857600  MAXSIZE 20480M;
ALTER TABLESPACE TEMP ADD TEMPFILE '/u02/oradata/PUK1SM01/temp03.dbf'
     SIZE 104857600  REUSE AUTOEXTEND ON NEXT 104857600  MAXSIZE 20480M;
-- End of tempfile additions.
------------------------------------------------------------------------------------------------------------------------------------

4. Now copy all datafiles,tempfile,redolog files from old Instance location to new location 
cp -pr /u02/oradata/TUK1SM01 /u02/oradata/PUK1SM01

5. Create environment file for new instance and set environement 
6. Connect to sqlplus with new instance PUK1SM01 and execute controlfile creation script 
sql> @/u02/PUK1SM01_control.sql
7. Above steps creates new controlfile for new instance , after that need to start db with resetlogs option.
Note: you may face system datafile inconsitencey error during above steps, for that solution is do cancel based recovery
ERROR at line 1:
ORA-01194: file 1 needs more recovery to be consistent
ORA-01110: data file 1:

solution:
SQL> recover database using backup controlfile until cancel;
...
Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
AUTO/CANCEL

8. Do changes in listener.ora, tnsnames.ora files according to new db instance name and reload listener
9. Do changes in cronjobs for renamed instance
9. Do infdb changes as below for rman catalog

	
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
select SID,HOST_NAME,ENVIRONMENT,ORACLE_VERSION,CREATED_DATE,STATUS from INFDB.DATABASES where HOST_NAME = 'e2paa01spcora01';


SET LINESIZE 160 PAGESIZE 200
COL object_name FOR a16
COL object_type FOR a16
select object_name,object_type  from dba_objects where owner = 'INFDB' and object_type = 'TABLE';

update INFDB.DATABASES set SID='PUK1SM01' where HOST_NAME = 'e2paa01spcora01' and SID='TUK1SM01';
