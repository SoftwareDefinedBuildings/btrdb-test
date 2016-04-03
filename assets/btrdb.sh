#!/usr/bin/env sh

# This script starts or stops BTrDB.
# -f means to start from a fresh database. -q means to stop the BTrDB without starting a new one.
# This need NOT be run as root. (It will escalate privilege when it needs to.)

# Kill the database if it's running
screen -X -S btrdb quit

if [ -z $1 ] || [ $1 != "-q" ]
then
    if [ ! -z $1 ] && [ $1 = "-f" ]
    then
        # Delete database if it exists
        rm -rf $HOME/db
        ceph osd pool delete data data --yes-i-really-really-mean-it
        mongo btrdb --eval "db.dropDatabase();"
        
        mkdir -p $HOME/db
        ceph osd pool create data 128 128
        
        # Create a new database
        btrdbd -makedb
    fi

    # Start BTrDB
    screen -d -m -S btrdb btrdbd
fi
