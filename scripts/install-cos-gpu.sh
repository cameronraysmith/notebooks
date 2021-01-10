#! /bin/bash

if [ -d "/var/lib/nvidia/lib64" ]
then
    LD_PRELOAD=/var/lib/nvidia/lib64 cos-extensions install gpu
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
else
    cos-extensions install gpu
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
fi
