#!/usr/bin/env bash

######################################################################################
# Name: server_setter.sh
# Date: 2018-03-23
# Made: ninanotech.com (MyoungSigYoun)
# Desc: Linux Server Setting Script
# Ver :
#      2018-03-23 : 0.1
#                   Create
######################################################################################

export  PATH=/bin:/usr/bin:/sbin:/usr/sbin:.
export  LD_LIBRARY_PATH=/lib64:/usr/lib64:.
export  DATETIME=`date +"%F %H:%M:%S"`
export  DATE=`date +%Y%m%d`
export  HOST=$(hostname)
export  ARCH=$(uname -m)
export  OS=$(egrep ^ID= /etc/os-release  | cut -f 2 -d = | sed -e s/\"//g)
#
print_help() {
 echo  "
 ###################################################################################
 # Useage : server_setter software step
 #      --help or -h : Help
 #      software : oracle, mysql, postgresql, simple
 #      step     : 0 - all
 ###################################################################################
 "
}

make_local_repo() {

echo 'Make yum local repo'

if [ -d /mnt/Packages ]
then
    echo "# $DATE : Modify server setter" > /etc/yum.repos.d/local.repo
    echo "[local-repo]" >> /etc/yum.repos.d/local.repo
    echo "name=Local Repository">> /etc/yum.repos.d/local.repo
    echo "baseurl=file:///mnt" >> /etc/yum.repos.d/local.repo
    echo "enabled=1" >> /etc/yum.repos.d/local.repo
    echo "gpgcheck=0" >> /etc/yum.repos.d/local.repo
else
    echo "!!! Mount OS DVD to /mnt !!!"
    echo "mount -t iso9660 /dev/cdrom /mnt"
fi
}

install_package() {
    echo 'Package Update'

    if [ $OS = ubuntu ] || [ $OS = debian ] 
    then
        apt-get update -y
        
        apt-get install lsb gcc g++ git gdb cmake flex bison autoconf automake xlock xterm zip unzip bzip2 nano vim ntp ntpdate numactl hdparm bc lynx sysstat dstat strace screen mdadm
        apt-get install glances mc language-pack-ko hunspell-ko binutils ksh libaio-dev unixodbc unixodbc-dev python python-dev lvm2 lvm2-dev parted
        apt-get install openssl openssl-dev readline-common zlib1g zlib1g-dev ncurses-base ib64ncurses5 ib64ncurses5-dev libxml2 libxml2-dev xz-utils liblzma5 liblzma-dev
        apt-get install libxslt1.1 libxslt1-dev tcl8.4 tcl8.4-dev tk8.4 tk8.4-dev firewalld libx11-6 libx11-dev libxau6 libxau-dev libxcb1 libxcb1-dev htop nmon

        apt-get upgrade -y
    elif [ $OS = centos ] || [ $OS = rhel ] || [ $OS = ol ]
    then
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y

        yum update -y
        yum install zsh gcc g++ git gdb make cmake flex bsion autoconf automake xclock xterm cyrus-sasl cyrus-sasl-devel libcap libcap-devel -y
        yum install redhat-lsb net-tools bind-utils ethool dstat strace lynx nano vim ntp ntpdate numactl hdparm zip unzip bzip2 wget hunspell-ko man-pages-ko python-devel -y
        yum install mdadm glances nmon bc binutils compat-libcap1 compat-libstdc++ glibc glibc-devel ksh libaio libaio-devel libX11 libXau libXi libXst libgcc libstdc++ libxcb  nfs-utils -y 
        yum install python-configshell python-rtlib python-six smartmontools sysstat targetcli lvm2 lvm2-devel unixODBC unixODBC-devel mc parted -y
        yum install htop openssl openssl-libs openssl-devel zlib-devel ncurses-devel libxml2 libxml2-devel xz xz-devel libxslt libxslt-devel readline readline-devel tk tcl tcl-devel kernel-devel pam-devel firewalld -y

        if [ $OS = ol ]
        then
            yum install oracle-database-server-12cR2-preinstall kmod-oracleasm oracleasm-support -y
        fi
        
        yum upgrade -y
    fi
}

set_swapoff() {
echo 'Swap  OFF'
swapoff -a

if [ $OS = ubuntu ] || [ $OS = debian ] 
then
    chmod 755 /etc/rc.local
    echo 'swapoff -a' >> /etc/rc.local
elif [ $OS = centos ] || [ $OS = rhel ] || [ $OS = ol ]
then
    chmod 755 /etc/rc.d/rc.local
    echo 'swapoff -a' >> /etc/rc.d/rc.local
fi  
}
#

set_hugepage() {
echo 'Disable Transparent HugePages'

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

if [ $OS = ubuntu ] || [ $OS = debian ]
then
    echo "# $DATE : Modify server setter" >> /etc/rc.local
    echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
elif [ $OS = centos ] || [ $OS = rhel ] || [ $OS = ol ]
then
    echo "# $DATE : Modify server setter" >> /etc/rc.d/rc.local
    echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
fi
}

grubby --update-kernel=ALL --args="elevator=deadline"
grubby --update-kernel=ALL --args="transparent_hugepage=never"
grubby --info=ALL

#

set_limits() {
echo 'limits.conf setting'

mv /etc/security/limits.conf /etc/security/limits.conf.$DATE

echo "# $DATE : Modify server setter" >> /etc/security/limits.conf
echo "* soft nofile 102400" >> /etc/security/limits.conf
echo "* hard nofile 102400" >> /etc/security/limits.conf
echo "* soft nproc  131072" >> /etc/security/limits.conf
echo "* hard nproc  131072" >> /etc/security/limits.conf
echo "* soft stack  102400" >> /etc/security/limits.conf
echo "* hard stack  102400" >> /etc/security/limits.conf
echo "* soft core   unlimited" >> /etc/security/limits.conf
echo "* hard core   unlimited" >> /etc/security/limits.conf
echo "* soft memlock unlimited" >> /etc/security/limits.conf
echo "* hard memlock unlimited" >> /etc/security/limits.conf
}
#

set_pam() {
echo 'pam.conf setting'


if [ $OS = ubuntu ] || [ $OS = debian ]
then
    echo "# $DATE : Modify server setter" >> /etc/pam.d/login
    echo "session required /lib/x86_64-linux-gnu/security/pam_limits.so" >> /etc/pam.d/login
elif [ $OS = centos ] || [ $OS = rhel ] || [ $OS = ol ]
then
    echo "# $DATE : Modify server setter" >> /etc/pam.d/login
    echo "session required /lib64/security/pam_limits.so" >> /etc/pam.d/login
    echo "session required pam_limits.so" >> /etc/pam.d/login
fi
}

set_selinux() {
echo "selinux config setting"

sed -e s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config > /etc/selinux/config.tmp
mv /etc/selinux/config /etc/selinux/config.$DATE
mv /etc/selinux/config.tmp /etc/selinux/config

setenforce 0
sestatus

}

set_disks() {
echo "disk setting will be modify (disk count), not nvme disk"
echo "ex) disable write cache : hdparm -W 0 /dev/sdb"

if [ $OS = ubuntu ] || [ $OS = debian ]
then
    echo "echo 1000 > /sys/block/sdb/queue/nr_requests" >> /etc/rc.local

    echo "######################################################################################"
    echo "if data directiory file system is xfs then /etc/fstab"
    echo "    xfs mount option: rw,nodev,noatime,nodiratime,nobarrier,discard,inode64,logbufs=8,logbsize=256k,attr2,allocsize=16m"
    echo "    and /etc/rc.local "
    echo "    blockdev --setra 16384 /dev/sdb"
    echo "    blockdev --report /dev/sdb"
    echo " else ext4 then /etc/fstab"
    echo "   ext4 mount option: rw,noatime,nodiratime,nobarrier,data=ordered"
    echo "######################################################################################"
elif [ $OS = centos ] || [ $OS = rhel ] || [ $OS = ol ]
then
    echo "echo 1000 > /sys/block/sdb/queue/nr_requests" >> /etc/rc.d/rc.local

    echo "######################################################################################"
    echo "if data directiory file system is xfs then /etc/fstab"
    echo "    xfs mount option: rw,nodev,noatime,nodiratime,nobarrier,discard,inode64,logbufs=8,logbsize=256k,attr2,allocsize=16m"
    echo "    and /etc/rc.d/rc.local "
    echo "    blockdev --setra 16384 /dev/sdb"
    echo "    blockdev --report /dev/sdb"
    echo " else ext4 then /etc/fstab"
    echo "   ext4 mount option: rw,noatime,nodiratime,nobarrier,data=ordered"
    echo "######################################################################################"
fi

echo "tmpfs /tmp tmpfs defaults 0 0" >> /etc/fstab

mount /tmp

}
#
# Turn off TCP Segmentation
set_tcp() {
echo "Turn off TCP Segmentation"

ethtool -K eth0 tso off
ethtool -K eth0 gro off
}

# NTP
set_ntp() {
echo "NTP Setting"

systemctl stop ntpd

if [ $OS = ubuntu ] || [ $OS = debian ] ||  [ $OS = centos ] 
then
    mv /etc/default/ntpd /etc/default/ntpd.`date +%Y%m%d`
    echo "NTPD_OPTS=\"-x -g\"" > /etc/default/ntpd
elif [ $OS = rhel ] || [ $OS = ol ]
then
    mv /etc/sysconfig/ntpd /etc/sysconfig/ntpd.`date +%Y%m%d`
    echo "OPTIONS=\"-x -g\"" > /etc/sysconfig/ntpd
fi

echo "server ntp1.epidc.co.kr perfer " >> /etc/ntp.conf
echo "server ntp2.epidc.co.kr" >> /etc/ntp.conf
echo "server time.bora.net" >> /etc/ntp.conf

systemctl start ntpd
systemctl enable ntpd

ntpq -p
}

set_sysctl() {

export MEM_BYTES=$(awk '/MemTotal:/ { printf "%0.f",$2 * 1024}' /proc/meminfo)
export SHMMAX=$(echo "$MEM_BYTES * 0.80" | bc | cut -f 1 -d '.')
export SHMALL=$(expr $SHMMAX / $(getconf PAGE_SIZE))
export MAX_ORPHAN=$(echo "$MEM_BYTES * 0.10 / 65536" | bc | cut -f 1 -d '.')
export FILE_MAX=$(echo "$MEM_BYTES / 4194304 * 256" | bc | cut -f 1 -d '.')
export MAX_TW=$(($FILE_MAX * 2))
export MIN_FREE=$(echo "($MEM_BYTES / 1024) * 0.01" | bc | cut -f 1 -d '.')
export HUGEPAGE=$(echo "($MEM_BYTES * 0.25) / (2048 * 1024)" | bc | cut -f 1 -d '.')

mv /etc/sysctl.conf /etc/sysctl.conf.$DATE

echo "# $DATE : Modify server setter" >> /etc/sysctl.conf

echo "kernel.sched_autogroup_enabled=0 " >> /etc/sysctl.conf
echo "kernel.sched_min_granularity_ns=2000000 " >> /etc/sysctl.conf
echo "kernel.sched_latency_ns=10000000 " >> /etc/sysctl.conf
echo "kernel.sched_wakeup_granularity_ns=5000000 " >> /etc/sysctl.conf
echo "kernel.sched_migration_cost_ns=500000 " >> /etc/sysctl.conf
echo "kernel.sysrq=1" >> /etc/sysctl.conf
echo "kernel.core_uses_pid=1" >> /etc/sysctl.conf

echo "## Shared mem" >> /etc/sysctl.conf
echo "kernel.msgmnb=65536 " >> /etc/sysctl.conf
echo "kernel.msgmax=65536" >> /etc/sysctl.conf
echo "kernel.shmmax=$SHMMAX" >> /etc/sysctl.conf
echo "kernel.shmall=$SHMALL" >> /etc/sysctl.conf
echo "kernel.shmmni=4096" >> /etc/sysctl.conf
echo "kernel.sem=250 32000 100 128 " >> /etc/sysctl.conf

echo "vm.overcommit_memory=2" >> /etc/sysctl.conf
echo "vm.overcommit_ratio=50" >> /etc/sysctl.conf
 
echo "vm.max_map_count=1048576" >> /etc/sysctl.conf
echo "vm.swappiness=0 " >> /etc/sysctl.conf

echo "# this part check" >> /etc/sysctl.conf
echo "vm.nr_hugepages=$HUGEPAGE " >> /etc/sysctl.conf
echo "vm.hugetlb_shm_group=1000" >> /etc/sysctl.conf
echo "#" >> /etc/sysctl.conf

echo "vm.dirty_background_ratio=10" >> /etc/sysctl.conf
echo "vm.dirty_background_bytes=0 " >> /etc/sysctl.conf
echo "vm.dirty_ratio=20 " >> /etc/sysctl.conf
echo "vm.dirty_bytes=0 " >> /etc/sysctl.conf
echo "vm.min_free_kbytes=$MIN_FREE" >> /etc/sysctl.conf

echo "fs.file-max=$FILE_MAX " >> /etc/sysctl.conf
echo "fs.aio-max-nr=$FILE_MAX" >> /etc/sysctl.conf

echo "net.core.somaxconn=65535 " >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog=10000 " >> /etc/sysctl.conf
echo "net.core.rmem_default=26214400 " >> /etc/sysctl.conf
echo "net.core.rmem_max=26214400 " >> /etc/sysctl.conf
echo "net.core.wmem_default=26214400 " >> /etc/sysctl.conf
echo "net.core.wmem_max=26214400 " >> /etc/sysctl.conf

echo "net.ipv6.conf.all.disable_ipv6=1 " >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1 " >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1 " >> /etc/sysctl.conf

echo "net.ipv4.tcp_rmem=4096 65536 25165824 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem=4096 65536 25165824" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mem=786432 1048576 26777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout=20 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time=600 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_probes=3 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_intvl=10 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_orphan_retries=1 " >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_orphans=$MAX_ORPHAN" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rfc1337=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route=0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=20000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets=$MAX_TW" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
#
sysctl -p
}

#
create_users() {

echo 'ulimit -u 65535' >> /etc/profile
#
case $1 in
 oracle)
	groupadd -g 1000 oinstall
	groupadd -g 1001 dba
	groupadd -g 1002 oper
	groupadd -g 1003 asmdba
	groupadd -g 1004 asmoper
	groupadd -g 1005 asmadmin

	useradd -u 1000 -g oinstall -G dba,oper,asmdba,asmoper,asmadmin -d /home/oracle -s /bin/bash -m -c "Oracle Admin" $1

	echo $1 User Create
	;;
 mysql)
	groupadd -g 1000 mysql

	useradd -u 1000 -g mysql -d /home/mysql -s /bin/bash -m -c "MySQL Admin" $1

	echo $1 User Create
	;;
 postgres)
	groupadd -g 1000 postgres

	useradd -u 1000 -g postgres -d /home/postgres -s /bin/bash -m -c "Postgres Admin" $1

	echo $1 User Create
	;;
 *)
	;;
esac
}
#

if [ -z $1 ] || [ $1 = '--help' ] || [ $1 = '-h' ]
then
 print_help
 
 exit
fi

#
echo $DATETIME : $HOST $OS $ARCH $1 'Server Setting Processes start'
#

if [ $OS = rhel ] || [ $OS = ol ]
then
    make_local_repo
fi

install_package

set_swapoff
set_hugepage
set_limits
set_pam
set_selinux
set_disks
set_ntp
set_sysctl
create_users

#
echo `date +"%F %H:%M:%S"` : $HOST $OS $ARCH $1 'Server Setting Processes end'
