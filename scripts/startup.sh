#!/bin/sh
#
# [manual] startup script 
# > ./startup.sh
#
# https://cloud.google.com/compute/docs/startupscript#startupscriptrunninginstances
# startup-script: supply the startup script contents directly by using this key.
# startup-script-url: supply a Cloud Storage URL to the start script file by using this key.
#
# > HOME=/home/jovyan /home/jovyan/scripts/startup.sh
#
# PACKAGES to install at startup

## Arch packages
sudo pacman -Syu --needed --noconfirm - < $HOME/etc/pkglist-startup.txt
sudo pacman -Scc --noconfirm

## Python packages
# pip install --user -r $HOME/etc/python-libraries.txt

## AUR packages
# yay -S --needed --noconfirm - < $HOME/etc/pkglist-yay.txt
