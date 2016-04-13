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

trueuser=$(who | cut -d ' ' -f 1)
if [ -z $trueuser ]
then
    trueuser="ubuntu"
fi

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
service mongodb start

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
if [ $(ls installed | grep loadgen-installed) ]
then
    echo "Load Generator is already installed"
else
    cd $HOME
    mkdir -p loadgen
    export GOPATH=$(pwd)/loadgen
    go get github.com/SoftwareDefinedBuildings/btrdb-test/loadgen
    export PATH=$PATH:$GOPATH/bin
    sed -i "4iexport PATH=\$PATH:$GOPATH/bin" $HOME/.bashrc
    mkdir -p loadgen-output # Output of the load generator will go here
    chown $trueuser:$trueuser loadgen-output
    sync
    date > installed/loadgen-installed
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
    
    node=$(hostname)
    rm -rf ceph-cluster
    su $trueuser -c "
    mkdir -p ceph-cluster
    cd ceph-cluster
    ceph-deploy purge $node
    ceph-deploy purgedata $node
    ceph-deploy forgetkeys
    sleep 10
    echo new
    ceph-deploy new $node
    echo \"osd pool default size = 1\" >> ceph.conf
    chown -R $trueuser:$trueuser .
    echo install
    ceph-deploy install $node
    ceph-deploy mon create-initial
    sleep 10
    ceph-deploy gatherkeys $node
    sudo rm -rf ../cephdb
    sudo mkdir ../cephdb
    sudo chown ceph:ceph ../cephdb
    echo osd prepare
    ceph-deploy osd prepare $node:/home/$trueuser/cephdb
    echo osd activate
    ceph-deploy osd activate $node:/home/$trueuser/cephdb
    ceph-deploy admin $node
    cd ..
    "
    chown -R $trueuser:$trueuser /etc/ceph
    ls -l /etc/ceph
    sync
    date > installed/ceph-installed
    sync
fi
echo True user
echo $trueuser

# Mark Completion
date > installed/all-installed
sync
