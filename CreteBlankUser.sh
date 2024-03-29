#!/bin/ksh
# ==================================================================================================
# NAME:         CreteBlankUser.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This script will create the blank Schema for SABA MEETING
#
#
#
# USAGE:        CreteBlankUser.sh
#
#
# ==================================================================================================
#set -x
clear
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export MAILTO='bkhan@saba.com'
export MAILTO='CloudOps-DBA@Saba.com'
#export CURDATE=$(date +'%Y%m%d')
mkdir -p /home/oracle/local/dba/scripts/logs
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

print "Please Enter the Database name where you want to create the Blank schema:\c"
read sid

sid_in_oratab=$(grep -v "^#" $ORATAB | grep -w $sid | awk -F: '{print $1}')
if [ "$sid_in_oratab" != "$sid" ]
then
   print "\n\n\t\tYou entered the wrong DB name...Please check and execute again.\n\n"
   exit 2
fi



export ORACLE_SID=$sid
export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null
if [ $? -ne 0 ]
then
 print "\n\n\t\t There seems to be some problem please rectify and Execute Again\n\nAborting Here...."
 exit 2
fi

no_users=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<bk
set heading off
set feedback off
select count(*) from dba_users where username not in ('SYSTEM','SYS','OUTLN','DIP','ORACLE_OCM','DBSNMP','APPQOSSYS','WMSYS','EXFSYS','CTXSYS','XDB','ANONYMOUS','XS$NULL','MDSYS','ORDDATA','SI_INFORMTN_SCHEMA','ORDPLUGINS','ORDSYS','OLAPSYS','MDDATA','SPATIAL_WFS_ADMIN_USR','SPATIAL_CSW_ADMIN_USR','SYSMAN','MGMT_VIEW','FLOWS_FILES','APEX_030200','APEX_PUBLIC_USER','OWBSYS','OWBSYS_AUDIT','SCOTT','BI','PM','OE','IX','HR','SH');
bk`
if [ $? -ne 0 ]
then
 print "\n\nThere is Some Problem Please Rectify and Execute Again
Aborting Here...."
 exit 3
fi

export no_users=$(print $no_users|tr -d " ")

print "There are already $no_users DB Users created...Do you Want to proceed?[y/n]:\c"
read ch

export ch=$(print $ch|tr '[A-Z]' '[a-z]')
if [ $ch != 'y' ]
then
 print "\n\n\t\t Thanks Aborting here........\n"
 exit 4
fi


print "Please enter the name of Blank Schema:\c"
read username

chk_user=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<bk
set heading off
set feedback off
select username from dba_users where username=upper('${username}');
bk`
if [ $? -ne 0 ]
then
 print "\n\nThere is Some Problem Please Rectify and Execute Again
Aborting Here...."
 exit 4
fi

export chk_user=$(print $chk_user|tr -d " ")

if [[ -n $chk_user ]]
then
  print "\n Blank schema $username already exist..Please use Other Blank Schema name \nAborting Here....\n"
 exit 4
fi

disk_uti=$(df -h /u01 | grep /u01 |awk '{print $5}' |awk -F% '{print $1}')
export disk_uti=$(print $disk_uti|tr -d " ")

if [ $disk_uti -gt 80 ]
then
 print "\n\n\t\t Disk Utilization reached to threshold...Please contact DBA to proceed\n"
 exit 4
fi


$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<bk
spool $HOME/local/dba/app_scripts/logs/CreateBlankUser_${username}.out
create tablespace ${username}_TBS datafile '/oracle_data/oradata/${sid}/${username}_01.dbf' size 100m autoextend on next 100m maxsize unlimited;
CREATE USER ${username} IDENTIFIED BY ${username} DEFAULT TABLESPACE ${username}_TBS TEMPORARY TABLESPACE TEMP;
GRANT CONNECT TO ${username};
GRANT RESOURCE TO ${username};
GRANT CTXAPP TO ${username};
GRANT CREATE SEQUENCE TO ${username};
GRANT DROP PUBLIC SYNONYM TO ${username};
GRANT CREATE PUBLIC SYNONYM TO ${username};
GRANT UNLIMITED TABLESPACE TO ${username};
grant create public synonym, drop public synonym to ${username};
grant create view to ${username};
grant ctxapp to ${username};
grant execute on ctx_ddl to ${username};
grant create procedure to ${username};
grant execute any procedure to ${username};
grant create public synonym, drop public synonym to ${username};
grant create synonym to ${username};
spool off
bk
cat /home/oracle/local/dba/scripts/logs/CreateBlankUser_${username}.out |/bin/mail -s "Blank User ${username} created on Saba Meeting DB $sid...Please check if any Concern" ${MAILTO}
print "\t\t**********USER CREATED SUCCESSFULLY***********\n\n"
exit 0
