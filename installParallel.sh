#!/bin/bash
mkdir ~/install_parallel
cd ~/install_parallel
wget http://ftp.gnu.org/gnu/parallel/parallel-20140922.tar.bz2 
tar -xvjf parallel*
cd parallel*
#less README
./configure
make
sudo make install
cd ~
