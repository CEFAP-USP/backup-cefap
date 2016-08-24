#!/bin/bash

if [[ $UID != 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#Get timestamp in seconds from epoch format
DATE=`date +%s`

#Commit, dump and gzip routine

docker commit -m="Backing up container $CONTAINER_NAME" -a="Cron Backup Job" $CONTAINER_ID $ORGANIZATION/cron-backup-job-$IMAGE_NAME:$DATE
docker export $CONTAINER_ID | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.tar.gz

#Rotate commits and dumps routine
#Keeps the current and the last image and dump

for IMID in `docker images -q $ORGANIZATION/cron-backup-job-$IMAGE_NAME | tail -n +3`
do
    docker rmi $IMID
done

for IMTAR in `ls -t $BKPATH/cron-backup-job-$IMAGE_NAME-*.tar.gz | tail -n +3`
do
    rm -v $IMTAR
done
