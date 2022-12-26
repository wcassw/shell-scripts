#!/bin/bash

# func:sys info check
# version:v1.0
# sys:centos6.x/7.x

[ $(id -u) -gt 0 ] && echo "root" && exit 1
sysversion=$(rpm -q centos-release|cut -d- -f3)
line="-------------------------------------------------"


[ -d logs ] || mkdir logs

sys_check_file="logs/$(ip a show dev eth0|grep -w inet|awk '{print $2}'|awk -F '/' '{print $1}')-`date +%Y%m%d`.txt"

# cpu
function get_cpu_info() {
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
cat <<EOF | column -t 
CPU:

CPU Phy: $Physical_CPUs
CPU virt: $Virt_CPUs
CPU kernel: $CPU_Kernels
CPU type: $CPU_Type
CPU arch: $CPU_Arch
EOF
}

function get_mem_info() {
    check_mem=$(free -m)
    MemTotal=$(grep MemTotal /proc/meminfo| awk '{print $2}')  #KB
    MemFree=$(grep MemFree /proc/meminfo| awk '{print $2}')    #KB
    let MemUsed=MemTotal-MemFree
    MemPercent=$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")
    report_MemTotal="$((MemTotal/1024))""MB"        
    report_MemFree="$((MemFree/1024))""MB"   
    report_MemUsedPercent="$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%"  

cat <<EOF
Mem:

${check_mem}
EOF
}

function get_net_info() {
    pri_ipadd=$(ip a show dev eth0|grep -w inet|awk '{print $2}'|awk -F '/' '{print $1}')
    pub_ipadd=$(curl ifconfig.me -s)
    gateway=$(ip route | grep default | awk '{print $3}')
    mac_info=$(ip link| egrep -v "lo"|grep link|awk '{print $2}')
    dns_config=$(egrep -v "^$|^#" /etc/resolv.conf)
    route_info=$(route -n)
cat <<EOF | column -t 
IP:

public: ${pub_ipadd}
private: ${pri_ipadd}
gateway: ${gateway}
MAC: ${mac_info}

route:
${route_info}

DNS:
${dns_config}
EOF
}

function get_disk_info() {
    disk_info=$(fdisk -l|grep "Disk /dev"|cut -d, -f1)
    disk_use=$(df -hTP|awk '$2!="tmpfs"{print}')
    disk_inode=$(df -hiP|awk '$1!="tmpfs"{print}')

cat <<EOF
Disk:

${disk_info}
Disk use:

${disk_use}
inodes:

${disk_inode}
EOF


}

function get_systatus_info() {
    sys_os=$(uname -o)
    sys_release=$(cat /etc/redhat-release)
    sys_kernel=$(uname -r)
    sys_hostname=$(hostname)
    sys_selinux=$(getenforce)
    sys_lang=$(echo $LANG)
    sys_lastreboot=$(who -b | awk '{print $3,$4}')
    sys_runtime=$(uptime |awk '{print  $3,$4}'|cut -d, -f1)
    sys_time=$(date)
    sys_load=$(uptime |cut -d: -f5)

cat <<EOF | column -t 
OS:

OS: ${sys_os}
sys_release:   ${sys_release}
sys_kernel:   ${sys_kernel}
sys_hostname:    ${sys_hostname}
selinux:  ${sys_selinux}
lang:   ${sys_lang}
time: ${sys_time}
lastreboot:   ${sys_lastreboot}
runtime: ${sys_runtime}
load:   ${sys_load}
EOF
}

function get_service_info() {
    port_listen=$(netstat -lntup|grep -v "Active Internet")
    kernel_config=$(sysctl -p 2>/dev/null)
    if [ ${sysversion} -gt 6 ];then
        service_config=$(systemctl list-unit-files --type=service --state=enabled|grep "enabled")
        run_service=$(systemctl list-units --type=service --state=running |grep ".service")
    else
        service_config=$(/sbin/chkconfig | grep -E ":on|:启用" |column -t)
        run_service=$(/sbin/service --status-all|grep -E "running")
    fi
cat <<EOF
service:

${service_config}
${line}
service:

${run_service}
${line}
Ports:

${port_listen}
${line}
kernel_config:

${kernel_config}
EOF
}


function get_sys_user() {
    login_user=$(awk -F: '{if ($NF=="/bin/bash") print $0}' /etc/passwd)
    ssh_config=$(egrep -v "^#|^$" /etc/ssh/sshd_config)
    sudo_config=$(egrep -v "^#|^$" /etc/sudoers |grep -v "^Defaults")
    host_config=$(egrep -v "^#|^$" /etc/hosts)
    crond_config=$(for cronuser in /var/spool/cron/* ;do ls ${cronuser} 2>/dev/null|cut -d/ -f5;egrep -v "^$|^#" ${cronuser} 2>/dev/null;echo "";done)
cat <<EOF
sys_user:

${login_user}
${line}
ssh sys_user:

${ssh_config}
${line}
sudo ssh:

${sudo_config}
${line}
crond_config:

${crond_config}
${line}
hosts:

${host_config}
EOF
}


function process_top_info() {

    top_title=$(top -b n1|head -7|tail -1)
    cpu_top10=$(top b -n1 | head -17 | tail -10)
    mem_top10=$(top -b n1|head -17|tail -10|sort -k10 -r)

cat <<EOF
CPU top10:

${top_title}
${cpu_top10}

top10:

${top_title}
${mem_top10}
EOF
}


function sys_check() {
    get_cpu_info
    echo ${line}
    get_mem_info
    echo ${line}
    get_net_info
    echo ${line}
    get_disk_info
    echo ${line}
    get_systatus_info
    echo ${line}
    get_service_info
    echo ${line}
    get_sys_user
    echo ${line}
    process_top_info
}


sys_check > ${sys_check_file}
