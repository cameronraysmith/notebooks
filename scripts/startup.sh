#!/bin/sh
#
# [manual] startup script 
# > ./startup.sh
#


# PACKAGES to install at startup

## Arch packages
pacman -Syu --needed --noconfirm - < $HOME/etc/pkglist-startup.txt
pacman -Scc --noconfirm

## Python packages
pip install -r $HOME/etc/python-libraries.txt

## AUR packages
yay -S --needed --noconfirm - < $HOME/etc/pkglist-yay.txt


# jupyter extensions

## https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter nbextension enable --user --py widgetsnbextension

## https://github.com/jupyterlab/jupyterlab-google-drive/
jupyter labextension install @jupyterlab/google-drive