#!/bin/bash
#echo "##################################################"
#echo "SET SCIDB ENVIRONMENTAL VARIABLES TO bashrc"
#echo "##################################################"
echo "#***** ***** SCIDB" >> ~/.bashrc
echo "export SCIDB_VER=14.12" >> ~/.bashrc
echo "export PATH=$PATH:/opt/scidb/14.12/bin:/opt/scidb/14.12/share/scidb" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/scidb/14.12/lib" >> ~/.bashrc
