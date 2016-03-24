#!/usr/bin/env sh

# This script starts or stops BTrDB.
# -f means to start from a fresh database. -q means to stop the BTrDB without starting a new one.
# This need NOT be run as root.

# Kill the database if it's running
screen -X -S btrdb quit

if [ -z $1 ] || [ $1 != "-q" ]
then
    if [ ! -z $1 ] && [ $1 = "-f" ]
    then
        # Delete database if it exists
        rm -rf $HOME/db
        mkdir -p $HOME/db
        mongo btrdb --eval "db.dropDatabase();"
        
        # Create a new database
        btrdbd -makedb
    fi

    # Start BTrDB
    screen -d -m -S btrdb btrdbd
fi
