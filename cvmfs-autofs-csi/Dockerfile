FROM sfiligoi/prp-osg-cvmfs:cvmfs-autofs

ENV CSI_ENDPOINT unix://var/lib/kubelet/plugins/csi-cvmfsplugin/csi.sock

ADD bin/csi-cvmfsplugin /usr/sbin/csi-cvmfsplugin
ADD create_supervisor_csi_conf.sh /etc/osg/image-config.d/99_create_supervisor_csi_conf.sh

