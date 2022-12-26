#!/bin/bash

# ping
PINGCMD=/usr/bin/ping
SENDCMD=/usr/bin/zabbix_sender
CHECKHOST=aws.com11
ZABBIXSERVER=43.254.55.225
ZABBIXPORT=10051
LOCALHOST=checkping_monitor
PAG_NUM=1
ZAX_KEY=ping_response


# ping
check_ping() {
   $PINGCMD -c $PAG_NUM $CHECKHOST >/dev/null 2>&1
   if [ $? -eq 0 ];then
        RESPONSE_TIME=`$PINGCMD -c $PAG_NUM -w 1 $CHECKHOST |head -2 |tail -1|awk '{print $(NF-1)}'|cut -d= -f2`
        echo $RESPONSE_TIME
   else
        echo 0
   fi
}

# zabbixserver
send_data() {
  DATA=`check_ping`
  $SENDCMD -z $ZABBIXSERVER -s $LOCALHOST -k $ZAX_KEY -o $DATA
}

while true
do
        send_data
        sleep 0.5
done
