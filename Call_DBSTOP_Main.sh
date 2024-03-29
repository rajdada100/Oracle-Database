#!/bin/ksh
# ********************************************************************************************
# NAME:         Call_DBSTOP_Main.sh
#
# AUTHOR:       Brij Lal Kapoor
#
# PURPOSE:      The script is part of automation and used to fetch metadb details.
#
# DATE:                 11/25/2017
#
# CHANGE TRACKER LOG:
#*******************************************************************************************
# Date          Developer       Change Description
#===========================================================================================
# 11/25/2017    BLK (BRIJ)       Initial creation
#
# Required script parameters:
# ---------------------------
# -d metadb name
# -h metadb hostname
# -e SC environment Name (NA1/2/3/4/5/6/7 etc.)
# -u OS user who owns Oracle databases
# -p db port
# -m OS user who owns Mongo databases
# -q unique jobid
# -i meta db server ip
# -x meta schema name
# -w meta schema pwd
#
# Script Return codes:
# --------------------
# 2--> "Incorrect number of arguments in calling stop process, check with -help|-h options"
# 3--> "Problem fetching METADB details, check attached logs"
# 4--> "Error ssh to $RHOST, check attached logs"
# 5--> "Error executing db stop script, check attached logs"
# Example: ./Call_DBSTOP_Main.sh -u oracle -m mongouser -h n3pp07spcora01 -d PNA7META -p 9101 -q 1234 -e NA7
############################################################################################





###################################################
########### Mongo stop function ################
###################################################
Restart_MongoDB () {
>$LOGFILEMONGO
echo " " >>$LOGFILEMONGO
echo "`date +"%d%b%Y_%H%M%S"`::Stopping Mongo database(s), script starts...please wait " >>$LOGFILEMONGO
echo "======================================================================================" >>$LOGFILEMONGO
echo "List of MongoDB environments to be stopped:" >>$LOGFILEMONGO
echo "===============================================" >>$LOGFILEMONGO
cat ${METADBLISTMONGO} >>$LOGFILEMONGO
echo "===============================================" >>$LOGFILEMONGO

export PID_STATUS=/tmp/PID_${UNQID}_${DATE}_${PROCID}_mongo.stat
export PID_STATUS_FINAL=/tmp/PID_FINAL_${UNQID}_${DATE}_${PROCID}_mongo.stat

export RESTART_MONGO_CLUSTER=SC_Stop_Mongo_Cluster.sh
export RESTART_MONGO_STANDALONE=SC_Stop_Mongo_Standalone.sh

for line in `cat ${METADBLISTMONGO}` ; do
        export MONGODESC=`echo $line | cut -d ":" -f 1`
        export RMONHOST=`echo $line | cut -d ":" -f 2`
        export RMONHOST_ORIG=`echo $line | cut -d ":" -f 2`
        nslookup $RMONHOST >>$LOGFILEMONGO
        if [ $? -eq 0 ] ; then
                ping -c 1 -i 1 $RMONHOST >>$LOGFILEMONGO
                if [ $? -ne 0 ] ; then
                        export RMONHOST=`nslookup $RMONHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1` >>$LOGFILEMONGO
                fi
        fi
        export RPORT=`echo $line | cut -d ":" -f 3`
        scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@$RMONHOST:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
        RUNCMD_ARG="test -d ${REMOTEHOME_DIR}"
        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
        if [ $? -ne 0 ] ; then
                RUNCMD_ARG="mkdir -p ${REMOTEHOME_DIR}"
                ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                if [ $? -ne 0 ] ; then
                        RETVAL=4
                        export MESG="Failing to connect to user: ${CURRUSER} - Error in ssh or inconsistent profile access using user:$MUSER on host: $RMONHOST "
                        echo "`date +"%d%b%Y_%H%M%S"`::Failing to connect to user: ${CURRUSER} - Error in ssh or inconsistent profile access using user:$MUSER on host: $RMONHOST" >>$LOGFILEMONGO
                fi
        else
                RETVAL=0
        fi
        if [ $RETVAL -eq 0 ] ; then

                echo "Checking for Cluster Enablement status for env: $MONGODESC on $RMONHOST/$RPORT." >>$LOGFILEMONGO
                scp -p ${SCRIPTDIR}/${MONGO_CLUSTER_CHK} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_CLUSTER_CHK.lst
                MON_RDET=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                LOCAL_RDET=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                RUNCMD_ARG=${REMOTEHOME}/logs
                ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                if [ $pwdchk -gt 0 ] ; then
                        MONGO_AUTH_CHK='Y'
                        MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                        MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                else
                        MONGO_AUTH_CHK='N'
                        MONGO_SABAADMIN_USR='notset'
                        MONGO_SABAADMIN_PWD='notset'
                fi
                ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CHK} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                RETVAL=$?
                if [ $RETVAL -eq 0 ] ; then
                        scp -p $CURRUSER@$RMONHOST:$MON_RDET $LOGDIR >>$LOGFILEMONGO

                        if [ -f ${LOCAL_RDET} ] ; then
                                MONCHK=`cat ${LOCAL_RDET} | awk '{print $1}'`
                                if [ $MONCHK -gt 0 ] ; then
                                        MONCHK=1
                                else
                                        MONCHK=0
                                fi
                                ssh $CURRUSER@$RMONHOST "cat $MON_RLOG" >>$LOGFILEMONGO
                                echo >>$LOGFILEMONGO
                                echo "`date +"%d%b%Y_%H%M%S"`::${ENVNAME} ${MUSER}@$RMONHOST ${MONGODESC}/${RPORT} Mongo is found clustering enabled (yes-0, No-1): $MONCHK" >>$LOGFILEMONGO
                                echo >>$LOGFILEMONGO
                                RUNCMD_ARG="rm $MON_RLOG"
                                ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                RUNCMD_ARG="rm $MON_RDET"
                                ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CHK}"
                                ssh $CURRUSER@$RMONHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                echo >>$LOGFILEMONGO

                                if [ ${MONCHK} -eq 0 ] ; then

                                        echo "`date +"%d%b%Y_%H%M%S"`::Fetching cluster configs, env: ${MUSER}@${RMONHOST}:${MONGODESC}/${RPORT} Mongo env." >>$LOGFILEMONGO
                                        echo "========================================================================================================" >>$LOGFILEMONGO

                                        scp -p ${SCRIPTDIR}/${MONGO_CLUSTER_CONFIGS} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                                        scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_CLUSTER_CONFIGS.lst
                                        MON_RDET=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                                        LOCAL_RDET=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                                        RUNCMD_ARG=${REMOTEHOME}/logs
                                        ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                                        pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                        if [ $pwdchk -gt 0 ] ; then
                                                MONGO_AUTH_CHK='Y'
                                                MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                        else
                                                MONGO_AUTH_CHK='N'
                                                MONGO_SABAADMIN_USR='notset'
                                                MONGO_SABAADMIN_PWD='notset'
                                        fi
                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CONFIGS} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                        RETVAL=$?
                                        if [ $RETVAL -eq 0 ] ; then
                                                scp -p $CURRUSER@$RMONHOST:$MON_RDET ${LOGDIR} >>$LOGFILEMONGO
                                                ssh $CURRUSER@$RMONHOST "cat $MON_RLOG" >>$LOGFILEMONGO

                                                if [ -f ${LOCAL_RDET} ] ; then

                                                        echo >>$LOGFILEMONGO
                                                        echo "Mongo Cluster current configs BEFORE STOP are as below:" >>$LOGFILEMONGO
                                                        echo "==========================================================" >>$LOGFILEMONGO
                                                        cat ${LOCAL_RDET} >>$LOGFILEMONGO
                                                        echo "========================================================================================================" >>$LOGFILEMONGO
                                                        echo >>$LOGFILEMONGO
                                                        RUNCMD_ARG="rm $MON_RLOG"
                                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                                        RUNCMD_ARG="rm $MON_RDET"
                                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                                        RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CONFIGS}"
                                                        ssh $CURRUSER@$RMONHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                                        echo >>$LOGFILEMONGO

                                                        cat /dev/null >${PID_STATUS}
                                                        cat /dev/null >${PID_STATUS_FINAL}

                                                        echo  >>$LOGFILEMONGO
                                                        echo "Now processing cluster nodes stop in orderly fashion (primary --> arbiter --> secondary)." >>$LOGFILEMONGO
                                                        echo  >>$LOGFILEMONGO
                                                        for line in `cat ${LOCAL_RDET}` ; do
                                                                export MHOST=`echo $line | cut -d ":" -f 1`
                                                                nslookup $MHOST >>$LOGFILEMONGO
                                                                if [ $? -eq 0 ] ; then
                                                                        ping -c 1 -i 1 $MHOST >>$LOGFILEMONGO
                                                                        if [ $? -ne 0 ] ; then
                                                                                export MHOST=`nslookup $MHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1` >>$LOGFILEMONGO
                                                                        fi
                                                                fi
                                                                export MPORT=`echo $line | cut -d ":" -f 2`
                                                                export MROLE=`echo $line | cut -d ":" -f 3`

                                                                scp -p ${SCRIPTDIR}/${RESTART_MONGO_CLUSTER} $CURRUSER@${MHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                                                                scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@${MHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO

                                                                if [ "${MROLE}" == 'PRIMARY' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_PRIMARY.lst
                                                                        for line in `cat ${PID_STATUS}` ; do
                                                                                export BPID=`echo $line | cut -d ":" -f 1`
                                                                                while :
                                                                                do
                                                                                        running_pid=$(ps -eo pid| awk '$1 == '${BPID}'')
                                                                                        if [ "x$running_pid" != "x" ] ; then
                                                                                                        printf "." >>$LOGFILEMONGO ; sleep 2; continue
                                                                                        fi
                                                                                        break
                                                                                done
                                                                        done
                                                                elif [ "${MROLE}" == 'SECONDARY' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_SECONDARY.lst
                                                                elif [ "${MROLE}" == 'ARBITER' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_ARBITER.lst
                                                                fi
                                                                RUNCMD_ARG=${REMOTEHOME}/logs
                                                                ssh $CURRUSER@$MHOST "mkdir -p ${RUNCMD_ARG}"
                                                                pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                                                if [ $pwdchk -gt 0 ] ; then
                                                                        MONGO_AUTH_CHK='Y'
                                                                        MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                                        MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                                                else
                                                                        MONGO_AUTH_CHK='N'
                                                                        MONGO_SABAADMIN_USR='notset'
                                                                        MONGO_SABAADMIN_PWD='notset'
                                                                fi
                                                                ssh $CURRUSER@$MHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RESTART_MONGO_CLUSTER} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${MPORT} -s ${MHOST} -l ${MON_RLOG} -x ${MROLE} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                                                PID=$!
                                                                echo "${PID}:${MHOST}:${MON_RLOG}:${MONGODESC}" >> ${PID_STATUS}
                                                        done

                                                        for line in `cat ${PID_STATUS}` ; do
                                                                export BPID=`echo $line | cut -d ":" -f 1`
                                                                export RHOST=`echo $line | cut -d ":" -f 2`
                                                                export RLOG=`echo $line | cut -d ":" -f 3`
                                                                export MONGODESC=`echo $line | cut -d ":" -f 4`
                                                                echo " " >>$LOGFILEMONGO
                                                                echo "`date +"%d%b%Y_%H%M%S"`::Stopping mongoDB: ${MONGODESC} on Host:${RHOST} " >>$LOGFILEMONGO

                                                                echo "Waiting on Process id: $BPID" >>$LOGFILEMONGO
                                                                while :
                                                                do
                                                                        running_pid=$(ps -eo pid| awk '$1 == '${BPID}'')
                                                                        if [ "x$running_pid" != "x" ] ; then
                                                                                        printf "." >>$LOGFILEMONGO ; sleep 5; continue
                                                                        fi
                                                                        printf "Process: $BPID done!\n" >>$LOGFILEMONGO
                                                                        break
                                                                done

                                                                ls -d /proc/${BPID} 2>/dev/null
                                                                PIDCHK=$?
                                                                if [ $PIDCHK -gt 0 ] ; then
                                                                        ssh $CURRUSER@$RHOST "cat $RLOG" >>$LOGFILEMONGO
                                                                        grep "${BPID}:${RHOST}" ${PID_STATUS} >> ${PID_STATUS_FINAL}

                                                                        RUNCMD_ARG="rm $RLOG"
                                                                        ssh $CURRUSER@$RHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                                                        RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${RESTART_MONGO_CLUSTER}"
                                                                        ssh $CURRUSER@$RHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                                                fi
                                                        done

                                                        FILE1COUNT=`cat ${PID_STATUS} | wc -l`
                                                        FILE2COUNT=`cat ${PID_STATUS_FINAL} | wc -l`
                                                        DIFF_OUTPUT=`expr $FILE1COUNT - $FILE2COUNT`

                                                        if [ ${DIFF_OUTPUT} -gt 0 ] ; then
                                                                export MESG="Seems errors in MongoDB stop, check logs for more details."
                                                                echo "Seems Errors in MongoDB stop, check logs for more details." >>$LOGFILEMONGO
                                                                RETVAL=5
                                                        fi
                                                fi
                                        fi
                                else
                                        echo  >>$LOGFILEMONGO
                                        echo "Mongo: ${MONGODESC} environment does not have clustering enabled." >>$LOGFILEMONGO
                                        echo  >>$LOGFILEMONGO

                                        echo "`date +"%d%b%Y_%H%M%S"`::Stopping Standalone MongoDB, env: ${MUSER}@${RMONHOST}:${MONGODESC}/${RPORT} Mongo env." >>$LOGFILEMONGO
                                        echo "========================================================================================================" >>$LOGFILEMONGO
                                        scp -p ${SCRIPTDIR}/${RESTART_MONGO_STANDALONE} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                                        scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEMONGO
                                        RUNCMD_ARG=${REMOTEHOME}/logs
                                        ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                                        pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                        if [ $pwdchk -gt 0 ] ; then
                                                MONGO_AUTH_CHK='Y'
                                                MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                        else
                                                MONGO_AUTH_CHK='N'
                                                MONGO_SABAADMIN_USR='notset'
                                                MONGO_SABAADMIN_PWD='notset'
                                        fi
                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RESTART_MONGO_STANDALONE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                        ssh $CURRUSER@$RMONHOST "cat $MON_RLOG" >>$LOGFILEMONGO
                                        echo >>$LOGFILEMONGO
                                        RUNCMD_ARG="rm $MON_RLOG"
                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                        RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${RESTART_MONGO_STANDALONE}"
                                        ssh $CURRUSER@$RMONHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEMONGO
                                        echo >>$LOGFILEMONGO
                                        touch ${PID_STATUS} ${PID_STATUS_FINAL}
                                fi
                        fi
                fi
        fi
done

echo "`date +"%d%b%Y_%H%M%S"`::MONGO databases stop, Script Completed...verifying logs. " >>$LOGFILEMONGO
echo "======================================================================================" >>$LOGFILEMONGO
echo " " >>$LOGFILEMONGO
echo " " >>$LOGFILEMONGO
rm ${PID_STATUS} ${PID_STATUS_FINAL}

return $RETVAL
}
########### Mongo stop function ends here ################

#######################################################################
########### Checkpointing DB services : Oracle and Mongo ##############
#######################################################################
Create_Checkpoint () {

echo " ">>$LOGFILE
echo " ">>$LOGFILE
echo "===============================================" >>$LOGFILE
echo "`date +"%d%b%Y_%H%M%S"`::Performing Stop Oracle Services Checkpoint..." >>$LOGFILE
echo "===============================================" >>$LOGFILE
echo " ">>$LOGFILE
echo " ">>$LOGFILE

export GET_ORAHOME_LISTENER=SC_Get_Listener_Orahome.sh
export MONGO_CLUSTER_CONFIGS=SC_Mongo_Cluster_Configs_Shutdown.sh
export MONGO_CLUSTER_CHK=SC_Mongo_Cluster_Chk.sh
export GET_MONGO_CLUSTER_INFO=SC_Get_Local_Mongo_Env.sh

scp -p ${SCRIPTDIR}/${CHK_ORACLE} $CURRUSER@${METADB_HOSTNAME}:${REMOTEHOME_DIR}/

for line in `cat ${METADBLISTORACLE}` ; do
export RORAHOST=`echo $line | cut -d ":" -f 1`
nslookup $RORAHOST >/dev/null
if [ $? -eq 0 ] ; then
        ping -c 1 -i 1 $RORAHOST >/dev/null
        if [ $? -ne 0 ] ; then
                export RORAHOST=`nslookup $RORAHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1`
        fi
fi
export RSID=`echo $line | cut -d ":" -f 2`
export RPORT=`echo $line | cut -d ":" -f 3`
if [ $RETVAL -eq 0 ] ; then

        scp -p ${SCRIPTDIR}/${GET_ORAHOME_LISTENER} $CURRUSER@${RORAHOST}:${REMOTEHOME_DIR}/
        ORA_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RORAHOST}_${RSID}_ORACLE_RESTART.lst
        ORA_LOGFILE=${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RORAHOST}_${RSID}_ORACLE_RESTART.lst
        RUNCMD_ARG="${REMOTEHOME_DIR}/logs"
        ssh $CURRUSER@$RORAHOST "mkdir -p ${RUNCMD_ARG}"
        ssh $CURRUSER@$RORAHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${GET_ORAHOME_LISTENER} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${RSID} -t ${DATE} -p ${RPORT} -o ${ORA_RLOG} -m ${ORACLE_SABAADMIN_USR} -w ${ORACLE_SABAADMIN_PWD} " >>$LOGFILE
        RETVAL=$?
        scp -p $CURRUSER@$RORAHOST:${ORA_RLOG} ${SCRIPTDIR}/logs/ >>$LOGFILE
        LISTNAME=`cat ${SCRIPTDIR}/logs/${ORA_LOGFILE} | awk '{print $2}' | tr -d " "`
        ORA_HOME=`cat ${SCRIPTDIR}/logs/${ORA_LOGFILE} | awk '{print $1}' | tr -d " "`
        STARTUPSEQ=0
        ssh $CURRUSER@${METADB_HOSTNAME} "mkdir -p ${RUNCMD_ARG}"
        ssh $CURRUSER@${METADB_HOSTNAME} "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CHK_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${META_SID} -t ${DATE} -p ${RPORT} -o ${ORA_RLOG} -m ${METAUSRNM} -w ${METAUSRPWD} -s ${RSID} -y 'oracle' -r ${LISTNAME} -l ${ORA_HOME} -b ${RORAHOST} -f ${STARTUPSEQ} -x ${RPORT} -g ${RORAHOST} " >>$LOGFILE
        RETVAL=$?
fi
done


for line in `cat ${METADBLISTMONGO}` ; do
        export MONGODESC=`echo $line | cut -d ":" -f 1`
        export RMONHOST=`echo $line | cut -d ":" -f 2`
        export RMONHOST_ORIG=`echo $line | cut -d ":" -f 2`
        nslookup $RMONHOST >/dev/null
        if [ $? -eq 0 ] ; then
                ping -c 1 -i 1 $RMONHOST >/dev/null
                if [ $? -ne 0 ] ; then
                        export RMONHOST=`nslookup $RMONHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1`
                fi
        fi
        export RPORT=`echo $line | cut -d ":" -f 3`

        if [ $RETVAL -eq 0 ] ; then

                scp -p ${SCRIPTDIR}/${MONGO_CLUSTER_CHK} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/ >>$LOGFILE
                MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_CLUSTER_CHK.lst
                MON_RDET=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                LOCAL_RDET=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                MONGO_HOME_ENV=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_HOME.lst
                RUNCMD_ARG=${REMOTEHOME}/logs
                ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                if [ $pwdchk -gt 0 ] ; then
                        MONGO_AUTH_CHK='Y'
                        MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                        MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                else
                        MONGO_AUTH_CHK='N'
                        MONGO_SABAADMIN_USR='notset'
                        MONGO_SABAADMIN_PWD='notset'
                fi
                ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CHK} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                RETVAL=$?
                if [ $RETVAL -eq 0 ] ; then
                        scp -p $CURRUSER@$RMONHOST:$MON_RDET $LOGDIR

                        if [ -f ${LOCAL_RDET} ] ; then
                                MONCHK=`cat ${LOCAL_RDET} | awk '{print $1}'`
                                ssh $CURRUSER@$RMONHOST "cat $MON_RLOG"
                                echo >>$LOGFILE

                                if [ ${MONCHK} -eq 0 ] ; then
                                        scp -p ${SCRIPTDIR}/${MONGO_CLUSTER_CONFIGS} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/
                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_CLUSTER_CONFIGS.lst
                                        MON_RDET=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                                        LOCAL_RDET=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_DETAILS.lst
                                        MONGO_HOME_ENV=${LOGDIR}/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RMONHOST}_${MONGODESC}_${RPORT}_MONGO_HOME.lst
                                        RUNCMD_ARG=${REMOTEHOME}/logs
                                        ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                                        pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                        if [ $pwdchk -gt 0 ] ; then
                                                MONGO_AUTH_CHK='Y'
                                                MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                        else
                                                MONGO_AUTH_CHK='N'
                                                MONGO_SABAADMIN_USR='notset'
                                                MONGO_SABAADMIN_PWD='notset'
                                        fi
                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${MONGO_CLUSTER_CONFIGS} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                        RETVAL=$?
                                        if [ $RETVAL -eq 0 ] ; then
                                                scp -p $CURRUSER@$RMONHOST:$MON_RDET ${LOGDIR}
                                                ssh $CURRUSER@$RMONHOST "cat $MON_RLOG"

                                                if [ -f ${LOCAL_RDET} ] ; then

                                                        echo  >>$LOGFILE
                                                        echo "Now processing mongo cluster nodes checkpoints in orderly fashion (primary --> arbiter --> secondary)." >>$LOGFILE
                                                        echo "===========================================================================================================" >>$LOGFILE
                                                        cat ${LOCAL_RDET} >>$LOGFILE
                                                        echo  >>$LOGFILE
                                                        for line in `cat ${LOCAL_RDET}` ; do
                                                                export MHOST=`echo $line | cut -d ":" -f 1`
                                                                nslookup $MHOST >>$LOGFILE
                                                                if [ $? -eq 0 ] ; then
                                                                        ping -c 1 -i 1 $MHOST >/dev/null
                                                                        if [ $? -ne 0 ] ; then
                                                                                export MHOST=`nslookup $MHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1`
                                                                        fi
                                                                fi
                                                                export MPORT=`echo $line | cut -d ":" -f 2`
                                                                export MROLE=`echo $line | cut -d ":" -f 3`

                                                                scp -p ${SCRIPTDIR}/${GET_MONGO_CLUSTER_INFO} $CURRUSER@${MHOST}:${REMOTEHOME_DIR}/

                                                                RUNCMD_ARG=${REMOTEHOME}/logs
                                                                ssh $CURRUSER@$MHOST "mkdir -p ${RUNCMD_ARG}"
                                                                pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                                                if [ $pwdchk -gt 0 ] ; then
                                                                        MONGO_AUTH_CHK='Y'
                                                                        MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                                        MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                                                else
                                                                        MONGO_AUTH_CHK='N'
                                                                        MONGO_SABAADMIN_USR='notset'
                                                                        MONGO_SABAADMIN_PWD='notset'
                                                                fi

                                                                ssh $CURRUSER@${MHOST} "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${GET_MONGO_CLUSTER_INFO} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${MPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                                                scp -p $CURRUSER@${MHOST}:$MON_RDET ${MONGO_HOME_ENV}
                                                                MONGO_HOME_BIN=`cat ${MONGO_HOME_ENV} | awk -F: '{print $1}'`
                                                                MONGO_RUN_COMMAND=`cat ${MONGO_HOME_ENV} | awk -F: '{print $2}'`
                                                                MONGO_RUN_COMMAND=\"${MONGO_RUN_COMMAND}\"
                                                                if [ "${MROLE}" == 'PRIMARY' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_PRIMARY.lst
                                                                        STARTUPSEQ=2
                                                                        ssh $CURRUSER@${METADB_HOSTNAME} "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CHK_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${META_SID} -t ${DATE} -p ${MPORT} -o ${MON_RLOG} -m ${METAUSRNM} -w ${METAUSRPWD} -s ${MONGODESC} -y 'mongo_cluster' -r "${MONGO_RUN_COMMAND}" -l ${MONGO_HOME_BIN} -b ${MHOST} -f ${STARTUPSEQ} -x ${RPORT} -g ${RMONHOST_ORIG} " >>$LOGFILE
                                                                elif [ "${MROLE}" == 'SECONDARY' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_SECONDARY.lst
                                                                        STARTUPSEQ=3
                                                                        ssh $CURRUSER@${METADB_HOSTNAME} "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CHK_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${META_SID} -t ${DATE} -p ${MPORT} -o ${MON_RLOG} -m ${METAUSRNM} -w ${METAUSRPWD} -s ${MONGODESC} -y 'mongo_cluster' -r "${MONGO_RUN_COMMAND}" -l ${MONGO_HOME_BIN} -b ${MHOST} -f ${STARTUPSEQ} -x ${RPORT} -g ${RMONHOST_ORIG} " >>$LOGFILE
                                                                elif [ "${MROLE}" == 'ARBITER' ] ; then
                                                                        MON_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${MHOST}_${MHOST}_${MPORT}_ARBITER.lst
                                                                        STARTUPSEQ=1
                                                                        ssh $CURRUSER@${METADB_HOSTNAME} "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CHK_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${META_SID} -t ${DATE} -p ${MPORT} -o ${MON_RLOG} -m ${METAUSRNM} -w ${METAUSRPWD} -s ${MONGODESC} -y 'mongo_cluster' -r "${MONGO_RUN_COMMAND}" -l ${MONGO_HOME_BIN} -b ${MHOST} -f ${STARTUPSEQ} -x ${RPORT} -g ${RMONHOST_ORIG} " >>$LOGFILE
                                                                fi
                                                                RETVAL=$?
                                                        done
                                                fi
                                        fi

                                else
                                        echo "`date +"%d%b%Y_%H%M%S"`::Creating checkpoint for Standalone MongoDB, env: ${MUSER}@${RMONHOST}:${MONGODESC}/${RPORT} Mongo env." >>$LOGFILE
                                        echo "========================================================================================================" >>$LOGFILE
                                        scp -p ${SCRIPTDIR}/${GET_MONGO_CLUSTER_INFO} $CURRUSER@${RMONHOST}:${REMOTEHOME_DIR}/
                                        RUNCMD_ARG=${REMOTEHOME}/logs
                                        ssh $CURRUSER@$RMONHOST "mkdir -p ${RUNCMD_ARG}"
                                        pwdchk=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | wc -l`
                                        if [ $pwdchk -gt 0 ] ; then
                                                MONGO_AUTH_CHK='Y'
                                                MONGO_SABAADMIN_USR=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $2}'`
                                                MONGO_SABAADMIN_PWD=`grep "mongodbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | grep -i ${RMONHOST_ORIG}| grep -i ${RPORT} | awk -F- '{print $3}'`
                                        else
                                                MONGO_AUTH_CHK='N'
                                                MONGO_SABAADMIN_USR='notset'
                                                MONGO_SABAADMIN_PWD='notset'
                                        fi
                                        ssh $CURRUSER@$RMONHOST "sudo -u ${MUSER} ${REMOTEHOME_DIR}/${GET_MONGO_CLUSTER_INFO} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${MUSER} -d ${MONGODESC} -t ${DATE} -p ${RPORT} -l ${MON_RLOG} -x ${MON_RDET} -c ${MONGO_AUTH_CHK} -a ${MONGO_SABAADMIN_USR} -w ${MONGO_SABAADMIN_PWD} "
                                        scp -p $CURRUSER@$RMONHOST:$MON_RDET ${MONGO_HOME_ENV}
                                        MONGO_HOME_BIN=`cat ${MONGO_HOME_ENV} | awk -F: '{print $1}'`
                                        MONGO_RUN_COMMAND=`cat ${MONGO_HOME_ENV} | awk -F: '{print $2}'`
                                        MONGO_RUN_COMMAND=\"${MONGO_RUN_COMMAND}\"
                                        STARTUPSEQ=0
                                        ssh $CURRUSER@${METADB_HOSTNAME} "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CHK_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${META_SID} -t ${DATE} -p ${RPORT} -o ${MON_RLOG} -m ${METAUSRNM} -w ${METAUSRPWD} -s ${MONGODESC} -y 'mongo_standalone' -r "${MONGO_RUN_COMMAND}" -l ${MONGO_HOME_BIN} -b ${RMONHOST} -f ${STARTUPSEQ} -x ${RPORT} -g ${RMONHOST_ORIG} " >>$LOGFILE
                                        RETVAL=$?
                                fi
                        fi
                fi
        fi
done

echo "`date +"%d%b%Y_%H%M%S"`::Oracle and Mongo databases checkpoints, Script Completed." >>$LOGFILE
echo "======================================================================================" >>$LOGFILE
echo " " >>$LOGFILE
echo " " >>$LOGFILE

return $RETVAL
}



####################################################
########### Oracle stop function ################
####################################################
Restart_OracleDB () {
>$LOGFILEORACLE
echo " " >>$LOGFILEORACLE
echo "======================================================================================" >>$LOGFILEORACLE
echo "`date +"%d%b%Y_%H%M%S"`::Stopping Oracle databases, script starts...please wait " >>$LOGFILEORACLE
echo "List of OracleDB environments to be stopped:" >>$LOGFILEORACLE
echo "===============================================" >>$LOGFILEORACLE
cat ${METADBLISTORACLE} >>$LOGFILEORACLE
echo "===============================================" >>$LOGFILEORACLE
export OPID_STATUS=/tmp/PID_${UNQID}_${DATE}_${PROCID}_oracle.stat
cat /dev/null >${OPID_STATUS}

for line in `cat ${METADBLISTORACLE}` ; do
export RORAHOST=`echo $line | cut -d ":" -f 1`
nslookup $RORAHOST >>$LOGFILEORACLE
if [ $? -eq 0 ] ; then
        ping -c 1 -i 1 $RORAHOST >>$LOGFILEORACLE
        if [ $? -ne 0 ] ; then
                export RORAHOST=`nslookup $RORAHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1` >>$LOGFILEORACLE
        fi
fi
export RSID=`echo $line | cut -d ":" -f 2`
export RPORT=`echo $line | cut -d ":" -f 3`
scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@$RORAHOST:${REMOTEHOME_DIR}/ >>$LOGFILEORACLE
RUNCMD_ARG="test -d ${REMOTEHOME_DIR}"
ssh $CURRUSER@$RORAHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEORACLE
if [ $? -ne 0 ] ; then
        RUNCMD_ARG="mkdir -p ${REMOTEHOME_DIR}"
        ssh $CURRUSER@$RORAHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILEORACLE
        if [ $? -ne 0 ] ; then
                RETVAL=4
                export MESG="Failing to connect to user: ${CURRUSER} - Error in ssh or inconsistent profile access for user:$OSUSER on host: $RORAHOST "
                echo "`date +"%d%b%Y_%H%M%S"`::Failing to connect to user: ${CURRUSER} - Error in ssh or inconsistent profile access for user:$OSUSER on host: $RORAHOST" >>$LOGFILEORACLE
        fi
else
        RETVAL=0
fi
if [ $RETVAL -eq 0 ] ; then

        export RESTART_ORACLE=SC_Stop_Oracle.sh

        scp -p ${SCRIPTDIR}/${RESTART_ORACLE} $CURRUSER@${RORAHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEORACLE
        scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@${RORAHOST}:${REMOTEHOME_DIR}/ >>$LOGFILEORACLE
        ORA_RLOG=${REMOTEHOME_DIR}/logs/${ENVNAME}_${UNQID}_${DATE}_${PROCID}_${RORAHOST}_${RSID}_ORACLE_RESTART.lst
        RUNCMD_ARG="mkdir -p ${REMOTEHOME_DIR}/logs"
        ssh $CURRUSER@$RORAHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'"
        ssh $CURRUSER@$RORAHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RESTART_ORACLE} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${RSID} -t ${DATE} -p ${RPORT} -l ${ORA_RLOG} -m ${ORACLE_SABAADMIN_USR} -w ${ORACLE_SABAADMIN_PWD} " &
        PID=$!
        echo "${PID}:${RORAHOST}:${ORA_RLOG}:${RSID}:`date +"%d%b%Y_%H%M%S"` " >> ${OPID_STATUS}
        sleep 1
fi
done
RETVAL=$?

return $RETVAL
}
########### Oracle stop function ends here ################


####################################################
########### Parallel stop function ##############
####################################################
Restart_All_DBs_Parallel () {
Create_Checkpoint
if [ $RETVAL -eq 0 ] ; then
Restart_OracleDB
RETVAL=$?
if [ $RETVAL -gt 0 ] ; then export MESG="Error(s) Running Oracle Stop, check logs." ; RETVAL=5 ; fi

echo >>$LOGFILE
echo "Both Oracle and Mongo stop are going on in parallel, tail through below intermediate temp trace log files for latest... " >>$LOGFILE
echo "=====================================================" >>$LOGFILE
echo "For Oracle: `echo ${LOGFILEORACLE}` " >>$LOGFILE
echo "For Mongo: `echo ${LOGFILEMONGO}` " >>$LOGFILE
echo "=====================================================" >>$LOGFILE

Restart_MongoDB
RETVAL=$?
if [ $RETVAL -gt 0 ] ; then export MESG="Error(s) Running Mongo Stop, check logs." ; RETVAL=5 ; fi

echo >>$LOGFILE
echo "Waiting on following oracle processes to complete execution:" >>$LOGFILE
echo "=====================================================" >>$LOGFILE
cat ${OPID_STATUS} >>$LOGFILE
echo "=====================================================" >>$LOGFILE
echo >>$LOGFILE

export OPID_STATUS_FINAL=/tmp/PID_FINAL_${UNQID}_${DATE}_${PROCID}_oracle.stat
>${OPID_STATUS_FINAL}
for line in `cat ${OPID_STATUS}` ; do
        export BPID=`echo $line | cut -d ":" -f 1`
        export RORAHOST=`echo $line | cut -d ":" -f 2`
        export RLOG=`echo $line | cut -d ":" -f 3`
        export RSID=`echo $line | cut -d ":" -f 4`
        export RESTARTTIME=`echo $line | cut -d ":" -f 5`
        echo " " >>$LOGFILE
        echo "$RESTARTTIME::Stopping db: ${RSID} on Host:${RORAHOST} " >>$LOGFILE

        while :
        do
        running_pid=$(ps -eo pid| awk '$1 == '${BPID}'')
        if [ "x$running_pid" != "x" ] ; then
                printf "."; sleep 5; continue
        fi
        printf "done!\n"
        break
        done

        ls -d /proc/${BPID} 2>/dev/null
        PIDCHK=$?
        if [ $PIDCHK -gt 0 ] ; then
                ssh $CURRUSER@$RORAHOST "cat $RLOG" >>$LOGFILE
                errcnt=`grep -v ORA-32004 $LOGFILE | egrep -i 'Error|ORA-' | wc -l`
                if [ $errcnt -gt 0 ] ; then
                        >>$LOGFILE ; echo "Errors found while stopping $RSID DB on $RORAHOST." >>$LOGFILE ; >>$LOGFILE
                        RETVAL=5
                fi
                grep "${BPID}:${RORAHOST}" ${OPID_STATUS} >> ${OPID_STATUS_FINAL}
        fi
done

for line in `cat ${OPID_STATUS}` ; do
        export RORAHOST=`echo $line | cut -d ":" -f 2`
        export RLOG=`echo $line | cut -d ":" -f 3`

        RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${RESTART_ORACLE}"
        ssh $CURRUSER@$RORAHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
        RUNCMD_ARG="rm $RLOG"
        ssh $CURRUSER@$RORAHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
done

FILE1COUNT=`cat ${OPID_STATUS} | wc -l`
FILE2COUNT=`cat ${OPID_STATUS_FINAL} | wc -l`
DIFF_OUTPUT=`expr $FILE1COUNT - $FILE2COUNT`

if [ ${DIFF_OUTPUT} -gt 0 ] ; then
for line in `cat ${OPID_STATUS}` ; do
                export BPID=`echo $line | cut -d ":" -f 1`
                export RORAHOST=`echo $line | cut -d ":" -f 2`
                export RSID=`echo $line | cut -d ":" -f 4`
                CHK_ISSUE_DB=`grep "${BPID}:${RORAHOST}" ${OPID_STATUS_FINAL}| grep -v grep|wc -l`
                if [ ${CHK_ISSUE_DB} -gt 0 ] ; then
                        export MESG="Error in Oracle db stop on host: $RORAHOST for DB:${RSID}"
                        echo ${MESG} >>$LOGFILE
                        RETVAL=5
                fi
done
fi
rm ${OPID_STATUS} ${OPID_STATUS_FINAL}
echo "`date +"%d%b%Y_%H%M%S"`::Oracle databases stop, Script Completed...verifying logs. " >>$LOGFILE
echo "======================================================================================" >>$LOGFILE
echo " " >>$LOGFILE
echo " " >>$LOGFILE


while :
do
mongo_run_status=`grep "MONGO databases stop, Script Completed...verifying logs." $LOGFILEMONGO | wc -l`
if [ ${mongo_run_status} = 0 ] ; then
        printf "."; sleep 5; continue
fi
printf "done!\n"
break
done
CHK_ISSUE_DB=`grep -i Error $LOGFILEMONGO| grep -v grep | wc -l`
cat $LOGFILEMONGO >>$LOGFILE
if [ ${CHK_ISSUE_DB} -gt 0 ] ; then
   export MESG="Error in Mongo db stop, check above the logs for mongo stop details. "
   echo ${MESG} >>$LOGFILE
   RETVAL=5
fi
rm -f $LOGFILEMONGO $LOGFILEORACLE
fi

return $RETVAL
}


#################################################################
########### Oracle fetch metadb details function ################
#################################################################
Fetch_Metadb () {

REMOTEHOMELOC=/tmp/remotehomeloc.lst.$UNQID
ssh $CURRUSER@$RHOST "echo \$HOME">${REMOTEHOMELOC}
export TEMPDIR=`cat ${REMOTEHOMELOC}`
echo "TEMPDIR=$TEMPDIR" >>$LOGFILE
ssh $CURRUSER@$RHOST "mkdir -p ${TEMPDIR}" >>$LOGFILE
scp -p ${SCRIPTDIR}/${RHOME} $CURRUSER@$RHOST:${TEMPDIR}/ >>$LOGFILE
#REMOTEHOME=`ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${TEMPDIR}/${RHOME} '\$HOME'"`
REMOTEHOME=`ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${TEMPDIR}/${RHOME} $TEMPDIR"`
echo "REMOTEHOME=$REMOTEHOME" >>$LOGFILE
RUNCMD_ARG=${REMOTEHOME}/logs
ssh $CURRUSER@$RHOST "mkdir -p ${RUNCMD_ARG}" >>$LOGFILE
RUNCMD_ARG=${REMOTEHOME}
export REMOTEHOME_DIR=`ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${TEMPDIR}/${RHOME} '${RUNCMD_ARG}'"`
echo "REMOTEHOME_DIR=$REMOTEHOME_DIR" >>$LOGFILE
scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE
RUNCMD_ARG="test -d ${REMOTEHOME_DIR}"
ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
if [ $? -ne 0 ] ; then
        RUNCMD_ARG="mkdir -p ${REMOTEHOME_DIR}"
        ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
        if [ $? -ne 0 ] ; then
                RETVAL=4
                export MESG="Error ssh to host: $RHOST, Username: ${CURRUSER} "
                echo "`date +"%d%b%Y_%H%M%S"`::Error ssh to host: $RHOST", Username: ${CURRUSER} >>$LOGFILE
        fi
else
        RETVAL=0
fi

if [ $RETVAL -eq 0 ] ; then

        export FETCH_METADB=SC_Fetch_Metadb_Det.sh
        export CLUSTER_CONFIRM_CHK=SC_Fetch_Metadb_Cluschk.sh
        export FETCH_CREDENTIALS=SC_Fetch_Credentials.sh
        export CHK_ORACLE=SC_Insert_Metadb.sh

        export CLUSCHK=${ENVNAME}_${UNQID}_${DATE}_${PROCID}_CLUSCHK.lst
        export CLUSCRED=${ENVNAME}_${UNQID}_${DATE}_${PROCID}_CLUSCRED.lst
        export METADBORACLE=${ENVNAME}_${UNQID}_${DATE}_${PROCID}_ORACLE.lst
        export METADBMONGO=${ENVNAME}_${UNQID}_${DATE}_${PROCID}_MONGO.lst
        export METADBCLUSCHK=${SCRIPTDIR}/logs/${CLUSCHK}
        export METADBLISTORACLE=${SCRIPTDIR}/logs/${METADBORACLE}
        export METADBLISTMONGO=${SCRIPTDIR}/logs/${METADBMONGO}
        scp -p ${SCRIPTDIR}/${FETCH_METADB} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE
        scp -p ${SCRIPTDIR}/${FETCH_CREDENTIALS} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE
        scp -p ${SCRIPTDIR}/${CLUSTER_CONFIRM_CHK} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE
        scp -p ${SCRIPTDIR}/${RUNCMD} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE
        scp -p ${SCRIPTDIR}/${CHK_ORACLE} $CURRUSER@$RHOST:${REMOTEHOME_DIR}/ >>$LOGFILE

        echo " " >>$LOGFILE
        echo "`date +"%d%b%Y_%H%M%S"`::Fetching Metadb credentials: $CURRUSER@$RHOST, db: ${ORACLE_SID} " >>$LOGFILE
        ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${FETCH_CREDENTIALS} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${ORACLE_SID} -t ${DATE} -p ${PORT} -o ${CLUSCRED} -m ${METAUSRNM} -w ${METAUSRPWD}" >>$LOGFILE
        RETVAL=$?
        echo " " >>$LOGFILE
        if [ $RETVAL -ne 0 ] ; then
                echo "`date +"%d%b%Y_%H%M%S"`::Error Fetching Metadb credentials: $CURRUSER@$RHOST,db: ${ORACLE_SID} " >>$LOGFILE
                export MESG="Problem fetching METADB credentials from $RHOST, either ssh to $RHOST is not working OR other DB errors, Username: ${CURRUSER}."
                RETVAL=3
        else
        scp -p $CURRUSER@$RHOST:${REMOTEHOME_DIR}/logs/${CLUSCRED} ${SCRIPTDIR}/logs/ >>$LOGFILE
        export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${FETCH_CREDENTIALS}"
        ssh $CURRUSER@$RHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
        export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/logs/${CLUSCRED}"
        ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
        pwdchk=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | wc -l`
        if [ $pwdchk -gt 0 ] ; then
                ORACLE_AUTH_CHK='Y'
                ORACLE_SABAADMIN_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | awk -F- '{print $2}'`
                ORACLE_SABAADMIN_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabaadmin' | awk -F- '{print $3}'`
                ORACLE_ANT_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i '\-ant\-' | awk -F- '{print $2}'`
                ORACLE_ANT_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i '\-ant\-' | awk -F- '{print $3}'`
                ORACLE_SABADI_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'saba_di' | awk -F- '{print $2}'`
                ORACLE_SABADI_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'saba_di' | awk -F- '{print $3}'`
                ORACLE_SMF_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'smf' | awk -F- '{print $2}'`
                ORACLE_SMF_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'smf' | awk -F- '{print $3}'`
                ORACLE_JET_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i '\-jet\-' | awk -F- '{print $2}'`
                ORACLE_JET_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i '\-jet\-' | awk -F- '{print $3}'`
                ORACLE_BENCHMARKS_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'benchmarks' | awk -F- '{print $2}'`
                ORACLE_BENCHMARKS_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'benchmarks' | awk -F- '{print $3}'`
                ORACLE_SABAMASTER_USR=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabamaster' | awk -F- '{print $2}'`
                ORACLE_SABAMASTER_PWD=`grep "oracledbcred" ${SCRIPTDIR}/logs/${CLUSCRED} | grep -i 'sabamaster' | awk -F- '{print $3}'`
        else
                ORACLE_AUTH_CHK='N'
                ORACLE_SABAADMIN_USR='SABAADMIN'
                ORACLE_SABAADMIN_PWD='dba4you'
        fi
        #rm -f ${SCRIPTDIR}/logs/${CLUSCRED}

        echo "`date +"%d%b%Y_%H%M%S"`::Crosschecking Cluster Name in Metadb: $CURRUSER@$RHOST, db: ${ORACLE_SID} " >>$LOGFILE
        ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${CLUSTER_CONFIRM_CHK} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${ORACLE_SID} -t ${DATE} -p ${PORT} -o ${CLUSCHK} -m ${METAUSRNM} -w ${METAUSRPWD} " >>$LOGFILE
        RETVAL=$?
        echo " " >>$LOGFILE
        if [ $RETVAL -ne 0 ] ; then
                echo "`date +"%d%b%Y_%H%M%S"`::Error Fetching Metadb Details from host: $CURRUSER@$RHOST,db: ${ORACLE_SID} " >>$LOGFILE
                export MESG="Problem fetching METADB details on $RHOST, either ssh to $RHOST is not working OR other DB errors, Username: ${CURRUSER}."
                RETVAL=3
        else
                scp -p $CURRUSER@$RHOST:${REMOTEHOME_DIR}/logs/${CLUSCHK} ${SCRIPTDIR}/logs/ >>$LOGFILE
                export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${CLUSTER_CONFIRM_CHK}"
                ssh $CURRUSER@$RHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
                export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/logs/${CLUSCHK}"
                ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
                echo "`date +"%d%b%Y_%H%M%S"`::Cluster Name found in Metadb is," >>$LOGFILE
                cat ${METADBCLUSCHK} >>$LOGFILE
                FOUND_CLUS_NAME=`cat $METADBCLUSCHK |tr -d ' '`
                if [[ ${FOUND_CLUS_NAME}"x" != ${ENVNAME}"x" ]] ; then
                        echo "`date +"%d%b%Y_%H%M%S"`::Error Crosschecking Cluster Identification, Input cluster mismatched with actual clustername: $CURRUSER@$RHOST,db: ${ORACLE_SID} " >>$LOGFILE
                        export MESG="Problem Crosschecking Cluster Identification on $RHOST, refer the execution logs for more details, Username: ${CURRUSER}."
                        RETVAL=3
                else
                        echo "`date +"%d%b%Y_%H%M%S"`::Input cluster matching with actual clustername: $CURRUSER@$RHOST,db: ${ORACLE_SID} " >>$LOGFILE
                        echo " " >>$LOGFILE
                        echo "`date +"%d%b%Y_%H%M%S"`::Fetching Metadb Details from host: $CURRUSER@$RHOST, db: ${ORACLE_SID} " >>$LOGFILE
                        ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${FETCH_METADB} -e ${ENVNAME} -z ${PROCID} -q ${UNQID} -u ${OSUSER} -d ${ORACLE_SID} -t ${DATE} -p ${PORT} -o ${METADBORACLE} -m ${METADBMONGO} -x ${METAUSRNM} -w ${METAUSRPWD} " >>$LOGFILE
                        RETVAL=$?
                        echo " " >>$LOGFILE
                        if [ $RETVAL -ne 0 ] ; then
                                echo "`date +"%d%b%Y_%H%M%S"`::Error Fetching Metadb Details from host: $CURRUSER@$RHOST,db: ${ORACLE_SID} " >>$LOGFILE
                                export MESG="Problem fetching METADB details on $RHOST, either ssh to $RHOST is not working OR other DB errors, Username: ${CURRUSER}."
                                RETVAL=3
                        else
                                scp -p $CURRUSER@$RHOST:${REMOTEHOME_DIR}/logs/${METADBORACLE} ${SCRIPTDIR}/logs/ >>$LOGFILE
                                scp -p $CURRUSER@$RHOST:${REMOTEHOME_DIR}/logs/${METADBMONGO} ${SCRIPTDIR}/logs/ >>$LOGFILE
                                echo " " >>$LOGFILE
                                echo "`date +"%d%b%Y_%H%M%S"`::Oracle metadb details fetched are," >>$LOGFILE
                                cat ${METADBLISTORACLE} >>$LOGFILE
                                echo " " >>$LOGFILE
                                echo "`date +"%d%b%Y_%H%M%S"`::Mongo metadb details fetched are," >>$LOGFILE
                                cat ${METADBLISTMONGO} >>$LOGFILE
                                echo " " >>$LOGFILE
                                echo "`date +"%d%b%Y_%H%M%S"`::Completed the Process of Fetching Metadb Details from host: $CURRUSER@$RHOST,db: ${ORACLE_SID}" >>$LOGFILE
                                export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/${FETCH_METADB}"
                                ssh $CURRUSER@$RHOST "${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
                                export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/logs/${METADBORACLE}"
                                ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE
                                export RUNCMD_ARG="rm ${REMOTEHOME_DIR}/logs/${METADBMONGO}"
                                ssh $CURRUSER@$RHOST "sudo -u ${OSUSER} ${REMOTEHOME_DIR}/${RUNCMD} '${RUNCMD_ARG}'" >>$LOGFILE

                                Restart_All_DBs_Parallel
                                RETVAL=$?
                                if [ $RETVAL -gt 0 ] ; then export MESG="Error(s) executing stop, check logs." ; RETVAL=5 ; fi
                        fi
                fi
        fi
        fi
fi

return $RETVAL
}
########### Oracle fetch metadb details function ends here ################


SendNotification() {
print "${PROGRAM_NAME} " > /tmp/mail.dat
print "Machine: $BOX " >> /tmp/mail.dat
if [[ x$1 != 'x' ]] ; then
        print "\n$1\n" >> /tmp/mail.dat
fi
cat /tmp/mail.dat | /bin/mailx -a ${LOGFILE} -s "$3" ${MAILLIST}
rm -f /tmp/mail.dat
RETVAL=$2
return $RETVAL
}

script_usage() {
echo "SCRIPT USAGE: ${PROGRAM_NAME} -u|usr <OS_User> -h|-host <hostname> -d|db <dbname> -p|port <PORT> -e|envname <NA1/2/3 etc.> -q|unqid <uniq_id>"
echo " "
}


######MAIN####
set -ux
export HOSTNAME=`hostname`
export CURRUSER=`id -u -n`
NOW=`date +"%d%b%Y_%H%M%S"`
export DATE=${NOW}
export PROGRAM_NAME=`echo $0 | sed 's/.*\///g'`
export SCRIPTDIR=`dirname $0`
export SCRIPTNAME=`basename $0`
export PROGRAM_NAME_FIRST=`echo $PROGRAM_NAME | awk -F "." '{print $1}'`
export BOX=`echo $(hostname) | awk -F "." '{print $1}'`
export PROCID=$$
export RHOME=SC_Get_RemoteHome.sh
export RUNCMD=SC_RunCmd.sh


if [ ! -d $SCRIPTDIR/logs ] ; then mkdir -p $SCRIPTDIR/logs ; fi
if [ $# -ge 20 ] ; then
RETVAL=0
#MAILLIST='blal@csod.com'
MAILLIST='CloudOps-DBA@csod.com'

while [ "$#" != "0" ] ; do
case $1 in
-usr|-u)
   shift
   export OSUSER=${1:-$OSUSER}
   shift
   ;;
-musr|-m)
   shift
   export MUSER=${1:-$MUSER}
   shift
   ;;
-host|-h)
   shift
   export RHOST=${1:-$RHOST}
   nslookup $RHOST
   if [ $? -eq 0 ] ; then
    ping -c 1 -i 1 $RHOST
        if [ $? -ne 0 ] ; then
                export RHOST=`nslookup $RHOST|grep -i name|awk '{print $NF}'|awk -F. '{print $1}'|head -1`
        fi
   fi
   export METADB_HOSTNAME=$RHOST
   shift
   ;;
-db|-d)
   shift
   export ORACLE_SID=${1:-$ORACLE_SID}
   export META_SID=${ORACLE_SID}
   shift
   ;;
-port|-p)
   shift
   export PORT=${1:-$PORT}
   shift
   ;;
-unqid|-q)
   shift
   export UNQID=${1:-$UNQID}
   shift
   ;;
-envname|-e)
   shift
   export ENVNAME=${1:-$ENVNAME}
   shift
   ;;
-mdbip|-i)
   shift
   export METADBIP=${1:-$METADBIP}
   shift
   ;;
-musrnm|-x)
   shift
   export METAUSRNM=${1:-$METAUSRNM}
   shift
   ;;
-musrpwd|-w)
   shift
   export METAUSRPWD=${1:-$METAUSRPWD}
   shift
   ;;
-help|-y)
   script_usage
   RETVAL=1
   shift
   ;;
esac
done
else
   script_usage
   RETVAL=2
   export MESG="Incorrect number of arguments in calling $SCRIPTNAME on host: $HOSTNAME "
fi

if [[ ! -z ${OSUSER} && ! -z ${MUSER} && ! -z ${RHOST} && ! -z ${ENVNAME} && ! -z ${ORACLE_SID} && ! -z ${UNQID} && ! -z ${PORT} && ! -z ${METADBIP} && ! -z ${METAUSRNM} && ! -z ${METAUSRPWD} ]] ; then

        export LOGDIR=${SCRIPTDIR}/logs
        export LOGFILE=${SCRIPTDIR}/logs/${ENVNAME}_${PROGRAM_NAME_FIRST}_${UNQID}_${DATE}_${PROCID}.log
        export LOGFILEORACLE=${SCRIPTDIR}/logs/${ENVNAME}_${PROGRAM_NAME_FIRST}_${UNQID}_${DATE}_${PROCID}_ORACLE.log
        export LOGFILEMONGO=${SCRIPTDIR}/logs/${ENVNAME}_${PROGRAM_NAME_FIRST}_${UNQID}_${DATE}_${PROCID}_MONGO.log

        >$LOGFILE

        echo "##################################### " >>$LOGFILE
        echo "${PROGRAM_NAME} "  >>$LOGFILE
        echo "Machine: $BOX "  >>$LOGFILE
        echo "Script Start Timestamp: $DATE "  >>$LOGFILE
        echo "##################################### " >>$LOGFILE
        echo "Script Parameters:" >>$LOGFILE
        echo "------------------------:" >>$LOGFILE
        echo "Oracle Database Owner:${OSUSER}" >>$LOGFILE
        echo "Mongo Database Owner:${MUSER}" >>$LOGFILE
        echo "Metadb Hostname:${RHOST}" >>$LOGFILE
        echo "Environment Name:${ENVNAME}" >>$LOGFILE
        echo "Metadb Name:${ORACLE_SID}" >>$LOGFILE
        echo "Metadb User:${METAUSRNM}" >>$LOGFILE
        echo "DB Port:${PORT}" >>$LOGFILE
        echo "Unique Click ID:${UNQID}" >>$LOGFILE
        echo "##################################### " >>$LOGFILE
        echo " " >>$LOGFILE

        if [ $RETVAL -eq 0 ] ; then

                export MESG="Username: ${CURRUSER} has kick started the ${ENVNAME} environment stop process, ignore any stop related alerts meanwhile. You shall receive the notification when the process is completed."
                SendNotification "$MESG" "$RETVAL" "Env: ${ENVNAME} Cluster Stop, User: ${CURRUSER} has kicked off the Automation Process!"

                Fetch_Metadb
                RETVAL=$?
                rm -f ${SCRIPTDIR}/logs/${CLUSCRED}
                if [ $RETVAL -gt 0 ] ; then export MESG="Error(s) Fetching Oracle metadb details, check logs." ; RETVAL=5 ; fi
        fi
else
   script_usage
   RETVAL=2
   export MESG="Incorrect number of arguments in calling $SCRIPTNAME on host: $HOSTNAME, Username: ${CURRUSER} "
fi
ERRCHK=`egrep -i 'Error|ORA-' $LOGFILE |egrep -v 'ORA-32004|grep|Encryption Validation Failed on host|Encryption Error Message' | wc -l`
if [[ $RETVAL -ge 1 || $ERRCHK -gt 0 ]] ; then
        RETVAL=5
        export MESG="Error: ${ENVNAME} Environment Stop Failed, check logs."
        echo " " >>${LOGFILE} ; echo "`date +"%d%b%Y_%H%M%S"`::$MESG" >> ${LOGFILE}
        SendNotification "$MESG" "$RETVAL" "Error: ${ENVNAME} Cluster Stop Failed, User:${CURRUSER}"
else
        RETVAL=0
        export MESG="${ENVNAME} Environment Stop Successfully Completed"
        echo " " >>${LOGFILE} ; echo "`date +"%d%b%Y_%H%M%S"`::$MESG, Username: ${CURRUSER}." >> ${LOGFILE}
        SendNotification "$MESG" "$RETVAL" "Env: ${ENVNAME} Cluster Stop Successful."
fi

ENC_ERRCHK=`egrep -i 'Encryption Validation Failed on host' $LOGFILE | wc -l`
if [ ${ENC_ERRCHK} -gt 0 ] ; then
        RETVAL=5
        export MESG="Failed: Wallet Validation, ${ENVNAME} Environment Stop Successful though, check logs."
        SendNotification "$MESG" "$RETVAL" "Failed Wallet Validation, Env: ${ENVNAME} Cluster Stop Successful though."
fi

find $SCRIPTDIR/logs/ -name "${ENVNAME}_${PROGRAM_NAME_FIRST}*.log" -mtime +360 -type f -exec rm {} \;
find $SCRIPTDIR/logs/ -name "${ENVNAME}*.lst" -mtime +360 -type f -exec rm {} \;

exit $RETVAL
