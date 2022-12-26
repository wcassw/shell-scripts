#!/bin/bash
#############

echo "##########################################"
echo "Auto Install smokeping-2.6.11           ##"
echo "Press Ctrl + C to cancel                ##"
echo "Any key to continue                     ##"
echo "##########################################"
read -n 1
/etc/init.d/iptables status >/dev/null 2>&1
if [ $? -eq 0 ]
then
iptables -I INPUT -p tcp --dport 80 -j ACCEPT && 
iptables-save >/dev/null 2>&1
else
	echo -e "\033[32m iptables is stopd\033[0m"
fi
IP=`/sbin/ifconfig|sed -n '/inet addr/s/^[^:]*:\([0-9.]\{7,15\}\) .*/\1/1p'|sed -n '1p'`
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
rpm -Uvh http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm 1>/dev/null
yum -y install perl perl-Net-Telnet perl-Net-DNS perl-LDAP perl-libwww-perl perl-RadiusPerl perl-IO-Socket-SSL perl-Socket6 perl-CGI-SpeedyCGI perl-FCGI perl-CGI-SpeedCGI perl-Time-HiRes perl-ExtUtils-MakeMaker perl-RRD-Simple rrdtool rrdtool-perl curl fping echoping  httpd httpd-devel gcc make  wget libxml2-devel libpng-devel glib pango pango-devel freetype freetype-devel fontconfig cairo cairo-devel libart_lgpl gcc libart_lgpl-devel mod_fastcgi wget wqy-*
if [ -d /opt ];then
    cd /opt
else
    mkdir -p /opt && cd /opt
fi
wget http://oss.oetiker.ch/smokeping/pub/smokeping-2.6.11.tar.gz 
tar -xvf smokeping-2.6.11.tar.gz 1>/dev/null
cd /opt/smokeping-2.6.11
./setup/build-perl-modules.sh /usr/local/smokeping/thirdparty 
./configure -prefix=/usr/local/smokeping 
/usr/bin/gmake install  1>/dev/null
cd /usr/local/smokeping
mkdir cache data var 1>/dev/null
touch /var/log/smokeping.log
chown -R apache:apache cache data var
chown -R apache:apache /var/log/smokeping.log
mv /usr/local/smokeping/htdocs/smokeping.fcgi.dist  /usr/local/smokeping/htdocs/smokeping.fcgi
mv /usr/local/smokeping/etc/config.dist  /usr/local/smokeping/etc/config
cp -f /usr/local/smokeping/etc/config /usr/local/smokeping/etc/config.back
sed -i "s/some.url/IP/g" /usr/local/smokeping/etc/config
chmod 600 /usr/local/smokeping/etc/smokeping_secrets.dist

if [ -d /opt ];then
    cd /opt
else
    mkdir -p /opt && cd /opt
fi
wget -c -O /opt/fping-3.13.tar.gz http://fping.org/dist/fping-3.13.tar.gz
tar zxvf fping-3.13.tar.gz
cd fping-3.13
./configure --prefix=/usr/local/fping
make && make install
sed -i "s#`grep fping /usr/local/smokeping/etc/config`#binary = /usr/local/fping/sbin/fping#g" /usr/local/smokeping/etc/config
sed -i "148i'--font TITLE:20:"WenQuanYi\ Zen\ Hei\ Mono"'\," /usr/local/smokeping/lib/Smokeping/Graphs.pm
cp -rf /etc/httpd/conf/httpd.conf  /etc/httpd/conf/httpd.conf.back
cat >> /etc/httpd/conf/httpd.conf <<'EOF'
Alias /cache "/usr/local/smokeping/cache/"
Alias /cropper "/usr/local/smokeping/htdocs/cropper/"
Alias /smokeping "/usr/local/smokeping/htdocs/smokeping.fcgi"
<Directory "/usr/local/smokeping">
AllowOverride None
Options All
AddHandler cgi-script .fcgi .cgi
Order allow,deny
Allow from all
DirectoryIndex smokeping.fcgi
</Directory>
EOF

if [ -f /etc/init.d/smokeping ];then
    echo "/etc/init.d/smokeping is exist"
else
    touch /etc/init.d/smokeping
    cat > /etc/init.d/smokeping <<'EOF'
	#!/bin/bash
	#chkconfig: 2345 80 05
	# Description: Smokeping init.d script
	# Create by : Mox
	# Get function from functions library
	. /etc/init.d/functions
	# Start the service Smokeping
	smokeping=/usr/local/smokeping/bin/smokeping
	prog=smokeping
	pidfile=${PIDFILE-/usr/local/smokeping/var/smokeping.pid}
	lockfile=${LOCKFILE-/var/lock/subsys/smokeping}
	RETVAL=0
	STOP_TIMEOUT=${STOP_TIMEOUT-10}
	LOG=/var/log/smokeping.log

	start() {
        echo -n $"Starting $prog: "
        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $smokeping $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
	}


	# Restart the service Smokeping
	stop() {
        echo -n $"Stopping $prog: "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $smokeping
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
	}

	STOP_TIMEOUT=${STOP_TIMEOUT-10}
	LOG=/var/log/smokeping.log

	start() {
        echo -n $"Starting $prog: "
        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $smokeping $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
	}


	# Restart the service Smokeping
	stop() {
        echo -n $"Stopping $prog: "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $smokeping
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
	}

	case "$1" in
	start)
        start
	;;
	stop)
        stop
	;;
	status)
        status -p ${pidfile} $httpd
        RETVAL=$?
	;;
	restart)
        stop
        start
        ;;
	*)
        echo $"Usage: $prog {start|stop|restart|status}"
        RETVAL=2

	esac

EOF
fi

cat > /usr/local/smokeping/etc/config <<'EOF'
*** General ***

owner    = Peter Random
contact  = service02@51idc.com
#mailhost = smtp.51idc.com:25
#mailusr  = xuel@51idc
#mailpwd  = anchnet@123.com
#sendmail = /usr/sbin/sendmail
# NOTE: do not put the Image Cache below cgi-bin
# since all files under cgi-bin will be executed ... this is not
# good for images.
imgcache = /usr/local/smokeping/cache
imgurl   = cache
datadir  = /usr/local/smokeping/data
piddir  = /usr/local/smokeping/var
cgiurl   = http://$IP/smokeping.cgi
smokemail = /usr/local/smokeping/etc/smokemail.dist
tmail = /usr/local/smokeping/etc/tmail.dist
# specify this to get syslog logging
syslogfacility = local0
# each probe is now run in its own process
# disable this to revert to the old behaviour
# concurrentprobes = no

*** Alerts ***
to = 13122690827@163.com
from = service02@51idc.com

+someloss
type = loss
# in percent
pattern = >0%,*12*,>0%,*12*,>0%
comment = loss 3 times  in a row

+rttdetect
type = rtt
 #in milli seconds
pattern = <10,<10,<10,<10,<10,<100,>100,>100,>100
edgetrigger = yes
comment = routing messed up again ?

+lossdetect
type = loss
# in percent
pattern = ==0%,==0%,==0%,==0%,>20%,>20%,>20%
edgetrigger = yes
comment = suddenly there is packet loss

+miniloss
type = loss
# in percent
pattern = >0%,*12*,>0%,*12*,>0%
edgetrigger = yes
#pattern = >0%,*12*
comment = detected loss 1 times over the last two hours

#+rttdetect
#type = rtt
# in milliseconds
#pattern = <1,<1,<1,<1,<1,<2,>2,>2,>2
#comment = routing messed up again ?

+rttbad
type = rtt
# in milliseconds
edgetrigger = yes
pattern = ==S,>20
comment = route

+rttbadstart
type = rtt
# in milliseconds
edgetrigger = yes
pattern = ==S,==U
comment = offline at startup
*** Database ***

step     = 60
pings    = 20

# consfn mrhb steps total

AVERAGE  0.5   1  1008
AVERAGE  0.5  12  4320
    MIN  0.5  12  4320
    MAX  0.5  12  4320
AVERAGE  0.5 144   720
    MAX  0.5 144   720
    MIN  0.5 144   720

*** Presentation ***
charset = utf-8
template = /usr/local/smokeping/etc/basepage.html.dist

+ charts

menu = "menu"
title = "title"

++ stddev
sorter = StdDev(entries=>4)
title = "stddev"
menu = "menu_stddev"
format = 综合指数 %f

++ max
sorter = Max(entries=>5)
title = max
menu = max_menu
format = ""

++ loss
sorter = Loss(entries=>5)
title = loss
menu = loss_menu
format = ""

++ median
sorter = Median(entries=>5)
title = median
menu = median_menu
format = ""

+ overview 

width = 860
height = 150
range = 10h

+ detail

width = 860
height = 200
unison_tolerance = 2

"Last 3 Hours"    3h
"Last 30 Hours"   30h
"Last 10 Days"    10d
"Last 30 Days"   30d
"Last 90 Days"   90d
#+ hierarchies
#++ owner
#title = Host Owner
#++ location
#title = Location

*** Probes ***

+ FPing

binary = /usr/local/fping/sbin/fping

*** Slaves ***
secrets=/usr/local/smokeping/etc/smokeping_secrets.dist
+boomer
display_name=boomer
color=0000ff

+slave2
display_name=another
color=00ff00

*** Targets ***

probe = FPing

menu = Top
#title = Network Latency Grapher
title = IDC
#remark = Welcome to the SmokePing website of xxx Company. \
#         Here you will learn all about the latency of our network.
remark = Smokeping 

+ TELCOM
menu = TELCOM
title = TELCOM

++ north
menu = north
title = north


+++ dublin
menu = dublin
title = IP:218.30.25.45
host = 218.30.25.45

EOF
chmod +x /etc/init.d/smokeping
chkconfig smokeping on
chkconfig httpd on
/etc/init.d/httpd start
/etc/init.d/smokeping start
if [ $? -eq 0 ];then
echo -e "\\033[32m smokeping setup successfull URR：http://$IP/smokeping\\033[0m"
fi
