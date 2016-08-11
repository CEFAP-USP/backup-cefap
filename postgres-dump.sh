#!/bin/bash

if [[ $UID ne 0 ]]; then
    echo Error: This script is meant to be run as root.
    exit 1
fi

#PosgreSQL dump all and gzip backup routine
#Have to use a .pgpass file for login

pg_dumpall \
    --host=$PGHOST \
    --port=$PGPORT \
    --username=$PGUSER \
    --no-password \
    | gzip \
	  > $BKPATH/posgresql-dumpall-`date -I`.sql.gz
