FROM centos:centos7

RUN yum -y nfs-utils

RUN yum -y install https://repo.opensciencegrid.org/osg/3.4/osg-3.4-el7-release-latest.rpm && \
    yum -y install epel-release \
                   yum-plugin-priorities && \
    yum -y install osg-oasis \
                   redhat-lsb-core && \
    yum -y install supervisor


RUN yum clean all

#ADD cron.d/fetch-crl.cron /etc/cron.d/fetch-crl.cron

#RUN mkdir -p /var/log/supervisor
#ADD supervisord.conf /etc/supervisord.conf
#ADD supervisord.d/condor.conf /etc/supervisord.d/condor.conf

#CMD ["/usr/bin/supervisord" ,"-c" ,"/etc/supervisord.conf"]
