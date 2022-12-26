#!/bin/bash
#func:scan file
#md5sum -c $SCAN_FILE


SCAN_DIR=`echo $PATH |sed 's/:/ /g'`
SCAN_CMD=`which md5sum`
SCAN_FILE_FAIL="/tmp/scan_$(date +%F%H%m)_fall.txt"
SCAN_FILE_BIN="/tmp/scan_$(date +%F%H%m)_bin.txt"

scan_fall_disk() {
	echo ":$SCAN_FILE_FALL"
	find / -type f ! -path "/proc/*" -exec $SCAN_CMD \{\} \;>> $SCAN_FILE_FAIL 2>/dev/null
	echo " "
	echo "$SCAN_CMD -c $SCAN_FILE_FAIL |grep -v 'OK$'"
}

scan_bin() {
	echo "：$SCAN_FILE_BIN"
	for file in $SCAN_DIR
	do
		find $file -type f -exec $SCAN_CMD \{\} \;>> $SCAN_FILE_BIN 2>/dev/null
	done
	echo " "
	echo "$SCAN_CMD -c $SCAN_FILE_BIN |grep -v 'OK$'"
}

clear
echo "##########################################"
echo "#                                        #"
echo "#        d5sum.                      #"
echo "#                                        #"
echo "##########################################"
echo "1: scan_fail_disk"
echo "2: bin path"
echo "3: EXIT"
read -p "Please input your choice:" method
case $method in 
1)
	scan_fall_disk;;
2)
	scan_bin;;
3)
        echo "you choce channel!" && exit 1;;
*)
	echo "input Error! Place input{1|2|3}" && exit 0;;
esac
        
