#!/usr/bin/env sh

# This script installs the dependencies for BTrDB and for the load generator. It needs to be run as root.
if [ $(whoami) != "root" ]
then
    echo "Root privilege required"
    exit 1
fi

mkdir -p installed

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

# Mark Completion
date > installed/all-installed
sync
