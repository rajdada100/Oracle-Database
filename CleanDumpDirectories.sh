#!/bin/ksh
# ==================================================================================================
# NAME:         CleanDumpDirectories.sh
#
# AUTHOR:       Basit Khan
#
# PURPOSE:      This script will clear the dump directories
#
#
# USAGE:        CleanDumpDirectories.sh
# Modified:             Modified by Brij for audit file removal check.
#
# ==================================================================================================
#################### MAIN ##########################
# -----------------------------------------------------------------------------
# Function db_env
#       This function set the oracle env
# -----------------------------------------------------------------------------
db_env() {
set -ux
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

#uncomment the below line to debug
set -x
clear

export NOFD='+30'
export AUDNOFD='-1'
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
export OS_TYPE=`uname`
export OHOMES=/tmp/ohomes_${CURDATE}.lst

ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}' > $HOME/local/dba/scripts/logs/sid_list.txt
sed -i '/^$/d' $HOME/local/dba/scripts/logs/sid_list.txt
if [[ -s $HOME/local/dba/scripts/logs/sid_list.txt ]] ; then
   cat  $HOME/local/dba/scripts/logs/sid_list.txt | while read LINE
   do
     export sid=$LINE
     sid=$(print $sid|tr -d " ")
     export ORACLE_SID=$sid
#     export ORAENV_ASK=NO
#     export PATH=/usr/local/bin:$PATH
#. /usr/local/bin/oraenv > /dev/null

if [ $? -ne 0 ]
then
 print "\n\n\t\t There seems to be some problem please rectify and Execute Again\n\nAborting Here...."
 exit 2
fi
db_env
        $ORACLE_HOME/bin/sqlplus -s '/ as sysdba' <<EOF >$HOME/local/dba/scripts/logs/dumppaths.txt
        set verify off
        set feedback off
        set heading off
        select value
        from v\$parameter
        where name in('audit_file_dest');
EOF

sed -i '/^$/d' $HOME/local/dba/scripts/logs/dumppaths.txt
if [[ -s $HOME/local/dba/scripts/logs/dumppaths.txt ]] ; then
        export dumppath=`cat $HOME/local/dba/scripts/logs/dumppaths.txt|awk '{print $1}'`
        rm -f $dumppath/*.aud
fi

     $ORACLE_HOME/bin/sqlplus -s '/ as sysdba' <<EOF >$HOME/local/dba/scripts/logs/dumppaths.txt
     set verify off
     set feedback off
     set heading off
     select value
     from v\$parameter
     where name in('background_dump_dest');
EOF

cat $HOME/local/dba/scripts/logs/dumppaths.txt | sed '/^$/d' > $HOME/local/dba/scripts/logs/dumppaths_new.txt
     rm -f $HOME/local/dba/scripts/logs/dumppaths.txt
     cat $HOME/local/dba/scripts/logs/dumppaths_new.txt > $HOME/local/dba/scripts/logs/dumppaths.txt
     rm -f $HOME/local/dba/scripts/logs/dumppaths_new.txt
     if [[ -s $HOME/local/dba/scripts/logs/dumppaths.txt ]]
     then
      cat $HOME/local/dba/scripts/logs/dumppaths.txt | while read LINE1
       do
        export dumppath=$(print $LINE1|tr -d " ")
        find $dumppath  \( -name '*.trc' -o -name '*.trm' \) -mtime $NOFD -exec rm {} \; > /dev/null
       done
     fi
     rm -f $HOME/local/dba/scripts/logs/ver.txt
     rm -f $HOME/local/dba/scripts/logs/dumppaths.txt
     done
fi
rm -f  $HOME/local/dba/scripts/logs/sid_list.txt $OHOMES
exit
