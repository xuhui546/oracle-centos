FROM centos:7.2.1511

MAINTAINER Xu Hui <xuhui546@hotmail.com>

ENV LANG=en_US.UTF-8
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

RUN yum install -y binutils compat-libstdc++-33; yum clean all
RUN yum install -y libstdc++ libstdc++-devel; yum clean all
RUN yum install -y elfutils-libelf elfutils-libelf-devel; yum clean all
RUN yum install -y gcc gcc-c++ libgcc; yum clean all
RUN yum install -y glibc glibc-common glibc-devel; yum clean all
RUN yum install -y libaio libaio-devel; yum clean all
RUN yum install -y unixODBC unixODBC-devel; yum clean all
RUN yum install -y make numactl sysstat libXp; yum clean all
RUN yum install -y epel-release 
RUN yum install -y unzip bzip2 sudo curlftpfs; yum clean all

RUN mv /etc/localtime /etc/localtime.bak
RUN ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN chmod +x /etc/rc.d/rc.local

COPY ./scripts /root/scripts

CMD /bin/bash -c "cat /root/scripts/oracle.rc.local > /etc/rc.d/rc.local; /etc/rc.local"
