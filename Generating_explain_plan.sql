********************************************
Generating explain plan for a sql query:
********************************************

--- LOAD THE EXPLAIN PLAN TO PLAN_TABLE
SQL> explain plan for
2 select count(*) from dbaclass;

Explained.

--- DISPLAY THE EXPLAIN PLAN
SQL> set lines 150
SQL> select * from table(dbms_xplan.display);

OR


SQL> @$ORACLE_HOME/rdbms/admin/utlxpls.sql