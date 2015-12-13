#!/bin/bash
export LC_ALL="en_US.UTF-8"
echo "##################################################"
echo "SET UP SCIDB 14 ON A DOCKER CONTAINER"
echo "##################################################"

apt-get -qq update && apt-get install --fix-missing -y --force-yes \
	apt-utils \
	build-essential \
	cmake \
	libgdal-dev \
	libproj-dev \
	gdal-bin \
	g++ \
	python-dev \
	autotools-dev \
	gfortran \
	libicu-dev \
	libbz2-dev \
	libzip-dev


#********************************************************
echo "***** Update container-user ID to match host-user ID..."
#********************************************************
export NEW_SCIDB_UID=1004
export NEW_SCIDB_GID=1004
OLD_SCIDB_UID=$(id -u scidb)
OLD_SCIDB_GID=$(id -g scidb)
usermod -u $NEW_SCIDB_UID -U scidb
groupmod -g $NEW_SCIDB_GID scidb
find / -uid $OLD_SCIDB_UID -exec chown -h $NEW_SCIDB_UID {} +
find / -gid $OLD_SCIDB_GID -exec chgrp -h $NEW_SCIDB_GID {} +
#********************************************************
echo "***** Creating local directories..."
#********************************************************
mkdir /home/scidb/data/catalog
mkdir /home/scidb/data/toLoad
chown scidb:scidb /home/scidb/data/catalog
chown scidb:scidb /home/scidb/data/toLoad
#********************************************************
echo "***** Moving PostGres files..."
#********************************************************
/etc/init.d/postgresql stop
cp -aR /var/lib/postgresql/8.4/main /home/scidb/data/catalog/main
rm -rf /var/lib/postgresql/8.4/main
ln -s /home/scidb/data/catalog/main /var/lib/postgresql/8.4/main
/etc/init.d/postgresql start
#********************************************************
echo "***** Setting up passwordless SSH..."
#********************************************************
yes | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
sshpass -f /home/scidb/pass.txt ssh-copy-id "root@localhost"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "root@0.0.0.0"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "root@127.0.0.1"
su scidb <<'EOF'
cd ~
yes | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
sshpass -f /home/scidb/pass.txt ssh-copy-id "scidb@localhost"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "scidb@0.0.0.0"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "scidb@127.0.0.1"
EOF
#********************************************************
echo "***** Installing SciDB..."
#********************************************************
cd ~
wget -O- https://downloads.paradigm4.com/key | sudo apt-key add -
cat  /etc/apt/sources.list.d/scidb.list
echo "deb https://downloads.paradigm4.com/ ubuntu12.04/14.12/" >> /etc/apt/sources.list.d/scidb.list
echo "deb-src https://downloads.paradigm4.com/ ubuntu12.04/14.12/">> /etc/apt/sources.list.d/scidb.list
apt-get update
apt-cache search scidb
yes | apt-get install scidb-14.12-all-coord # On the coordinator server only
#yes | apt-get install scidb-14.12-all # On all servers other than the coordinator server
/etc/init.d/postgresql restart
/etc/init.d/postgresql status
cp /home/scidb/scidb_docker.ini /opt/scidb/14.12/etc/config.ini
cd /tmp && sudo -u postgres /opt/scidb/14.12/bin/scidb.py init_syscat sdb_doc_sstbfast
#********************************************************
echo "***** Installing additional stuff..."
#********************************************************
cd ~
yes | /root/./installR.sh


Rscript /home/scidb/installPackages.R packages=spdep,bfast,forecast,sandwich,scidb,Rserve verbose=0 quiet=0
git clone https://github.com/mengluchu/strucchange.git
git clone https://github.com/mengluchu/bfast2.git
R CMD INSTALL strucchange/
R CMD INSTALL bfast2/


yes | /root/./installParallel.sh
yes | /root/./installBoost_1570.sh
yes | /root/./installGribModis2SciDB.sh
ldconfig
cp /root/libr_exec.so /opt/scidb/14.12/lib/scidb/plugins
#********************************************************
echo "***** Starting RSERVE..."
#********************************************************
R CMD Rserve
#********************************************************
echo "***** Installing SHIM..."
#********************************************************
cd ~
wget http://paradigm4.github.io/shim/ubuntu_12.04_shim_14.12_amd64.deb
yes | gdebi -q ubuntu_12.04_shim_14.12_amd64.deb
rm /var/lib/shim/conf
mv /root/conf /var/lib/shim/conf
rm ubuntu_12.04_shim_14.12_amd64.deb
/etc/init.d/shimsvc stop
/etc/init.d/shimsvc start
#----------------
#sudo su scidb
su scidb <<'EOF'
cd ~
#********************************************************
echo "***** ***** Environment variables for user scidb..."
#********************************************************
/home/scidb/./setEnvironment.sh
source ~/.bashrc
#********************************************************
echo "***** ***** Starting SciDB..."
#********************************************************
cd ~
/home/scidb/./startScidb.sh
sed -i -e 's/yes/#yes/g' /home/scidb/startScidb.sh
#********************************************************
echo "***** ***** Testing installation using IQuery..."
#********************************************************
iquery -naq "store(build(<num:double>[x=0:4,1,0, y=0:6,1,0], random()),TEST_ARRAY);"
iquery -aq "list('arrays');"
iquery -aq "scan(TEST_ARRAY);"
iquery -aq "load_library('r_exec');"
iquery -aq "r_exec(build(<z:double>[i=1:100,10,0],0),'expr=x<-runif(1000);y<-runif(1000);list(sum(x^2+y^2<1)/250)');"
#********************************************************
echo "***** ***** Downloading MODIS data..."
#********************************************************
cd ~
./downloaddata.sh
#********************************************************
echo "***** ***** Downloading required scripts..."
#********************************************************
git clone http://github.com/albhasan/modis2scidb.git
#********************************************************
echo "***** ***** Creating arrays..."
#********************************************************
iquery -af /home/scidb/createArray.afl
#********************************************************
echo "***** ***** Loading data to arrays..."
#********************************************************
mkdir /home/scidb/toLoad/
python /home/scidb/modis2scidb/checkFolder.py --log DEBUG /home/scidb/toLoad/ /home/scidb/modis2scidb/ MOD09Q1 MOD09Q1 &
find /home/scidb/e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/ -type f -name '*h12v10**.hdf' -print | parallel -j +0 --no-notice --xapply python /home/scidb/modis2scidb/hdf2sdbbin.py --log DEBUG {} /home/scidb/toLoad/ MOD09Q1
#********************************************************
echo "***** ***** Waiting to finish uploading files to SciDB..."
#********************************************************
COUNTER=$(find /home/scidb/toLoad/ -type f -name '*.sdbbin' -print | wc -l)
while [  $COUNTER -gt 0 ]; do
	echo "Waiting to finish uploading files to SciDB. Files to go... $COUNTER"
	sleep 60
	let COUNTER=$(find /home/scidb/toLoad/ -type f -name '*.sdbbin' -print | wc -l)
done
#********************************************************
echo "***** ***** Removing array versions..."
#********************************************************
/home/scidb/./removeArrayVersions.sh MOD09Q1
#********************************************************
echo "***** ***** Executing BFAST..."
#********************************************************
# Subset just Juara
iquery -naq "store(between(MOD09Q1, 58828, 48103, 0, 59679, 49050, 9200), MOD09Q1_JUARA);"
# Redimension
# iquery -naq "store(repart(MOD09Q1_JUARA, <red:int16,nir:int16,quality:uint16> [col_id=57600:62399,502,5,row_id=48000:52799,502,5,time_id=0:9200,1,0]),  MOD09Q1_repart);"





Rscript rexec_sar_efp_f.R
Rscript reprosarefp.R





rm /home/scidb/pass.txt
EOF
#----------------
#********************************************************
echo "***** SciDB setup finished sucessfully!"
#********************************************************
