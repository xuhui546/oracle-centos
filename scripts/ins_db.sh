#!/bin/bash
set -x
# set time zone of virtual machine to Europe/Berlin
# mv /etc/localtime /etc/localtime.bak
# ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# add all necessary oracle groups
groupadd oinstall
groupadd dba
groupadd oper
groupadd asmadmin

# add user for oracle
useradd -p oracle -g oinstall -G dba,asmadmin,oper -s /bin/bash -m oracle
chown -R oracle:oinstall /opt/oracle-centos
chown -R oracle:oinstall /tmp/database

# set environment variables for the oracle user
#   - this is needed to be able to start the database with the user "oracle"
sed -e '{s/{{\([^{]*\)}}/${\1}/g; s/^/echo "/; s/$/";/}' -e e ./conf/bashrc > /home/oracle/.bashrc

# create oracle install directories
mkdir -p $ORACLE_HOME
# change the permissions of the oracle install directories
chown -R oracle:oinstall $ORACLE_BASE

# install packages
(
    error=0
    rpms='binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel 
gcc gcc-c++ glibc glibc-common glibc-devel libaio libaio-devel libgcc 
libstdc++ libstdc++-devel make numactl sysstat libXp unixODBC unixODBC-devel unzip sudo'
    for i in $rpms; do 
        set +e
        rpm -q $i
        status=$?
        set -e
        if [[ $status -ne 0 ]]; then
            yum -y install $i
        fi
    done
    if ! grep -q '^multilib_policy=all' /etc/yum.conf; then 
        sed -i '$ a multilib_policy=all' /etc/yum.conf; 
        echo "multilib_policy=all append success."; 
    else 
        echo "multilib_policy=all already exists."; 
    fi
    rpms='compat-libstdc++-33 glibc glibc-devel libaio libaio-devel libgcc libstdc++ unixODBC unixODBC-devel'
    for i in $rpms; do 
        set +e
        rpm -q $i
        status=$?
        set -e
        if [[ $status -ne 0 ]]; then
            yum -y install $i
        fi
    done
    if grep -q '^multilib_policy=all' /etc/yum.conf; then 
        sed -i '/multilib_policy=all/d' /etc/yum.conf; 
        echo "multilib_policy=all delete success."; 
    else 
        echo "multilib_policy=all not in this files."; 
    fi
)


# change location of the oracle inventory and set correct permissions
echo inventory_loc=$ORACLE_BASE/oraInventory > /etc/oraInst.loc
echo inst_group=oinstall >> /etc/oraInst.loc
chown oracle:oinstall /etc/oraInst.loc
chmod 777 /etc/oraInst.loc


# disable property requiretty to avoid an error during oracle installation
sed -i.bak s/Defaults\ \ \ \ requiretty/\#Defaults\ \ \ \ requiretty/g /etc/sudoers


if [[ ! -r "/tmp/database" ]]; then
    unzip /root/soft/linux.x64_11gR2_database_1of2.zip -d /tmp
    unzip /root/soft/linux.x64_11gR2_database_2of2.zip -d /tmp
fi


sed -e '{s/{{\([^{]*\)}}/${\1}/g; s/^/echo "/; s/$/";/}' -e e ./response/db_install.rsp.template > /home/oracle/db_install.rsp
sudo -u oracle bash << INSTALLSW
    . /home/oracle/.bashrc
    echo y | /tmp/database/runInstaller -silent -force -ignorePrereq -waitforcompletion -debug -logLevel finest DECLINE_SECURITY_UPDATES=true SECURITY_UPDATES_VIA_MYORACLESUPPORT=false -responseFile /home/oracle/db_install.rsp 3>&1 | cat
INSTALLSW

yes | cp ./response/db_netca.rsp.template /home/oracle/db_netca.rsp
sudo -u oracle bash << INSTALLLISTENER
    . /home/oracle/.bashrc
    export DISPLAY=localhost:0.0
    echo y | ${ORACLE_HOME}/bin/netca -silent -responsefile /home/oracle/db_netca.rsp 3>&1 | cat
INSTALLLISTENER

# sed -e '{s/{{\([^{]*\)}}/${\1}/g; s/^/echo "/; s/$/";/}' -e e ./response/dbca.rsp.template > /home/oracle/dbca.rsp
# sudo -u oracle bash << INSTALLDB
#     . /home/oracle/.bashrc
#     echo y | ${ORACLE_HOME}/bin/dbca -silent -responsefile /home/oracle/dbca.rsp 3>&1 | cat
# INSTALLDB

# enable property requiretty (default value)
cp /etc/sudoers.bak /etc/sudoers

# Auto Start and Stop for Oracle
echo $ORACLE_SID:$ORACLE_HOME:Y > /etc/oratab
cp ./conf/oracle_starter.sh /etc/rc.d/init.d/oracle
chmod 755 /etc/rc.d/init.d/oracle
chkconfig --add oracle
chkconfig oracle on
set +x
