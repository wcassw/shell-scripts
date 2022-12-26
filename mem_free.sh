#!/bin/bash

WARN_LINE=70
LOG_DIR=/var/log/memfree/
[ ! -d ${LOG_DIR} ] && mkdir -p ${LOG_DIR}
LOG_FILE=$(date +%F)-memefree.log
LOG_TOTLE=${LOG_DIR}${LOG_FILE}
MEM_TOTLE=$(free  -m | awk 'NR==2{print $2}')
MEM_USE=$(free  -m | awk 'NR==2{print $3}')

#USE_PERCENT=$(printf "%5f" `echo "scale=5;${MEM_USE}/${MEM_TOTLE}"|bc`)
USE_PERCENT=$(awk -v use=${MEM_USE} -v totle=${MEM_TOTLE} 'BEGIN{printf "%0.0f",use/totle*100}')

echo ${USE_PERCENT}
if [[ ${USE_PERCENT} -ge ${WARN_LINE} ]];then
        echo "---------$(date +%F" "%T) mem free begin---------" >> ${LOG_TOTLE}
        echo ":" >> ${LOG_TOTLE}
        free -m &>>${LOG_TOTLE}
        sync
        echo 1 > /proc/sys/vm/drop_caches
        echo 2 > /proc/sys/vm/drop_caches
        echo 3 > /proc/sys/vm/drop_caches
        echo ":" >> ${LOG_TOTLE}
        free -m &>>${LOG_TOTLE}
        echo "---------$(date +%F" "%T) mem free end---------" >> ${LOG_TOTLE}
fi
