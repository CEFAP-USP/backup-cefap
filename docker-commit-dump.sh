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

for var in {"CONTAINER_ID","ORGANIZATION","IMAGE_NAME","BKPATH"}
do
    eval testvar=\$$var
    if [ -z $testvar ]
    then
	echo No $var provided.
	exit 1
    fi
done

if [ ! -w $BKPATH ]
then
    echo $BKPATH does not exist or is not writable.
    exit 1
fi

#Get timestamp in seconds from epoch format
DATE=`date +%s`

#Commit, dump and gzip routine

echo Commiting container $CONTAINER_ID to image $IMAGE_NAME
docker commit -m="Backing up container $CONTAINER_NAME" -a="Cron Backup Job" $CONTAINER_ID $ORGANIZATION/cron-backup-job-$IMAGE_NAME:$DATE
echo Saving container $CONTAINER_ID to image $IMAGE_NAME
docker save $ORGANIZATION/cron-backup-job-$IMAGE_NAME:$DATE | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.tar.gz

#Test for PostgreSQL and dump it (service has to accept passwordless access)
echo Testing for psql
docker exec $CONTAINER_ID psql -Upostgres -l 1>/dev/null
if [ $? -eq 0 ]
then
    echo Dumping all psql on container $CONTAINER_ID to dump $IMAGE_NAME
    docker exec $CONTAINER_ID pg_dumpall --username=postgres | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.psql.gz
fi

#Test for MySQL and dump it (service has to accept passwordless access)
echo Testing for mysql
docker exec $CONTAINER_ID service mysql status 1>/dev/null
if [ $? -eq 0 ]
then
    echo Dumping all mysql on container $CONTAINER_ID to dump $IMAGE_NAME
    docker exec $CONTAINER_ID mysqldump --all-databases | gzip > $BKPATH/cron-backup-job-$IMAGE_NAME-$DATE.mysql.gz
fi

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

if ls $BKPATH/cron-backup-job-$IMAGE_NAME-*.psql.gz 1>/dev/null 2>&1
then
    for DPSQL in `ls -t $BKPATH/cron-backup-job-$IMAGE_NAME-*.psql.gz | tail -n +3`
    do
	rm -v $DPSQL
    done
fi

if ls $BKPATH/cron-backup-job-$IMAGE_NAME-*.mysql.gz 1>/dev/null 2>&1
then
    for MYSQL in `ls -t $BKPATH/cron-backup-job-$IMAGE_NAME-*.mysql.gz | tail -n +3`
    do
	rm -v $MYSQL
    done
fi
