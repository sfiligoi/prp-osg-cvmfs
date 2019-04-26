FROM opensciencegrid/software-base:fresh

RUN yum -y install osg-oasis \
                   redhat-lsb-core

RUN yum -y install nfs-utils

RUN yum clean all

ADD cvmfs.autofs /etc/auto.master.d/cvmfs.autofs
ADD supervisor_autofs.conf /etc/supervisord.d/

#ADD cron.d/fetch-crl.cron /etc/cron.d/fetch-crl.cron

