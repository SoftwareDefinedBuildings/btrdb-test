#!/usr/bin/env sh

# This script installs the dependencies for BTrDB and for the load generator. It needs to be run as root.
if [ $(whoami) != "root" ]
then
    echo "Root privilege required"
    exit 1
fi

# Apt-Get Install Dependencies
apt-get -y install gcc git librados-dev
sync

# Install Go 1.6
if [ $(which go) ]
then
    echo "Go is already installed"
else
    wget https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    sync
    echo "export PATH=\$PATH:/usr/local/go/bin" >> $HOME/.profile
    sync
fi

# Install BTrDB
if [ $(which btrdbd) ]
then
    echo "BTrDB is already installed"
else
    mkdir btrdb
    export GOPATH=$(pwd)/btrdb
    go get github.com/SoftwareDefinedBuildings/btrdb/btrdbd
    export PATH=$PATH:$GOPATH/bin
    sync
    echo "export PATH=\$PATH:$GOPATH/bin" >> $HOME/.profile
    sync
fi

# Install the Load Generator
if [ $(which quasarLoadGenerator) ]
then
    echo "QuasarLoadGenerator is already installed"
else
    cd $HOME
    mkdir qlg
    export GOPATH=$(pwd)/qlg
    go get github.com/SoftwareDefinedBuildings/quasarLoadGenerator
    export PATH=$PATH:$GOPATH/bin
    sync
    echo "export PATH=\$PATH:$GOPATH/bin" >> $HOME/.profile
    sync
fi

# Mark Completion
date > INSTALLED
sync
