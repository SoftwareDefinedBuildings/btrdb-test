#!/usr/bin/env sh

# This script sets up Ceph from the admin node.
# It assumes that the appropriate hostnames are added to /etc/hosts already.
# This script need not be run as root!

# The first argument is the names of the drives to use as OSDs.

hostnames=$(cat assets/hostfile | cut -d " " -f 2)
selfnode=$(hostname)
user=$(whoami)

mkdir -p ceph-cluster
cd ceph-cluster
ceph-deploy purge $hostnames
ceph-deploy purgedata $hostnames
ceph-deploy forgetkeys
sleep 10
echo new
ceph-deploy new $hostnames
echo "osd pool default size = $(wc -l ../assets/hostfile | cut -d ' ' -f 1)" >> ceph.conf
#chown -R $user:$user .
echo install
ceph-deploy install $hostnames
ceph-deploy mon create-initial
sleep 10
ceph-deploy gatherkeys $hostnames
#sudo rm -rf ../cephdb
#sudo mkdir ../cephdb
#sudo chown ceph:ceph ../cephdb
echo osd prepare
for node in $hostnames
do
    for diskletter in $1
    do
        diskid=xvd$diskletter
        ceph-deploy disk zap $node:$diskid
        ceph-deploy osd create $node:$diskid
    done
done
ceph-deploy admin $hostnames
sudo chmod +r /etc/ceph/ceph.client.admin.keyring
cd ..
