#! /bin/bash

if [ -d "/var/lib/nvidia/lib64" ]
then
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
    LD_PRELOAD=/var/lib/nvidia/lib64 cos-extensions install gpu
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
    LD_LIBRARY_PATH=/var/lib/nvidia/lib64 /var/lib/nvidia/bin/nvidia-smi
else
    cos-extensions install gpu
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
fi
