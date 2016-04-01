#!/usr/bin/env sh

# This script installs the dependencies for BTrDB and for the load generator. It needs to be run as root.

# -c means to install Ceph.
# -n means to install NTP ONLY.

if [ $(whoami) != "root" ]
then
    echo "Root privilege required"
    exit 1
fi

# Get a valid IP address of this node that is not link-local
ipaddr=$(hostname -I | cut -d ' ' -f 1)

trueuser=$(who am i | cut -d ' ' -f 1)

# Make sure every node can ssh into every other node without asking for user input
mkdir -p .ssh
cp assets/key .ssh/id_rsa
cp assets/key.pub .ssh/id_rsa.pub
chown $trueuser:$trueuser .ssh/id_rsa
chown $trueuser:$trueuser .ssh/id_rsa.pub

authorized=$(grep "$(cat assets/key.pub)" .ssh/authorized_keys)
if [ -z $(ls .ssh/authorized_keys) ] || [ -z "$authorized" ]
then
    cat assets/key.pub >> .ssh/authorized_keys
    chown $trueuser:$trueuser .ssh/authorized_keys
    chmod 600 .ssh/authorized_keys
fi
nohostcheck="Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null"
if [ "$(tail -n 3 /etc/ssh/ssh_config)" != "$nohostcheck" ]
then
    echo "$nohostcheck" >> /etc/ssh/ssh_config
fi

mkdir -p installed

# Install NTP Only
if [! -z $1] && [ $1 = "-n" ]
then
    apt-get install ntp
    service ntp restart
    exit
fi

# Apt-Get Install Dependencies
apt-get -y install gcc git librados-dev mongodb
sync

# Install Go 1.6
if [ $(ls installed | grep go-installed) ]
then
    echo "Go is already installed"
else
    wget https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    sed -i "4iexport PATH=\$PATH:/usr/local/go/bin" $HOME/.bashrc
    sync
    date > installed/go-installed
    sync
fi

# Install BTrDB
if [ $(ls installed | grep btrdb-installed) ]
then
    echo "BTrDB is already installed"
else
    mkdir -p btrdb
    export GOPATH=$(pwd)/btrdb
    go get github.com/SoftwareDefinedBuildings/btrdb/btrdbd
    export PATH=$PATH:$GOPATH/bin
    sed -i "4iexport PATH=\$PATH:$GOPATH/bin" $HOME/.bashrc
    sync
    date > installed/btrdb-installed
    sync
fi

# Install the Load Generator
if [ $(ls installed | grep qlg-installed) ]
then
    echo "QuasarLoadGenerator is already installed"
else
    cd $HOME
    mkdir qlg
    export GOPATH=$(pwd)/qlg
    go get github.com/SoftwareDefinedBuildings/quasarLoadGenerator
    export PATH=$PATH:$GOPATH/bin
    sed -i "4iexport PATH=\$PATH:$GOPATH/bin" $HOME/.bashrc
    mkdir qlgoutput # Output of the load generator will go here
    sync
    date > installed/qlg-installed
    sync
fi

# Install Ceph
if [ -z $1 ] || [ $1 != "-c" ]
then
    echo "Skipping installation of Ceph"
elif [ $(ls installed | grep ceph-installed) ]
then
    echo "Ceph is already installed"
    service ntp restart
else
    wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
    echo deb http://download.ceph.com/debian-hammer/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list
    apt-get update
    apt-get -y install ceph-deploy ntp
    service ntp restart
    
    echo "$ipaddr $(hostname)" >> /etc/hosts
    
    # We'll just use the current user for deploying Ceph
    
    sync
    date > installed/ceph-installed
    sync
fi

# Mark Completion
date > installed/all-installed
sync
