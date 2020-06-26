#!/bin/sh
#
# [manual] startup script 
# > ./startup.sh
#


# PACKAGES to install at startup

## Arch packages
sudo pacman -Syu --needed --noconfirm - < $HOME/etc/pkglist-startup.txt
sudo pacman -Scc --noconfirm

## Python packages
pip install --user -r $HOME/etc/python-libraries.txt

## AUR packages
yay -S --needed --noconfirm - < $HOME/etc/pkglist-yay.txt
