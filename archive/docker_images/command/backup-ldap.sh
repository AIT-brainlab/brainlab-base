#!/bin/bash

set -e

BACKUP_PATH=/mnt/HDD/home/root/_backup/ldap
SLAPCAT=/usr/sbin/slapcat

current_time=$(date "+%Y%m%d-%H%M")

#Kepp the last n files
n=5

config_list=$(find ${BACKUP_PATH}/config.ldif* -type f -printf '%T@\t%p\n' | sort -t '  ' -g | head -n -${n} | cut -d ' ' -f 2- )

if [[ $(echo "$config_list" | wc -l) -gt $n ]];
then
    echo "$config_list" | xargs rm
fi


config_list=$(find ${BACKUP_PATH}/ldap.brainlab.ldif* -type f -printf '%T@\t%p\n' | sort -t '   ' -g | head -n -${n} | cut -d ' ' -f 2- )

if [[ $(echo "$config_list" | wc -l) -gt $n ]];
then
    echo "$config_list" | xargs rm
fi

# Create backup
nice ${SLAPCAT} -b cn=config > ${BACKUP_PATH}/config.ldif-${current_time}
nice ${SLAPCAT} -b dc=ldap,dc=brainlab > ${BACKUP_PATH}/ldap.brainlab.ldif-${current_time}
chown root:root ${BACKUP_PATH}/*
chmod 600 ${BACKUP_PATH}/*.ldif*