#!/bin/ksh
# ********************************************************************************************
# NAME:         RMANArcLogBkp_All_Clean.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This utility will perform a RMAN archivelog backup
#
# USAGE:        RMANArcLogBkp_All_Clean.sh ORACLE_SID
#
# INPUT PARAMETERS:
#               SID     Oracle SID of database to backup
#
#
# *********************************************************************************************


#!/bin/ksh
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
function SendNotification {

    # Uncomment for debug

    print "${PROGRAM_NAME} \n     Machine: $BOX " > mail.dat
    if [[ x$1 != 'x' ]]; then
        print "\n$1\n" >> mail.dat
    fi

    if [[ -a ${ERROR_FILE} ]]; then
        cat $ERROR_FILE >> mail.dat
        rm ${ERROR_FILE}
    fi

    if [[ $2 = 'FATAL' ]]; then
        echo "*** This is a FATAL ERROR - ${PROGRAM_NAME} aborted at this point *** " >> mail.dat
    fi

    cat mail.dat | /bin/mail -s "PROBLEM WITH ${TYPE} Environment -- ${PROGRAM_NAME} on ${BOX} for ${ORACLE_SID}" ${MAILTO}
    rm mail.dat

    # Update the mail counter
    MAIL_COUNT=${MAIL_COUNT}+1

    return 0
}
# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
funct_db_online_verify(){

        STATUS=`ps -fu oracle |grep -v grep| grep ora_pmon_${ORA_SID}`
        if [ $? -ne 0 ]
    then
     print "Database ${ORACLE_SID} is not running.  Can not perform RMAN Backup"
         SendNotification "Database ${ORACLE_SID} is not running. ${PROGRAM_NAME} can not run "
     exit 1
        fi
}

# --------------------------------------------------------------------------------------------------------------
# funct_chk_bkup_dir(): Make sure Datadomain is mounted and create backup directory if it doesn't  exist
# --------------------------------------------------------------------------------------------------------------
funct_chk_bkup_dir() {

        DD_MOUNTED=`mount | grep ${BACKUP_MOUNT}`
        DD_MOUNTED=`print $DD_MOUNTED|tr -d " "`
        if [[ x$DD_MOUNTED = 'x' ]]; then
        #export MAILTO=abasitkhan465@gmail.com
        export MAILTO=CloudOps-DBA@csod.com,CloudOps-DBA@saba.com
                SendNotification "${PROGRAM_NAME} can not run because datadomain is not mounted"
                exit 1
        fi

        mkdir -p  ${BACKUP_SET}
        if [ $? != 0 ]; then
                SendNotification "${PROGRAM_NAME} failed for ${ORACLE_SID} because program could not create directory $BACKUP_SET"
                exit 1
        fi

}


#---------------------------------------------------------------------------------------------------
# funct_archivelog_rman_backup -- To Backup Archive Log between specified Sequence Numbers
#----------------------------------------------------------------------------------------------------
funct_archivelog_rman_backup() {

# Create the script to run for the RMAN backup
print "connect target $TRGT_DB" > $BACKUP_SCRIPT

print "run {" >> $BACKUP_SCRIPT
print " host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT
print " CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 1;" >> $BACKUP_SCRIPT

typeset -i i=1
while [ ${i} -le ${NUM_CHANNELS} ]
do
        print " ALLOCATE CHANNEL d${i} DEVICE TYPE DISK;" >> $BACKUP_SCRIPT
        i=${i}+1;
done

print "   BACKUP TAG  \"$BACKUP_TAG\" " >> $BACKUP_SCRIPT
print "   AS COMPRESSED BACKUPSET FORMAT '$BACKUP_SET/al_${BACKUP_TAG}_%U_archive'" >> $BACKUP_SCRIPT
print "   ARCHIVELOG ALL NOT BACKED UP DELETE ALL INPUT ;" >> $BACKUP_SCRIPT
print "   host \"date +'%b %d %Y %T'>>${BACKUPLOGFILE}\" ;" >> $BACKUP_SCRIPT

typeset -i j=1
while [ ${j} -le ${NUM_CHANNELS} ]
do
        print " RELEASE CHANNEL d${j};" >> $BACKUP_SCRIPT
        j=${j}+1;
done

print "}" >> $BACKUP_SCRIPT
print "quit" >> $BACKUP_SCRIPT

nohup $ORACLE_HOME/bin/rman >>${BACKUPLOGFILE} 2>&1 <<HOF
        @${BACKUP_SCRIPT}
HOF

process_errors;

}
# ----------------------------------------------------------------------------------------
# process_errors():   PROCESS errors that occured in backup and in the validitation process
# ----------------------------------------------------------------------------------------
process_errors()
{
 TMP_ERR_FILE=$HOME/local/dba/backups/rman/captureerr_${BACKUP_TAG}
 rm -f ${TMP_ERR_FILE}
 egrep -i 'failure|ORA-|corruption|RMAN-' $BACKUPLOGFILE | grep -v 'RMAN-08137' > $TMP_ERR_FILE
 if [[ -s $TMP_ERR_FILE ]]
 then
  error_msg=`cat $TMP_ERR_FILE`
  SendNotification "$PROGRAM_NAME Failed for $ORA_SID -> See $BACKUPLOGFILE for errors::  $error_msg"
  print  "$PROGRAM_NAME Failed for $ORA_SID -> See $BACKUPLOGFILE for errors::  $error_msg "
  exit 1
 fi
 rm -f $TMP_ERR_FILE
}
#-----------------------------------
#         MAIN
#-----------------------------------
#set -x
NARG=$#
PROCEDURENAME=$0
if [ $NARG -ne 1 ]; then
        print "$PROCEDURENAME requires one argument - Enter parameters or 0 to exit"
        read INPUT_SID?"Enter Database SID: "
        if [[ -x $INPUT_SID ]]
    then
     print "\nProcess Terminated\n"
         exit
        fi
else
    INPUT_SID=$1
fi

#export CHK_SID=$(grep $INPUT_SID /etc/oratab | awk -F: '{print $1}')
#CHK_SID=$(print '$CHK_SID' | tr -d " ")
#if [ $CHK_SID -ne $INPUT_SID ]
#then
#   print '$INPUT_SID does not exist in ORATAB file'
#   exit 1
#fi

# Set environment variables
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
export PROGRAM_NAME_FIRST=`echo ${PROGRAM_NAME} | awk -F "." '{print $1}'`
export BOX=`print $(hostname) | awk -F "." '{print $1}'`


export ORATAB_LOC="/etc"
export ERROR_FILE=$HOME/local/dba/backups/rman/${PROGRAM_NAME_FIRST}_error.txt
export PAR_HOME=$HOME/local/dba
export NO_COMMENT_PARFILE=$PAR_HOME/${PROGRAM_NAME_FIRST}_$$_temp.ini

export ORACLE_SID=$INPUT_SID
export ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv

export MAILTO=CloudOps-DBA@csod.com,CloudOps-DBA@saba.com
HOSTNAME=$(hostname)

((process_count=$(ps -ef | grep -c "RMANArcLogBkp_All_Clean\.sh $ORACLE_SID")))
if [ $process_count -gt 1 ]
then
 print "Currently running RMANArcLogBkp_All_Clean.sh   Aborting script."
 exit 1
fi


export CURDATE=`date +'%Y%m'`
export BACKUP_BASE=/backup/sac/${ORACLE_SID}
export BACKUP_MOUNT=`print $BACKUP_BASE | awk -F/ '{print $2}'`
export BACKUP_SET=$(find $BACKUP_BASE -type d -name "${CURDATE}*" | sort -n | tail -1)

if [ -z $BACKUP_SET ]
then
 export CURDATE=`date +'%Y%m%d_%H%M%S'`
 mkdir -p $BACKUP_BASE/$CURDATE
 export BACKUP_SET=$(find $BACKUP_BASE -type d -name "${CURDATE}*" | sort -n | tail -1)
fi

export BACKUP_TAG=${INPUT_SID}_`date +'%Y%m%d_%H%M%S'`
export TRGT_DB="/"
export BACKUP_SCRIPT=$HOME/local/dba/backups/rman/${INPUT_SID}_ArchiveLog_rman_backup_script.sql
export BACKUPLOGFILE="${BACKUP_SET}/${BACKUP_TAG}_ARCHIVE_log.TXT"

export PATH
export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

export NUM_CHANNELS=1

funct_db_online_verify

funct_chk_bkup_dir

funct_archivelog_rman_backup

    # Get SCN
export SCN=`${ORACLE_HOME}/bin/sqlplus -s '/as sysdba' <<EOF
        set heading off
        set feedback off
                select max(NEXT_CHANGE#) from V\\$LOG_HISTORY;
        exit
EOF`


    SCN=`print $SCN|tr -d " "`
    export SCN
print "Until SCN Number ${SCN}" >> ${BACKUPLOGFILE}

print  "\n ------------------------------------------------------------------------------\n "
print  "  Please Check Log File Located in  ${BACKUPLOGFILE} for more details"
print  "\n ------------------------------------------------------------------------------\n "
exit 0
