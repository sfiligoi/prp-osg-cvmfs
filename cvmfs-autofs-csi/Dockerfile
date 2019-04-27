FROM sfiligoi/prp-osg-cvmfs:cvmfs-autofs

ENV CSI_ENDPOINT unix://var/lib/kubelet/plugins/csi-cvmfsplugin/csi.sock

ADD bin/csi-cvmfsplugin /usr/sbin/csi-cvmfsplugin
ADD supervisor_csi.conf /etc/supervisord.d/

