#!/bin/bash

if [[ $UID -ne 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#Check for correct input
CONTAINER_ID=$1
ORGANIZATION=$2
IMAGE_NAME=$3
BKPATH=$4

for var in {CONTAINER_ID,ORGANIZATION,IMAGE_NAME,BKPATH}
do
    if [ -z $$var ]
    then
	echo No $var provided.
	return 1
    fi
done

if [ ! -w $BKPATH ]
then
    echo $BKPATH does not exist or is not writable.
    return 1
fi

#Get timestamp in seconds from epoch format
DATE=`date +%s`

#Commit, dump and gzip routine

echo Commiting container $CONTAINER_NAME
docker commit -m="Backing up container $CONTAINER_NAME" -a="Cron Backup Job" $CONTAINER_ID $ORGANIZATION/cron-backup-job-$IMAGE_NAME:$DATE
echo Saving container $CONTAINER_NAME
docker save $ORGANIZATION/cron-backup-job-$IMAGE_NAME:$DATE | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.tar.gz
echo Dumping all psql on container $CONTAINER_NAME
docker exec $CONTAINER_ID pg_dumpall --username=postgres | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.psql.gz

#Rotate commits, saves and dumps
#Keeps the current and the last

echo Rotating commits, saves and dumps
for IMID in `docker images -q $ORGANIZATION/cron-backup-job-$IMAGE_NAME | tail -n +3`
do
    docker rmi $IMID
done

for IMTAR in `ls -t $BKPATH/cron-backup-job-$IMAGE_NAME-*.tar.gz | tail -n +3`
do
    rm -v $IMTAR
done

for DPSQL in `ls -t $BKPATH/cron-backup-job-$IMAGE_NAME-*.psql.gz | tail -n +3`
do
    rm -v $DPSQL
done
