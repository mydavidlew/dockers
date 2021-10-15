#!/bin/sh
#
sudo apt update
sudo apt list --upgradable
sudo apt --fix-broken install -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
