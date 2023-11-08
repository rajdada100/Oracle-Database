. Single-Instance Database
1. Connect to the database.
Suppose we want to change tempfile location of a PDB.

SQL> conn sys@orclpdb as sysdba
Enter password:
Connected.
2. Check the status of the PDB.
You have to make sure the PDB is open as read write for further operations.

SQL> show con_name;

CON_NAME
------------------------------
ORCLPDB
SQL> show pdbs;

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         3 ORCLPDB                        READ WRITE NO
3. Check current tempfiles.
We check v$tempfile for temp files, just like we check v$datafile for data files and v$logfile for redo log files.

SQL> column name format a60;
SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
/u01/app/oracle/oradata/ORA19C1/ORCLPDB1/temp01.dbf          ONLINE
4. Add a new tempfile.
Here we add a new tempfile in different directory with the same name to the temporary tablespace for later use.

SQL> alter tablespace temp add tempfile '/oradata/ORCLCDB/ORCLPDB/temp01.dbf' size 10m autoextend on next 10m maxsize unlimited;

Tablespace altered.
Please note that, there's no ALTER TEMPORARY TABLESPACE such statement in Oracle database. So I don't event try it.

We check the status of tempfiles.

SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
/u01/app/oracle/oradata/ORA19C1/ORCLPDB1/temp01.dbf          ONLINE
/oradata/ORCLCDB/ORCLPDB/temp01.dbf                          ONLINE
OK, both old and new tempfile are online.

5. Offline the original tempfile.
We take the original tempfile offline for later dropping.

SQL> alter database tempfile '/u01/app/oracle/oradata/ORA19C1/ORCLPDB1/temp01.dbf' offline;

Database altered.
6. Drop the original tempfile.
Here we drop the tempfile physically.

SQL> alter database tempfile '/u01/app/oracle/oradata/ORA19C1/ORCLPDB1/temp01.dbf' drop including datafiles;

Database altered.
Check current tempfiles again.
SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
/oradata/ORCLCDB/ORCLPDB/temp01.dbf                          ONLINE
As you can see, what we did is to replace the old tempfile with the new tempfile in order to reach our goal.

B. RAC Database
The steps to change the location of a tempfile in RAC databases is very similar with single-instances'.

1. Make directory for new tempfile.
If necessary, we should create the directory for the new tempfile. For RAC database, we make directory by ASM Command-Line Utility (ASMCMD).

[grid@primary01 ~]$ asmcmd mkdir +DATA/TESTCDB/ORCLPDB
2. Connect to the database.
Suppose we want to change tempfile location of a PDB.

SQL> conn sys@orclpdb as sysdba
Enter password:
Connected.
3. Check the status of the PDB.
You have to make sure the PDB is open as read write for further operations.

SQL> show con_name;

CON_NAME
------------------------------
ORCLPDB
SQL> show pdbs;

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         3 ORCLPDB                        READ WRITE NO
4. Check current tempfiles.
We check v$tempfile for temp files, just like we check v$datafile for data files and v$logfile for redo log files.

SQL> column name format a60;
SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
+DATA/ORCLCDB/ORCLPDB/temp01.dbf                             ONLINE
5. Add a new tempfile.
Here we add a new tempfile in different directory with the same name to the temporary tablespace for later use.

SQL> alter tablespace temp add tempfile '+DATA/TESTCDB/ORCLPDB/temp01.dbf' size 10m autoextend on next 10m maxsize unlimited;

Tablespace altered.

SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
+DATA/TESTCDB/ORCLPDB/temp01.dbf                             ONLINE
+DATA/ORCLCDB/ORCLPDB/temp01.dbf                             ONLINE
6. Offline the original tempfile.
We take the original tempfile offline for later dropping.

SQL> alter database tempfile '+DATA/ORCLCDB/ORCLPDB/temp01.dbf' offline;

Database altered.
7. Drop the original tempfile.
Here we drop the tempfile physically.

SQL> alter database tempfile '+DATA/ORCLCDB/ORCLPDB/temp01.dbf' drop including datafiles;

Database altered.

SQL> select name, status from v$tempfile;

NAME                                                         STATUS
------------------------------------------------------------ -------
+DATA/TESTCDB/ORCLPDB/temp01.dbf                             ONLINE
Let's check the physical file.

[grid@primary01 ~]$ asmcmd ls -l +DATA/TESTCDB/ORCLPDB/temp*
Type      Redund  Striped  Time             Sys  Name
TEMPFILE  UNPROT  COARSE   JAN 19 11:00:00  N    temp01.dbf => +DATA/TESTCDB/B19AA2333D82DCFBE0530C2AA8C0EE3A/TEMPFILE/TEMP.334.1062237233
