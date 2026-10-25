#!/bin/bash
# Debian 13 / Ubuntu 24.04 以降に Paper サーバーを入れる（何度実行してもよい）。
# このリポジトリを /opt/minecraft-server に置いて root で実行する:
#
#   ACCEPT_EULA=yes /opt/minecraft-server/install.sh
#
# ACCEPT_EULA=yes は Minecraft EULA (https://www.minecraft.net/eula) に同意したことを意味する。
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
data=/srv/minecraft
server="$data/server"
. "$repo/versions.env"

if [[ "$repo" != /opt/minecraft-server ]]; then
  echo "このリポジトリは /opt/minecraft-server に置いてください（systemd ユニットがこのパスを参照します）" >&2
  exit 1
fi

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-25-jre-headless python3 curl ca-certificates >/dev/null

id minecraft >/dev/null 2>&1 || useradd --system --home "$data" --shell /usr/sbin/nologin minecraft
install -d -o minecraft -g minecraft "$data" "$server" "$server/plugins"
install -d "$data/backups"

fetch() {  # fetch <url> <dest> <sha256|sha512> <hash>
  local url=$1 dest=$2 algo=$3 hash=$4
  if [[ -f "$dest" ]] && echo "$hash  $dest" | "${algo}sum" -c --status; then
    return
  fi
  curl -fsSL -o "$dest.tmp" "$url"
  echo "$hash  $dest.tmp" | "${algo}sum" -c --status || { echo "checksum mismatch: $url" >&2; rm -f "$dest.tmp"; exit 1; }
  mv "$dest.tmp" "$dest"
  chown minecraft:minecraft "$dest"
}

fetch "$PAPER_URL" "$server/paper.jar" sha256 "$PAPER_SHA256"
# 古いバージョンの ViaVersion が残らないようにする
find "$server/plugins" -maxdepth 1 -name 'ViaVersion-*.jar' ! -name "ViaVersion-$VIAVERSION_VERSION.jar" -delete
fetch "$VIAVERSION_URL" "$server/plugins/ViaVersion-$VIAVERSION_VERSION.jar" sha512 "$VIAVERSION_SHA512"

if [[ ! -f "$server/eula.txt" ]] || ! grep -q '^eula=true' "$server/eula.txt"; then
  if [[ "${ACCEPT_EULA:-}" != yes ]]; then
    echo "Minecraft EULA (https://www.minecraft.net/eula) に同意する場合は ACCEPT_EULA=yes を付けて実行してください" >&2
    exit 1
  fi
  echo "eula=true" > "$server/eula.txt"
  chown minecraft:minecraft "$server/eula.txt"
fi

# server.properties: 管理対象のキーだけ上書きし、RCON パスワードは初回に生成する
props="$server/server.properties"
touch "$props"
set_prop() {
  local key=$1 value=$2
  if grep -q "^${key}=" "$props"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$props"
  else
    echo "${key}=${value}" >> "$props"
  fi
}
grep -v '^\s*\(#\|$\)' "$repo/config/server.properties.managed" | while IFS='=' read -r key value; do
  set_prop "$key" "$value"
done
if ! grep -q '^rcon.password=.\+' "$props"; then
  set_prop rcon.password "$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9')"
fi
chown minecraft:minecraft "$props"
chmod 600 "$props"

[[ -f /etc/default/minecraft ]] || install -m 644 "$repo/config/minecraft.default" /etc/default/minecraft

install -m 644 "$repo"/systemd/minecraft*.service "$repo"/systemd/minecraft*.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable -q minecraft.service minecraft-backup.timer
systemctl restart minecraft.service
systemctl start minecraft-backup.timer

echo "installed Paper $PAPER_VERSION build $PAPER_BUILD + ViaVersion $VIAVERSION_VERSION"
echo "logs: journalctl -u minecraft -f"
