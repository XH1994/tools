#!/bin/bash
echo "
*                soft    nproc           unlimited
*                hard    nproc           unlimited
*                soft    nofile          65535
*                hard    nofile          65535 " >> /etc/security/limits.conf
echo "
ulimit -SHn 65535
ulimit -SHu unlimited
ulimit -SHd unlimited
ulimit -SHm unlimited
ulimit -SHs unlimited
ulimit -SHt unlimited
ulimit -SHv unlimited" >> /etc/profile
source /etc/profile
ulimit -a
echo "
#*          soft    nproc     1024               //注释
#root       soft    nproc     unlimited          //注释
*          soft    nproc     unlimited
*          hard    nproc     unlimited
*          soft    nofile    65535
*          hard    nofile    65535" >> /etc/security/limits.d/20-nproc.conf
echo "
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.core.netdev_max_backlog = 1024
net.core.somaxconn = 2048
net.core.wmem_default  = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_max_orphans  = 3276800
net.ipv4.tcp_mem = 94500000 915000000 927000000
vm.overcommit_memory = 1" >> /etc/sysctl.conf
/sbin/sysctl -p 
sed -i 's/#Port 22/Port 13688/' /etc/ssh/sshd_config
systemctl restart sshd.service
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
systemctl restart sshd.service
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd.service
systemctl stop firewalld.service                 //停止firewall
systemctl disable firewalld.service	             //禁止firewall开机启动
yum -y install iptables-services                 //yum方式安装iptables
systemctl start iptables.service                 //启动iptables防火墙
systemctl enable iptables.service
echo "
# Firewall configuration written by system-config-firewall
# Manual customization of this file is not recommended.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 80,13688 -j ACCEPT
-A INPUT -s 192.168.100.0/24 -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT 
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
# Iptables For Carisok.com Date 2015/10/20" >> /etc/sysconfig/iptables
systemctl restart iptables.service
systemctl reload iptables.service
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sed -i 's/SELINUXTYPE=targeted/#SELINUXTYPE=targeted/' /etc/selinux/config
setenforce 0
yum -y install ntp
ntpdate cn.pool.ntp.org
hwclock --systohc
yum -y install bash-completion curl curl-devel c-ares gcc gcc-c++ glibc libxml2-devel libxml2 libxml-devel libxml libmcrypt libmcrypt-devel lsof lrzsz libaio libaio-devel lzo make m4 ntp ncurses ncurses-devel net-tools openssl openssl-devel python-devel patch quota sos sysstat telnet vim wget zlib zlib-devel zip unzip perl-Data-Dumper perl-Test-Harness perl-Thread-Queue perl-XML-Parser
mkdir -p /data/{tools,backup,www,logs,mysql,shell}
cd /data/tools
wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
tar xf autoconf-2.69.tar.gz
cd autoconf-2.69
./configure
make && make install
cd /data/tools
wget http://ftp.gnu.org/gnu/automake/automake-1.16.1.tar.gz
tar xf automake-1.16.1.tar.gz
cd automake-1.16.1
./configure
make && make install
cd /data/tools
wget ftp://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz
tar xf libtool-2.4.6.tar.gz
cd libtool-2.4.6
./configure
make && make install
echo "
#!/bin/bash
# This script is used to close some service is not used on the server
# Date 2016-03-05

for i in `chkconfig --list | awk -F ' '  '{print $1}'`;do
    chkconfig $i off
done

for j in network crond rsyslog sshd ntpdate iptables;do
    chkconfig $j on
done" >> close_service.sh
chmod o+x close_service.sh
bash close_service.sh
