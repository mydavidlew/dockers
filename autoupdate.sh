#!/bin/sh
#
sudo apt update
sudo apt list --upgradable
sudo apt --fix-broken install -y
sudo apt upgrade -y
#sudo apt-get dist-upgrade -y
#sudo apt autoremove -y
#sudo apt-get clean && sudo apt-get purge -y $(dpkg -l | grep '^rc' | awk '{print $2}')
