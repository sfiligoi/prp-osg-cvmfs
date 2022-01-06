#!/bin/bash

#
# We use a separate bash script to get a clean exit signal (here, not in parent)
#

echo "$$" > /etc/mount-and-wait.pid

echo "Checking and Sleeping"

mps=`cat /etc/mount-and-wait.mps`
checki=0
while [ 1 -lt 2 ]; do 
  # loop forever

  # make sure all the mountpoins are still alive; if not, remount
  for mp1 in $mps; do
    if [ ! -f /dev/shm/unmounting.lck ]; then
      mntd=`df -k /cvmfs/${mp1} |tail -1 |grep cvmfs2`
      if [ "x${mntd}" == "x" ]; then
        echo "INFO: `date` Found /cvmfs/${mp1} unmounted, retrying" | tee -a /cvmfs/cvmfs-pod.log
        sleep 2
        mntd=`df -k /cvmfs/${mp1} |tail -1 |grep cvmfs2`
      fi

      if [ "x${mntd}" == "x" ]; then
        echo "WARNING: `date` Found /cvmfs/${mp1} unmounted." | tee -a /cvmfs/cvmfs-pod.log
        mount -t cvmfs ${mp1} /cvmfs/${mp1}
        rc=$?
        if [ $rc -eq 0 ]; then
          echo "INFO: `date` Mounted /cvmfs/${mp1}" | tee -a /cvmfs/cvmfs-pod.log
          # apart from info, this also warms up the mount
          echo "INFO: N. Files: `ls /cvmfs/${mp1} |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
          echo "INFO: N. etc Files: `find /cvmfs/${mp1}/etc 2>/dev/null |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
        else
           echo "WARNING: `date` Failed to mount /cvmfs/${mp1}, killing cvmfs daemon" | tee -a /cvmfs/cvmfs-pod.log
           ps -ef |grep /cvmfs/${mp1} |grep cvmfs2 | awk '{print $2}' |xargs kill
           sleep 2
           mount -t cvmfs ${mp1} /cvmfs/${mp1}
           rc=$?
           if [ $rc -eq 0 ]; then
             echo "INFO: `date` Mounted /cvmfs/${mp1}" | tee -a /cvmfs/cvmfs-pod.log
             # apart from info, this also warms up the mount
             echo "INFO: N. Files: `ls /cvmfs/${mp1} |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
             echo "INFO: N. etc Files: `find /cvmfs/${mp1}/etc 2>/dev/null |wc -l`" | tee -a /cvmfs/cvmfs-pod.log
           else
              echo "WARNING: `date` Failed to mount /cvmfs/${mp1}, unknown error" | tee -a /cvmfs/cvmfs-pod.log
           fi
        fi
      elif [ ${checki} -eq 0 ]; then
        nerr=`/usr/bin/attr -q -g nioerr /cvmfs/${mp1}`
        rc=$?
        if [ $rc -eq 0 ]; then
          if [ "x${nerr}" != "x0" ]; then
            echo "WARNING: `date` Found nioerr=${nerr} for /cvmfs/${mp1}" | tee -a /cvmfs/cvmfs-pod.log
            cvmfs_talk -i "${mp1}" reset error counters
          fi
        else
          echo "WARNING: `date` Failed to get nioerr for /cvmfs/${mp1}" | tee -a /cvmfs/cvmfs-pod.log
        fi
      fi
    fi

  done

  if [ ${checki} -eq 0 ]; then
    # check about once per hour
    let checki=100
  else
    let checki=${checki}-1
  fi

  sleep 30
done

