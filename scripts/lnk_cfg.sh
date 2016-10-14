#!/bin/bash
set -x

chown oracle:oinstall /home/scmsdb -R
sudo -u oracle bash << INSTALLDB
    . /home/oracle/.bashrc
    yes | cp /home/scmsdb/network/tnsnames.ora /opt/oracle/product/11.2.0/dbhome_1/network/admin/
    yes | cp /home/scmsdb/network/listener.ora /opt/oracle/product/11.2.0/tg_1/network/admin/
    yes | cp /home/scmsdb/network/init* /opt/oracle/product/11.2.0/tg_1/dg4msql/admin/
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
