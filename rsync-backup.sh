#!/bin/bash

if [[ $UID -ne 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#Check for correct input
ORIG_PATH=$1
DEST_PATH=$2

for var in {ORIG_PATH,DEST_PATH}
do
    if [ -z $$var ]
    then
	echo No $var provided.
	return 1
    fi
done

if [ ! -w $DEST_PATH ]
then
    echo $DEST_PATH does not exist or is not writable.
    return 1
fi


#Commented out are alternate lines for using backup over ssh with key authentication

#if [[ ! -e /root/.ssh/id_rsa ]]; then
#    echo Error: Could not find root private key file.
#    exit 1
#fi

#rsync -e 'ssh -i /root/.ssh/id_rsa' \
rsync \
    --one-file-system \
    --delete \
    --archive \
    --partial \
    --progress \
    --sparse \
    --human-readable \
    --numeric-ids \
    --exclude=/dev/ \
    --exclude=/proc/ \
    --exclude=/run/ \
    --exclude=/sys/ \
    $ORIG_PATH \
    $DEST_PATH
#    $DEST_HOST:$DEST_PATH
