#!/bin/bash
set -x

chown oracle:oinstall /home/scmsdb -R
sudo -u oracle bash << INSTALLDB
    . /home/oracle/.bashrc
    mkdir -p /opt/oracle/oradata
    mkdir -p /opt/oracle/admin/scms/adump
    mkdir -p /opt/oracle/flash_recovery_area
    ln -s /home/scmsdb/oradata/scms /opt/oracle/oradata/scms
    ln -s /home/scmsdb/flash/scms /opt/oracle/flash_recovery_area/scms
    ln -s /home/scmsdb/dbs/orapwscms /opt/oracle/product/11.2.0/dbhome_1/dbs/orapwscms
    ln -s /home/scmsdb/dbs/spfilescms.ora /opt/oracle/product/11.2.0/dbhome_1/dbs/spfilescms.ora
INSTALLDB

set +x
