# oracle-centos
A Dockerfile that produces a Docker Image for oracle on centos7.

Envionment variables:
```
ENV ORACLE_SID scms
ENV ORACLE_GDBN scms.act
ENV ORACLE_BASE /opt/oracle
ENV ORACLE_HOME /opt/oracle/product/11.2.0/dbhome_1
ENV GATEWAYS_HOME /opt/oracle/product/11.2.0/tg_1
ENV ORACLE_DATA /opt/oracle
ENV ORACLE_PASS scmspass
ENV ORACLE_LINK /home/scmsdb
ENV ORACLE_EXPDIR /home/scmsdb
ENV ORACLE_BAKFTP /mnt/backup
```
