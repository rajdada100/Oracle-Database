
***********************************************************
		Get standby redo log info
***********************************************************

SQL> set lines 200 pages 999
col member format a70
select st.group#
, st.sequence#
, ceil(st.bytes / 1048576) mb
, lf.member,
st.status
from v$standby_log st
, v$logfile lf
where st.group# = lf.group#;

ALTER DATABASE ADD STANDBY LOGFILE  GROUP 7 ('/ora01_PCA001_P_u02/oradata/PSPCN203/redo07.log','/ora01_PCA001_P_u02/oradata/PSPCN203/redo07a.log') size 500M;  
OR 
ALTER DATABASE ADD STANDBY LOGFILE ('/u01_EU2_PVEME205/oradata/standby_redo_001.log') SIZE 500M;

ALTER SYSTEM SWITCH LOGFILE;
----VERIFY WHICH GROUP IS INACTIVE AND DROP THAT
ALTER DATABASE DROP  LOGFILE GROUP 3;

***********************************************************
		Get  redo log info
***********************************************************
set lines 200 pages 999
col member format a70
select st.group#
, st.sequence#
, ceil(st.bytes / 1048576) mb
, lf.member,
st.status
from v$log st
, v$logfile lf
where st.group# = lf.group#;




ALTER DATABASE ADD LOGFILE THREAD 1 GROUP 7 ('/ora01_PCA001_P_u02/oradata/PSPCN203/redo07.log','/ora01_PCA001_P_u02/oradata/PSPCN203/redo07a.log') size 500M;  

ALTER SYSTEM SWITCH LOGFILE;
----VERIFY WHICH GROUP IS INACTIVE AND DROP THAT
ALTER DATABASE DROP LOGFILE GROUP 3;