#!/bin/bash
# ==========================================================
# 🔄 TrueNAS /mnt/pool-1/home UID & GID Migration Script
# ==========================================================
# Run directly on TrueNAS (cairo) in root shell:
#   chmod +x migrate_truenas_uids.sh && ./migrate_truenas_uids.sh
# ==========================================================
set -e

echo '🚀 Starting UID/GID reconciliation on /mnt/pool-1/home...'

if [ -d '/mnt/pool-1/home/worachotn' ]; then
    echo '  Updating worachotn: 101001 -> 122153:2008...'
    chown -R 122153:2008 '/mnt/pool-1/home/worachotn'
fi

if [ -d '/mnt/pool-1/home/nopphawann' ]; then
    echo '  Updating nopphawann: 101003 -> 122410:2008...'
    chown -R 122410:2008 '/mnt/pool-1/home/nopphawann'
fi

if [ -d '/mnt/pool-1/home/pranisaac' ]; then
    echo '  Updating pranisaac: 101004 -> 123175:2008...'
    chown -R 123175:2008 '/mnt/pool-1/home/pranisaac'
fi

if [ -d '/mnt/pool-1/home/wanchanoks' ]; then
    echo '  Updating wanchanoks: 101014 -> 122053:2008...'
    chown -R 122053:2008 '/mnt/pool-1/home/wanchanoks'
fi

if [ -d '/mnt/pool-1/home/chaklams' ]; then
    echo '  Updating chaklams: 101007 -> 2002:2008...'
    chown -R 2002:2008 '/mnt/pool-1/home/chaklams'
fi

if [ -d '/mnt/pool-1/home/slwp1' ]; then
    echo '  Updating slwp1: 100001 -> 2003:2008...'
    chown -R 2003:2008 '/mnt/pool-1/home/slwp1'
fi

if [ -d '/mnt/pool-1/home/pasitt' ]; then
    echo '  Updating pasitt: 101011 -> 3001:2008...'
    chown -R 3001:2008 '/mnt/pool-1/home/pasitt'
fi

if [ -d '/mnt/pool-1/home/aimanl' ]; then
    echo '  Updating aimanl: 110008 -> 3002:2008...'
    chown -R 3002:2008 '/mnt/pool-1/home/aimanl'
fi

if [ -d '/mnt/pool-1/home/abhinavl' ]; then
    echo '  Updating abhinavl: 220001 -> 3003:2008...'
    chown -R 3003:2008 '/mnt/pool-1/home/abhinavl'
fi

if [ -d '/mnt/pool-1/home/buddhabhushans' ]; then
    echo '  Updating buddhabhushans: 110006 -> 3004:2008...'
    chown -R 3004:2008 '/mnt/pool-1/home/buddhabhushans'
fi

if [ -d '/mnt/pool-1/home/hamzak' ]; then
    echo '  Updating hamzak: 110002 -> 3005:2008...'
    chown -R 3005:2008 '/mnt/pool-1/home/hamzak'
fi

if [ -d '/mnt/pool-1/home/jinayp' ]; then
    echo '  Updating jinayp: 110007 -> 3006:2008...'
    chown -R 3006:2008 '/mnt/pool-1/home/jinayp'
fi

if [ -d '/mnt/pool-1/home/mokshs' ]; then
    echo '  Updating mokshs: 110005 -> 3007:2008...'
    chown -R 3007:2008 '/mnt/pool-1/home/mokshs'
fi

if [ -d '/mnt/pool-1/home/bci' ]; then
    echo '  Updating bci: 2009 -> 2001:2001...'
    chown -R 2001:2001 '/mnt/pool-1/home/bci'
fi

# Update GID to 2008 for all other users
echo '🔄 Ensuring GID 2008 on all other student home directories...'
for dir in /mnt/pool-1/home/*; do
    if [ -d "" ]; then
        user=""
        if [ "" != "bci" ]; then
            chown -R :2008 "" 2>/dev/null || true
        fi
    fi
done

echo '✅ TrueNAS UID & GID reconciliation complete!'
