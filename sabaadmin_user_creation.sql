CREATE USER "SABAADMIN" IDENTIFIED BY VALUES 'dba4you'
      DEFAULT TABLESPACE "USERS"
      TEMPORARY TABLESPACE "TEMP";


   GRANT "CONNECT" TO "SABAADMIN";
   GRANT "SELECT_CATALOG_ROLE" TO "SABAADMIN";


  GRANT ALTER SYSTEM TO "SABAADMIN";
  GRANT AUDIT SYSTEM TO "SABAADMIN";
  GRANT CREATE SESSION TO "SABAADMIN";
  GRANT ALTER SESSION TO "SABAADMIN";
  GRANT RESTRICTED SESSION TO "SABAADMIN";
  GRANT CREATE TABLESPACE TO "SABAADMIN";
  GRANT ALTER TABLESPACE TO "SABAADMIN";
  GRANT MANAGE TABLESPACE TO "SABAADMIN";
  GRANT DROP TABLESPACE TO "SABAADMIN";
  GRANT UNLIMITED TABLESPACE TO "SABAADMIN";
  GRANT CREATE USER TO "SABAADMIN";
  GRANT BECOME USER TO "SABAADMIN";
  GRANT ALTER USER TO "SABAADMIN";
  GRANT DROP USER TO "SABAADMIN";
  GRANT CREATE ROLLBACK SEGMENT TO "SABAADMIN";
  GRANT ALTER ROLLBACK SEGMENT TO "SABAADMIN";
  GRANT DROP ROLLBACK SEGMENT TO "SABAADMIN";
  GRANT CREATE TABLE TO "SABAADMIN";
  GRANT CREATE ANY TABLE TO "SABAADMIN";
  GRANT ALTER ANY TABLE TO "SABAADMIN";
  GRANT BACKUP ANY TABLE TO "SABAADMIN";
  GRANT DROP ANY TABLE TO "SABAADMIN";
  GRANT LOCK ANY TABLE TO "SABAADMIN";
  GRANT COMMENT ANY TABLE TO "SABAADMIN";
  GRANT SELECT ANY TABLE TO "SABAADMIN";
  GRANT INSERT ANY TABLE TO "SABAADMIN";
  GRANT UPDATE ANY TABLE TO "SABAADMIN";
  GRANT DELETE ANY TABLE TO "SABAADMIN";
  GRANT CREATE CLUSTER TO "SABAADMIN";
  GRANT CREATE ANY CLUSTER TO "SABAADMIN";
  GRANT ALTER ANY CLUSTER TO "SABAADMIN";
  GRANT DROP ANY CLUSTER TO "SABAADMIN";
  GRANT CREATE ANY INDEX TO "SABAADMIN";
  GRANT ALTER ANY INDEX TO "SABAADMIN";
  GRANT DROP ANY INDEX TO "SABAADMIN";
  GRANT CREATE SYNONYM TO "SABAADMIN";
  GRANT CREATE ANY SYNONYM TO "SABAADMIN";
  GRANT DROP ANY SYNONYM TO "SABAADMIN";
  GRANT CREATE PUBLIC SYNONYM TO "SABAADMIN";
  GRANT DROP PUBLIC SYNONYM TO "SABAADMIN";
  GRANT CREATE VIEW TO "SABAADMIN";
  GRANT CREATE ANY VIEW TO "SABAADMIN";
  GRANT DROP ANY VIEW TO "SABAADMIN";
  GRANT CREATE SEQUENCE TO "SABAADMIN";
  GRANT CREATE ANY SEQUENCE TO "SABAADMIN";
  GRANT ALTER ANY SEQUENCE TO "SABAADMIN";
  GRANT DROP ANY SEQUENCE TO "SABAADMIN";
  GRANT SELECT ANY SEQUENCE TO "SABAADMIN";
  GRANT CREATE DATABASE LINK TO "SABAADMIN";
  GRANT CREATE PUBLIC DATABASE LINK TO "SABAADMIN";
  GRANT DROP PUBLIC DATABASE LINK TO "SABAADMIN";
  GRANT CREATE ROLE TO "SABAADMIN";
  GRANT DROP ANY ROLE TO "SABAADMIN";
  GRANT GRANT ANY ROLE TO "SABAADMIN";
  GRANT ALTER ANY ROLE TO "SABAADMIN";
  GRANT AUDIT ANY TO "SABAADMIN";
  GRANT ALTER DATABASE TO "SABAADMIN";
  GRANT FORCE TRANSACTION TO "SABAADMIN";
  GRANT FORCE ANY TRANSACTION TO "SABAADMIN";
  GRANT CREATE PROCEDURE TO "SABAADMIN";
  GRANT CREATE ANY PROCEDURE TO "SABAADMIN";
  GRANT ALTER ANY PROCEDURE TO "SABAADMIN";
  GRANT DROP ANY PROCEDURE TO "SABAADMIN";
  GRANT EXECUTE ANY PROCEDURE TO "SABAADMIN";
  GRANT CREATE TRIGGER TO "SABAADMIN";
  GRANT CREATE ANY TRIGGER TO "SABAADMIN";
  GRANT ALTER ANY TRIGGER TO "SABAADMIN";
  GRANT DROP ANY TRIGGER TO "SABAADMIN";
  GRANT CREATE PROFILE TO "SABAADMIN";
  GRANT ALTER PROFILE TO "SABAADMIN";
  GRANT DROP PROFILE TO "SABAADMIN";
  GRANT ALTER RESOURCE COST TO "SABAADMIN";
  GRANT ANALYZE ANY TO "SABAADMIN";
  GRANT GRANT ANY PRIVILEGE TO "SABAADMIN";
  GRANT CREATE MATERIALIZED VIEW TO "SABAADMIN";
  GRANT CREATE ANY MATERIALIZED VIEW TO "SABAADMIN";
  GRANT ALTER ANY MATERIALIZED VIEW TO "SABAADMIN";
  GRANT DROP ANY MATERIALIZED VIEW TO "SABAADMIN";
  GRANT CREATE ANY DIRECTORY TO "SABAADMIN";
  GRANT DROP ANY DIRECTORY TO "SABAADMIN";
  GRANT CREATE TYPE TO "SABAADMIN";
  GRANT CREATE ANY TYPE TO "SABAADMIN";
  GRANT ALTER ANY TYPE TO "SABAADMIN";
  GRANT DROP ANY TYPE TO "SABAADMIN";
  GRANT EXECUTE ANY TYPE TO "SABAADMIN";
  GRANT UNDER ANY TYPE TO "SABAADMIN";
  GRANT CREATE LIBRARY TO "SABAADMIN";
  GRANT CREATE ANY LIBRARY TO "SABAADMIN";
  GRANT ALTER ANY LIBRARY TO "SABAADMIN";
  GRANT DROP ANY LIBRARY TO "SABAADMIN";
  GRANT EXECUTE ANY LIBRARY TO "SABAADMIN";
  GRANT CREATE OPERATOR TO "SABAADMIN";
  GRANT CREATE ANY OPERATOR TO "SABAADMIN";
  GRANT ALTER ANY OPERATOR TO "SABAADMIN";
  GRANT DROP ANY OPERATOR TO "SABAADMIN";
  GRANT EXECUTE ANY OPERATOR TO "SABAADMIN";
  GRANT CREATE INDEXTYPE TO "SABAADMIN";
  GRANT CREATE ANY INDEXTYPE TO "SABAADMIN";
  GRANT ALTER ANY INDEXTYPE TO "SABAADMIN";
  GRANT DROP ANY INDEXTYPE TO "SABAADMIN";
  GRANT UNDER ANY VIEW TO "SABAADMIN";
  GRANT QUERY REWRITE TO "SABAADMIN";
  GRANT GLOBAL QUERY REWRITE TO "SABAADMIN";
  GRANT EXECUTE ANY INDEXTYPE TO "SABAADMIN";
  GRANT UNDER ANY TABLE TO "SABAADMIN";
  GRANT CREATE DIMENSION TO "SABAADMIN";
  GRANT CREATE ANY DIMENSION TO "SABAADMIN";
  GRANT ALTER ANY DIMENSION TO "SABAADMIN";
  GRANT DROP ANY DIMENSION TO "SABAADMIN";
  GRANT CREATE ANY CONTEXT TO "SABAADMIN";
  GRANT DROP ANY CONTEXT TO "SABAADMIN";
  GRANT CREATE ANY OUTLINE TO "SABAADMIN";
  GRANT ALTER ANY OUTLINE TO "SABAADMIN";
  GRANT DROP ANY OUTLINE TO "SABAADMIN";
  GRANT MERGE ANY VIEW TO "SABAADMIN";
  GRANT ON COMMIT REFRESH TO "SABAADMIN";
  GRANT RESUMABLE TO "SABAADMIN";
  GRANT DEBUG CONNECT SESSION TO "SABAADMIN";
  GRANT DEBUG ANY PROCEDURE TO "SABAADMIN";
  GRANT FLASHBACK ANY TABLE TO "SABAADMIN";
  GRANT GRANT ANY OBJECT PRIVILEGE TO "SABAADMIN";
  GRANT ADVISOR TO "SABAADMIN";
  GRANT CREATE JOB TO "SABAADMIN";
  GRANT CREATE ANY JOB TO "SABAADMIN";
  GRANT EXECUTE ANY PROGRAM TO "SABAADMIN";
  GRANT EXECUTE ANY CLASS TO "SABAADMIN";
  GRANT MANAGE SCHEDULER TO "SABAADMIN";
  GRANT SELECT ANY TRANSACTION TO "SABAADMIN";
  GRANT DROP ANY SQL PROFILE TO "SABAADMIN";
  GRANT ALTER ANY SQL PROFILE TO "SABAADMIN";
  GRANT ADMINISTER SQL TUNING SET TO "SABAADMIN";
  GRANT ADMINISTER ANY SQL TUNING SET TO "SABAADMIN";
  GRANT CREATE ANY SQL PROFILE TO "SABAADMIN";
  GRANT CHANGE NOTIFICATION TO "SABAADMIN";
  GRANT CREATE EXTERNAL JOB TO "SABAADMIN";
  GRANT CREATE ANY EDITION TO "SABAADMIN";
  GRANT DROP ANY EDITION TO "SABAADMIN";
  GRANT ALTER ANY EDITION TO "SABAADMIN";
  GRANT CREATE ASSEMBLY TO "SABAADMIN";
  GRANT CREATE ANY ASSEMBLY TO "SABAADMIN";
  GRANT ALTER ANY ASSEMBLY TO "SABAADMIN";
  GRANT DROP ANY ASSEMBLY TO "SABAADMIN";
  GRANT EXECUTE ANY ASSEMBLY TO "SABAADMIN";
  GRANT EXECUTE ASSEMBLY TO "SABAADMIN";
  GRANT CREATE MINING MODEL TO "SABAADMIN";
  GRANT CREATE ANY MINING MODEL TO "SABAADMIN";
  GRANT DROP ANY MINING MODEL TO "SABAADMIN";
  GRANT SELECT ANY MINING MODEL TO "SABAADMIN";
  GRANT ALTER ANY MINING MODEL TO "SABAADMIN";
  GRANT COMMENT ANY MINING MODEL TO "SABAADMIN";
  GRANT CREATE CUBE DIMENSION TO "SABAADMIN";
  GRANT ALTER ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT CREATE ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT DELETE ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT DROP ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT INSERT ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT SELECT ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT CREATE CUBE TO "SABAADMIN";
  GRANT ALTER ANY CUBE TO "SABAADMIN";
  GRANT CREATE ANY CUBE TO "SABAADMIN";
  GRANT DROP ANY CUBE TO "SABAADMIN";
  GRANT SELECT ANY CUBE TO "SABAADMIN";
  GRANT UPDATE ANY CUBE TO "SABAADMIN";
  GRANT CREATE MEASURE FOLDER TO "SABAADMIN";
  GRANT CREATE ANY MEASURE FOLDER TO "SABAADMIN";
  GRANT DELETE ANY MEASURE FOLDER TO "SABAADMIN";
  GRANT DROP ANY MEASURE FOLDER TO "SABAADMIN";
  GRANT INSERT ANY MEASURE FOLDER TO "SABAADMIN";
  GRANT CREATE CUBE BUILD PROCESS TO "SABAADMIN";
  GRANT CREATE ANY CUBE BUILD PROCESS TO "SABAADMIN";
  GRANT DROP ANY CUBE BUILD PROCESS TO "SABAADMIN";
  GRANT UPDATE ANY CUBE BUILD PROCESS TO "SABAADMIN";
  GRANT UPDATE ANY CUBE DIMENSION TO "SABAADMIN";
  GRANT ADMINISTER SQL MANAGEMENT OBJECT TO "SABAADMIN";
  GRANT FLASHBACK ARCHIVE ADMINISTER TO "SABAADMIN";
  GRANT CREATE CREDENTIAL TO "SABAADMIN";
  GRANT CREATE ANY CREDENTIAL TO "SABAADMIN";
  GRANT LOGMINING TO "SABAADMIN";


  GRANT EXECUTE ON DIRECTORY "ADD_TENANT" TO "SABAADMIN" WITH GRANT OPTION;
  GRANT READ ON DIRECTORY "ADD_TENANT" TO "SABAADMIN" WITH GRANT OPTION;
  GRANT WRITE ON DIRECTORY "ADD_TENANT" TO "SABAADMIN" WITH GRANT OPTION;
  GRANT EXECUTE ON DIRECTORY "DECOM_DIRECTORY" TO "SABAADMIN" WITH GRANT OPTION;
  GRANT READ ON DIRECTORY "DECOM_DIRECTORY" TO "SABAADMIN" WITH GRANT OPTION;
  GRANT WRITE ON DIRECTORY "DECOM_DIRECTORY" TO "SABAADMIN" WITH GRANT OPTION;


   ALTER USER "SABAADMIN" DEFAULT ROLE ALL;
