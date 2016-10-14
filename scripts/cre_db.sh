#!/bin/bash
set -x

sed -e '{s/{{\([^{]*\)}}/${\1}/g; s/^/echo "/; s/$/";/}' -e e ./response/dbca.rsp.template > /home/oracle/dbca.rsp
sudo -u oracle bash << INSTALLDB
    . /home/oracle/.bashrc
    echo y | ${ORACLE_HOME}/bin/dbca -silent -responsefile /home/oracle/dbca.rsp 3>&1 | cat
INSTALLDB

# enable property requiretty (default value)
cp /etc/sudoers.bak /etc/sudoers

# Auto Start and Stop for Oracle
echo $ORACLE_SID:$ORACLE_HOME:Y > /etc/oratab
cp ./conf/oracle_starter.sh /etc/rc.d/init.d/oracle
chmod 755 /etc/rc.d/init.d/oracle
chkconfig --add oracle
chkconfig oracle on
set +x
