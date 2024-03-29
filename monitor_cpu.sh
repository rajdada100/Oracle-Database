#! /bin/ksh

# -----------------------------------------------------------------------------
# Function SendNotification
#       This function sends mail notifications
# -----------------------------------------------------------------------------
function SendNotification {

        # Uncomment for debug
        # set -x

        print "${PROGRAM_NAME} \n     Machine: $BOX \n" > mail.dat
        if [[ x$1 != 'x' ]]; then
                print "\n$1\n\n\n" >> mail.dat
        fi

        cat $LOGFILE >> mail.dat
        cat mail.dat | /bin/mail -s "Critical: CPU Load -- on ${BOX}" ${MAILTO}
        rm -f mail.dat

        return 0
}

############################################################
#                       MAIN
############################################################
#uncomment the below line to debug
set -x
#clear
mkdir -p $HOME/local/dba/scripts/logs
export LOGFILE=/tmp/current_load
export BOX=$(print $(hostname) | awk -F "." '{print $1}')
export PROGRAM_NAME=$(print $0 | sed 's/.*\///g')
#export MAILTO='bkhan@saba.com'
export MAILTO='CloudOps-DBA@csod.com,CloudOps-DBA@saba.com,CloudOps-DBA@saba.com'
#export MAILTO='makhtar@saba.com'
export CURDATE=$(date +'%Y%m%d')

FTEXT='load average:'

F5M="$(uptime | awk -F "$FTEXT" '{ printf "%.0f\n", $2 }' | cut -d, -f1 | sed 's/ //g')"
echo "Current Load on `date +"%m-%d-%Y"`" at "`date +"%r"`" > $LOGFILE
echo $(print "\n \t \t")>> $LOGFILE
echo "Load Averages: `uptime | awk -F "$FTEXT" '{ print $2}'`">> $LOGFILE
CLOAD="$(echo $F5M |awk '{print $1}')"
echo "CLoad:" $CLOAD
if [[ $CLOAD -gt  `cat /proc/cpuinfo | grep processor | wc -l`  ]];  then
        SendNotification
fi

exit

