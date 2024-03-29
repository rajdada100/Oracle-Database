#!/bin/ksh
# ********************************************************************************************
# NAME:         CheckTablespace.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This Utility will the the utilization of tablespace reached to the threshold which 90%.
#               If the Tablespace utilization reached to 90% it will send the alert.
#
# USAGE:        CheckTablespace.sh
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

        print "${PROGRAM_NAME} \n     Machine: $BOX " > mail.dat
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n\n\n" >> mail.dat
        fi

        cat $HOME/local/dba/scripts/logs/tablespace.log >> mail.dat
        cat mail.dat | /bin/mail -s "Tablespace Usage Exceeded the Threshold -- on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        return 0
}

# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
funct_db_online_verify(){
 # Uncomment next line for debugging
 set -x

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
set -x
clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
#export MAILTO='bkhan@saba.com'
MAILTO=CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com
#export MAILTO='makhtar@saba.com'
#export MAILTO='zsaudagar@saba.com'

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

 ps -ef | grep ora_pmon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}' > $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
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

#Query modified by Brij Lal Kapoor (BLK) -- 2-Nov-2020
$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF >> $HOME/local/dba/scripts/logs/tablespace.log
WHENEVER SQLERROR EXIT FAILURE
set feed off
set linesize 100
set pagesize 200
column Tablespace format a25
column FreeSpc format 999999999 heading "Free|Space(MB)"
column Tot_Size format 999999999 heading "Total|Allocated(MB)"
column Free_Spc_%age format 99999 heading "Free|Space%"
column DBFs format 99999 heading "Num|DBFs"
set pages 5000
select a.tablespace_name Tablespace,
sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024 FreeSpc,
sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0)))/1024/1024 Tot_Size,
round((sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0))))/(sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0))))*100,2) "Free_Spc_%age",
Count(a.file_name) DBFs
from dba_data_files a,
     (select b.tablespace_name, b.file_id, sum(nvl(a.bytes,0)) bytes
        from dba_free_space a, dba_data_files b
        where a.tablespace_name(+)=b.tablespace_name
        and b.file_id=a.file_id(+)
        group by b.tablespace_name, b.file_id) b
where a.tablespace_name=b.tablespace_name
and a.file_id=b.file_id
and a.bytes>0
group by a.tablespace_name
having round((sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0))))/(sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0))))*100,2) <2
minus
select a.tablespace_name Tablespace,
sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024 FreeSpc,
sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0)))/1024/1024 Tot_Size,
round((sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0))))/(sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0))))*100,2) "Free_Spc_%age",
Count(a.file_name) DBFs
from dba_data_files a,
     (select b.tablespace_name, b.file_id, sum(nvl(a.bytes,0)) bytes
        from dba_free_space a, dba_data_files b
        where a.tablespace_name(+)=b.tablespace_name
        and b.file_id=a.file_id(+)
        group by b.tablespace_name, b.file_id) b
where a.tablespace_name=b.tablespace_name
and a.file_id=b.file_id
and a.bytes>0
group by a.tablespace_name
having round((sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0))))/(sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0),nvl(a.bytes,0))))*100,2) <2
and sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024/1024 >20
order by tablespace;
EOF

if [[ -s $HOME/local/dba/scripts/logs/tablespace.log ]]; then
SendNotification
fi
rm -f $HOME/local/dba/scripts/logs/tablespace.log
done

rm -f $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt
fi

exit

