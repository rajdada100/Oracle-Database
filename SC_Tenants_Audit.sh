#!/bin/ksh
# ********************************************************************************************
# NAME:         SC_Tenants_Audit.sh
#
# AUTHOR:       Brij Lal Kapoor
#
# PURPOSE:      The script does tenant Aduit and identifies the inactive tenants.
#
# DATE:                 06/23/2018
#
# CHANGE TRACKER LOG:
#*******************************************************************************************
# Date          Developer       Change Description
#===========================================================================================
# 06/23/2018    BLK (BRIJ)       Initial creation
#
# Script Return codes:
# 3--> Wrong number of arguments in called scripts
# 5--> Failed Execution
# 0--> Successful Execution
# Example: how to run, last sunday of each month - [ $(date +"\%m") -ne $(date -d 7days +"\%m") ] && $HOME/local/dba/scripts/SC_Tenants_Audit.sh -e EU4 -d METAE102
############################################################################################
set -x
db_env() {
if [ "${OS_TYPE}" = "Linux" ] ; then
        ORATAB="/etc/oratab"
fi
echo $(ps eww $(ps -ef| grep pmon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep ORACLE_HOME | awk -F= '{print $2}') >$OHOMES
export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
if [ -z ${ORACLE_HOME} ] ; then
        echo $(ps eww $(ps -ef| grep smon| grep -v grep| grep $ORACLE_SID | awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep ORACLE_HOME | awk -F= '{print $2}') >$OHOMES
        export ORACLE_HOME=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
        if [ -z ${ORACLE_HOME} ] ; then
                export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $ORACLE_SID| grep -v grep| awk -F":" '{print $2}'`
                if [ -z ${ORACLE_HOME} ] ; then
                        SID=`ps -ef | grep pmon | grep -i ${ORACLE_SID} | sed -e 's/ora_pmon_//g'| awk '{print $8}'| awk '{print substr($0,0,length($0)-1)}'`
                        export ORACLE_HOME=`sed -e '/^*/d' -e '/^#/d' -e '/^?/d' -e '/^=/d' -e '/^+/d' -e '/^$/d' $ORATAB| grep $SID| grep -v grep| awk -F":" '{print $2}'`
                fi
        fi
fi

echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep LD_LIBRARY_PATH | awk -F= '{print $2}') >$OHOMES
export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
if [ -z ${LD_LIBRARY_PATH} ] ; then
        echo $(ps eww $(ps -ef| grep pmon| grep -v grep|grep $ORACLE_SID |awk '{print $2}')|sed '1d' | sed 's/ / \n/g'| grep LIBPATH | awk -F= '{print $2}') >$OHOMES
        export LD_LIBRARY_PATH=`cat $OHOMES | awk -F":" '{print $1}'|awk '{print $1}'`
fi
export PATH=$ORACLE_HOME/bin:$PATH:.
}

script_usage() {
echo "SCRIPT USAGE: ${PROGRAM_NAME}.sh -e <ENVNAME> -d <ORACLE_SID>"
echo " "
}


######MAIN####
#set -ux
export OS_TYPE=`uname`
export ORATAB='/etc/oratab'
export HOSTNAME=`hostname`
export CURRUSER=`id -u -n`
export PROGRAM_NAME=`echo $0 | sed 's/.*\///g'`
export SCRIPTDIR=`dirname $0`
export SCRIPTNAME=`basename $0`
export PROGRAM_NAME_FIRST=`echo $PROGRAM_NAME | awk -F "." '{print $1}'`
export BOX=`echo $(hostname) | awk -F "." '{print $1}'`
export NOWDT=`date +"%m%d%Y%H%M"`
#export SEND_EMAILS=blal@csod.com
export SEND_EMAILS="CloudOps-DBA@csod.com,CloudOps-DBA@csod.com,Cloud-Ops-SRE@csod.com,CloudProvisioning@csod.com"
if [ $# -eq 4 ] ; then
RETVAL=0

while [ "$#" != "0" ] ; do
case $1 in
-envname|-e)
   shift
   export ENVNAME=${1:-$ENVNAME}
   shift
   ;;
-db|-d)
   shift
   export ORACLE_SID=${1:-$ORACLE_SID}
   shift
   ;;
-help|-h)
   script_usage
   RETVAL=3
   shift
   ;;
esac
done
else
   script_usage
   RETVAL=3
fi

if [[ ${ORACLE_SID} != "" && ${ENVNAME} != "" ]]  ; then
if [ $RETVAL -eq 0 ] ; then
export OHOMES=/tmp/ohomes_${ORACLE_SID}.lst
export DBUSER=SABAADMIN
export DBPASS=dba4you
mkdir -p ${SCRIPTDIR}/logs
export METADBLISTORACLE=${SCRIPTDIR}/logs/list_${ORACLE_SID}_${NOWDT}.lst
export METADBLISTTENANTS=${SCRIPTDIR}/logs/list_tenants_${ORACLE_SID}_${NOWDT}.lst
export TENANTSLOC=${SCRIPTDIR}/logs/tnt_location_${ORACLE_SID}_${NOWDT}.lst
export INACTIVE_DET=${SCRIPTDIR}/logs/Tenants_Audit_Details_${ENVNAME}_${NOWDT}.lst
export TENANTSDIS=${SCRIPTDIR}/logs/tenants_count_details_${ORACLE_SID}_${NOWDT}.lst
export BKPTABLES=${SCRIPTDIR}/logs/list_bkptables_${ORACLE_SID}_${NOWDT}.lst
export EMAIL_NOTE=${SCRIPTDIR}/logs/email_note_${ORACLE_SID}_${NOWDT}.lst
#export ORAENV_ASK=NO
#. /usr/local/bin/oraenv
db_env

sqlplus -S "/nolog" <<BLK >${METADBLISTORACLE}
conn metadb/metadb
set line 1500 pages 0 heading off feedback off
col DB_IP_NAME for a30
col sid for a10
col port for a10
select distinct DB_IP_NAME||':'||SID||':'||Port from (
select substr(substr(b.CONN_STR,instr(CONN_STR,'@')+1),1,instr(substr(CONN_STR,instr(CONN_STR,'@')+1),':')-1) DB_IP_NAME,substr(b.CONN_STR,instr(b.CONN_STR,':',-1)+1) SID,
substr(substr(b.CONN_STR,1,length(b.CONN_STR)-length(substr(b.CONN_STR,instr(b.CONN_STR,':',-1)))),
instr(substr(b.CONN_STR,1,length(b.CONN_STR)-length(substr(b.CONN_STR,instr(b.CONN_STR,':',-1)))),':',-1)+1) Port
from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME and a.IS_ACTIVE='1' and upper(a.DB_NAME) not like '%SABAMEETING%' and upper(a.db_name) not like '%SM_DS%');
-----where SID<>'ORCL' and upper(DB_IP_NAME)<>'LOCALHOST';
BLK
RETVAL=$?

if [[ -s ${METADBLISTORACLE} && ${RETVAL} -eq 0 ]] ; then
        >${TENANTSDIS}
        echo "See attached tenant audit report for ${ENVNAME} cluster." > ${EMAIL_NOTE}
        echo "========================================================" >> ${EMAIL_NOTE}
        echo "Notes:" >> ${EMAIL_NOTE}
        echo "======" >>${EMAIL_NOTE}
        echo "DBA will create one main COIR for any of below Section(s) if found in the attachment, which will be reviewed and confirmed by CP team for further action required on any of below items." >> ${EMAIL_NOTE}
        echo "-----" >> ${EMAIL_NOTE}
        echo "          List of Migrated/Moved Tenant(s)." >> ${EMAIL_NOTE}
        echo "          List of INACTIVE Site(s)." >> ${EMAIL_NOTE}
        echo "          List of Temp Schema(s), that may not be in use currently." >> ${EMAIL_NOTE}
        echo "          " >> ${EMAIL_NOTE}
        echo "=========================" >>${EMAIL_NOTE}
        echo "DBA will create one COIR for below Section(s) if found in the attachment, which will be reviewed and confirmed by SRE team to cleanup backup state occupying db space unnecessarily." >> ${EMAIL_NOTE}
        echo "-----" >> ${EMAIL_NOTE}
        echo "          List of Temporary/Backup Object(s), that may not be in use currently." >> ${EMAIL_NOTE}
        echo "          " >> ${EMAIL_NOTE}
        cat ${EMAIL_NOTE} >${INACTIVE_DET}
        for db in `cat ${METADBLISTORACLE}` ; do
                HOSTNM=`echo $db |cut -d ":" -f1`
                DBNAME=`echo $db |cut -d ":" -f2`
                PORT=`echo $db |cut -d ":" -f3`
                sqlplus -S "/nolog" <<BLK >>${TENANTSDIS}
                conn metadb/metadb
                set line 250 pages 0 echo off feed off
                col DB_NAME for a30
                select '    ${HOSTNM}:'||substr(b.CONN_STR,instr(b.CONN_STR,'${DBNAME}'),length('${DBNAME}'))||' database currently holds '||count(*) || ' Active Tenants.'
                from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                where a.DB_NAME = b.DB_NAME and b.CONN_STR like '%${DBNAME}%'
                and a.IS_ACTIVE='1'
                and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0)
                group by substr(b.CONN_STR,instr(b.CONN_STR,'${DBNAME}'),length('${DBNAME}'));
BLK
        done

        if [[ -s ${TENANTSDIS} && $RETVAL -eq 0 ]] ; then
                echo "########################################################################" >>${INACTIVE_DET}
                echo "## Host:Database Wise Tenant Distribution/Capacity Stats:" >>${INACTIVE_DET}
                echo "#######################################################################################################" >>${INACTIVE_DET}
                cat ${TENANTSDIS}>>${INACTIVE_DET}
                echo "#######################################################################################################" >>${INACTIVE_DET}
        fi

        for db in `cat ${METADBLISTORACLE}` ; do
                HOSTNM=`echo $db |cut -d ":" -f1`
                DBNAME=`echo $db |cut -d ":" -f2`
                PORT=`echo $db |cut -d ":" -f3`

                sqlplus -S "/nolog" <<BLK >${METADBLISTTENANTS}
                conn ${DBUSER}/${DBPASS}@${DBNAME}
                set line 150 pages 0 heading off feedback off
                col owner for a30
                select username from dba_users
                where username not in(select username from dba_users
                                                          where to_char(created,'dd-MON-rr') =(select created from (select distinct to_date(to_char(created,'dd-MON-rr')) created
                                                                                                                                                        from dba_users order by created)
                                                                                                                                   where rownum < 2))
                -- and username not in ('SABAMASTER','SABAADMIN','SMF','METADB','JET1','JET','BENCHMARKS','SABA_DI','ANT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR')
                -- and username not in ('SABAMASTER','METADB','SABAADMIN','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR')
                and username not in ('SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','GSMCATUSER','REMOTE_SCHEDULER_AGENT','DBSFWUSER','SYSBACKUP','GSMUSER','GGSYS','SYSRAC','OJVMSYS','AUDSYS','GSMADMIN_INTERNAL','SYSKM','SYS\$UMF','SYSDG');
BLK
                RETVAL=$?

                if [ ${RETVAL} -eq 0 ] ; then
                tnsping $DBNAME >/dev/null
                RETVAL=$?

                if [ ${RETVAL} -eq 0 ] ; then
                if [ -s ${METADBLISTTENANTS} ] ; then

                        cout1=0
                        for tnt in `cat ${METADBLISTTENANTS}` ; do

                                sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                conn metadb/metadb
                                set line 250 pages 0 echo off feed off
                                col SCHEMA_NAME for a30
                                col CONN_STR for a100
                                select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                                where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                and a.IS_ACTIVE='1'
                                and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                RETVAL=$?
                                if [[ -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                        TNTCHK=`grep -i $tnt ${TENANTSLOC} | grep $DBNAME | wc -l`
                                        if [ $TNTCHK -eq 0 ] ; then
                                                cout1=1
                                        fi
                                fi
                        done

                        cout2=0
                        for tnt in `cat ${METADBLISTTENANTS}` ; do
                                sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                conn metadb/metadb
                                set line 250 pages 0 echo off feed off
                                col SCHEMA_NAME for a30
                                col CONN_STR for a100
                                col DB_NAME for a30
                                select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                                where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                and a.IS_ACTIVE<>'1'
                                and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                RETVAL=$?
                                if [[ -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                        TNTCHK=`grep -i $tnt ${TENANTSLOC} | grep $DBNAME | wc -l`
                                        if [ $TNTCHK -gt 0 ] ; then
                                                cout2=1
                                        fi
                                fi
                        done

                        cout3=0
                        for tnt in `cat ${METADBLISTTENANTS}` ; do
                                        sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                        conn metadb/metadb
                                        set line 250 pages 0 echo off feed off
                                        col SCHEMA_NAME for a30
                                        col CONN_STR for a100
                                        col DB_NAME for a30
                                        select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                        from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                                        where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                        and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                        RETVAL=$?
                                        if [[ ! -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                        case $tnt in
                                                (SABAMASTER|SABAADMIN|METADB|SABAEXPIMP) ;;
                                                (*) cout3=1  ;;
                                        esac
                                        fi
                        done

                        cout4=0
                        sqlplus -S "/nolog" <<BLK >${BKPTABLES}
                        conn ${DBUSER}/${DBPASS}@${DBNAME}
                        set line 150 pages 3000 heading on feedback off
                        set trimout on
                        set tab off
                        set MARKUP HTML PREFORMAT ON
                        set COLSEP '|'
                        col username for a30
                        col object_name for a30
                        col object_type for a30
                        break on username
                        select a.owner username, a.object_name, a.object_type, a.created
                        from dba_objects a
                        where a.owner not in(select username from dba_users
                                                                  where to_char(created,'dd-MON-rr') =(select created from (select distinct to_date(to_char(created,'dd-MON-rr')) created
                                                                                                                                                                                        from dba_users order by created)
                                                                                                                                          where rownum < 2))
                        -- and a.owner not in ('SABAMASTER','SABAADMIN','SMF','METADB','JET1','JET','BENCHMARKS','SABA_DI','ANT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR')
                        and a.owner not in ('SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','GSMCATUSER','REMOTE_SCHEDULER_AGENT','DBSFWUSER','SYSBACKUP','GSMUSER','GGSYS','SYSRAC','OJVMSYS','AUDSYS','GSMADMIN_INTERNAL','SYSKM','SYS\$UMF','SYSDG')
                        and
                        (regexp_instr(a.object_name,'(SPC)(\d\d\d\d)|(SPC_)(\d\d\d\d)|(COIR)|(_BKP_)|(_BKP)|(\ATEST)|(BKP_)') > 0 )
                        and object_type not in('INDEX')
                        order by 1,4,2;
BLK
                        RETVAL=$?
                        if [[ -s ${BKPTABLES} && ${RETVAL} -eq 0 ]] ; then
                                cout4=1
                        fi

                        if [[ $cout1 -gt 0 || $cout2 -gt 0 || $cout3 -gt 0 || $cout4 -gt 0 ]] ; then
                                echo " ">>${INACTIVE_DET}
                                echo " ">>${INACTIVE_DET}
                                echo "###################################################################################################" >>${INACTIVE_DET}
                                echo "## Auditing DB: $HOSTNM:$PORT:${DBNAME}, raise COIR to clean'em up in this db" >>${INACTIVE_DET}
                                echo "###################################################################################################" >>${INACTIVE_DET}
                        fi

                        #list of migrated or moved tenants
                        if [ $cout1 -gt 0 ] ; then
                                echo "        List of Migrated/moved Tenant(s)." >>${INACTIVE_DET}
                                echo "        =================================" >>${INACTIVE_DET}
                                for tnt in `cat ${METADBLISTTENANTS}` ; do
                                        sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                        conn metadb/metadb
                                        set line 250 pages 0 echo off feed off
                                        col SCHEMA_NAME for a30
                                        col CONN_STR for a100
                                        select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                        from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                                        where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                        and a.IS_ACTIVE='1'
                                        and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                        RETVAL=$?
                                        if [[ -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                                TNTCHK=`grep -i $tnt ${TENANTSLOC} | grep $DBNAME | wc -l`
                                                CNN_STR=`cat ${TENANTSLOC} | cut -d "," -f2`
                                                if [ $TNTCHK -eq 0 ] ; then
                                                        echo "              Tenant:$tnt, currently active inside db conn_str: ${CNN_STR}" >>${INACTIVE_DET}
                                                fi
                                        fi
                                done
                                echo " ">>${INACTIVE_DET}
                        fi

                        ###List of inactive tenants
                        if [ $cout2 -gt 0 ] ; then
                                echo "        List of INACTIVE Site(s).">>${INACTIVE_DET}
                                echo "        =========================">>${INACTIVE_DET}
                                for tnt in `cat ${METADBLISTTENANTS}` ; do
                                        sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                        conn metadb/metadb
                                        set line 250 pages 0 echo off feed off
                                        col SCHEMA_NAME for a30
                                        col CONN_STR for a100
                                        col DB_NAME for a30
                                        select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                        from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
                                        where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                        and a.IS_ACTIVE<>'1'
                                        and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                        RETVAL=$?
                                        if [[ -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                                TNTCHK=`grep -i $tnt ${TENANTSLOC} | grep $DBNAME | wc -l`
                                                CNN_STR=`cat ${TENANTSLOC} | cut -d "," -f2`
                                                if [ $TNTCHK -gt 0 ] ; then
                                                        echo "              $tnt" >>${INACTIVE_DET}
                                                fi
                                        fi
                                done
                                echo " ">>${INACTIVE_DET}
                        fi

                        #list of unused temp schemas
                        if [ $cout3 -gt 0 ] ; then
                                echo "        List of Temp Schema(s), that may not be in use currently.">>${INACTIVE_DET}
                                echo "        =========================================================">>${INACTIVE_DET}
                                for tnt in `cat ${METADBLISTTENANTS}` ; do
                                        sqlplus -S "/nolog" <<BLK >${TENANTSLOC}
                                        conn metadb/metadb
                                        set line 250 pages 0 echo off feed off
                                        col SCHEMA_NAME for a30
                                        col CONN_STR for a100
                                        col DB_NAME for a30
                                        select upper(a.SCHEMA_NAME)||','||b.CONN_STR
                                        from MDT_SITE_DB_MAPPING a, MDT_DB_DETAILS b
                                        where a.DB_NAME = b.DB_NAME and upper(a.SCHEMA_NAME) = '${tnt}'
                                        and (instr(b.CONN_STR,'$HOSTNM')>0 and instr(b.CONN_STR,'$DBNAME')>0 and instr(b.CONN_STR,'$PORT')>0);
BLK
                                        RETVAL=$?
                                        if [[ ! -s ${TENANTSLOC} && ${RETVAL} -eq 0 ]] ; then
                                        case $tnt in
                                                (SABAMASTER|SABAADMIN|METADB|SABAEXPIMP) ;;
                                                (*) echo "              $tnt" >>${INACTIVE_DET}  ;;
                                        esac
                                        fi
                                done
                                echo " ">>${INACTIVE_DET}
                        fi

                        ##list of backup/unused tables goes here.
                        if [ $cout4 -gt 0 ] ; then
                                echo "        List of Temp Object(s), that may not be in use currently.">>${INACTIVE_DET}
                                echo "        =========================================================">>${INACTIVE_DET}
                                awk '{print "       "$0}' ${BKPTABLES} >>${INACTIVE_DET}
                                echo " ">>${INACTIVE_DET}
                        fi
                fi
                else
                        echo "##############################-----ERROR----##########################################" >>${INACTIVE_DET}
                        echo "## Error connecting to Database $DBNAME on host: $HOSTNM, validate db entries" >>${INACTIVE_DET}
                        echo "##############################-----ERROR----##########################################" >>${INACTIVE_DET}
                fi
                fi
                if [[ $cout1 -gt 0 || $cout2 -gt 0 || $cout3 -gt 0 ]] ; then
                        echo "###############################++++++++++++++++++++++++++++++######################################" >>${INACTIVE_DET}
                fi
        done
        if [ -s ${INACTIVE_DET} ] ; then
                cat ${EMAIL_NOTE}| mailx -s "${ENVNAME}: Tenant Audit" -a ${INACTIVE_DET} ${SEND_EMAILS}
        fi
fi
fi
fi
rm -f ${METADBLISTORACLE} ${METADBLISTTENANTS} $OHOMES $TENANTSLOC ${INACTIVE_DET} ${TENANTSDIS} ${BKPTABLES} ${EMAIL_NOTE}

exit $RETVAL
