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
        if [ ! -z $2 ] && [ $2 = "-c" ]
        then
            node=$(hostname)
            mkdir -p ceph-cluster
            cd ceph-cluster
            ceph-deploy purge $node
            ceph-deploy purgedata $node
            ceph-deploy forgetkeys
            ceph-deploy new $node
            echo "osd pool default size = 1" >> ceph.conf
            ceph-deploy install $node
            ceph-deploy mon create-initial
            sudo rm -rf ../cephdb
            sudo mkdir ../cephdb
            sudo chown ceph:ceph ../cephdb
            ceph-deploy osd prepare $node:$(pwd)/../cephdb
            ceph-deploy osd activate $node:$(pwd)/../cephdb
            fi
        mkdir -p $HOME/db
        mongo btrdb --eval "db.dropDatabase();"
        
        # Create a new database
        btrdbd -makedb
    fi

    # Start BTrDB
    screen -d -m -S btrdb btrdbd
fi
