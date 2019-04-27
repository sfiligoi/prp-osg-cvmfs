#!/bin/bash

# Get the env variables at startup time and then hardcode them for supervisord to use
cat > /etc/supervisord.d/supervisor_csi.conf << EOF 
[program:csi]
command=/usr/sbin/csi-cvmfsplugin --nodeid=${HOSTNAME} --endpoint=${CSI_ENDPOINT} --v=5 --drivername=csi-cvmfsplugin 
autorestart=true
EOF
