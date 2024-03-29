 cat $HOME/local/dba/scripts/validate_wallet.sh
#!/bin/ksh
# ********************************************************************************************
# NAME:         validate_wallet.sh
#
# AUTHOR:       venkata
#
# PURPOSE:      To check wallet status and wallet location
#                alerts when status is not OPEN or location doesn't exist
#
# USAGE:        validate_wallet.sh <SID>
#
#
# *********************************************************************************************
# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------

function SendNotification {

        # Uncomment for debug
        # set -x

        echo "Status:"  >> mail.dat
        cat $HOME/local/dba/scripts/logs/wallet_status.log >> mail.dat
        echo "-----------------------------------------">> mail.dat
        echo "Location: "  >> mail.dat
        cat $HOME/local/dba/scripts/logs/wallet_location.log >> mail.dat
        #$STATUS2 >> mail.dat

        cat mail.dat | /bin/mail -s "Wallet issues on $BOX $ORACLE_SID - please validate! " ${MAILTO}
        rm mail.dat

        return 0
}


# --------------------------------------------------------------
# funct_db_online_verify(): Verify that database is online
# --------------------------------------------------------------
funct_db_online_verify(){
 # Uncomment next line for debugging
 #set -x

 ps -ef | grep ora_pmon_$ORACLE_SID | grep -v grep > /dev/null
 if [ $? -ne 0 ]
 then
  SendNotification "Wallet issues on $BOX $ORACLE_SID - please validate! "
  export PROCESS_STATUS=FAILURE
  #exit 3
 fi
}


############################################################
#                       MAIN
############################################################
#uncomment the below line to debug
set -ux
#clear
mkdir -p $HOME/local/dba/scripts/logs
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
MAILTO=CloudOps-DBA@csod.com
#MAILTO=vkurra@csod.com
export CURDATE=$(date +'%Y%m%d')


ostype=$(uname)
if [ $ostype = Linux ]
then
 ORATAB=/etc/oratab
fi
if [ $ostype = SunOS ]
then
 ORATAB=/var/opt/oracle/oratab
fi

 export ORACLE_SID=$1


funct_db_online_verify

# export ORACLE_SID=$1


export ORACLE_HOME=`cat /etc/oratab |sed '/^\s*#/d;/^\s*$/d'|sed 's/:/ /g' |grep $ORACLE_SID |awk '{print $2}'`


     export ORAENV_ASK=NO
     export PATH=/usr/local/bin:$PATH
. /usr/local/bin/oraenv > /dev/null
if [ $? -ne 0 ]
then
 print "\n\n\t\t There seems to be some problem please rectify and Execute Again\n\nAborting Here...."
 exit 2
fi


echo $ORACLE_HOME
$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF > $HOME/local/dba/scripts/logs/wallet_status.log
WHENEVER SQLERROR EXIT FAILURE
set feed off
set head off
set linesize 100
set pagesize 200

select status from V\$ENCRYPTION_WALLET;

exit
EOF

if [[ -s $HOME/local/dba/scripts/logs/wallet_status.log ]]; then

wal_status=`cat $HOME/local/dba/scripts/logs/wallet_status.log |grep -v -e '^$'`

echo $wal_status

if [ $wal_status == 'OPEN' ]; then

echo 'status is OPEN'

else
STATUS=$wal_status
#SendNotification
echo 'NOT open'
fi
#rm -f $HOME/local/dba/scripts/logs/wallet_status.log

fi

$ORACLE_HOME/bin/sqlplus -s '/as sysdba'<<EOF > $HOME/local/dba/scripts/logs/wallet_location.log
WHENEVER SQLERROR EXIT FAILURE
set feed off
set head off
set linesize 100
set pagesize 200

select WRL_PARAMETER from V\$ENCRYPTION_WALLET;

exit
EOF

if [[ -s $HOME/local/dba/scripts/logs/wallet_location.log ]]; then

wal_location=`cat $HOME/local/dba/scripts/logs/wallet_location.log |grep -v -e '^$'`

echo $wal_location

if [ -d $wal_location ]; then

echo 'dir exits'

else

echo 'dir not exits'
SendNotification
STATUS2="${STATUS} patch DOES NOT EXIST - $wal_location"
echo $STATUS2
fi
fi


rm $HOME/local/dba/scripts/logs/wallet_location.log
rm $HOME/local/dba/scripts/logs/wallet_status.log

exit
