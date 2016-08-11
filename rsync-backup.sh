#!/bin/bash

if [[ $UID ne 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#Commented out are lines for using backup over ssh with key authentication

#if [[ ! -e /root/.ssh/id_rsa ]]; then
#    echo Error: Could not find root private key file.
#    exit 1
#fi


rsync \
#    -e 'ssh -i /root/.ssh/id_rsa' \
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
    /. \
#    $DEST_HOST:$DEST_PATH
    $DEST_PATH
