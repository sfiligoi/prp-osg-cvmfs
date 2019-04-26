FROM opensciencegrid/software-base:fresh

RUN yum -y install osg-oasis \
                   redhat-lsb-core

RUN yum -y install nfs-utils

RUN yum clean all

# Default cvmfs disk limit, can be changes by instances
ENV  CVMFS_QUOTA_LIMIT 20000

ADD cvmfs.autofs /etc/auto.master.d/cvmfs.autofs
ADD supervisor_autofs.conf /etc/supervisord.d/

# Expects the frontier env to be set
#   FRONTIER_SQUID_SERVICE_HOST and FRONTIER_SQUID_SERVICE_PORT
# There are no defualts
ADD cvmfs_frontier_setup.sh /etc/osg/image-config.d/90_cvmfs_frontier_setup.sh

#ADD cron.d/fetch-crl.cron /etc/cron.d/fetch-crl.cron

