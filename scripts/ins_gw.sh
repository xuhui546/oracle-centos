#!/bin/bash
set -x

if [[ ! -r "/tmp/gateways" ]]; then
    unzip /root/soft/linux.x64_11gR2_gateways.zip -d /tmp
fi
chown -R oracle:oinstall /tmp/gateways

sed -e '{s/{{\([^{]*\)}}/${\1}/g; s/^/echo "/; s/$/";/}' -e e ./response/tg.rsp.template > /home/oracle/tg.rsp
sudo -u oracle bash << INSTALLSW
    . /home/oracle/.bashrc
    echo y | /tmp/gateways/runInstaller -silent -noconfig -responseFile /home/oracle/tg.rsp 3>&1 | cat
INSTALLSW

yes | cp ./response/gw_netca.rsp.template /home/oracle/gw_netca.rsp
sudo -u oracle bash << INSTALLLISTENER
    . /home/oracle/.bashrc
    export DISPLAY=localhost:0.0
    echo y | ${GATEWAYS_HOME}/bin/netca -silent -responsefile /home/oracle/gw_netca.rsp 3>&1 | cat
INSTALLLISTENER

# enable property requiretty (default value)
cp /etc/sudoers.bak /etc/sudoers

# Auto Start and Stop for Oracle
echo $ORACLE_SID:$ORACLE_HOME:Y > /etc/oratab
cp ./conf/oracle_starter.sh /etc/rc.d/init.d/oracle
chmod 755 /etc/rc.d/init.d/oracle
chkconfig --add oracle
chkconfig oracle on
set +x
