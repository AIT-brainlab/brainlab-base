#!/bin/bash

GROUP="jan2025"

for USERNAME in $(ls /root/$GROUP)
do
    USERHOME=/home/$USERNAME/
    adduser $USERNAME --ingroup $GROUP --disabled-password --comment ""
    usermod -aG docker $USERNAME
    mkdir $USERHOME/.ssh
    mv /root/$GROUP/$USERNAME $USERHOME/.ssh/authorized_keys
    chmod 600 $USERHOME/.ssh/authorized_keys
    chmod 700 $USERHOME/.ssh/
    chown $USERNAME:$GROUP -R $USERHOME/.ssh
    echo "set noautoindent" > $USERHOME/.vimrc
    chown $USERNAME:$GROUP -R $USERHOME/.vimrc
done
