#!/bin/ksh
# ********************************************************************************************
# NAME:         CheckTablespace_And_AddDatafiles.sh
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
#
# *********************************************************************************************
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
function SendNotification {

        # Uncomment for debug
         set -x


                cat $LOGFILE >> mail.dat


        cat mail.dat | /bin/mail -s "PROBLEM WITH  Environment -- $PROGRAM_NAME on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        return 0
}

# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
function funct_db_online_verify
{
 # Uncomment next line for debugging
 set -x

 ps -ef | grep ora_pmon_${ORACLE_SID} | grep -v grep > /dev/null
 if [ $? -ne 0 ]
 then
  print "Database $ORACLE_SID is not running.  Cannot perform CheckSessionProcess.sh"
  SendNotification "Database $ORACLE_SID is not running. $PROGRAM_NAME cannot run "
  export PROCESS_STATUS=FAILURE
  exit 3
 fi
}

function get_standby_max_seq
{
set -x
export HAMAXSEQ=`$ORACLE_HOME/bin/sqlplus -s sys/sabadba4you@$HAHOST:$HAPORT/$HADB as sysdba<<EOF
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
select max(sequence#)  from v\\$archived_log where applied='YES' group by thread#;
EOF`
 if [ $? -ne 0 ]
 then
  print "Unable to get the HA max sequence numr for $ORACLE_SID. Please check">> $LOGFILE
  SendNotification
 fi
export HAMAXSEQ=`print $HAMAXSEQ|tr -d " "`
}

function get_prod_max_seq
{
set -x
export PRODMAXSEQ=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<EOF
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
select thread#, max(sequence#) from v\\$archived_log where thread#=1 group by thread#;
EOF`
 if [ $? -ne 0 ]
  then
  print "Unable to get the Prod max sequence numr for $ORACLE_SID. Please check">> $LOGFILE
  SendNotification
 fi
export PRODMAXSEQ=`print $PRODMAXSEQ|tr -d " "`
}


function check_prod_ha_parameters_setting
{
set -x
export STBYFILEMGMT=`$ORACLE_HOME/bin/sqlplus -s sys/sabadba4you@$HAHOST:$HAPORT/$HADB as sysdba<<EOF
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
select value from v\\$parameter where NAME='standby_file_management';
EOF`
 if [ $? -ne 0 ]
 then
  print "unable to check Standby_file_management on $HADB. Please check">> $LOGFILE
  SendNotification
 fi
export STBYFILEMGMT=`print $STBYFILEMGMT|tr -d " "`

 if [ "$STBYFILEMGMT" != "AUTO" ]
 then
  print "Standby_file_management is not set to AUTO on $HADB hence can not add datafiles. Please check">> $LOGFILE
  SendNotification
  exit
 fi


$ORACLE_HOME/bin/sqlplus -s '/as sysdba' <<EOF>$LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB.txt
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
select distinct substr(file_name,1,instr(file_name,'/',1,2))
from dba_data_files
group by substr(file_name,1,instr(file_name,'/',1,2));
EOF
 if [ $? -ne 0 ]
  then
  print "Unable to get the Prod filesystem details for $ORACLE_SID. Please check">> $LOGFILE
  SendNotification
  exit
 fi

cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB.txt|sed '/^$/d'> $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB_new.txt
#sed -i '/^$/d' $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB.txt > $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB_new.txt
#rm $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB.txt

$ORACLE_HOME/bin/sqlplus -s sys/sabadba4you@$HAHOST:$HAPORT/$HADB as sysdba<<EOF>$LOGLOCATION/${PROGRAM_NAME}_${REFID}_DBFILENAMECONVERT.txt
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
col value for a300
select value from v\$parameter where NAME='db_file_name_convert';
EOF
 if [ $? -ne 0 ]
 then
  print "unable to check db_file_name_convert on $HADB. Please check">> $LOGFILE
  SendNotification
  exit
 fi


cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB_new.txt|while read LINE
do
export GETDBFILENAMECONVERTCOUNT=`grep $LINE $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DBFILENAMECONVERT.txt|wc -l`
if [ $GETDBFILENAMECONVERTCOUNT -lt 1 ]
 then
  print "db_file_name_convert is not setup on $HADB. Please check">> $LOGFILE
  SendNotification
  exit
 fi
done


$ORACLE_HOME/bin/sqlplus -s sys/sabadba4you@$HAHOST:$HAPORT/$HADB as sysdba<<EOF>$LOGLOCATION/${PROGRAM_NAME}_${REFID}_LOGFILENAMECONVERT.txt
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
col value for a300
select value from v\$parameter where NAME='log_file_name_convert';
EOF
 if [ $? -ne 0 ]
 then
  print "unable to check log_file_name_convert on $HADB. Please check">> $LOGFILE
  SendNotification
  exit
 fi


cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB_new.txt|while read LINE
do
export GETLOGFILENAMECONVERTCOUNT=`grep $LINE $LOGLOCATION/${PROGRAM_NAME}_${REFID}_LOGFILENAMECONVERT.txt|wc -l`
if [ $GETLOGFILENAMECONVERTCOUNT -lt 1 ]
 then
  print "log_file_name_convert is not setup on $HADB. Please check">> $LOGFILE
  SendNotification
  exit
 fi
done

#rm $LOGLOCATION/${PROGRAM_NAME}_${REFID}_FILESYSTEM_USED_BU_DB_new.txt

}





function check_ha_db
{
set -x

export HATNSCOUNT=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
col VALUE for a160
select count(value) from v\\$parameter where value like '%service=%' and rownum=1;
exit;
!`
if [ $? -ne 0 ]
then
 export PROCESS_STATUS=FAILURE
 export MSG="Not able to fetch DB archive Location  ${ORACLE_SID} : server $BOX."
 print "PROCESS_STATUS=$PROCESS_STATUS" >  $LOGFILE
 print "MSG=$MSG" >> $LOGFILE
exit 3
fi

export HATNSCOUNT=`print $HATNSCOUNT|tr -d " "`

if [ $HATNSCOUNT -ne 0 ]
then

export HATNS=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set linesize 150 pages 0 echo off feedback off verify off heading off
col VALUE for a160
select value from v\\$parameter where value like '%service=%' and rownum=1;
exit;
!`
if [ $? -ne 0 ]
then
 export PROCESS_STATUS=FAILURE
 export MSG="Not able to fetch DB archive Location  ${ORACLE_SID} : server $BOX."
 print "PROCESS_STATUS=$PROCESS_STATUS" >  $LOGFILE
 print "MSG=$MSG" >> $LOGFILE
exit 3
fi

if [ $HATNSCOUNT -gt 0 ]
        then

        export HATNS=`print $HATNS|awk '{print $1}'|awk -F\= '{print $2}'|tr -d " "`
        export HAHOST=`tnsping $HATNS|grep HOST|awk -F\HOST '{print $2}'|awk  '{print $2}'|awk -F\) '{print $1}'|tr -d " "`
        export HAPORT=`tnsping $HATNS|grep PORT|awk -F\PORT '{print $2}'|awk  '{print $2}'|awk -F\) '{print $1}'|tr -d " "`
        export HADB=`tnsping $HATNS|grep SERVICE_NAME|awk -F\SERVICE_NAME '{print $2}'|awk  '{print $2}'|awk -F\) '{print $1}'|tr -d " "`

get_prod_max_seq
get_standby_max_seq
fi
export SYNCGAP="$(($HAMAXSEQ - $HAMAXSEQ))"
if [ $SYNCGAP -ge 6 ]
then
print "Can not add datafile in $ORACLE_SID as it's HA on $HAHOST:$HAPORT/$HADB is $SYNCGAP archive behind" >> $LOGFILE
SendNotification
fi

#all logic here

check_prod_ha_parameters_setting


#else
#print "HA is not configured for $ORACLE_SID." >>  $LOGFILE
fi
}

function add_into_single_filesystem
{
set -x
export CHECKMOUNTSIZE=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL.txt|tr -d " "`
df "/${CHECKMOUNTSIZE}/" |grep "/${CHECKMOUNTSIZE}" >$LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL_DF.txt
#---used filesystem
export CHECKMOUNTSIZE=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL_DF.txt |grep %|grep -v Avail|awk '{print $(NF-3),"\t",$NF}' |awk '{print $1}'|awk -F\G '{print $1}'`
#---Total filesystem
export CHECKMOUNTSIZETOT=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL_DF.txt |grep %|grep -v Avail|awk '{print $(NF-4),"\t",$NF}' |awk '{print $1}'|awk -F\G '{print $1}'`
#---Available space in filesystem
export AVAILABLESPACE=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL_DF.txt |grep %|grep -v Avail|awk '{print $(NF-2),"\t",$NF}' |awk '{print $1}'|awk -F\G '{print $1}'`
#---used filesystem MB
export CHECKMOUNTSIZE=$(($CHECKMOUNTSIZE / 1024))
#---Total filesystem MB
export CHECKMOUNTSIZETOT=$(($CHECKMOUNTSIZETOT / 1024))
#--Available space in filesystem in MB
export AVAILABLESPACE=$(($AVAILABLESPACE / 1024 /1024))
export REQUIREDSPACE=300

        if [ $AVAILABLESPACE -lt $REQUIREDSPACE ]
        then
        export PROCESS_STATUS=FAILURE
        export MSG="Cant't Add datafile to  DB ${ORACLE_SID} : $BOX for target due to less required Space available."
         print "PROCESS_STATUS=$PROCESS_STATUS" >  $LOGFILE
         print "MSG=$MSG" >> $LOGFILE

        exit 2
        fi


export DATAFILELOCATION=`$ORACLE_HOME/bin/sqlplus -s -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off
set feedback off
set echo off
select file_name from dba_data_files where rownum=1;
exit;
EOF`

export DATAFILELOCATION=$(print $DATAFILELOCATION|tr -d " ")
export DATAFILELOCATION=`dirname $DATAFILELOCATION`
export DFLOCATION=$DATAFILELOCATION


export i=1

while [ $i -le $NOOFFILES ]
do
FILECOUNTER=$(( $FILECOUNTER+1 ))

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off
set feedback off
set echo off
alter tablespace ${TABLESPACE_NAME} add datafile '$DFLOCATION/${DATAFILESTD}_00${FILECOUNTER}.dbf' size 100m autoextend on next 100m maxsize 20g;
exit;
EOF

i=$(( $i+1 ))

done
}

function add_into_multiple_filesystem
{
set -x
export REFIDNEW=`date +'%Y%m%d_%H%M%S'`
cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL.txt|while read LINE
do
 df "/${LINE}/" |grep "/${LINE}" >> $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEM_DF.txt
 cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEM_DF.txt |grep "/${LINE}" |grep %|grep -v Avail|awk '{print $(NF-3),"\t",$NF}' >> $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEM.txt
 cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEM_DF.txt |grep %|grep -v Avail|awk '{print $(NF-4),"\t",$NF}' >> $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEMTOT.txt
done


cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEM.txt|sort -k 2|head -2 > $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM.txt
cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_FILESYSTEMTOT.txt|sort -k 2|head -2 > $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEMTOT.txt
cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM.txt |awk '{print $2}' > $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_LOC.txt
cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM.txt |awk '{print $1}' > $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_SIZE.txt
cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEMTOT.txt |awk '{print $1}' > $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_TOTSIZE.txt

export CHECKMOUNTSIZE1=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_SIZE.txt|head -1|awk -F\G '{print $1}'`
export CHECKMOUNTSIZE1=$(($CHECKMOUNTSIZE1 / 1024))
export CHECKMOUNTSIZETOT1=`cat $LOGLOCATION//${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_TOTSIZE.txt|head -1|awk -F\G '{print $1}'`
export CHECKMOUNTSIZETOT1=$(($CHECKMOUNTSIZETOT1 / 1024))

export CHECKMOUNTSIZE2=`cat $LOGLOCATION//${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_SIZE.txt|tail -1|awk -F\G '{print $1}'`
export CHECKMOUNTSIZE2=$(($CHECKMOUNTSIZE2 / 1024))
export CHECKMOUNTSIZETOT2=`cat $LOGLOCATION//${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_TOTSIZE.txt|tail -1|awk -F\G '{print $1}'`
export CHECKMOUNTSIZETOT2=$(($CHECKMOUNTSIZETOT2 / 1024))

export DATAFILELOCATION1=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_LOC.txt|head -1|tr -d " "`
export DATAFILELOCATION2=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFIDNEW}_MAX_FILESYSTEM_LOC.txt|tail -1|tr -d " "`
export REQUIREDSPACE=300

export i=1
while [ $i -lt $NOOFFILES ]
do
FILECOUNTER=$(( $FILECOUNTER+1 ))

        if [ $CHECKMOUNTSIZE1 -lt $REQUIREDSPACE ]
        then
        export PROCESS_STATUS=FAILURE
        export MSG="Problem while adding datafile on DB ${ORACLE_SID} : $BOX for target."
        print "PROCESS_STATUS=$PROCESS_STATUS" >  $LOGFILE
        print "MSG=$MSG" >>  $LOGFILE

        else

export DFLOCATION1=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
        WHENEVER SQLERROR EXIT FAILURE
        set heading off
        set feedback off
        set echo off
        select file_name from dba_data_files where file_name like '%$DATAFILELOCATION1%' and rownum=1;
        exit;
EOF`

        export DFLOCATION1=$(print $DFLOCATION1|tr -d " ")
        export DFLOCATION1=`dirname $DFLOCATION1`

        $ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
        WHENEVER SQLERROR EXIT FAILURE
        set heading off
        set feedback off
        set echo off
        alter tablespace ${TABLESPACE_NAME} add datafile '$DFLOCATION1/${DATAFILESTD}_${FILECOUNTER}.dbf' size 100m autoextend on next 100m maxsize 20g;
        exit;
EOF
        fi

#        if [ $i -eq 3 ] && [$NOOFFILES = 3]
#        then
#        export PROCESS_STATUS=SUCCESS
#        export MSG="$NOOFFILES datafiles added successfully  on DB ${ORACLE_SID} : $BOX for target."
#        print "PROCESS_STATUS=$PROCESS_STATUS" >>  $LOGFILE
#        print "$MSG" >>  $LOGFILE
#
#       fi

FILECOUNTER=$(( $FILECOUNTER+1 ))

        if [ $CHECKMOUNTSIZE2 -lt $REQUIREDSPACE ]
        then
        export PROCESS_STATUS=FAILURE
        export MSG="Problem while adding datafile on DB ${ORACLE_SID} : $BOX for target."
        print "PROCESS_STATUS=$PROCESS_STATUS" >>  $LOGFILE
        print "MSG=$MSG" >>  $LOGFILE

         else

export DFLOCATION2=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
        WHENEVER SQLERROR EXIT FAILURE
        set heading off
        set feedback off
        set echo off
        select file_name from dba_data_files where file_name like '%$DATAFILELOCATION2%' and rownum=1;
EOF`

export DFLOCATION2=$(print $DFLOCATION2|tr -d " ")
        export DFLOCATION2=`dirname $DFLOCATION2`
        $ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
        WHENEVER SQLERROR EXIT FAILURE
        set heading off
        set feedback off
        set echo off
        alter tablespace ${TABLESPACE_NAME} add datafile '$DFLOCATION2/${DATAFILESTD}_${FILECOUNTER}.dbf' size 100m autoextend on next 100m maxsize 20g;
EOF
        fi
i=$(( $i+1 ))
done
}

############################################################
#                     MAIN
############################################################
#uncomment the below line to debug
set -x
clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export CDATE=`date +'%Y%m%d_%H%M%S'`
export REFID=$CDATE
export PROGRAM_NAME_FIRST=$(print $PROGRAM_NAME | awk -F "." '{print $1}')
export LOGFILE=$HOME/local/dba/scripts/logs/${PROGRAM_NAME_FIRST}_${CDATE}_LOG.log
export LOGLOCATION=$HOME/local/dba/scripts/logs
#export MAILTO='bkhan@csod.com'
export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com'
#export MAILTO='makhtar@csod.com'
#export MAILTO='zsaudagar@csod.com'
export CURDATE=$(date +'%Y%m%d')

print "${PROGRAM_NAME} \n\n     Machine: $BOX \n" > $LOGFILE
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n\n\n" >> $LOGFILE
        fi


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
if [ -s $HOME/local/dba/scripts/logs/sid_sess_list_for_ct.txt ]
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

if [ "$RW_CHK" == "$RW_CHK2" ]
then
check_ha_db
$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF>>$HOME/local/dba/scripts/logs/tablespace_${REFID}.log
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
having  sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024/1024 <20
order by tablespace;
EOF
fi

if [[ -s $HOME/local/dba/scripts/logs/tablespace_$REFID.log ]]
then
print "List of talespace found less than 20GB on DB $ORACLE_SID is attached:\n\n">> $LOGFILE

#=========================Just html result =================================

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
set markup HTML ON HEAD "<style type='text/css'> -
body { -
font:10pt Arial,Helvetica,sans-serif; -
color:blue; background:white; } -
p { -
font:8pt Arial,sans-serif; -
color:grey; background:white; } -
table,tr,td { -
font:10pt Arial,Helvetica,sans-serif; -
text-align:center; -
color:Black; background:white; -
padding:0px 0px 0px 0px; margin:0px 0px 0px 0px; } -
th { -
font:bold 10pt Arial,Helvetica,sans-serif; -
color:#336699; -
background:#cccc99; -
padding:0px 0px 0px 0px;} -
h1 { -
font:16pt Arial,Helvetica,Geneva,sans-serif; -
color:#336699; -
background-color:White; -
border-bottom:1px solid #cccc99; -
margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} -
h2 { -
font:bold 12pt Arial,Helvetica,Geneva,sans-serif; -
color:#336699; -
background-color:#d4f3ff; -
margin-top:4pt; margin-bottom:0pt;} -
a { -
font:9pt Arial,Helvetica,sans-serif; -
color:#663300; -
background:#ffffff; -
margin-top:0pt; margin-bottom:0pt; vertical-align:top;} -
.threshold-critical { -
font:bold 10pt Arial,Helvetica,sans-serif; -
color:red; } -
.threshold-warning { -
font:bold 10pt Arial,Helvetica,sans-serif; -
color:orange; } -
.threshold-ok { -
font:bold 10pt Arial,Helvetica,sans-serif; -
color:green; } -
</style> -
<title>SQL*Plus Report</title>" -
BODY "" -
TABLE "border='1' width='90%' align='center'" -
ENTMAP OFF SPOOL ON
spool $HOME/local/dba/scripts/logs/tablespace_${REFID}_${ORACLE_SID}_just.html
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
having  sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024/1024 <20
order by tablespace;
spool off
EOF


#=========================End of html result ===============================

#cat $HOME/local/dba/scripts/logs/tablespace_${REFID}_just.html >> $LOGFILE

print  "Below are the Summary of space addtion report on $ORACLE_SID:\n">> $LOGFILE
print "===\n\n">> $LOGFILE
$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF>>$HOME/local/dba/scripts/logs/just_tablespace_list_$REFID.log
        WHENEVER SQLERROR EXIT FAILURE
        set heading off;
        set feedback off;
        select a.tablespace_name
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
        having  sum(decode(a.autoextensible,'YES',nvl(a.maxbytes,0)-nvl(a.bytes,0)+nvl(b.bytes,0),nvl(b.bytes,0)))/1024/1024/1024 <20
        order by a.tablespace_name;
EOF
fi

sed  '/^$/d' $HOME/local/dba/scripts/logs/just_tablespace_list_$REFID.log > $HOME/local/dba/scripts/logs/just_tablespace_list_new_$REFID.log
rm $HOME/local/dba/scripts/logs/just_tablespace_list_$REFID.log


        cat $HOME/local/dba/scripts/logs/just_tablespace_list_new_$REFID.log | while read LINE
        do
export TABLESPACE_NAME=`print $LINE|tr -d " "`

export SCHEMAOWNER=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
        WHENEVER SQLERROR EXIT FAILURE
        set heading off;
        set feedback off;
        select distinct owner from dba_segments where tablespace_name='${TABLESPACE_NAME}' and owner not in('OUTLN','DIP','ORACLE_OCM','DBSNMP','APPQOSSYS','WMSYS','EXFSYS','CTXSYS','ANONYMOUS','XDB','XS$NULL','SI_INFORMTN_SCHEMA','MDSYS','ORDDATA','ORDPLUGINS','ORDSYS','OLAPSYS','MDDATA','SPATIAL_CSW_ADMIN_USR','FLOWS_FILES', 'APEX_030200','APEX_PUBLIC_USER','OWBSYS','OWBSYS_AUDIT','SYSDG','SYSBACKUP','SYSKM','GSMADMIN_INTERNAL','SYSRAC','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYS$UMF','GSMCATUSER','GGSYS','OJVMSYS','SABAEXPIMP','DVSYS' ,'AUDSYS');
EOF`
export SCHEMAOWNER=`print $SCHEMAOWNER|tr -d " "`

export FILECOUNTER=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off;
set feedback off;
select count(1) from dba_Data_files where tablespace_name='${TABLESPACE_NAME}';
EOF`
export FILECOUNTER=`print $FILECOUNTER|tr -d " "`

export DATAFILESTD=`print $TABLESPACE_NAME|awk -F\_ '{print $1}'`

export SCHEMASIZE=`$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF
WHENEVER SQLERROR EXIT FAILURE
set heading off;
set feedback off;
select  round( sum(bytes)/1024/1024/1024) from dba_segments where owner='$SCHEMAOWNER';
EOF`
export SCHEMASIZE=`print $SCHEMASIZE|tr -d " "`

        if [ $SCHEMASIZE -le 500 ]
        then
                export NOOFFILES=2
        fi
        if [ $SCHEMASIZE -gt 500 ] && [ $SCHEMASIZE -le 1000 ]
        then
                export NOOFFILES=3
        fi
        if [ $SCHEMASIZE -gt 1000 ]
        then
                export NOOFFILES=4
        fi


$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF >$LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE.txt
WHENEVER SQLERROR EXIT FAILURE
set pages 5000
set heading off
set feedback off
select file_name from dba_data_files;
EOF

cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE.txt |awk -F\/ '{print $2}' |sed '/^$/d'|sort -u >$LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL.txt
export MOUNTCOUNT=`cat $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE_FINAL.txt|wc -l|tr -d " "`

rm $LOGLOCATION/${PROGRAM_NAME}_${REFID}_DATAFILE.txt


if [ $MOUNTCOUNT -eq 1 ]
then
add_into_single_filesystem
fi

if [ $MOUNTCOUNT -gt 1 ]
then
add_into_multiple_filesystem
fi


#export PROCESS_STATUS=SUCCESS
export MSG="$NOOFFILES datafiles added successfully  on DB ${ORACLE_SID} to Tablespace $TABLESPACE_NAME : $BOX for target."
#print "PROCESS_STATUS=$PROCESS_STATUS" >>  $LOGFILE
print "$MSG\n" >>  $LOGFILE

     done

print "===\n">>$LOGFILE

done

#print "===">>$LOGFILE

ls $HOME/local/dba/scripts/logs/tablespace_${REFID}_*_just.html|sed  '/^$/d' > $HOME/local/dba/scripts/logs/html_attachment_${REFID}.txt

cat $HOME/local/dba/scripts/logs/html_attachment_${REFID}.txt|while read LINE
do
export ATTACH=`echo $ATTACH -a $LINE`
done


if [[ -s $HOME/local/dba/scripts/logs/just_tablespace_list_new_$REFID.log ]]
then
cat $LOGFILE | /bin/mail -s "Tablespace Proactive space addition Report  -- on ${BOX}"   $ATTACH  ${MAILTO}
fi

fi
rm $HOME/local/dba/scripts/logs/tablespace_${REFID}_*_just.html $HOME/local/dba/scripts/logs/html_attachment_${REFID}.txt
exit 0
