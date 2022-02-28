#!/bin/bash

if [ "x${SQUID_URI}" == "x" ]; then
  echo "Missing SQUID_URI" 1>&2
  exit 1
fi
echo "CVMFS_HTTP_PROXY=\"${SQUID_URI}\"" >/etc/cvmfs/default.local
echo "CVMFS_MAX_RETRIES=10" >> /etc/cvmfs/default.local
echo "CVMFS_TIMEOUT=15" >> /etc/cvmfs/default.local
echo "CVMFS_TIMEOUT_DIRECT=15" >> /etc/cvmfs/default.local

if [ "x${QUOTA_LIMIT}" != "x" ]; then
  echo "CVMFS_QUOTA_LIMIT=${QUOTA_LIMIT}" >> /etc/cvmfs/default.local
fi


if [ "x${MOUNT_REPOS}" == "x" ]; then
  echo "ERROR: `date` Missing MOUNT_REPOS" 1>&2
  exit 1
fi

if [ "x${DEP_REPOS}" != "x" ]; then
  for d in `echo ${DEP_REPOS} |tr , ' '` ; do
    if [ ! -d "/cvmfs/${d}" ]; then
      echo "INFO: `date` Not yet ready /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 1
    fi
    if [ ! -d "/cvmfs/${d}" ]; then
      echo "INFO: `date` Not yet ready /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 2
    fi
    if [ ! -d "/cvmfs/${d}" ]; then
      echo "INFO: `date` Not yet ready /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 5
    fi
    if [ ! -d "/cvmfs/${d}" ]; then
      echo "ERROR: `date` Not yet ready /cvmfs/${d}. Aborting." | tee -a /cvmfs/cvmfs-pod.log
      exit 1
    fi
    if [ "`ls /cvmfs/${d} |wc -l`" -lt 2 ]; then
      echo "INFO: `date` Still empty /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 1
    fi
    if [ "`ls /cvmfs/${d} |wc -l`" -lt 2 ]; then
      echo "INFO: `date` Still empty /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 2
    fi
    if [ "`ls /cvmfs/${d} |wc -l`" -lt 2 ]; then
      echo "INFO: `date` Still empty /cvmfs/${d}. Waiting." | tee -a /cvmfs/cvmfs-pod.log
      sleep 5
    fi
    if [ "`ls /cvmfs/${d} |wc -l`" -lt 2 ]; then
      echo "ERROR: `date` Still empty /cvmfs/${d}. Aborting." | tee -a /cvmfs/cvmfs-pod.log
      exit 1
    fi
    echo "INFO: `date` Dependency ready: /cvmfs/${d}." | tee -a /cvmfs/cvmfs-pod.log
  done
fi

# do not die on signal, try to cleanup as fast as you can
trap "/usr/local/sbin/force_unmount.sh" SIGTERM SIGINT

mps=""
for mp in `echo ${MOUNT_REPOS} |tr , ' '` ; do 
 echo "INFO: `date` `date` Processing /cvmfs/${mp}." | tee -a /cvmfs/cvmfs-pod.log

 mkdir -p /cvmfs/${mp}
 rc=$?
 if [ ${rc} -ne 0 ]; then
   echo "INFO: `date` Removing existing /cvmfs/${mp}." | tee -a /cvmfs/cvmfs-pod.log
   rmdir /cvmfs/${mp}
   # no error checking ... if it failed, we will catch below
   mkdir -p /cvmfs/${mp}
   rc=$?
 fi

 if [ ${rc} -ne 0 ]; then
   # force clean if already there
   echo "WARNING: `date` Found /cvmfs/${mp}. Unmounting." | tee -a /cvmfs/cvmfs-pod.log
   umount /cvmfs/${mp}
   rc=$?
   if [ $rc -ne 0 ]; then
     echo "WARNING: `date` Using lazy umount for /cvmfs/${mp}" | tee -a /cvmfs/cvmfs-pod.log
     umount -l /cvmfs/${mp}
     sleep 5 # give time for the system to catch up
   fi
   rmdir /cvmfs/${mp}

   mkdir -p /cvmfs/${mp}
   rc=$?
 fi

 # try without checking rc... will fail if mkdir failed
 echo "INFO: Mounting /cvmfs/${mp}." | tee -a /cvmfs/cvmfs-pod.log
 mount -t cvmfs ${mp} /cvmfs/${mp}
 rc=$?
 if [ ${rc} -ne 0 ] ; then
   echo "WARNING: `date` Failed to mount $mp, retrying"  | tee -a /cvmfs/cvmfs-pod.log
   sleep 15
   mkdir -p /cvmfs/${mp}
   mount -t cvmfs ${mp} /cvmfs/${mp}
   rc=$?
 fi

 if [ ${rc} -eq 0 ] ; then
   echo "INFO: `date` Mounted /cvmfs/${mp}" | tee -a /cvmfs/cvmfs-pod.log
   # apart from info, this also warms up the mount
   echo "INFO: N. Files: `ls /cvmfs/${mp} |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
   echo "INFO: N. etc Files: `find /cvmfs/${mp}/etc 2>/dev/null |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
   mps="$mp $mps" #save them in reverse order
 else
   echo "ERROR: `date` Failed to mount $mp"  | tee -a /cvmfs/cvmfs-pod.log

   # cleanup
   for mp1 in $mps; do
     umount /cvmfs/${mp1}
   done
   exit 2
 fi
done

echo "$mps" > /etc/mount-and-wait.mps

echo "INFO: `date` CVMFS mountpoints started: $mps"  | tee -a /cvmfs/cvmfs-pod.log
/usr/local/sbin/wait-only.sh
echo "INFO: `date` Terminating"   | tee -a /cvmfs/cvmfs-pod.log

# cleanup

# first try the proper way
for mp1 in $mps; do
   if [ -d /cvmfs/${mp1} ]; then
     umount /cvmfs/${mp1}
     rc=$?
     if [ $rc -ne 0 ]; then
       echo "WARNING: `date` Failed unmounting ${mp1}"  | tee -a /cvmfs/cvmfs-pod.log
     else
       rmdir /cvmfs/${mp1}
       echo "INFO: `date` Unmounted ${mp1}"  | tee -a /cvmfs/cvmfs-pod.log
     fi
   fi
done

# now do a pass with the most fail-safe option possible
for mp1 in $mps; do
   if [ -d /cvmfs/${mp1} ]; then
     echo "INFO: `date` Attempting lazy umount of ${mp1}"  | tee -a /cvmfs/cvmfs-pod.log
     umount -l /cvmfs/${mp1}
     if [ $? -eq 0 ]; then
       echo "INFO: `date` Lazy unmounted ${mp1}"  | tee -a /cvmfs/cvmfs-pod.log
     fi
     # try to remove mount dir no matter what, to minimize chance of PVC mounting an inactive dir
     rmdir /cvmfs/${mp1}
   fi
done

# wait a tiny bit to make sure everything is cleaned up properly
sleep 2

echo "INFO: `date` Bye"  | tee -a /cvmfs/cvmfs-pod.log

