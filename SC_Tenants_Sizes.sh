#!/bin/ksh
# ********************************************************************************************
# NAME:         SC_Tenants_Sizes.sh
#
# AUTHOR:       Brij Lal Kapoor
#
# PURPOSE:      The script does tenant size to get history and draw future patterns.
#
# DATE:                 09/14/2018
#
# CHANGE TRACKER LOG:
#*******************************************************************************************
# Date          Developer       Change Description
#===========================================================================================
# 09/14/2018    BLK (BRIJ)       Initial creation
#
# Script Return codes:
# 3--> Wrong number of arguments in called scripts
# 5--> Failed Execution
# 0--> Successful Execution
# Run day: Every last day of the month
# eg: 45 00 1 * * $HOME/local/dba/scripts/SC_Tenants_Sizes.sh -e EU2 -d metae101 -i prmne101 >$HOME/local/dba/scripts/logs/SC_Tenants_Sizes_EU2.debug
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
#export SEND_EMAILS="blal@csod.com"
#export VIP_SEND_EMAILS="blal@csod.com"
export SEND_EMAILS="CloudOps-DBA@csod.com,CloudOps-DBA@csod.com,Cloud-Ops-SRE@csod.com,CP@csod.com"
export VIP_SEND_EMAILS="NKulurkar@csod.com,sakhtar@csod.com,blal@csod.com"


if [ $# -eq 6 ] ; then
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
-inf|-i)
   shift
   export INFDB=${1:-$INFDB}
   shift
   ;;
#-pwd|-p)
#   shift
#   export MDBPASS=${1:-$MDBPASS}
#   shift
#   ;;
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
export MDBUSER=sabaadmin
export DBPASS=dba4you
export INFUSER=INFDB
export INFPASS=saba#465
mkdir -p ${SCRIPTDIR}/logs
export METADBLISTORACLE=${SCRIPTDIR}/logs/list_${ORACLE_SID}_${NOWDT}.lst
export METADBLISTTENANTS=${SCRIPTDIR}/logs/list_tenants_${ORACLE_SID}_${NOWDT}.lst
export TENANTSLOC=${SCRIPTDIR}/logs/tnt_location_${ORACLE_SID}_${NOWDT}.lst
export INACTIVE_DET=${SCRIPTDIR}/logs/Tenants_Sizes_Details_${ENVNAME}_${NOWDT}.htm
export TENANTSDIS=${SCRIPTDIR}/logs/tenants_count_details_${ORACLE_SID}_${NOWDT}.lst
export BKPTABLES=${SCRIPTDIR}/logs/list_bkptables_${ORACLE_SID}_${NOWDT}.lst
export EMAIL_NOTE=${SCRIPTDIR}/logs/email_note_${ORACLE_SID}_${NOWDT}.lst
export CSVFILENAME=${SCRIPTDIR}/logs/${ENVNAME}_TENANT_DETAILS.csv
export REPORT_RUN_ON=`date +"%d-%b-%Y %T"`
#export ORAENV_ASK=NO
#. /usr/local/bin/oraenv
db_env
>${INACTIVE_DET}
>${CSVFILENAME}
TENANT_COUNT=`sqlplus -S "/nolog" <<BLK
conn metadb/metadb
set line 1500 pages 0 heading off feedback off
select count(*)
from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME and a.IS_ACTIVE='1' and upper(a.DB_NAME) not like '%SABAMEETING%' and upper(a.db_name) not like '%SM_DS%';
-----where SID<>'ORCL' and upper(DB_IP_NAME)<>'LOCALHOST';
BLK`

sqlplus -S "/nolog" <<BLK >${METADBLISTORACLE}
conn metadb/metadb
set echo off line 1500 pages 0 heading off feedback off verify off
select distinct DB_IP_NAME||':'||SID||':'||Port||':'||schema_name||':'||SITE_NAME from (
select a.site_name,a.schema_name,
substr(substr(b.CONN_STR,instr(CONN_STR,'@')+1),1,instr(substr(CONN_STR,instr(CONN_STR,'@')+1),':')-1) DB_IP_NAME,substr(b.CONN_STR,instr(b.CONN_STR,':',-1)+1) SID,
substr(substr(b.CONN_STR,1,length(b.CONN_STR)-length(substr(b.CONN_STR,instr(b.CONN_STR,':',-1)))),
instr(substr(b.CONN_STR,1,length(b.CONN_STR)-length(substr(b.CONN_STR,instr(b.CONN_STR,':',-1)))),':',-1)+1) Port
from MDT_SITE_DB_MAPPING a , MDT_DB_DETAILS b
where a.DB_NAME = b.DB_NAME and a.IS_ACTIVE='1' and upper(a.DB_NAME) not like '%SABAMEETING%' and upper(a.db_name) not like '%SM_DS%');
BLK
RETVAL=$?

if [[ -s ${METADBLISTORACLE} && ${RETVAL} -eq 0 ]] ; then

        sqlplus -S "/nolog" <<BLK
        conn ${INFUSER}/${INFPASS}@${INFDB}
        set echo off feedback off verify off pages 0
        declare
                chk number;
        begin
                select count(*) into chk from user_tables where table_name='TENANT_AUDIT';
                if chk = 0 then
                        execute immediate 'create table tenant_audit (
                        clusternm       varchar2(20),
                        aud_id          number,
                        aud_run_on      date,
                        SCHEMA_NAME     varchar2(20),
                        SITE_NAME       varchar2(30),
                        orahostname     varchar2(30),
                        sid             varchar2(20),
                        oport           number,
                        oracle_size_GB  number,
                        otime_fetch_sec number,
                        mongohostname   varchar2(30),
                        mport           number,
                        mongo_size_GB   number,
                        mtime_fetch_sec number,
                        comments        varchar2(100))';
                end if;
        end;
        /
        delete from tenant_audit where clusternm ='${ENVNAME}' and aud_run_on < (select trunc(sysdate, 'YEAR') - interval '5' year from dual);
        commit;
BLK
        RETVAL=$?

        if [ ${RETVAL} -eq 0 ] ; then
                AUDID=`sqlplus -S "/nolog" <<BLK
                conn ${INFUSER}/${INFPASS}@${INFDB}
                set echo off feedback off verify off pages 0
                select nvl(max(aud_id),0)+1 from tenant_audit;
BLK`
AUDID=`echo ${AUDID} | sed -e 's/ //g'`

        for db in `cat ${METADBLISTORACLE}` ; do
                NOW1=`date +"%d-%b-%Y %T"`
                HOSTNM=`echo $db |cut -d ":" -f1`
                DBNAME=`echo $db |cut -d ":" -f2`
                PORT=`echo $db |cut -d ":" -f3`
                TENANT=`echo $db |cut -d ":" -f4`
                SITENM=`echo $db |cut -d ":" -f5`

                #Oracle Details
                TENANT_SIZE=`sqlplus -S "/nolog" <<BLK
                conn ${DBUSER}/${DBPASS}@${DBNAME}
                set echo off line 150 pages 0 heading off feedback off
                select round(sum(bytes)/1024/1024/1024,2) from dba_segments where owner=upper('${TENANT}');
BLK`
                RETVAL=$?

                NOW2=`date +"%d-%b-%Y %T"`
                TOTTIME=`sqlplus -S "/nolog" <<BLK
                        conn ${DBUSER}/${DBPASS}
                        set echo off line 150 pages 0 heading off feedback off
                        select round(24* 60 * 60 * (to_date('${NOW2}','dd-mon-rrrr hh24:mi:ss') - to_date('${NOW1}','dd-mon-rrrr hh24:mi:ss'))) from dual;
BLK`
                TOTTIME=`echo ${TOTTIME} | sed -e 's/ //g'`
                if [[ ! -z ${TENANT_SIZE} && ${RETVAL} -eq 0 ]] ; then
                        sqlplus -S "/nolog" <<BLK
                        conn ${INFUSER}/${INFPASS}@${INFDB}
                        set echo off line 150 pages 0 heading off feedback off
                        insert into tenant_audit
                        (       clusternm,
                                aud_id,
                                aud_run_on ,
                                SCHEMA_NAME,
                                SITE_NAME,
                                orahostname,
                                sid ,
                                oport,
                                oracle_size_GB,
                                otime_fetch_sec
                        )
                        values
                        (
                                '${ENVNAME}',
                                 ${AUDID},
                                 to_date('${REPORT_RUN_ON}','dd-mon-rrrr hh24:mi:ss'),
                                '${TENANT}',
                                '${SITENM}',
                                '${HOSTNM}',
                                '${DBNAME}',
                                 ${PORT},
                                 ${TENANT_SIZE},
                                 ${TOTTIME}
                        );
                        commit;
BLK
                else
                        sqlplus -S "/nolog" <<BLK
                        conn ${INFUSER}/${INFPASS}@${INFDB}
                        set echo off line 150 pages 0 heading off feedback off

                        insert into tenant_audit
                        (       clusternm,
                                aud_id,
                                aud_run_on ,
                                SCHEMA_NAME,
                                SITE_NAME,
                                orahostname,
                                sid ,
                                oport,
                                oracle_size_GB,
                                otime_fetch_sec,
                                comments
                        )
                        values
                        (       '${ENVNAME}',
                                 ${AUDID},
                                 to_date('${REPORT_RUN_ON}','dd-mon-rrrr hh24:mi:ss'),
                                '${TENANT}',
                                '${SITENM}',
                                '${HOSTNM}',
                                '${DBNAME}',
                                 ${PORT},
                                 null,
                                 null,
                                'Error fetching Oracle Size'
                        );
                        commit;
BLK
                fi

                #mongo tenant size details.
                NOW1=`date +"%d-%b-%Y %T"`
                MONGOHOSTPORT=`sqlplus -S "/nolog" <<BLK
                        conn metadb/metadb
                        set line 150 pages 0 heading off feedback off
                        SELECT m.host||':'||m.port
                        FROM mdt_site_db_mapping s INNER JOIN mdt_mongodb_details d ON d.db_name=s.mongodb_name
                                INNER JOIN mdt_mongoserver_details m ON m.server_name=d.server_name
                        where upper(s.site_name)=upper('${SITENM}');
BLK`
        RETVAL=$?

        if [[ ! -z ${MONGOHOSTPORT} && ${RETVAL} -eq 0 ]] ; then

        MONGOHOST=`echo $MONGOHOSTPORT | awk -F: '{print $1}'`
        MONGOPORT=`echo $MONGOHOSTPORT | awk -F: '{print $2}'`

        if [[ "${SITENM}" = *"QA"* ]] ; then
        MDBPASS=`sqlplus -S "/nolog" <<BLK
        conn metadb/metadb
        set echo off line 150 pages 0 heading off feedback off serveroutput on
        Declare
                cout number;
                admin_pass varchar2(50);
        Begin
        Select count(*) into cout from MDT_MONGOSERVER_DETAILS where server_name like '%QADB%';
        If cout > 0 then
                select distinct password into admin_pass from MDT_MONGOSERVER_DETAILS where lower(username)='${MDBUSER}' and server_name like '%QADB';
        else
                select distinct password into admin_pass from MDT_MONGOSERVER_DETAILS where lower(username)='${MDBUSER}';
        end if;
        dbms_output.put_line(admin_pass);
        exception when others then null;
        End;
        /
BLK`
        else
        MDBPASS=`sqlplus -S "/nolog" <<BLK
        conn metadb/metadb
        set echo off line 150 pages 0 heading off feedback off
        select distinct password from MDT_MONGOSERVER_DETAILS where lower(username)='${MDBUSER}' and server_name not like '%QADB';
BLK`
        fi

        ssh mongouser@${MONGOHOST} bash -s <<BLK > ${BKPTABLES}
                /saba/mongouser/mongo_4.2/bin/mongo --port ${MONGOPORT} --quiet -u ${MDBUSER} -p ${MDBPASS} --authenticationDatabase "admin" <<BLK1
                        db.getMongo().getDB('${TENANT}').runCommand({ dbStats: 1, scale: 1 })
BLK1
BLK

        RETVAL=$?

        MONGOTENANTSIZE=`cat ${BKPTABLES} | grep storageSize | awk -F: '{print $2}' | awk -F, '{print $1}'`
        NOW2=`date +"%d-%b-%Y %T"`
        TOTTIME=`sqlplus -S "/nolog" <<BLK
                conn ${DBUSER}/${DBPASS}
                set echo off line 150 pages 0 heading off feedback off
                select round(24* 60 * 60 * (to_date('${NOW2}','dd-mon-rrrr hh24:mi:ss') - to_date('${NOW1}','dd-mon-rrrr hh24:mi:ss'))) from dual;
BLK`
        TOTTIME=`echo ${TOTTIME} | sed -e 's/ //g'`
        if [[ ! -z ${MONGOTENANTSIZE} && ${RETVAL} -eq 0 ]] ; then
                sqlplus -S "/nolog" <<BLK
                conn ${INFUSER}/${INFPASS}@${INFDB}
                set echo off line 150 pages 0 heading off feedback off
                update tenant_audit
                set
                        mongohostname='${MONGOHOST}',
                        mport=$MONGOPORT,
                        mongo_size_GB=round(${MONGOTENANTSIZE}/1024/1024/1024,3),
                        mtime_fetch_sec=${TOTTIME}
                where
                        clusternm='${ENVNAME}' and schema_name='${TENANT}' and aud_id=${AUDID};
                commit;
BLK
        else
                sqlplus -S "/nolog" <<BLK
                conn ${INFUSER}/${INFPASS}@${INFDB}
                set echo off line 150 pages 0 heading off feedback off
                update tenant_audit
                set
                        mongohostname='${MONGOHOST}',
                        mport=$MONGOPORT,
                        mongo_size_GB=null,
                        mtime_fetch_sec=null,
                        comments=decode(comments,null,'Error fetching Mongo Size.',comments||', Error fetching Mongo Size.')
                where
                        clusternm='${ENVNAME}' and schema_name='${TENANT}' and aud_id=${AUDID};
                commit;
BLK
        fi
        fi
        done

        sqlplus -S "/nolog" <<BLK >>${INACTIVE_DET}
                        conn ${INFUSER}/${INFPASS}@${INFDB}
                        SET LINE 150 HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF PAGES 0
                        SET MARKUP HTML ON ENTMAP OFF ;
                        PROMPT <H1 id="Section1">Cluster (${ENVNAME}) Tenant Sizes, Total Active Tenants in the cluster: ${TENANT_COUNT} </H1>
                        SELECT '<H2 id="Section2">  Report run on '  ||  TO_CHAR(SYSDATE, 'MON-DD-YYYY HH24:MM:SS PM') FROM DUAL ;
                        SELECT '<H3 id="Section3">  Server/Database Wise Active Tenants Count:'  FROM DUAL ;

                        SET ECHO OFF HEADING ON FEEDBACK OFF PAGES 5000
                        select orahostname Server, sid Database, count(*) Tenant_Count
                        from tenant_audit
                        where clusternm='${ENVNAME}' and aud_id=${AUDID}
                        group by orahostname, sid
                        order by 3 desc;

                        SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF PAGES 0
                        SELECT '<H3 id="Section4">  All Tenant Size Details:'  FROM DUAL ;

                        SET ECHO OFF HEADING ON FEEDBACK OFF PAGES 5000
                        select rownum Sr#, a.* from (select Site_name, Oracle_Size_GB, Mongo_Size_GB, Comments
                        from tenant_audit
                        where clusternm='${ENVNAME}' and aud_id=${AUDID}
                        order by oracle_size_GB desc) a;
BLK
        sqlplus -S "/nolog" <<BLK >>${CSVFILENAME}
                        conn ${INFUSER}/${INFPASS}@${INFDB}
                        SET LINE 150 PAGES 5000 FEEDBACK OFF VERIFY OFF ECHO OFF colsep ','
                        col Site_name for a30
                        col Comments for a30
                        select rownum Sr#, a.* from (select Site_name, Oracle_Size_GB, Mongo_Size_GB, Comments
                        from tenant_audit where clusternm='${ENVNAME}' and aud_id=${AUDID}
                        order by oracle_size_GB desc) a;
BLK
        sed -i '/^\s*$/d' ${CSVFILENAME}
        fi

        if [[ -s ${INACTIVE_DET} && ${RETVAL} -eq 0 ]] ; then
                echo "See Attached Tenant Report (HTML format) For ${ENVNAME} Cluster." | mailx -s "${ENVNAME}: Tenant Details" -a ${INACTIVE_DET} ${SEND_EMAILS}
                echo "See Attached Tenant Report (CSV format) For ${ENVNAME} Cluster." | mailx -s "${ENVNAME}: Tenant Details" -a ${CSVFILENAME} ${VIP_SEND_EMAILS}
        else
                echo "Error Pulling Tenant Sizes For ${ENVNAME} Cluster. Potential Reasons Might be Access Profile Changes, Please Check More to Troubleshoot." | mailx -s "${ENVNAME}: Error Pulling Tenant Details" ${SEND_EMAILS}
        fi
fi
fi
fi
rm -f ${METADBLISTORACLE} ${METADBLISTTENANTS} $OHOMES $TENANTSLOC ${INACTIVE_DET} ${TENANTSDIS} ${BKPTABLES} ${EMAIL_NOTE} ${CSVFILENAME}

exit $RETVAL
