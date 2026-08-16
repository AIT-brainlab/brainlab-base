#!/bin/bash
FOLDER=""
cd $FOLDER && nohup ls . | xargs -n1 -P10 -I% rsync -aP % /mnt/HDD/home/archive > rsync.out