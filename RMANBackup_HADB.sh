#!/bin/ksh
# ********************************************************************************************
# NAME:         RMANBackup_HADB.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This utility will perform a RMAN backup of the specified database to execute from HA DB Server. It will also check archive log gap.
#
# USAGE:        RMANBackup_HADB.sh SID [INCREMENTAL] [LEVEL]
#
# INPUT PARAMETERS:
#               SID   ->   Oracle SID of database to backup
#               INCREMENTAL -> Specifies that this backup is INCREMENTAL
#               LEVEL  -> 0 or 1 - To execute Level 0 or Level 1 INCREMENTAL RMAN backup
# *********************************************************************************************
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
function SendNotification {

        # Uncomment for debug
        set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX " > mail.dat
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n" >> mail.dat
        fi

        if [[ -a ${ERROR_FILE} ]]; then
                cat $ERROR_FILE >> mail.dat
                rm ${ERROR_FILE}
        fi

        if [[ $2 = 'FATAL' ]]; then
                print "*** This is a FATAL ERROR - ${PROGRAM_NAME} aborted at this point *** " >> mail.dat
        fi

        if [[ -s $HOME/local/dba/backups/rman/check_multi_runs.txt ]]; then
           cat $HOME/local/dba/backups/rman/check_multi_runs.txt >> mail.dat
           rm $HOME/local/dba/backups/rman/check_multi_runs.txt
        fi

        if [[ -s $HOME/local/dba/backups/rman/level_0_chk.txt ]]; then
           cat $HOME/local/dba/backups/rman/level_0_chk.txt >> mail.dat
           rm $HOME/local/dba/backups/rman/level_0_chk.txt
        fi

        cat mail.dat | /bin/mail -s "PROBLEM WITH  Environment -- ${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        rm mail.dat

        # Update the mail counter
        MAIL_COUNT=${MAIL_COUNT}+1

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
        print "HA Database $ORACLE_SID is not running. Cannot perform RMAN Backup"
        SendNotification "$ORACLE_SID HA Database is not running on ${BOX}. $PROGRAM_NAME cannot run."
        export PROCESS_STATUS=FAILURE
        exit 15
 fi
}

# --------------------------------------------------------------------------------------------------------------
# funct_chk_bkup_dir(): Make sure backup directory is mounted and create backup directory if it doesn't exist
# --------------------------------------------------------------------------------------------------------------
funct_chk_bkup_dir() {
# Uncomment next line for debugging
set -x

DD_MOUNTED=$(/bin/mount | grep $BACKUP_MOUNT)
DD_MOUNTED=$(print $DD_MOUNTED | tr -d " ")
if [[ x$DD_MOUNTED = 'x' ]]; then
export MAILTO='CloudOps-DBA@csod.com'
#export MAILTO='nmalwade@csod.com'
        SendNotification "$PROGRAM_NAME can not run because $BACKUP_MOUNT is not mounted on ${BOX}"
        export PROCESS_STATUS=FAILURE
        exit 16
fi

mkdir -p $BACKUP_LOC
if [ $? -ne 0 ]
    then
                SendNotification "$PROGRAM_NAME failed for $ORACLE_SID HA DB because program could not create directory $BACKUP_LOC on ${BOX}"
                export PROCESS_STATUS=FAILURE
                exit 17
        fi
}

# ----------------------------------------------------------------------------------
# Below Functions are added to validate the HA DB are in sync with primary database.
# ----------------------------------------------------------------------------------
# ------------------------------------------------------------------
# recovery_proc_chk(): Check MRP process is running on HA DB or not
# ------------------------------------------------------------------
function recovery_proc_chk
{
set -x
RECOVER_PROC_CHK=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn $DB_OWNER/$DB_OWNER_PASSWD@${FAL_CLIENT} as sysdba
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select count(*) from v\\$managed_standby where process='MRP0';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        RECOVER_PROC_CHK=`echo $RECOVER_PROC_CHK | sed 's/ //g'`
 fi
 return 0
}

# ------------------------------------------------------------------------
# get_fal_server_details(): Get the FAL_SERVER parameter value from HA DB
# ------------------------------------------------------------------------
function get_fal_server_details
{
set -x
FAL_SERVER=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn / as sysdba
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select value from v\\$parameter where name='fal_server';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        FAL_SERVER=`echo $FAL_SERVER | awk -F, '{print $1}' | sed 's/ //g'`
 fi
 return 0
}

# ------------------------------------------------------------------------
# get_fal_client_details(): Get the FAL_CLIENT parameter value from HA DB
# ------------------------------------------------------------------------
function get_fal_client_details
{
set -x
FAL_CLIENT=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn / as sysdba
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select value from v\\$parameter where name='fal_client';
EOF`
 if [ $? -ne 0 ]
 then
  return 1
 else
        FAL_CLIENT=`echo $FAL_CLIENT | awk -F, '{print $1}' | sed 's/ //g'`
 fi
 return 0
}

# -----------------------------------------------------------------
# get_standby_max_seq(): Get the max_sequence apllied on standby DB
# -----------------------------------------------------------------
function get_standby_max_seq
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${GAP_CHK_DR}
conn sabaadmin/dba4you@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select thread#, max(sequence#) apl_max_seq from v\$archived_log where applied='YES' group by thread#;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}

# -----------------------------------------------------------------
# get_prod_max_seq(): Get the max_sequence generated on prod DB
# -----------------------------------------------------------------
function get_prod_max_seq
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${GAP_CHK_PRD}
conn sabaadmin/dba4you@${FAL_SERVER}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select thread#, max(sequence#) from v\$archived_log where thread#=$1 group by thread#;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}

# ---------------------------------------------------------------------
# get_active_standby_realtime_sync_status(): new function added by brij
# ---------------------------------------------------------------------
function get_active_standby_realtime_sync_status
{
set -x
BLK=`$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn sabaadmin/dba4you@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select count(*) FROM V\\$DATAGUARD_STATS WHERE name like 'apply lag' and (value is null or value not like '+00 00:0%') ;
EOF`

if [ $BLK -ne 0 ] ; then
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF
conn sabaadmin/dba4you@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 10 sqlp "" trim on trims on lines 450
select name,value, TIME_COMPUTED, DATUM_TIME from v\$DATAGUARD_STATS WHERE name like 'apply lag' ;
EOF
 BLK_COUNTER=`expr ${BLK_COUNTER} + 1`
 echo ${BLK_COUNTER}>${BLK_COUNTER_CHK}
else
 echo 0 >${BLK_COUNTER_CHK}
fi
return 0
}

# ---------------------------------------------------------------------
# get_standby_sync(): To validte the real time sync from standby DB
# ---------------------------------------------------------------------
function get_standby_sync
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${SYNC_CHK_DR}
conn sabaadmin/dba4you@${FAL_CLIENT}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select to_char(scn_to_timestamp(current_scn),'dd:mm:rrrr:hh24:mi') date_time from v\$database;
EOF
 if [ $? -ne 0 ] ; then
  return 1
 else
        dayp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $1}'`
        monp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $2}'`
        yyyp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $3}'`
        hrsp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $4}'`
        minp=`cat ${SYNC_CHK_PRD} | awk -F: '{print $5}'`

        days=`cat ${SYNC_CHK_DR} | awk -F: '{print $1}'`
        mons=`cat ${SYNC_CHK_DR} | awk -F: '{print $2}'`
        yyys=`cat ${SYNC_CHK_DR} | awk -F: '{print $3}'`
        hrss=`cat ${SYNC_CHK_DR} | awk -F: '{print $4}'`
        mins=`cat ${SYNC_CHK_DR} | awk -F: '{print $5}'`

 if [[ $dayp -ne $days && $monp -ne $mons && $yyyp -ne $yyys && $hrsp -ne $hrss && $minp -ne $mins ]] ; then
        BLK_COUNTER=`expr ${BLK_COUNTER} + 1`
        echo ${BLK_COUNTER}>${BLK_COUNTER_CHK}
 else
        echo 0 >${BLK_COUNTER_CHK}
 fi
 fi
 return 0
}

# ------------------------------------------------------------
# get_prod_sync(): To validte the real time sync from Prod DB
# ------------------------------------------------------------
function get_prod_sync
{
set -x
$ORACLE_HOME/bin/sqlplus -s "/nolog"<<EOF >${SYNC_CHK_PRD}
conn sabaadmin/dba4you@${FAL_SERVER}
WHENEVER SQLERROR EXIT FAILURE
set echo off veri off feed off pages 0 sqlp "" trim on trims on lines 80
select to_char(scn_to_timestamp(current_scn),'dd:mm:rrrr:hh24:mi') date_time from v\$database;
EOF
 if [ $? -ne 0 ]
 then
  return 1
 fi
 return 0
}
# ------------------------------------------------
# HA DB Sync check function declaration ends here.
# ------------------------------------------------
# -------------------------------------------------
# funct_logmode_check(): Check DB Archive log mode
# -------------------------------------------------
#funct_logmode_check(){
#
#        # Uncomment next line for debugging
#         set -x
#
#        STATUS=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
#                set heading off
#                set feedback off
#                select log_mode from v\\$database;
#                quit
#EOF`
#
#        if [ ! $STATUS = "ARCHIVELOG" ]; then
#                print "${PROGRAM_NAME} required database to be in ARCHIVELOG mode -- $ORACLE_SID can not be backed up"  >>${BACKUPLOGFILE}
#                SendNotification "Database is not in ARCHIVELOG mode -- $ORACLE_SID can not be backed up"
#                export PROCESS_STATUS=FAILURE
#                exit 18
#        fi
#}

# --------------------------------------------------------------------------------------------
# funct_set_retention():  To set the backup file retention in controlfile at primary database
# --------------------------------------------------------------------------------------------
funct_set_retention(){

    # Uncomment next line for debugging
     set -x
        rman target=$DB_OWNER/$DB_OWNER_PASSWD@$FAL_SERVER catalog=$CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<EOF
        ${RETENTION_PERIOD}
        exit
EOF

}

# -----------------------------------------------------------
# funct_switch_logfile():  Switch logile on primary database
# -----------------------------------------------------------
funct_switch_logfile(){

set -x
${ORACLE_HOME}/bin/sqlplus -s $DB_OWNER/$DB_OWNER_PASSWD@$FAL_SERVER as sysdba <<EOF
alter system archive log current;
alter system SWITCH LOGFILE;
exit
EOF

}

# --------------------------------------------
# funct_rman_backup():   Backup database in its entirety
# --------------------------------------------
funct_rman_backup() {
    # Uncomment next line for debugging
      set -x

# Touch a file to be used later to determine which files are part of this backup set
touch ${START_FILE}

# Create the script to run for the RMAN backup

if [ ${NO_CATALOG} = '1' ]; then
    print "connect target $RMAN_TRGT_DB" > $BACKUP_SCRIPT
else
    print "connect catalog $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB" > $BACKUP_SCRIPT
    print "connect target $RMAN_TRGT_DB" >> $BACKUP_SCRIPT
fi


#print "$RETENTION_PERIOD"     >>$BACKUP_SCRIPT
print "$CTRL_AUTO_BKP_FORMAT" >>$BACKUP_SCRIPT
print "$CTRL_SNAPSHOT"        >>$BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   CROSSCHECK ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "run {" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "   CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 1;" >> $BACKUP_SCRIPT

typeset -i i=1
while [ ${i} -le ${NUM_CHANNELS} ]
do
    print "   ALLOCATE CHANNEL d${i} DEVICE TYPE DISK;" >> $BACKUP_SCRIPT
    i=${i}+1;
done

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/df_${BACKUP_TAG}_%U_full_dbf' " >> $BACKUP_SCRIPT
print "   DATABASE FILESPERSET 1 ;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   sql \"alter system SWITCH LOGFILE\";" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/al_${BACKUP_TAG}_%U_full_archive'" >> $BACKUP_SCRIPT
print "   ARCHIVELOG ALL NOT BACKED UP 1 TIMES ;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "  FORMAT '$BACKUP_LOC/cf_${BACKUP_TAG}_%U_full_ctrl'" >> $BACKUP_SCRIPT
print "   CURRENT CONTROLFILE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   report schema;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

typeset -i j=1
while [ ${j} -le ${NUM_CHANNELS} ]
do
    print "   RELEASE CHANNEL d${j};" >> $BACKUP_SCRIPT
    j=${j}+1;
done

print "   CROSSCHECK BACKUP;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT FORCE OBSOLETE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-1';" >> $BACKUP_SCRIPT
print "   DELETE NOPROMPT ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "}" >> $BACKUP_SCRIPT
print "quit" >> $BACKUP_SCRIPT

nohup $ORACLE_HOME/bin/rman >>${BACKUPLOGFILE} 2>&1 <<HOF
    @${BACKUP_SCRIPT}
HOF

process_errors;

}
# --------------------------------------------
# funct_rman_level_0_backup():   Backup Level 0 Incremental Backup
# --------------------------------------------
funct_rman_level_0_backup() {
    # Uncomment next line for debugging
      set -x

# Touch a file to be used later to determine which files are part of this backup set
touch ${START_FILE}

# Create the script to run for the RMAN backup

if [ ${NO_CATALOG} = '1' ]; then
    print "connect target $RMAN_TRGT_DB" > $BACKUP_SCRIPT
else
    print "connect catalog $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB" > $BACKUP_SCRIPT
    print "connect target $RMAN_TRGT_DB" >> $BACKUP_SCRIPT
fi

#print "$RETENTION_PERIOD" >>$BACKUP_SCRIPT
print "$CTRL_AUTO_BKP_FORMAT" >>$BACKUP_SCRIPT
print "$CTRL_SNAPSHOT"        >>$BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   CROSSCHECK ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "run {" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "   CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 1;" >> $BACKUP_SCRIPT

typeset -i i=1
while [ ${i} -le ${NUM_CHANNELS} ]
do
    print "   ALLOCATE CHANNEL d${i} DEVICE TYPE DISK;" >> $BACKUP_SCRIPT
    i=${i}+1;
done

print "   BACKUP INCREMENTAL LEVEL 0 TAG \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/df_${BACKUP_TAG}_%U_level_0_dbf' " >> $BACKUP_SCRIPT
print "   DATABASE FILESPERSET 1;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   sql \"alter system SWITCH LOGFILE\";" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/al_${BACKUP_TAG}_%U_level_0_archive'" >> $BACKUP_SCRIPT
print "   ARCHIVELOG ALL NOT BACKED UP 1 TIMES ;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "  FORMAT '$BACKUP_LOC/cf_${BACKUP_TAG}_%U_full_ctrl'" >> $BACKUP_SCRIPT
print "   CURRENT CONTROLFILE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   report schema;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

typeset -i j=1
while [ ${j} -le ${NUM_CHANNELS} ]
do
    print "   RELEASE CHANNEL d${j};" >> $BACKUP_SCRIPT
    j=${j}+1;
done

print "   CROSSCHECK BACKUP;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT FORCE OBSOLETE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-1';" >> $BACKUP_SCRIPT
print "   DELETE NOPROMPT ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "}" >> $BACKUP_SCRIPT
print "quit" >> $BACKUP_SCRIPT

nohup $ORACLE_HOME/bin/rman >>${BACKUPLOGFILE} 2>&1 <<HOF
    @${BACKUP_SCRIPT}
HOF

process_errors;

}

# --------------------------------------------
# funct_rman_level_1_backup():   Backup Level 1 Incremental Backup
# --------------------------------------------
funct_rman_level_1_backup() {
    # Uncomment next line for debugging
      set -x

# Touch a file to be used later to determine which files are part of this backup set
touch ${START_FILE}

# Create the script to run for the RMAN backup

if [ ${NO_CATALOG} = '1' ]; then
    print "connect target $RMAN_TRGT_DB" > $BACKUP_SCRIPT
else
    print "connect catalog $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB" > $BACKUP_SCRIPT
    print "connect target $RMAN_TRGT_DB" >> $BACKUP_SCRIPT
fi


#print "$RETENTION_PERIOD" >>$BACKUP_SCRIPT
print "$CTRL_AUTO_BKP_FORMAT" >>$BACKUP_SCRIPT
print "$CTRL_SNAPSHOT"        >>$BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   CROSSCHECK ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "run {" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "   CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 1;" >> $BACKUP_SCRIPT

typeset -i i=1
while [ ${i} -le ${NUM_CHANNELS} ]
do
    print "   ALLOCATE CHANNEL d${i} DEVICE TYPE DISK;" >> $BACKUP_SCRIPT
    i=${i}+1;
done

print "   BACKUP INCREMENTAL LEVEL 1 CUMULATIVE TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/df_${BACKUP_TAG}_%U_level_1_dbf' " >> $BACKUP_SCRIPT
print "   DATABASE FILESPERSET 1;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   sql \"alter system SWITCH LOGFILE\";" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_LOC/al_${BACKUP_TAG}_%U_level_1_archive'" >> $BACKUP_SCRIPT
print "   ARCHIVELOG ALL NOT BACKED UP 1 TIMES ;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "  FORMAT '$BACKUP_LOC/cf_${BACKUP_TAG}_%U_full_ctrl'" >> $BACKUP_SCRIPT
print "   CURRENT CONTROLFILE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   report schema;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

typeset -i j=1
while [ ${j} -le ${NUM_CHANNELS} ]
do
    print "   RELEASE CHANNEL d${j};" >> $BACKUP_SCRIPT
    j=${j}+1;
done

print "   CROSSCHECK BACKUP;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

print "   DELETE NOPROMPT FORCE OBSOLETE;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

#print "   DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-1';" >> $BACKUP_SCRIPT
print "   DELETE NOPROMPT ARCHIVELOG ALL;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print "}" >> $BACKUP_SCRIPT
print "quit" >> $BACKUP_SCRIPT

nohup $ORACLE_HOME/bin/rman >>${BACKUPLOGFILE} 2>&1 <<HOF
    @${BACKUP_SCRIPT}
HOF

process_errors;

}
# ------------------------------------------------------
# funct_control_backup():  Backup control file to trace
# -------------------------------------------------------
funct_control_backup(){

    # Uncomment next line for debugging
     set -x

        CONTROLFILE_NAME=${BACKUP_LOC}/${BACKUP_TAG}_CONTROL_FILE.sql;
    STATUS=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
        alter database backup controlfile to trace as '${CONTROLFILE_NAME}';
        exit
EOF`

}

# ---------------------------------------------------------------
# funct_create_restore_log(): Create log with backup information
# ---------------------------------------------------------------
funct_create_restore_log() {

        # Uncomment next line for debugging
         set -x

        # Get the list of datafiles
        print  "\n ------------------------------------------------------------------------------\n " >> ${RESTOREFILE}
        print  "DATAFILES: " >> ${RESTOREFILE}
        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF | tee -a ${RESTOREFILE}
                set heading off
                set feedback off
                set pagesize 500
                select 'DATAFILE |'||file#||' | '||name||' | '||BYTES/1024/1024||'M'
                from V\$DATAFILE;
        quit
EOF

        # Get the number of datafiles
        NUM_DATA_FILES=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
                set heading off
                set feedback off
                select count(*) from V\\$DATAFILE;
        quit
EOF`
        export NUM_DATA_FILES

        # Get the list of Temporary Files
        print  "\n ------------------------------------------------------------------------------\n " >> ${RESTOREFILE}
        print  "Temporary Files: " >> ${RESTOREFILE}
        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<GOF |tee -a ${RESTOREFILE}
                set heading off
                set feedback off
                select 'TEMPFILE |'||file#||' | '||name||' | '||BYTES/1024/1024||'M'
                from V\$TEMPFILE;
                quit
GOF

        # Get the list of redo logs
        print  "\n ------------------------------------------------------------------------------\n " >> ${RESTOREFILE}
        print  "REDO LOGS: " >> ${RESTOREFILE}
        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<BOF | tee -a ${RESTOREFILE}
                set heading off
                set feedback off
                set pagesize 500
        select 'LOGFILE | '||a.group#||' | '||member||' | '||a.bytes/1024/1024||'M' from V\$LOGFILE b , V\$LOG a
                where a.GROUP#=b.GROUP#;
        quit
BOF


        # Get SCN
        print  "\n ------------------------------------------------------------------------------\n " >> ${RESTOREFILE}
        SCN=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
                set heading off
                set feedback off
                select max(next_change#) from V\\$LOG_HISTORY;
                exit
EOF`
        SCN=$(print $SCN|tr -d " ")
        export SCN

print "DBID:  ${DBID}" | tee -a  ${RESTOREFILE}
print "SCN before backup for information purpose only [max(next_change#)]:  ${SCN}" | tee -a  ${RESTOREFILE}
print "This SCN is not required to restore.  The SCN after the backup will be in the restore scripts." | tee -a  ${RESTOREFILE}
print "BACKUP_TAG:  ${BACKUP_TAG}" | tee -a  ${RESTOREFILE}
print "BACKUPDIR:  ${BACKUP_LOC}" | tee -a  ${RESTOREFILE}
}

# ----------------------------------------------------------------------------------------
# funct_create_restore_scripts(): Create scripts to be used to restore a 19c database
# -----------------------------------------------------------------------------------------
funct_create_restore_scripts() {

        # Uncomment next line for debugging
         set -x

        BACKED_UP_CONTROLFILE=$(ls $BACKUP_LOC/cf_${BACKUP_TAG}_*_full_ctrl)

        # Create the controlfile restore script
        print "set dbid ${DBID} " >> ${RESTORE_CONTROLFILE_19c}
        print " " >> ${RESTORE_CONTROLFILE_19c}
        print "run {  " >> ${RESTORE_CONTROLFILE_19c}
        print " set controlfile autobackup format for device type disk to '${BACKUP_LOC}/cf_%F_full_ctrl';  "  >> ${RESTORE_CONTROLFILE_19c}
        print " restore primary controlfile from autobackup maxdays 7; " >> ${RESTORE_CONTROLFILE_19c}
        print " alter database mount; " >> ${RESTORE_CONTROLFILE_19c}
        print "  CONFIGURE CONTROLFILE AUTOBACKUP OFF; " >> ${RESTORE_CONTROLFILE_19c}
        print "}  " >> ${RESTORE_CONTROLFILE_19c}

        # Create the Data/Temp files restore script
        print "run {  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print " allocate channel 'RCHL1' device type disk;  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print " allocate channel 'RCHL2' device type disk;  " >> ${RESTORE_DATA_TEMP_FILES_19c}

    ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF | tee -a ${RESTORE_DATA_TEMP_FILES_19c}
        set heading off
        set feedback off
        set pagesize 500
                select 'SET NEWNAME FOR DATAFILE ' ||file#|| ' TO ''' || (replace (name,'$ORACLE_SID','xxxxxx')) || ''';'
        from V\$DATAFILE;
    quit
EOF

        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<GOF |tee -a ${RESTORE_DATA_TEMP_FILES_19c}
                set heading off
                set feedback off
                select 'SET NEWNAME FOR TEMPFILE ' ||file#|| ' TO ''' || (replace (name,'$ORACLE_SID','xxxxxx')) || ''';'
                from V\$TEMPFILE;
                quit
GOF

        print "" >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "$restore_by_log_sequence" >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "restore database;  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "switch datafile all;  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "switch tempfile all;  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "recover database;  " >> ${RESTORE_DATA_TEMP_FILES_19c}
        print "}  " >> ${RESTORE_DATA_TEMP_FILES_19c}

        # Create the Redo files script file
        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<BOF | tee -a ${RESTORE_REDO_19c}
                set heading off feedback off pagesize 500 trimspool on linesize 200
                select 'ALTER DATABASE RENAME FILE ''' || member || ''' TO ''' || (replace (member,'$ORACLE_SID','xxxxxx')) || ''';'
                from V\$LOGFILE b , V\$LOG a
                where a.GROUP#=b.GROUP#;
        quit
BOF

}

# ---------------------------------------------------
# funct_init_backup():  Backup initxxxxxx.ora file
# ---------------------------------------------------
funct_init_backup(){

        # Uncomment next line for debugging
         set -x

        #Copy current init<SID>.ora file to backup directory
        print  " Copying current init${ORACLE_SID}.ora file from spfile"  >> ${BACKUPLOGFILE}

        ${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<BOF | tee -a ${BACKUPLOGFILE}
        set heading off
        set feedback off
        create pfile='${BACKUP_LOC}/${BACKUP_TAG}_init${ORACLE_SID}.ora' from SPFILE;
        quit
BOF
        if [ $? -ne 0 ]
    then
     print "Error Copying the init.ora file to the backup location as init${ORACLE_SID}_${BACKUP_TAG}.ora" >> ${BACKUPLOGFILE}
        fi

        cp ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ${BACKUP_LOC}/${BACKUP_TAG}_orapw${ORACLE_SID}

}

# ----------------------------------------------------------------------------------------
# process_errors():   PROCESS errors that occured in backup and in the validitation process
# ----------------------------------------------------------------------------------------
process_errors() {
        # Uncomment next line for debugging
          set -x

    TMP_ERR_FILE=$HOME/local/dba/backups/rman/captureerr_${BACKUP_TAG}
    rm -rf ${TMP_ERR_FILE}
    cat ${BACKUPLOGFILE}| egrep -vi 'RMAN-06908|RMAN-06909' | egrep -i 'failure|ORA-|corruption|rman-|RMAN-'|grep -v RMAN-08137|tee ${TMP_ERR_FILE}

        if [ $? -eq 0 ]
        then
        if [ -s ${TMP_ERR_FILE} ]
                then
            error_msg=$(cat ${TMP_ERR_FILE})
                        SendNotification "${PROGRAM_NAME} Failed for ${ORACLE_SID} -> See ${BACKUPLOGFILE} for errors::  $error_msg"
                        print  "${PROGRAM_NAME} Failed for ${ORACLE_SID} -> See ${BACKUPLOGFILE} for errors::  $error_msg "
                        export PROCESS_STATUS=FAILURE
                fi
        fi

        rm -rf ${TMP_ERR_FILE}

}
# ---------------------------------------------------------------------------------------------
# funct_initial_audit_update (): Maintain Backup information
# ---------------------------------------------------------------------------------------------
function funct_initial_audit_update {

        # Uncomment for debug
         set -x

        DB_INSTANCE=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                set heading off
                set feedback off
                select SID from databases where sid='${ORACLE_SID}' and HOST_NAME = (select HOST_NAME from DB_MACHINES where lower(HOST_NAME) like '%${BOX}%');
                exit
EOF`
        DB_INSTANCE=$(print $DB_INSTANCE |tr -d " ")
        export DB_INSTANCE
        if [ "x$DB_INSTANCE" == "x" ]; then
                SendNotification "${ORACLE_SID} on ${BOX} does not exist in infdb -> ${PROGRAM_NAME} will run for ${ORACLE_SID} but infdb will not be updated"
        PERFORM_CRON_STATUS=0
                return 1
        fi

        HOST_NAME=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                set heading off
                set feedback off
                select HOST_NAME from databases where sid='${ORACLE_SID}' and HOST_NAME = (select HOST_NAME from DB_MACHINES where lower(HOST_NAME) like '%${BOX}%');
                exit
EOF`
        HOST_NAME=$(print $HOST_NAME |tr -d " ")
        export HOST_NAME

        Sequence_Number=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                set heading off
                set feedback off
                select SEQ_NO from BACKUP_RUNS where trim(PROGRAME_NAME)='${PROGRAM_NAME}' and
                start_time > to_char(sysdate,'DD-MON-YYYY') and sid='${DB_INSTANCE}';
                exit
EOF`
        Sequence_Number=$(print $Sequence_Number|tr -d " ")
        if [[ x$Sequence_Number = 'x' ]]; then
                Sequence_Number=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                set serveroutput on size 1000000
                set heading off
                set feedback off
                declare i number;
                begin
                insert into BACKUP_RUNS values (backup_runs_seq.nextval,'${HOST_NAME}','${DB_INSTANCE}','${PROGRAM_NAME}',sysdate, '','',0,'${BACKUP_LOC}','','${BACKUP_TYPE}','') returning SEQ_NO into i;
                commit;
                dbms_output.put_line (i);
                end;
/
                exit
EOF`
        else
                STATUS=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                set heading off
                set feedback off
                update BACKUP_RUNS set start_time=sysdate where SEQ_NO=${Sequence_Number};
                commit;
EOF`

        fi
        export Sequence_Number
        return 0

}


# ---------------------------------------------------------------------------------------------
# funct_final_audit_update (): update backup details
# ---------------------------------------------------------------------------------------------
funct_final_audit_update () {

                BACKUP_SIZE=`du -sh ${BACKUP_LOC}| awk  '{print $1}'`
                export BACKUP_SIZE=$(print $BACKUP_SIZE|tr -d " ")
                STATUS=`${ORACLE_HOME}/bin/sqlplus -s ${AUD_USER}/${AUD_PASS}@${AUD_DB} <<EOF
                        set heading off
                        set feedback off
                        update BACKUP_RUNS set end_time=sysdate,BKP_SIZE='${BACKUP_SIZE}',BACKUP_STATUS='${PROCESS_STATUS}',NO_OF_RUNS=NO_OF_RUNS+1 where SEQ_NO=${Sequence_Number};
                        commit;

                        update BACKUP_RUNS set RUN_TIME= (select
                        trim(to_char(trunc(((86400*(end_time-start_time))/60)/60)-24*(trunc((((86400*(end_time-start_time))/60)/60)/24)),'09')) || ':' ||
                        trim(to_char(trunc((86400*(end_time-start_time))/60)-60*(trunc(((86400*(end_time-start_time))/60)/60)),'09')) || ':'||
                        trim(to_char(trunc(86400*(end_time-start_time))-60*(trunc((86400*(end_time-start_time))/60)),'09'))
                        from backup_runs where SEQ_NO=${Sequence_Number}),BKP_TYPE='$BACKUP_TYPE'
                        where SEQ_NO=${Sequence_Number};
                        commit;
                        exit
EOF`


}


# -------------------------------------------------------------------
# funct_catalog_check(): Verify ability to connect to RMAN Catalog
# -------------------------------------------------------------------
funct_catalog_check(){

        # Uncomment next line for debugging
         set -x

        export NO_CATALOG=0
        CATALOG_CONNECT=`${ORACLE_HOME}/bin/sqlplus -s $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<EOF
                set heading off
                set feedback off
                select 1 from dual;
        exit
EOF`
    CATALOG_CONNECT=$(print $CATALOG_CONNECT|tr -d " ")
        if [ ${CATALOG_CONNECT} != '1' ]; then
                export NO_CATALOG=1
        if [ $BACKUP_TYPE='INCREMENTAL' ]
        then
         export BACKUP_TYPE=0
        fi
                HOLD_MAILTO=$MAILTO
                export MAILTO=CloudOps-DBA@csod.com
                SendNotification "Unable to connect to RMAN catalog using $CATALOG_ID/xxxxxxxx@$CATALOG_DB however rman backup is continuing" "WARN"
                export PROCESS_STATUS=WARNING
                export MAILTO=$HOLD_MAILTO
        fi
}


# -------------------------------------------------------------------------------------------------------------
# funct_check_registered(): Verify the database is registered in the RMAN catalog and, if not, register it
# -------------------------------------------------------------------------------------------------------------
funct_check_registered() {

        # Uncomment next line for debugging
         set -x

        DBID=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
                set heading off
                set feedback off
                select dbid from v\\$database;
                exit
EOF`
        DBID=$(print $DBID|tr -d " ")

        REGISTERED=`${ORACLE_HOME}/bin/sqlplus -s $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<EOF
                set heading off
                set feedback off
                select count(*) from rc_database where dbid=${DBID} ;
        exit
EOF`
    REGISTERED=$(print $REGISTERED|tr -d " ")

        if [[ ${REGISTERED} != '1' ]]; then
                STATUS=`${ORACLE_HOME}/bin/rman <<EOF
                        connect catalog $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB
                        connect target $DB_OWNER/$DB_OWNER_PASSWD@$PRIMARY_DB
                        register database;
                        ${RETENTION_PERIOD}
                        configure controlfile autobackup ON;
                        configure controlfile autobackup format for device type disk to '${BACKUP_LOC}/cf_%F_full_ctrl';
                        quit
EOF`
                REGISTERED=`${ORACLE_HOME}/bin/sqlplus -s $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<EOF
                        set heading off
                        set feedback off
                        select count(*) from rc_database where dbid=${DBID};
                        exit
EOF`
        if [ $BACKUP_TYPE='INCREMENTAL' ]
        then
         export BACKUP_TYPE=0
        fi
                REGISTERED=$(print $REGISTERED|tr -d " ")
                if [[ ${REGISTERED} != '1' ]]; then
                        SendNotification "${ORACLE_SID} was not registered in the RMAN catalog $CATALOG_DB and an attempt to register the database failed.  The RMAN backup will continue but this needs to be resolved" "WARN"
                        export PROCESS_STATUS=WARNING
                else
                        export PROCESS_STATUS=SUCCESS
                fi
        fi
}

#-------------------------------------------------------------------
# funct_clean_obsolete_dir() :Clean Obsolete Directories
#------------------------------------------------------------------
funct_clean_obsolete_dir() {
set -x

        export CHK_CATALOG=`${ORACLE_HOME}/bin/sqlplus -s $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<!
                set heading off
                set feedback off
                select 1 from dual;
        exit
!`

        export LAST_LVL0_BKP_DATE=`${ORACLE_HOME}/bin/sqlplus -s $AUD_USER/$AUD_PASS@$AUD_DB <<!
        set heading off
        set feedback off
        alter session set nls_date_format='yyyymmdd';
        select max(START_TIME) from BACKUP_RUNS where BKP_TYPE='0' and SID='${ORACLE_SID}' and START_TIME >sysdate-15 and BACKUP_STATUS='SUCCESS' and END_TIME is not null;
!`


        CHK_CATALOG=$(print $CHK_CATALOG|tr -d " ")
        LAST_LVL0_BKP_DATE=$(print $LAST_LVL0_BKP_DATE|tr -d " ")

        if [ ${CHK_CATALOG} = '1' ]
        then
${ORACLE_HOME}/bin/rman target $TRGT_DB catalog $CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB <<!>$WORKING_DIR/RETENTION_${ORACLE_SID}.log
show RETENTION POLICY;
exit
!
else
${ORACLE_HOME}/bin/rman target $TRGT_DB <<!>$WORKING_DIR/RETENTION_${ORACLE_SID}.log
show RETENTION POLICY;
exit
!
fi

        grep 'RETENTION POLICY' $WORKING_DIR/RETENTION_${ORACLE_SID}.log > $WORKING_DIR/RET_POLICY.log
        RETENTION_DAYS=`cat $WORKING_DIR/RET_POLICY.log | awk '{print $8}'`
        RETENTION_DAYS=`expr ${RETENTION_DAYS} + 1`
#        if [ $RETENTION_DAYS -ne 14 ]
#        then
#        SendNotification "RMAN RETENATION POLICY is not set to 14 days in control file as per the DB standards.
#               Aborting RMAN $2 Level $3 backup for $1 HA DB. Please set RMAN RETENATION POLICY and rerun it."
#        rm $WORKING_DIR/RETENTION_${ORACLE_SID}.log
#        rm $WORKING_DIR/RET_POLICY.log
#        exit 9
#        fi
        SYSDATE=`date "+%Y%m%d"`
        LAST_BKP_DATE=`date -d "-2 days" "+%Y%m%d"`
        OBSOLETE_DATE=`date -d "-$RETENTION_DAYS days" "+%Y%m%d"`
###LAST_LEVEL_0_DATE=`expr $(( ( $(date "+%Y%m%d") - $(date -d "-7 days" "+%Y%m%d" ) ) ))`
        LAST_LEVEL_0_DATE=`date -d "$(date -d "$LAST_LVL0_BKP_DATE + 7 days")" "+%Y%m%d"`
        ls -l $BACKUP_BASE/$ORACLE_SID |grep -v root| awk '{print $9}'|sed '1d'|grep -v CTRLFILE_BACKUP > $WORKING_DIR/DIRECTOY_LIST.txt
        if [[ -s $WORKING_DIR/DIRECTOY_LIST.txt ]]; then
        cat $WORKING_DIR/DIRECTOY_LIST.txt | while read LINE
        do
        CHK_OBS_DIR=`print $LINE | awk '{print substr($1,1,8)}'`
        if [ $BACKUP_TYPE -eq 0 ] && [ $SYSDATE -ge $LAST_LEVEL_0_DATE ]
        then
          if [ $CHK_OBS_DIR -lt $OBSOLETE_DATE ]
          then
          rm -rf $BACKUP_BASE/$ORACLE_SID/$LINE
          fi
         #elif [ $BACKUP_TYPE -eq 1 ] ; then
         # if [ $CHK_OBS_DIR -lt $LAST_BKP_DATE ] ; then
         # rm -f $BACKUP_BASE/$ORACLE_SID/$LINE/al*${ORACLE_SID}*_1_1_archive
         # fi
        fi
        done
        fi
        rm $WORKING_DIR/DIRECTOY_LIST.txt
        rm $WORKING_DIR/RETENTION_${ORACLE_SID}.log
        rm $WORKING_DIR/RET_POLICY.log
}
#----------------------------------------------------------------------
# check_level_0_run(): To check no multiple level 0 backup run in a week
#----------------------------------------------------------------------
#check_level_0_run() {
#set -x
#        export LAST_LVL0=`${ORACLE_HOME}/bin/sqlplus -s $AUD_USER/$AUD_PASS@$AUD_DB <<!
#        set heading off
#        set feedback off
#        alter session set nls_date_format='yyyymmdd';
#        select max(START_TIME) from BACKUP_RUNS where BKP_TYPE='0' and SID='${ORACLE_SID}' and START_TIME >sysdate-15 and BACKUP_STATUS='SUCCESS' and END_TIME is not null;
#!`
#        LAST_LVL0=$(print $LAST_LVL0|tr -d " ")
#        if [ ! -z $LAST_LVL0 ]
#        then
#        print "$LAST_LVL0" > $HOME/local/dba/backups/rman/LAST_LVL0_BKP_DT.txt
#        if [ -s $HOME/local/dba/backups/rman/LAST_LVL0_BKP_DT.txt ]
#        then
#        CUR_DT=`date "+%Y%m%d"`
#        LAST_LEVEL_0_RUN=`date -d "$(date -d "$LAST_LVL0 + 7 days")" "+%Y%m%d"`
#        if [ $BACKUP_TYPE -eq 0 ] && [ $CUR_DT -lt $LAST_LEVEL_0_RUN ]
#        then
#        SendNotification "LEVEL 0 BACKUP CAN NOT BE RUN TWICE IN A WEEK...PLEASE CHECK"
#        rm $HOME/local/dba/backups/rman/LAST_LVL0_BKP_DT.txt
#        exit 6
#        fi
#        fi
#        rm $HOME/local/dba/backups/rman/LAST_LVL0_BKP_DT.txt
#        fi
#}
#--------------------------------------------------------------------------
# check_concurrent_run(): check no concurrent backup run on the same server
#--------------------------------------------------------------------------
check_concurrent_run() {
set -x
export CHKEXECUTION=`ps -ef |grep ${PROGRAM_NAME} |grep -v grep|wc -l`
export CHKEXECUTION=$(print $CHKEXECUTION|tr -d " ")
if [ $CHKEXECUTION -gt '0' ]
then

   if [[ -s $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt ]]; then
export RPID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $1}'`
export RSID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $2}'`

####For same DB start Check
        if [ $RSID == ${ORACLE_SID} ]
        then
        export CURBKPDATE=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
        set heading off
        set echo off
        set feedback off
        select TO_CHAR(start_time,'YYYYMMDD') from V\\$RMAN_BACKUP_JOB_DETAILS where status='RUNNING';
EOF`

                export CURBKPDATE=$(print $CURBKPDATE|sed 's/.*\///g'| tr -d " ")
                export CURDT=`date +'%Y%m%d'`
                export CURDT=$(print $CURDT|tr -d " ")

              if [ ! -z $CURBKPDATE ]
              then

                if [ $CURBKPDATE == $CURDT ]
                then
                print "\nBackup can not be run for same DB within same date" > $HOME/local/dba/backups/rman/${PROGRAM_NAME_FIRST}_error.txt
                ERROR_FILE=$HOME/local/dba/backups/rman/${PROGRAM_NAME_FIRST}_error.txt
                SendNotification
                exit 5
                fi
              fi

              if [ ! -z $CURBKPDATE ]
              then

                if [ $CURDT -gt $CURBKPDATE ]
                then
                ps -ef |grep ${PROGRAM_NAME} |grep -v grep |grep -v $RPID |awk  '{print $2,$10,$11,$12}'|tail -1 |sed 's/.*\///g' >> $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
                typeset -i i=1
                while [ ${i} -le $NOITRATION ]
                do
                print "Sleeping for ${i} time" > $HOME/local/dba/backups/rman/Resum_backup.txt
                print "Backup for $ORACLE_SID is already running for $CURBKPDATE" >> $HOME/local/dba/backups/rman/Resum_backup.txt
                print "Sleeping for an hour to restart backup for $CURDT" >> $HOME/local/dba/backups/rman/Resum_backup.txt
                cat $HOME/local/dba/backups/rman/Resum_backup.txt | /bin/mail -s "Execution of backup going to sleep mode for an hour" $MAILTO
                rm $HOME/local/dba/backups/rman/Resum_backup.txt
                sleep 60m
                export CHKRUN=`grep $RPID $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|wc -l`
                export CHKRUN=$(print $CHKRUN|tr -d " ")
                if [ $CHKRUN -gt '0' ]
                then
                i=${i}+1;

                    if [ ${i} -gt $NOITRATION ]
                    then
                     cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|grep $RPID > $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt
                     cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt > $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
                     rm $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt
                     /bin/mail -s "Backup executtion of  $CURDT for $ORACLE_SID terminating after $NOITRATION iteration" $MAILTO
                     exit 6
                    fi
                fi
                done
                   export RPID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $1}'`
                   export RSID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $2}'`

                fi
              fi
        fi
####Same DB check end
###Different DB check start
        if [ $RSID != ${ORACLE_SID} ]
        then
        ps -ef |grep ${PROGRAM_NAME} |grep -v grep |grep -v $RPID |awk  '{print $2,$10,$11,$12}'|tail -1 |sed 's/.*\///g' >> $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
        export CHKRUN=`grep $RPID $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|wc -l`
        export CHKRUN=$(print $CHKRUN|tr -d " ")
        typeset -i i=1
        while [ ${i} -le $NOITRATION ] && [ $CHKRUN -gt '0' ]
        do
        print "Sleeping for ${i} time" >$HOME/local/dba/backups/rman/Resum_backup.txt
        print "\nBackup for $RSID is already running on the $BOX server" >> $HOME/local/dba/backups/rman/Resum_backup.txt
        print "\nSleeping for an hour to restart backup for $ORACLE_SID" >> $HOME/local/dba/backups/rman/Resum_backup.txt
        cat $HOME/local/dba/backups/rman/Resum_backup.txt | /bin/mail -s "Execution of backup going to sleep mode for an hour" $MAILTO
        sleep 60m
        export CHKRUN=`grep $RPID $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|wc -l`
        export CHKRUN=$(print $CHKRUN|tr -d " ")
          if [ $CHKRUN -gt '0' ]
          then
          i=${i}+1;

            if [ ${i} -gt $NOITRATION ]
                 then
                 cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|grep $RPID > $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt
                 cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt > $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
                 rm $HOME/local/dba/backups/rman/CHECK_CONCURRENT_TEMP.txt
                 /bin/mail -s "Backup executtion of $CURDT for $ORACLE_SID terminating after $NOITRATION iteration" $MAILTO
                  exit 7
            fi

          fi
        done
   fi
###Different DB check end
else
rm $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
 ps -ef |grep ${PROGRAM_NAME} |grep -v grep |head -1|tr -d '\-c'|awk  '{print $2,$10,$11,$12}'|sed 's/.*\///g' > $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt
   fi
fi
export RPID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $1}'`
export RSID=`cat $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt|awk '{print $2}'`

}

############################################################
#                       MAIN
############################################################
# Uncomment next line for debugging
set -x
ostype=$(uname)
if [ $ostype = Linux ]
then
 ORATAB=/etc/oratab
fi
if [ $ostype = SunOS ]
then
 ORATAB=/var/opt/oracle/oratab
fi

HOSTNAME=$(hostname)
export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null

export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export PROGRAM_NAME_FIRST=$(print $PROGRAM_NAME | awk -F "." '{print $1}')
export PROGRAM_LOG_PATH=`dirname $0`/logs
export MAILTO='CloudOps-DBA@csod.com'
#export MAILTO='nmalwade@csod.com'
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export DB_INSTANCE
export CURDATE=$(date +'%Y%m%d_%H%M%S')
#infdb/saba#465@d501syd1
export AUD_USER=infdb
export AUD_PASS='saba#465'
export AUD_DB=RMANREP4
#$CATALOG_ID/$CATALOG_PASSWD@$CATALOG_DB
export CATALOG_ID=rman
export CATALOG_PASSWD=rman
export CATALOG_DB=RMANREP4
export behind_threshold=2
export DB_OWNER=sys
export DB_OWNER_PASSWD=sabadba4you


export NOITRATION=3
if [ $# -lt 1 ] || [ $# -gt 3 ]
        then
        print "\n$0 Failed: Incorrect number of arguments -> $0 ORACLE_SID [INCREMENTAL] [LEVEL]"
        print "The second parameter INCREMENTAL is optional.  If not specified, backup is FULL.\n"
        print "If specified, the only valid value for the second parameter is INCREMENTAL.\n"
        print "The third parameter LEVEL of incremental backup is optional. If specified, must be 0 or 1\n"
        print "If third parameter LEVEL is not specified and second parameter INCREMENTAL is specified,"
        print "then the INCREMENTAL backup will be a Level 0 backup.\n"
        SendNotification "Incorrect number of arguments -> ${PROGRAM_NAME} ORACLE_SID [INCREMENTAL] [LEVEL]"
        exit 1
fi

export ORACLE_SID=$1
grep "^${ORACLE_SID}:" $ORATAB > /dev/null
if [ $? -ne 0 ]
        then
        print "\nThe first parameter entered into script is not a valid Oracle SID in $ORATAB."
        print "Choose a valid Oracle SID from $ORATAB.\n"
        SendNotification "Not a valid Oracle SID -> ${PROGRAM_NAME} ORACLE_SID [INCREMENTAL] [LEVEL]"
        exit 2
fi

export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv
export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_BASE=$HOME
export LEVEL_0_BACKUP=$HOME/local/dba/backups/rman/${ORACLE_SID}_level_0_status.txt

BACKUP_TYPE=F
BACKUP_FORMAT=FULL
if [ $# -gt 1 ]
        then
        BACKUP_TYPE=0
        BACKUP_FORMAT=$(print $2 | tr '[a-z]' '[A-Z]')
        if [ $BACKUP_FORMAT != INCREMENTAL ]
                then
                print "\nA second parameter was entered but only one value for the second parameter is allowed."
                print "The only allowed value for the second parameter is:  INCREMENTAL\n"
                print "Omit the second parameter to perform a FULL backup or enter INCREMENTAL for the second parameter to perform an incremental backup.\n"
                SendNotification "Not a valid second parameter -> ${PROGRAM_NAME} ORACLE_SID [INCREMENTAL] [LEVEL]"
                exit 3
        fi
fi

if [ $# -eq 3 ]
        then
        BACKUP_TYPE=$3
        if [ $BACKUP_TYPE != 0 ] && [ $BACKUP_TYPE != 1 ]
                then
                print "Level of Incremental backup must be 0 or 1"
                print "For example:  $0 INCREMENTAL 0"
                print "For example:  $0 INCREMENTAL 1"
                print "Or just omit the third parameter and it will default to 0"
                SendNotification "Not a valid third parameter LEVEL -> ${PROGRAM_NAME} ORACLE_SID [INCREMENTAL] [LEVEL]"
                exit 4
        fi
fi

export BLK_COUNTER_CHK=${PROGRAM_LOG_PATH}/${PROGRAM_NAME_FIRST}_${ORACLE_SID}.chk
if [ ! -f ${BLK_COUNTER_CHK} ] ; then
        echo 0 > ${BLK_COUNTER_CHK}
else
        BLK_COUNTER=`cat ${BLK_COUNTER_CHK} | awk '{print $1}'`
fi

funct_db_online_verify

get_fal_server_details
get_fal_client_details
recovery_proc_chk
if [ ${RECOVER_PROC_CHK} -ne 0 ] ; then

export GAP_CHK_DR=/tmp/dr_seq_chk_$$.log
export GAP_CHK_PRD=/tmp/prod_seq_chk_$$.log
export SYNC_CHK_DR=/tmp/dr_sync_chk_$$.log
export SYNC_CHK_PRD=/tmp/prod_sync_chk_$$.log
get_standby_max_seq
if [ $? -eq 0 ] ; then

#added by brij - need to run once at db level than sequence
#get_active_standby_realtime_sync_status
get_prod_sync
get_standby_sync
if [ $? -eq 0 ] ; then

while read drseq ; do

threadno_dr=`echo $drseq |awk '{print $1}'|  sed 's/ //g'`
dr_max_seq_no=`echo $drseq | awk '{print $2}'|  sed 's/ //g'`

get_prod_max_seq $threadno_dr
if [ $? -eq 0 ] ; then
        while read prodseq ; do

        threadno_prod=`echo  $prodseq |awk '{print $1}'|  sed 's/ //g'`
        prod_max_seq_no=`echo  $prodseq | awk '{print $2}'|  sed 's/ //g'`

        how_far_behind=`expr $prod_max_seq_no - $dr_max_seq_no`
        if [[ ${how_far_behind} -gt ${behind_threshold} && ${BLK_COUNTER} -gt 5 ]] ; then
                SendNotification "$PROGRAM_NAME
Machine: $BOX

Critical: $ORACLE_SID ACTIVE DATAGUARD behind Prod by ${how_far_behind} archive logs at $(date)
Thread# $threadno_dr with threshold limit $behind_threshold is ${how_far_behind} logs behind.

Last archived log sequence on Primary is : ${prod_max_seq_no}
Last archived log sequence on Standby is : ${dr_max_seq_no}

Aborting RMAN $2 Level $3 backup for $1 HA DB. Please check and rerun it once the HA DB is in sync."
        fi

        done < ${GAP_CHK_PRD}
else
SendNotification "$PROGRAM_NAME
Machine: $BOX

Critical:$(hostname): $ORACLE_SID Prod cannot get max log sequence number at $(date)
Aborting RMAN $2 Level $3 backup for $1 HA DB. Please check and rerun it once the issue is fixed."
fi
done < ${GAP_CHK_DR}
else
SendNotification "$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID HA setup is not found in realtime sync, check ACTIVE DATAGUARD status at $(date)
Aborting RMAN $2 Level $3 backup for $1 HA DB. Please check and rerun it once the issue is fixed."
fi
else
SendNotification "$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID ACTIVE DATAGUARD cannot get max log sequence number at $(date)
Aborting RMAN $2 Level $3 backup for $1 HA DB. Please check and rerun it once the issue is fixed."
fi
else
SendNotification "$PROGRAM_NAME
Machine: $BOX

Critical: $(hostname): $ORACLE_SID ACTIVE DATAGUARD managed recovery is DOWN!! at $(date)!!!
Aborting RMAN $2 Level $3 backup for $1 HA DB. Please check and rerun it once MRP process started."
fi



rm -f ${GAP_CHK_DR} ${GAP_CHK_PRD} ${SYNC_CHK_DR} ${SYNC_CHK_PRD}

##############################################################################################################################
###        if [[ -s $HOME/local/dba/backups/rman/CHECK_CONCURRENT_RMAN_BACKUP.txt ]]; then
###       export CHK_MULTI_RUNS=`grep RUNNING $HOME/local/dba/backups/rman/CHECK_CONCURRENT_RMAN_BACKUP.txt| wc -l`
###        if [ $CHK_MULTI_RUNS -gt 0 ] ; then
###        print "\n\nRMAN Backup already running on $BOX. " >> $HOME/local/dba/backups/rman/check_multi_runs.txt
###       print "\nNo Multiple RMAN Backups are Allowed on Same Server." >> $HOME/local/dba/backups/rman/check_multi_runs.txt
###        print "\n   Please check and take the action accordingly."         >> $HOME/local/dba/backups/rman/check_multi_runs.txt
###        SendNotification
###         exit 5
###        fi
###        fi
###############################################################################################################################

        check_concurrent_run

        check_level_0_run

        export WORKING_DIR="$HOME/local/dba/backups/rman"
        export DATABASES_FILE=$WORKING_DIR/${PROGRAM_NAME_FIRST}_databases.txt
        export ERROR_FILE=$WORKING_DIR/${PROGRAM_NAME_FIRST}_error.txt

        export PROCESS_STATUS=SUCCESS
        export Sequence_Number=0
        export BACKUP_SIZE=0
        export PERFORM_CRON_STATUS=0
        export PAR_HOME=$HOME/local/dba


        export BACKUP_BASE=/backup/syd
        export BACKUP_MOUNT=$(print $BACKUP_BASE | awk -F/ '{print $2}')
        export CTRL_BKP_LOC=$BACKUP_BASE/$ORACLE_SID/CTRLFILE_BACKUP
        export RETENTION_PERIOD='CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;'
        export CTRL_AUTO_BKP_FORMAT="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$CTRL_BKP_LOC/cf_%F_full_ctrl';"
        export CTRL_SNAPSHOT="CONFIGURE SNAPSHOT CONTROLFILE NAME TO '$CTRL_BKP_LOC/snapcf_D1SPCTN1.f';"
        BACKUP_LOC=$BACKUP_BASE/$ORACLE_SID/$CURDATE
        mkdir -p $CTRL_BKP_LOC
        mkdir -p $BACKUP_LOC
          if [[ ! -d $BACKUP_LOC ]]
          then
           print "Cannot create directory $BACKUP_LOC"
           print "Will abort here as there is no place to put the backup files."
           exit 10
          fi

### the_status=$(find $BACKUP_LOC -mtime -2 -name "*_LOG.TXT" | tail -1 | xargs grep 'RMAN Backup Completed ' | awk '{print $NF}')
###    export the_status=$(grep 'SUCCESS' $HOME/local/dba/backups/rman/${ORACLE_SID}_last_bkp_status.txt | tr -d " ")
###    if [[ -n $the_status ]]
###    then
###     if [ $the_status != SUCCESS ]
###     then
###      BACKUP_TYPE=0
###     fi
###    else
###     BACKUP_TYPE=0
###    fi

    funct_chk_bkup_dir

        export BACKUP_TAG=${ORACLE_SID}_$(date +'%Y%m%d_%H%M%S')
        export TRGT_DB="/"
        export RMAN_TRGT_DB=$DB_OWNER/$DB_OWNER_PASSWD@$ORACLE_SID
                export PRIMARY_DB=HA${ORACLE_SID}
        export BACKUP_SCRIPT=$HOME/local/dba/backups/rman/${ORACLE_SID}_rman_backup_script.sql
        export ORPHANED_BACKUPS=$HOME/local/dba/backups/rman/${ORACLE_SID}_Orphaned_Backups.txt
        export ORPHANED_BACKUP_DATES=$HOME/local/dba/backups/rman/${ORACLE_SID}_Orphaned_Backup_Dates.txt
        export ORPHANED_FILE_DELETES=$HOME/local/dba/backups/rman/${ORACLE_SID}_Orphaned_File_Deletes.txt
        export TEXT_FILE_DELETES=$HOME/local/dba/backups/rman/${ORACLE_SID}_TEXT_FILE__Deletes.txt

        BACKUPLOGFILE="$BACKUP_LOC/${BACKUP_TAG}_LOG.TXT"

        #Restore script files
        RESTORE_CONTROLFILE_19c="$BACKUP_LOC/Restore19c_ControlFile_${BACKUP_TAG}.rcv"
        RESTORE_DATA_TEMP_FILES_19c="$BACKUP_LOC/Restore19c_DataTempFiles_${BACKUP_TAG}.rcv"
        RESTORE_REDO_19c="$BACKUP_LOC/Restore19c_Redo_${BACKUP_TAG}.rcv"

        export START_FILE=$BACKUP_LOC/START_TIME.txt



        print " Starting RMAN Backup of ....  $ORACLE_SID HA database on $(date +\"%c\")"

        funct_initial_audit_update
        funct_switch_logfile
#        funct_logmode_check

        funct_catalog_check
        if [ $NO_CATALOG -eq 0 ]
        then
         funct_check_registered
        fi

                funct_clean_obsolete_dir

        if [ $BACKUP_FORMAT = FULL ]
        then
         RESTOREFILE="$BACKUP_LOC/${BACKUP_TAG}_RESTORE_INFO.TXT"
        else
         RESTOREFILE="$BACKUP_LOC/${BACKUP_TAG}_RESTORE_INFO_level_${BACKUP_TYPE}.TXT"
        fi

        funct_create_restore_log

 #Change the output to file - VK
     MAIL_DASHBOARD_LOC=$HOME/local/dba/backups/rman/
     mkdir -p $MAIL_DASHBOARD_LOC

     export DATE=$(date '+%Y-%m-%d %H:%M:%S.%3N')
         echo $DATE "|" ${BOX} "|" ${ORACLE_SID} "|" "Rman Backup Started " >> $MAIL_DASHBOARD_LOC/mail_status

       # print "${ORACLE_SID}, RMAN Backup Started on $(date +\"%c\")" |tee -a $BACKUPLOGFILE

###        print "RUNNING" > $HOME/local/dba/backups/rman/CHECK_CONCURRENT_RMAN_BACKUP.txt

$ORACLE_HOME/bin/sqlplus '/as sysdba' <<! >$WORKING_DIR/ora_editn.txt
exit;
!
grep 'Enterprise Edition' $WORKING_DIR/ora_editn.txt > $WORKING_DIR/ora_editn.txt

        if [[ -s $WORKING_DIR/ora_editn.txt ]]; then
        export NUM_CHANNELS=7
        else
        export NUM_CHANNELS=7
        fi
rm $WORKING_DIR/ora_editn.txt

funct_set_retention
#funct_switch_logfile

        if  [ $BACKUP_FORMAT = FULL ]
        then
         funct_rman_backup
        else
         if [ $BACKUP_TYPE -eq 0 ]
         then
          funct_rman_level_0_backup
         else
          funct_rman_level_1_backup
         fi
        fi

        # for PROD databases, create a standby control file
        #if  [ $TYPE = PROD ]
        #then
        # STATUS=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
        #        alter database create standby controlfile as  '${BACKUP_LOC}/standbycontrol_${BACKUP_TAG}.ctl';
        #        quit
#EOF`
#        fi

    newest_archive_log_in_backup=$(grep 'input archive.* log thread=[0-9] sequence=' $BACKUPLOGFILE | awk '{print $5}' | awk -F= '{print $NF}' | sort -n | tail -1)
    export restore_by_log_sequence="set until sequence $newest_archive_log_in_backup thread 1;"

    # Get the SCN after the backup
    SCN=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
        set heading off
        set feedback off
        select max(next_change#) from V\\$LOG_HISTORY;
        exit 16
EOF`
    SCN=$(print $SCN|tr -d " ")
    print "SCN retrieval after backup: $SCN" >> $BACKUPLOGFILE

        funct_create_restore_scripts
        funct_init_backup
        funct_control_backup
        funct_final_audit_update

        find $BACKUP_BASE/${ORACLE_SID}/  -type d -name "20*" -mtime +21 -exec rm -fr {} \;
    # change of mail to file - VK

        print  "${ORACLE_SID}, RMAN Backup Completed $(date +\"%c\") with a status of ${PROCESS_STATUS} " |tee -a ${BACKUPLOGFILE}
       export DATE_NEW=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        echo $DATE_NEW "|" ${BOX} "|" ${ORACLE_SID} "|" "STATUS: "RMAN Backup Completed with a status of ${PROCESS_STATUS}  >>  $MAIL_DASHBOARD_LOC//mail_status


        ###rm $HOME/local/dba/backups/rman/CHECK_CONCURRENT_RMAN_BACKUP.txt
        print "${PROCESS_STATUS}" > $HOME/local/dba/backups/rman/${ORACLE_SID}_last_bkp_status.txt

        sed -i '/'$RPID'/d' $HOME/local/dba/backups/rman/CHECK_CONCURRENT.txt

        grep 'RMAN Backup' $BACKUPLOGFILE > $BACKUP_LOC/Final_Report.txt
        if [ $PROCESS_STATUS == 'SUCCESS' ]
        then
        #disable mail - VK
        #cat $BACKUP_LOC/Final_Report.txt | /bin/mail -s "RMAN Backup Status on ${BOX} for ${ORACLE_SID}" ${MAILTO}
        fi
        rm -f $BACKUP_LOC/Final_Report.txt

######## END MAIN  #########################
exit 0
