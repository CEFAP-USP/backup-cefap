#!/bin/bash

if [[ $UID ne 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#Commit, dump and gzip routine

docker commit -m="Backing up container $CONTAINER_NAME" -a="Cron Backup Job" $CONTAINER_ID $ORGANIZATION/cron-backup-job-$IMAGE_NAME:`date -I`
docker export $CONTAINER_ID | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-`date -I`.tar.gz

#Rotate commits and dumps routine

$NUM_IMAGES=`docker images | grep $ORGANIZATION/cron-backup-job-$IMAGE_NAME  | wc -l`
$NUM_TARBALLS=`ls $BKPATH/cron-backup-job-$IMAGE_NAME-*.tar.gz | wc -l`

if [[ $NUM_IMAGES > 2 ]]
do
    for IMID in (docker images -q $ORGANIZATION/cron-backup-job-$IMAGE_NAME | head -n $(($NUM_IMAGES-2)))
    do
	docker rmi $IMID
    done
fi

if [[ $NUM_TARBALLS > 2 ]]
do
    for IMTAR in (ls $BKPATH/cron-backup-job-$IMAGE_NAME-*.tar.gz | head -n $(($NUM_TARBALLS-2)))
    do
	rm -v $IMTAR
    done
fi
